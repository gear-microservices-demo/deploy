#!/usr/bin/env bash
#
# Bring up Online Boutique locally on a kind cluster using the pre-rendered
# release manifests (public prebuilt images — no GCP credentials or local image
# builds required).
#
# Requirements (see README): docker, kind, kubectl.
# Usage:
#   ./run-local.sh            # create cluster, deploy, wait, port-forward
#   ./run-local.sh --no-forward   # create cluster and deploy only
#   PORT=8088 ./run-local.sh  # override local port (default 8080)
#
set -euo pipefail

CLUSTER="${CLUSTER:-boutique}"
PORT="${PORT:-8080}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="${SCRIPT_DIR}/release/kubernetes-manifests.yaml"

for bin in docker kind kubectl; do
  command -v "$bin" >/dev/null 2>&1 || { echo "ERROR: '$bin' is not installed." >&2; exit 1; }
done
docker info >/dev/null 2>&1 || { echo "ERROR: Docker daemon is not running." >&2; exit 1; }

if ! kind get clusters 2>/dev/null | grep -qx "$CLUSTER"; then
  echo ">> Creating kind cluster '$CLUSTER'..."
  kind create cluster --name "$CLUSTER" --wait 120s
else
  echo ">> Reusing existing kind cluster '$CLUSTER'."
fi

echo ">> Applying release manifests..."
kubectl --context "kind-${CLUSTER}" apply -f "$MANIFEST"

echo ">> Waiting for all deployments to become available (this pulls images)..."
kubectl --context "kind-${CLUSTER}" wait --for=condition=available --timeout=600s deployment --all

echo ">> All services are up."
if [[ "${1:-}" == "--no-forward" ]]; then
  echo "Run: kubectl --context kind-${CLUSTER} port-forward deployment/frontend ${PORT}:8080"
  exit 0
fi

echo ">> Port-forwarding frontend to http://localhost:${PORT} (Ctrl+C to stop)..."
exec kubectl --context "kind-${CLUSTER}" port-forward deployment/frontend "${PORT}:8080"
