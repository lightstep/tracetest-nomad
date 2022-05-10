job "app-postgres" {

  datacenters = ["dc1"]
  type        = "service"


  group "app-postgres" {
    restart {
      attempts = 10
      interval = "5m"
      delay    = "10s"
      mode     = "delay"
    }

    vault {
      policies = ["postgres"]
    }

    network {
      
      port "db" {
        static = 5432
      }
    }

    task "app-postgres-prehook" {
      lifecycle {
        hook = "prestart"
        sidecar = false
      }

      driver = "docker"
      config {
        image = "alpine:3.12.4"
        command = "sh"
        args = ["-c", "chown -R 1000:1000 /data/app && chmod -R 777 /data/app"]
      }
      volume_mount {
        volume      = "postgres"
        destination = "/data/app"
        read_only   = false
      }
    }

    task "app-postgres" {
      driver = "docker"

      config {
        image = "postgres:12.10"
        ports = ["db"]
      }
      env {
          POSTGRES_USER = "tracetest",
          POSTGRES_POSTGRES_PASSWORD = "lKcy7eXtHv",
          POSTGRES_PASSWORD = "not-secure-database-password",
          POSTGRES_DB = "tracetest",
      }

      resources {
        cpu    = 200
        memory = 512
      }

    service {
      name = "app-postgres"
      port = "db"
      tags = [
      "app-postgres",
      "traefik.enable=true",
      "traefik.tcp.routers.postgres.rule=HostSNI(`*`)",
      "traefik.tcp.routers.postgres.entrypoints=postgres",
      ]

      check {
        type     = "tcp"
        port     = "db"
        interval = "10s"
        timeout  = "5s"
        } 
      }  
    }
  }
}