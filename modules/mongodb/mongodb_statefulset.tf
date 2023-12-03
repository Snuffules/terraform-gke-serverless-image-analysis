resource "kubernetes_stateful_set" "mongodb_statefulset" {
  metadata {
    name      = "mongodb"
    namespace = var.nms
    labels = {
      app = "mongodb-app"
      release = var.release       
    }
  }

  spec {
    replicas = 2  # Set the number of replicas in the replica set

    selector {
      match_labels = {
        app = "mongodb-app"
        release = var.release        
      }
    }

    service_name = "mongo-lb-svc"

    template {
      metadata {
        labels = {
          app = "mongodb-app"
          release = var.release          
        }
      }

      spec {
        container {
          image = "eu.gcr.io/serverless-violence-score/mongo:latest"
          name  = "mongo"

          # MongoDB environment variables for replica set
          env {
            name = "MONGO_INITDB_ROOT_USERNAME"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mongo_secret.metadata[0].name
                key  = "username"
              }
            }
          }
          env {
            name = "MONGO_INITDB_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mongo_secret.metadata[0].name
                key  = "password"
              }
            }
          }
          env {
            name  = "MONGO_INITDB_REPLICA_SET_NAME"
            value = "rs0"  # Name of the replica set
          }

          # Additional environment variable for the keyfile
/*           env {
            name  = "MONGO_INITDB_KEYFILE"
            value = "/etc/mongodb-keyfile/mongodb-keyfile"
          } */

          # MongoDB port configuration
          port {
            container_port = 27017
          }

          # MongoDB volume mount configuration
          volume_mount {
            mount_path = "/data/db"
            name       = "mongodb-volume"
          }
          
/*           volume_mount {
            name       = "mongodb-keyfile"
            mount_path = "/etc/mongodb-keyfile"
            read_only  = true
          } */

          # MongoDB liveness and readiness probes
          liveness_probe {
            tcp_socket {
              port = "27017"
            }
            initial_delay_seconds = 10
            period_seconds        = 10
          }
          readiness_probe {
            tcp_socket {
              port = "27017"
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          # MongoDB image pull policy
          image_pull_policy = "IfNotPresent"
        }

        # MongoDB security context
        security_context {
          run_as_user     = 999
          run_as_non_root = true
          fs_group        = 999
        }
        volume {
          name = "mongodb-keyfile"
          secret {
            secret_name = kubernetes_secret.mongodb_keyfile.metadata[0].name
          }
        }        
      }
    }

    # MongoDB volume claim template
    volume_claim_template {
      metadata {
        name = "mongodb-volume"
      }
      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = var.storage_size
          }
        }
      }
    }
  }

  # Timeouts for the StatefulSet creation
  timeouts {
    create = "3m"
  }
}
