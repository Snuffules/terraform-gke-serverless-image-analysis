resource "kubernetes_secret" "mongodb_keyfile" {
  metadata {
    name      = "mongodb-keyfile"
    namespace = var.nms
  }

  data = {
    keyfile = "${path.module}/mongodb-keyfile"
  }
}
