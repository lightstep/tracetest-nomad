# Notes

**Assumption:** You have a Nomad/Vault/Consul HashiCorp environment running in a DC or locally using [HashiQube](https://github.com/avillela/hashiqube) set up. These jobspecs are set up assuming you are running Nomad locally via HashiQube. Please update accordingly for a DC setup.

## Jobspec Template

I used the Helm chart output to create the Tracetest jobspec.

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

1. Start up [hashiqube](https://github.com/avillela/hashiqube)

2. Update `/etc/hosts`

Add the following:

```text
192.168.56.192  tracetest.localhost
192.168.56.192  postgres.localhost
192.168.56.192  jaeger-ui.localhost
192.168.56.192  jaeger-grpc.localhost
192.168.56.192  jaeger-proto.localhost
192.168.56.192  go-server.localhost
```

3. Deploy to Nomad

```bash
# Traefik with HTTP and gRPC enabled
nomad job run jobspec/traefik.nomad

# PostgreSQL DB required by Tracetest
nomad job run jobspec/postgres.nomad

# Tracetest
nomad job run jobspec/tracetest.nomad

# Jaeger tracing backend, supported by Tracetest
nomad job run jobspec/jaeger.nomad

# Go server app
nomad job run jobspec/go-server.nomad
```

4. Check the PostgreSQL connection

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

5. Make sure tha Jaeger is up and running

Check gRPC endpoint (used by Tracetest)

```bash
grpcurl --plaintext jaeger-grpc.localhost:7233 list
```

>**NOTE:** We exposed port `7233` in Traefik, which maps to Jaeger gRPC container port `16685`.

Jaeger UI accessed here: `http://jaeger-ui.localhost`

6. Make sure that Tracetest is up and running

Tracetest UI accessed here: `http://tracetest.localhost`

7. Access the sample app

Open a browser: `http://go-server.localhost`

## Testing

****WORK IN PROGRESS - DOES NOT WORK YET****

You can try out Tracetest against the [Pokeshop example](https://github.com/kubeshop/pokeshop). You can either [build and run yourself](https://github.com/kubeshop/pokeshop/blob/master/docs/installing.md), or you can hit up the running example's API [here](https://pokeapi.co/api/v2).

## Troubleshooting

Login

```bash
psql -h postgres.localhost -d tracetest -U tracetest -W
```

Inspect runs -> Get run ID from `stdout` log. Sample log message:

```
2022/06/07 19:19:06 GET /api/tests/79e74617-e709-4113-a5a6-b334140c358e/run/dbefe9f9-ba90-421c-bac3-436165a99d3d GetTestRun 1.248909ms
```

The API endpoint is:

```
/api/tests/{test_id}/run/{run_id}
```

Now you can run the query:

```sql
select run from runs where id = '<run_id>';
```