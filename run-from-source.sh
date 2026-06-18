#!/usr/bin/env bash
#
# Build every service from local source and run the app on a kind cluster via
# Skaffold. Unlike run-local.sh (which uses prebuilt published images), this
# builds your local code into images and loads them into the cluster, so local
# changes are reflected.
#
# Skaffold's build contexts (skaffold.yaml) expect each service's source under
# ./src/<service>. The services live in separate repos, so this script checks
# them out as siblings of this repo and symlinks them into ./src.
#
# Requirements: docker (running), kind, kubectl, skaffold, git.
# Usage:
#   ./run-from-source.sh            # setup src/, create cluster, skaffold run
#   ./run-from-source.sh --no-run   # only set up src/ symlinks (then run skaffold yourself)
#
set -euo pipefail

CLUSTER="${CLUSTER:-boutique}"
ORG="${ORG:-https://github.com/gear-microservices-demo}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPOS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

SERVICES=(emailservice productcatalogservice recommendationservice \
  shoppingassistantservice shippingservice checkoutservice paymentservice \
  currencyservice cartservice frontend adservice loadgenerator)

for bin in docker kind kubectl skaffold git; do
  command -v "$bin" >/dev/null 2>&1 || { echo "ERROR: '$bin' is not installed." >&2; exit 1; }
done
docker info >/dev/null 2>&1 || { echo "ERROR: Docker daemon is not running." >&2; exit 1; }

mkdir -p "${SCRIPT_DIR}/src"
for s in "${SERVICES[@]}"; do
  if [[ ! -d "${REPOS_DIR}/${s}" ]]; then
    echo ">> Cloning ${s} into ${REPOS_DIR}/${s}..."
    git clone "${ORG}/${s}.git" "${REPOS_DIR}/${s}"
  fi
  ln -sfn "../../${s}" "${SCRIPT_DIR}/src/${s}"
done
echo ">> src/ symlinks ready."

if [[ "${1:-}" == "--no-run" ]]; then
  echo "Now run: skaffold run   (from ${SCRIPT_DIR})"
  exit 0
fi

if ! kind get clusters 2>/dev/null | grep -qx "$CLUSTER"; then
  echo ">> Creating kind cluster '$CLUSTER'..."
  kind create cluster --name "$CLUSTER" --wait 120s
fi

echo ">> Building all services from source and deploying (first run is slow)..."
cd "${SCRIPT_DIR}"
skaffold run --platform=linux/amd64 --kube-context "kind-${CLUSTER}"

echo ">> Deployed. Port-forward the frontend with:"
echo "   kubectl --context kind-${CLUSTER} port-forward deployment/frontend 8080:8080"
