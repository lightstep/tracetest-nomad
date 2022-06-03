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

    network {
      
      port "db" {
        static = 5432
      }
    }

    task "app-postgres" {
      driver = "docker"

      config {
        image = "docker.io/bitnami/postgresql:14.2.0-debian-10-r45"
        ports = ["db"]
      }
      env {
          BITNAMI_DEBUG = "false"
          POSTGRESQL_PORT_NUMBER = "5432"
          POSTGRESQL_VOLUME_DIR = "/bitnami/postgresql"
          PGDATA = "/bitnami/postgresql/data"
          POSTGRES_USER = "tracetest"
          POSTGRES_POSTGRES_PASSWORD = "lKcy7eXtHv"
          POSTGRES_PASSWORD = "not-secure-database-password"
          POSTGRES_DB = "tracetest"
          POSTGRESQL_ENABLE_LDAP = "no"
          POSTGRESQL_LOG_HOSTNAME = "false"
          POSTGRESQL_LOG_CONNECTIONS = "false"
          POSTGRESQL_LOG_DISCONNECTIONS = "false"
          POSTGRESQL_PGAUDIT_LOG_CATALOG = "off"
          POSTGRESQL_CLIENT_MIN_MESSAGES = "error"
          POSTGRESQL_SHARED_PRELOAD_LIBRARIES = "pgaudit"
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