# Notes

Notes I use to create the Tracetest jobspec.

1. Render helm charts:

```bash
helm repo add kubeshop https://kubeshop.github.io/helm-charts
helm repo update
helm template tracetest kubeshop/tracetest > tracetest.yaml
```

2. Base64 decode k8s secrets:

```bash
# postgrest-password
echo bEtjeTdlWHRIdg== | base64 -d

# password
echo bm90LXNlY3VyZS1kYXRhYmFzZS1wYXNzd29yZA== | base64 -d
```