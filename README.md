# helm-repo

Helm charts for the GenAI platform services, one chart per top-level directory,
consumed by ArgoCD (`spec.source.path` = the directory name).

| Path                                       | Service                          | Source repo                |
| ------------------------------------------ | -------------------------------- | -------------------------- |
| [`data-context-layer/`](data-context-layer) | Cube semantic layer (API + refresh worker) | `~/Projects/cubejs-service` |
| [`genai-mcp-server/`](genai-mcp-server)     | MCP server with Entra ID OAuth   | `~/Projects/genai-mcp-server` |
| [`argocd/`](argocd)                        | ArgoCD `Application` manifests   | —                          |

## Secrets

No chart renders a `Secret`. Each chart ships a `secret.example.yaml`: copy it,
fill in the values, and apply it to the namespace **before** the first sync. The
chart references it by name through `existingSecret` (env vars, via `envFrom`)
and `existingSecretFile` (mounted files).

`secret.example.yaml` is listed in `.helmignore`, so it is never packaged.

## Layout of a chart

```
<service>/
  Chart.yaml
  values.yaml            # stg defaults; overridden per-env from the Argo Application
  secret.example.yaml    # fill in + kubectl apply by hand
  templates/
    _helpers.tpl  deployment.yaml  service.yaml  ingress.yaml
    serviceaccount.yaml  vpa.yaml
```

`data-context-layer` additionally has `values-worker.yaml`: the refresh worker is
a **second release of the same chart** (same image, `CUBEJS_REFRESH_WORKER=true`,
no ingress/probes) rather than a second Deployment template.

`cubestore-router` is intentionally not in this repo — it runs the stock
`cubejs/cubestore` image and is deployed separately. Until it sits alongside the
release, `CUBEJS_ENABLE_PREAGG` must stay `"false"`.

## Local checks

```bash
helm lint data-context-layer genai-mcp-server
helm template dcl ./data-context-layer
helm template dcl-worker ./data-context-layer \
  -f data-context-layer/values.yaml -f data-context-layer/values-worker.yaml
helm template mcp ./genai-mcp-server
```

## Deploy

```bash
kubectl apply -f argocd/data-context-layer.yaml
kubectl apply -f argocd/genai-mcp-server.yaml
```

CI sets `image.tag` through the Application's `helm.parameters`; everything else
comes from the checked-in values files.

> The values in `argocd/` (`repoURL`, `project`, `targetRevision`) are the
> expected defaults — check them against your ArgoCD instance before applying.
