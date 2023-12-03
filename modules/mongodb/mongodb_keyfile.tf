resource "kubernetes_secret" "mongodb_keyfile" {
  metadata {
    name      = "mongodb-keyfile"
    namespace = var.namespace
  }

  data = {
    keyfile = "${path.module}/mongodb-keyfile"
  }
}
