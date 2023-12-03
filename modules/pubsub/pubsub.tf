#####################
# PUBSUB topic
#####################

resource "google_pubsub_topic" "my_topic" {
  name = "my-topic"
}