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

3. Update `/etc/hosts`

Add the following:

```text
192.168.56.192  tracetest.localhost
192.168.56.192  postgres.localhost
```

4. Install `postgres` on Mac using Homebrew so we have access to the `pg_isready` CLI.

Ref [here](https://stackoverflow.com/a/46703723).

```bash
brew install postgres
brew tap homebrew/services

# Check that postgres isn't running, since we don't want it running locally
brew services list
```

5. Check postgres connection

```bash
pg_isready -d tracetest -h postgres.localhost -p 5432 -U tracetest
```