#!/usr/bin/env bash

# Fail fast, fail loud:
# -e  exit on error
# -u  error on unset vars
# -o pipefail  fail if any part of a pipe fails
set -euo pipefail

# Safer word-splitting, avoid bugs with spaces in paths
IFS=$'\n\t'

# Default to private file permissions (good for secrets in CI)
umask 077

# Helper to assert required environment variables exist
need_var() {
    local name="$1"
    # Indirect expansion lets us check the variable by name
    if [ -z "${!name:-}" ]; then
        echo "Error: $name is not set." >&2
        exit 1
    fi
}

# Required CI inputs
need_var "GIT_BRANCH"
need_var "MWALIKA_SERVICE"

# Defaults (:- avoids errors with set -u)
AWS_REGION="${AWS_REGION:-af-south-1}"
ORG="${ORG:-karaalv}"

# Full repo path used by git clone
REPO="${ORG}/${MWALIKA_SERVICE}.git"

echo "1. Setup build for '${MWALIKA_SERVICE}'"

# Create isolated temp workspace for this build
TMP_DIR="$(mktemp -d -t "${MWALIKA_SERVICE}.XXXXXX")"
chmod 700 "$TMP_DIR"

# Track whether we started ssh-agent so we can cleanly shut it down
AGENT_STARTED="0"

cleanup() {
    # Cleanup must never fail the build
    set +e
    echo "5. Cleaning up"

    # Kill ssh-agent if we started it
    if [ "$AGENT_STARTED" = "1" ]; then
        ssh-agent -k >/dev/null 2>&1 || true
    fi

    # Remove temp workspace
    if [ -n "${TMP_DIR:-}" ] && [ -d "$TMP_DIR" ]; then
        rm -rf "$TMP_DIR"
    fi
}

# Ensure cleanup runs on normal exit or CI termination
trap cleanup EXIT INT TERM

echo "2. Retrieve repo SSH key"

# Start ssh-agent and load its env vars into this shell
# Output is hidden, env vars still apply
eval "$(ssh-agent -s)" >/dev/null
AGENT_STARTED="1"

# Fetch private key from Secrets Manager and pipe directly into agent
# Key never touches disk
aws secretsmanager get-secret-value \
    --secret-id "${MWALIKA_SERVICE}/key/repo" \
    --region "$AWS_REGION" \
    --query SecretString \
    --output text \
| ssh-add - >/dev/null

# Temporary known_hosts file for strict SSH verification
KNOWN_HOSTS="${TMP_DIR}/known_hosts"

# Preload GitHub host keys to avoid interactive prompts
ssh-keyscan github.com 2>/dev/null \
> "$KNOWN_HOSTS"

# Force git/ssh to use our known_hosts and enforce verification
export GIT_SSH_COMMAND="ssh \
-o StrictHostKeyChecking=yes \
-o UserKnownHostsFile=$KNOWN_HOSTS"

echo "3. Clone repository on branch '${GIT_BRANCH}'"

cd "$TMP_DIR"
rm -rf "$MWALIKA_SERVICE"

# Explicit destination directory keeps layout predictable
git clone \
    --branch "$GIT_BRANCH" \
    --single-branch \
    "git@github.com:${REPO}" \
    "$MWALIKA_SERVICE"

cd "$MWALIKA_SERVICE"

echo "4. Build and push Docker image"

# Delegates build logic to the service Makefile
make build-push

echo "Service '${MWALIKA_SERVICE}' built and pushed successfully"
