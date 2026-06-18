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
