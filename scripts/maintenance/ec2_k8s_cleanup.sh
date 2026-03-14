#!/usr/bin/env bash
# Used to clean up a Kubernetes node (EKS or self-managed).
# - Deletes bad pods (Evicted, Error, ContainerStatusUnknown)
# - Optionally deletes Completed pods from Jobs
# - Prunes container images (containerd or docker)
# - Cleans broken K8s log symlinks
# - Vacuums systemd journal (keeps ~200MB)
set -euo pipefail

echo "[1/5] Delete bad pods (all namespaces)…"
# Evicted / Error / ContainerStatusUnknown pods
kubectl get pods -A \
| egrep 'Evicted|Error|ContainerStatusUnknown' \
| awk '{print $1" "$2}' \
| xargs -r -n2 sh -c 'kubectl delete pod -n "$0" "$1"'

echo "[2/5] Optionally delete Completed pods from Jobs…"
kubectl get pods -A --field-selector=status.phase=Succeeded \
  -o name | xargs -r kubectl delete || true

echo "[3/5] Free node space: detect container runtime…"
RUNTIME="unknown"
if command -v crictl >/dev/null 2>&1; then
  if crictl info >/dev/null 2>&1; then
    RUNTIME="containerd"
  fi
fi
if [[ "$RUNTIME" == "unknown" ]] && command -v docker \
  >/dev/null 2>&1; then
  if docker info >/dev/null 2>&1; then
    RUNTIME="docker"
  fi
fi
echo "Runtime: $RUNTIME"

if [[ "$RUNTIME" == "containerd" ]]; then
  echo "Pruning with crictl / ctr…"
  crictl rm -a || true
  crictl rmi --prune || true
  if command -v ctr >/dev/null 2>&1; then
    ctr -n k8s.io images prune || true
  fi
elif [[ "$RUNTIME" == "docker" ]]; then
  echo "Pruning with docker…"
  docker container prune -f || true
  docker image prune -af || true
  docker volume prune -f || true
else
  echo "No known runtime detected; skipping image prune."
fi

echo "[4/5] Clean broken K8s log symlinks (safe)…"
find /var/log/containers -xtype l -delete 2>/dev/null || true
find /var/log/pods -xtype l -delete 2>/dev/null || true

echo "[5/5] Vacuum systemd journal (keep ~200MB)…"
journalctl --vacuum-size=200M || true

echo "Done."
