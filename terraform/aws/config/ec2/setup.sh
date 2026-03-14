#!/bin/bash
set -ex

# Set non-interactive mode for apt-get
export DEBIAN_FRONTEND=noninteractive

echo "--- Starting EC2 Setup Script ---"

# 1. Update packages and expand disk space
echo "1. Updating packages and expand disk space..."

apt-get update -y && apt-get install -y unattended-upgrades
sudo apt-get install -y cloud-guest-utils xfsprogs

# Expand root partition
sudo growpart /dev/nvme0n1 1 || true

# Resize filesystem (ext4 or xfs)
if df -T / | grep -q ext4; then
  sudo resize2fs /dev/nvme0n1p1 || true
else
  sudo xfs_growfs -d / || true
fi

# 2. Install AWS CLI and setup
echo "2. Installing AWS CLI..."

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y unzip

curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" \
  -o "/tmp/awscliv2.zip"
unzip -q /tmp/awscliv2.zip -d /tmp
sudo /tmp/aws/install
sudo snap start amazon-ssm-agent

# Clean up
rm -rf /tmp/aws /tmp/awscliv2.zip

# 3. Installing git and make
echo "3. Installing git and make..."

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y git
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y make

# 4. Installing Docker
echo "4. Installing Docker..."

sudo apt-get install -y ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) \
  signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli \
  containerd.io docker-buildx-plugin docker-compose-plugin

# Add ubuntu user to docker group
sudo usermod -aG docker ubuntu

# Configure Docker auth for root (kubelet / prod pulls)
sudo apt install -y amazon-ecr-credential-helper

REGION="af-south-1"
ACCOUNT_ID="$(
	aws sts get-caller-identity \
	--query Account \
	--output text
)"

if [ -z "$ACCOUNT_ID" ] || [ "$ACCOUNT_ID" = "None" ]; then
	echo "Failed to get AWS account id" >&2
	exit 1
fi

sudo mkdir -p /root/.docker

sudo tee /root/.docker/config.json >/dev/null <<JSON
{
	"credHelpers": {
		"${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com": "ecr-login"
	}
}
JSON

# 5. Installing k3s with docker and setting up kubectl
echo "5. Installing k3s with Docker..."

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--docker" sh -
sudo ln -sf /usr/local/bin/kubectl /usr/bin/kubectl

# TODO: Find more secure way of handling access to k3s
# For now it works but not the best
sudo chmod 644 /etc/rancher/k3s/k3s.yaml

# Wait for the node to appear in kubectl
for i in {1..30}; do
  NODE_NAME=$(hostname)
  if sudo k3s kubectl get node "$NODE_NAME" &>/dev/null; then
    break
  fi
  echo "Waiting for node $NODE_NAME to register with k3s..."
  sleep 5
done

kubectl wait --for=condition=Ready node/"$(hostname)" --timeout=120s

# 6. Pull services and deploy with makefile targets
echo "6. Pulling services and launching deployments..."

AWS_REGION="af-south-1"

TMP_DIR="$(mktemp -d -t mwalika-XXXXXX)"
chmod 700 "$TMP_DIR"

# Cleanup function to run on exit
cleanup() {
  rc=$?
  echo "7. Cleaning up resources from service deployment..."
  ssh-agent -k >/dev/null 2>&1 || true
  rm -rf "$TMP_DIR"
  unset GIT_SSH_COMMAND
  exit "$rc"
}
trap cleanup EXIT

# Set ssh-agent
eval "$(ssh-agent -s)"
export GIT_SSH_COMMAND='ssh -o StrictHostKeyChecking=no'

# Deployment function
deploy_service() {
  local NAME="$1"
  shift
  local MODES=("$@")

  echo "Launching $NAME..."

  local SECRET_ID="${NAME}/key/repo"
  local REPO="git@github.com:karaalv/${NAME}.git"

  # Pull key from AWS Secrets Manager
  aws secretsmanager get-secret-value \
    --secret-id "$SECRET_ID" \
    --region "$AWS_REGION" \
    --query SecretString \
    --output text \
    > "$TMP_DIR/${NAME}-key"

  chmod 600 "$TMP_DIR/${NAME}-key"
  ssh-add "$TMP_DIR/${NAME}-key"

  # Clone repo
  cd "$TMP_DIR"
  git clone "$REPO" "$NAME"
  cd "$NAME"

  # Deploy each mode
  for mode in "${MODES[@]}"; do
    make "deploy-${mode}"
  done

  cd "$TMP_DIR"
}

# Deploy services

# 6.1 Mwalika Frontend
deploy_service "mwalika-frontend" "production"

# 6.2 Mwalika Agent
deploy_service "mwalika-agent" "production"

# Script completed successfully
echo "--- Setup Script Completed Successfully ---"

# Cleanup function to run on exit
