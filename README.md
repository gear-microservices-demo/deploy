# deploy

Deployment artifacts for the Online Boutique microservices, extracted from the
original monorepo. Contains:

- `kubernetes-manifests/` — plain Kubernetes manifests (with aggregate `kustomization.yaml`).
- `kustomize/` — Kustomize base + components (variants/overlays).
- `helm-chart/` — Helm chart for the full application.
- `istio-manifests/` — Istio gateway / virtual service manifests.
- `release/` — pre-rendered release manifests.
- `skaffold.yaml` — Skaffold build/deploy config (build stanzas reference the
  per-service repos' source, which now live in separate repositories).

Note: references to service source directories (e.g. in `skaffold.yaml`) point to
the now-separate per-service repositories.

## Run locally

The quickest way to run the whole app on your machine is a local
[kind](https://kind.sigs.k8s.io/) cluster plus the pre-rendered release
manifests, which use public prebuilt images — no GCP credentials or local image
builds required.

Requirements: `docker` (running), `kind`, `kubectl`.

```bash
./run-local.sh
```

This creates a kind cluster named `boutique`, applies
`release/kubernetes-manifests.yaml`, waits for all deployments, and
port-forwards the frontend to http://localhost:8080. Override the local port
with `PORT=8088 ./run-local.sh`, or skip port-forwarding with
`./run-local.sh --no-forward`.

Tear down with:

```bash
kind delete cluster --name boutique
```

To build and run from local source instead of prebuilt images, use Skaffold
(`skaffold run`) with the per-service repos checked out as siblings, or the
`helm-chart/` and `kustomize/` variants.
