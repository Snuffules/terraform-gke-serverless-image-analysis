resource "kubernetes_secret" "mongo_secret" {
  metadata {
    name      = "mongo-secret"
    namespace = var.nms
  }

  data = {
    username = var.mongo_user
    password = var.mongo_password
  }
}

