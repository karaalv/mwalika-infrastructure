#!/usr/bin/env bash

# Fail fast, catch unset vars, fail pipelines properly
set -euo pipefail

# Safer word splitting (avoid spaces causing bugs)
IFS=$'\n\t'

# Default to private perms for any files we create
umask 077

need_var() {
	local name="$1"
	if [ -z "${!name:-}" ]; then
		echo "Error: $name is not set." >&2
		exit 1
	fi
}

# Required CI inputs
need_var "GIT_BRANCH"
need_var "MWALIKA_SERVICE"

# Allow overrides via env, safe defaults for CodeBuild
AWS_REGION="${AWS_REGION:-af-south-1}"
K8S_NAMESPACE="${K8S_NAMESPACE:-default}"
ORG="${ORG:-karaalv}"
REPO="${ORG}/${MWALIKA_SERVICE}.git"

echo "1. Setup redeploy for '${MWALIKA_SERVICE}'"

# Isolated workspace for repo + transient files
TMP_DIR="$(mktemp -d -t "${MWALIKA_SERVICE}.XXXXXX")"
chmod 700 "$TMP_DIR"

AGENT_STARTED="0"

cleanup() {
	# Never let cleanup fail the build
	set +e
	echo "5. Cleaning up"

	if [ "$AGENT_STARTED" = "1" ]; then
		ssh-agent -k >/dev/null 2>&1 || true
	fi

	if [ -n "${TMP_DIR:-}" ] && [ -d "$TMP_DIR" ]; then
		rm -rf "$TMP_DIR"
	fi
}

# CodeBuild commonly stops jobs with SIGTERM
trap cleanup EXIT INT TERM

echo "2. Load repo deploy key for '${MWALIKA_SERVICE}'"

# Start agent and export SSH_AUTH_SOCK into this shell
eval "$(ssh-agent -s)" >/dev/null
AGENT_STARTED="1"

# Pull key and load it into agent, key never hits disk
aws secretsmanager get-secret-value \
	--secret-id "${MWALIKA_SERVICE}/key/repo" \
	--region "$AWS_REGION" \
	--query SecretString \
	--output text \
| ssh-add - >/dev/null

# Pin host identity for non-interactive, safer SSH
KNOWN_HOSTS="${TMP_DIR}/known_hosts"
ssh-keyscan github.com 2>/dev/null \
> "$KNOWN_HOSTS"

export GIT_SSH_COMMAND="ssh \
-o StrictHostKeyChecking=yes \
-o UserKnownHostsFile=$KNOWN_HOSTS"

echo "3. Clone repo '${MWALIKA_SERVICE}' on branch '${GIT_BRANCH}'"

cd "$TMP_DIR"
rm -rf "$MWALIKA_SERVICE"

# Explicit destination dir keeps layout predictable
git clone \
	--branch "$GIT_BRANCH" \
	--single-branch \
	"git@github.com:${REPO}" \
	"$MWALIKA_SERVICE"

cd "$MWALIKA_SERVICE"

echo "4. Deploy application"

# k3s kubeconfig may be root-owned on some hosts
# This is only relevant if kubectl reads this default path
if [ -f /etc/rancher/k3s/k3s.yaml ]; then
	sudo chmod 644 /etc/rancher/k3s/k3s.yaml || true
fi

echo "Branch to deploy: ${GIT_BRANCH}"
echo "K8S namespace: ${K8S_NAMESPACE}"

# Deployment is intentionally branch-gated
case "$GIT_BRANCH" in
	staging)
		make deploy-staging
		;;
	main)
		make deploy-production
		;;
	*)
		echo "Invalid branch '${GIT_BRANCH}', refusing to deploy."
		exit 1
		;;
esac

echo "Service '${MWALIKA_SERVICE}' deployed successfully"

# Optional hygiene: prune old images to keep disk sane
# Risk: can remove rollback images on small nodes
echo "Cleaning up old Docker images for this service"

sleep 10 || true

# Never fail deploy due to cleanup issues
set +e

# Keep the N most recent images for this service
KEEP_COUNT="3"

# Service images are named with this repo prefix
IMAGE_REPO="${MWALIKA_SERVICE}"

# Collect image IDs sorted by creation time (newest first)
mapfile -t IMAGE_IDS < <(
	sudo docker images \
		--format '{{.CreatedAt}}\t{{.ID}}\t{{.Repository}}' \
	| grep -F "$IMAGE_REPO" \
	| sort -r \
	| awk -F'\t' '{ print $2 }' \
	| awk '!seen[$0]++'
)

# If we have fewer than KEEP_COUNT images, do nothing
if [ "${#IMAGE_IDS[@]}" -le "$KEEP_COUNT" ]; then
	echo "No cleanup needed, found ${#IMAGE_IDS[@]} image(s)"
else
	echo "Keeping ${KEEP_COUNT} newest images, removing the rest"

	# Remove all images older than the KEEP_COUNT threshold
	for ((i=KEEP_COUNT; i<${#IMAGE_IDS[@]}; i++)); do
		sudo docker rmi -f "${IMAGE_IDS[$i]}" >/dev/null 2>&1 || true
	done
fi

# Restore strict error handling
set -e
