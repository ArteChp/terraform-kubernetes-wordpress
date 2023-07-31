

resource "kubernetes_stateful_set" "mysql" {
  metadata {
    name = "mysql"
  }

  spec {
    service_name = "mysql-service"

    selector {
      match_labels = {
        app = "mysql"
      }
    }

    template {
      metadata {
        labels = {
          app = "mysql"
        }
      }

      spec {
        container {
          name  = "mysql"
          image = "docker.io/library/mariadb"
          port {
            name           = "mysql"
            container_port = 3306
          }
          volume_mount {
            name       = "mysql-data"
            mount_path = "/var/lib/mysql"
          }
          env {
            name  = "MYSQL_ROOT_PASSWORD"
            value = var.mysql_root_pass
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "mysql-data"
      }

      spec {
        access_modes       = ["ReadWriteOnce"]
        volume_name        = "mysql-data"
        storage_class_name = "local-path"

        resources {
          requests = {
            storage = "10Gi"
          }
        }
      }
    }
  }
}

resource "kubernetes_persistent_volume" "mysql-data" {
  metadata {
    name = "mysql-data"
  }
  spec {
    capacity = {
      storage = "10Gi"
    }
    access_modes = ["ReadWriteOnce"]
    persistent_volume_source {
      host_path {
        path = "/home/wps/data/mysql-data"
      }
    }
    storage_class_name = "local-path"
  }
}

resource "kubernetes_service" "mysql-service" {
  metadata {
    name = "mysql-service"
  }

  spec {
    selector = {
      app = "mysql"
    }

    port {
      name        = "mysql"
      protocol    = "TCP"
      port        = 3306
      target_port = 3306
    }
  }
}

output "mysql_cluster_ip" {
  value = kubernetes_service.mysql-service.spec[0].cluster_ip
}

