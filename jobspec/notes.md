# Notes

**Assumption:** You have a Nomad/Vault/Consul HashiCorp environment running in a DC or locally using [HashiQube](https://github.com/avillela/hashiqube) set up. These jobspecs are set up assuming you are running Nomad locally via HashiQube. Please update accordingly for a DC setup.

## Jobspec Template

Notes I used to create the Tracetest jobspec.

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

## Running the Jobspecs

1. Update `/etc/hosts`

Add the following:

```text
192.168.56.192  tracetest.localhost
192.168.56.192  postgres.localhost
192.168.56.192  jaeger-ui.localhost
192.168.56.192  jaeger-grpc.localhost
```

2. Deploy to Nomad

```bash
# Traefik with HTTP and gRPC enabled
nomad job run jobspec/traefik.nomad

# PostgreSQL DB required by Tracetest
nomad job run jobspec/postgres.nomad

# Tracetest
nomad job run jobspec/tracetest.nomad

# Jaeger tracing backend, supported by Tracetest
nomad job run jobspec/jaeger.nomad
```

3. Check the PostgreSQL connection

Install `postgres` on Mac using Homebrew so we have access to the `pg_isready` CLI, as per [these instructions](https://stackoverflow.com/a/46703723).

>**NOTE:** This downloads and installs PostgreSQL on your Mac, but doesn't run the service. We just want to use the `pg_isready` util to make sure that we can connect to our DB.

```bash
brew install postgres
brew tap homebrew/services

# Check that postgres isn't running, since we don't want it running locally
brew services list
```

Now we can test our connection. More info [here](https://stackoverflow.com/a/44496546).

```bash
pg_isready -d tracetest -h postgres.localhost -p 5432 -U tracetest
```

4. Make sure tha Jaeger is up and running

Check gRPC endpoint (used by Tracetest)
```bash
grpcurl --plaintext jaeger-grpc.localhost:7233 list
```

Jaeger UI accessed here: `http://jaeger-ui.localhost`

5. Make sure that Tracetest is up and running

Tracetest UI accessed here: `http://tracetest.localhost`