resource "google_pubsub_subscription" "push" {
  name  = "mongo-subscription-push"
  topic = google_pubsub_topic.my_topic.name

  ack_deadline_seconds = 20

  labels = {
    pubsub = "push"
  }

  push_config {
    push_endpoint = "https://my_topic.com/push"

    attributes = {
      x-goog-version = "v1"
    }
  }
}