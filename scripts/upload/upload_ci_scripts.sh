#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'
umask 077

# Defaults tuned for local setup, 
# override in CI env as needed
AWS_PROFILE="${AWS_PROFILE:-personal}"
AWS_REGION="${AWS_REGION:-af-south-1}"
BUCKET_NAME="${BUCKET_NAME:-mwalika-scripts}"
S3_PREFIX="${S3_PREFIX:-ci/}"

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CI_DIR="${REPO_ROOT}/scripts/ci"

usage() {
	cat <<'EOF'
Upload scripts/ci/ to the defined S3 bucket s3://<BUCKET_NAME>/<S3_PREFIX>

Usage:
	./scripts/upload/upload_ci_scripts.sh [--dry-run] [--help]

Notes:
	- Uses AWS profile "personal" by default
	- Uses region af-south-1 by default
	- Syncs scripts/ci/ to s3://mwalika-scripts/ci/ by default
	- Deletes stale objects under that prefix to mirror local state
EOF
}

DRY_RUN="0"

if [ "${1:-}" = "--help" ]; then
	usage
	exit 0
fi

if [ "${1:-}" = "--dry-run" ]; then
	DRY_RUN="1"
fi

if [ ! -d "$CI_DIR" ]; then
	echo "Error: Missing dir: $CI_DIR" >&2
	exit 1
fi

# Resolve object location
S3_BUCKET="${BUCKET_NAME}"
DEST="s3://${S3_BUCKET}/${S3_PREFIX}"

echo "Publishing CI scripts"
echo "Profile: ${AWS_PROFILE}"
echo "Region:  ${AWS_REGION}"
echo "Source:  ${CI_DIR}"
echo "Dest:    ${DEST}"

SYNC_ARGS=(
	"--only-show-errors"
	"--delete"
	"--exclude" ".DS_Store"
	"--exclude" "*.swp"
	"--exclude" "*.tmp"
	"--exclude" "*.bak"
	"--exclude" ".git/*"
    "--exclude" "*.md"
)

if [ "$DRY_RUN" = "1" ]; then
	SYNC_ARGS+=("--dryrun")
	echo "Mode:    DRY RUN"
else
	echo "Mode:    LIVE"
fi

# Ensure shell scripts are executable in the repo
find "$CI_DIR" -type f -name "*.sh" \
	-exec chmod 755 {} \;

aws --profile "$AWS_PROFILE" \
	--region "$AWS_REGION" \
	s3 sync "$CI_DIR" "$DEST" "${SYNC_ARGS[@]}"

echo "Done"
