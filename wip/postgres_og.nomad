job "app-postgres" {

  datacenters = ["${datacenter}"]
  type        = "service"


  constraint {
    attribute = "$${meta.namespace}"
    operator  = "="
    value     = "default"
  }

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

    volume "postgres" {
      type            = "csi"
      read_only       = false
      source          = "postgres"
      access_mode     = "single-node-writer"
      attachment_mode = "file-system"
      
      mount_options {
        fs_type = "ext4"
      }
    }
  
    ephemeral_disk {
      size = 300
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
        dns_servers = ["$${attr.unique.network.ip-address}"]
        ports = ["db"]
      }
      env {
          POSTGRES_USER="root",
          POSTGRES_PASSWORD="root"
      }

    template {
        data = <<EOH
        POSTGRES_USER="{{ with secret "kv/data/app/db/postgres" }}{{ .Data.data.username }}{{ end }}"
        POSTGRES_PASSWORD="{{ with secret "kv/data/app/db/postgres" }}{{ .Data.data.password }}{{ end }}"
        EOH

        env         = true
        destination = "secrets/postgres.env"
      }
      volume_mount {
        volume      = "postgres"
        destination = "/data/app"
        read_only   = false
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