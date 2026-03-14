# This is a simple set of commands that
# can be copy pasted into an EC2 instance
# terminal to quickly deploy a service.

# NOTE: Make sure to turn this into a heredoc for 
# copy pasting. bash << 'EOF' ... EOF

export AWS_REGION="af-south-1"
export NAME="mwalika-agent"

TMP_DIR="$(mktemp -d -t mwalika-XXXXXX)"
chmod 700 "$TMP_DIR"

export SECRET_ID="${NAME}/key/repo"
export REPO="git@github.com:karaalv/${NAME}.git"

cleanup() {
  rc=$?
  echo "Cleaning up resources from service deployment..."
  ssh-agent -k >/dev/null 2>&1 || true
  rm -rf "$TMP_DIR"
  unset GIT_SSH_COMMAND
  exit "$rc"
}
trap cleanup EXIT

eval "$(ssh-agent -s)" >/dev/null
export GIT_SSH_COMMAND='ssh -o StrictHostKeyChecking=no'

aws secretsmanager get-secret-value \
	--secret-id "$SECRET_ID" \
	--region "$AWS_REGION" \
	--query SecretString \
	--output text \
	> "$TMP_DIR/${NAME}-key"

chmod 600 "$TMP_DIR/${NAME}-key"
ssh-add "$TMP_DIR/${NAME}-key" >/dev/null

cd "$TMP_DIR"
git clone "$REPO" "$NAME"
cd "$NAME"

make deploy-production
