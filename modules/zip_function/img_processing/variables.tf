variable "project_id" {
    default = "serverless-violence-score"
}

variable "region" {
    default = "europe-west1"
}

variable "service_account" {
    default = "serverless-violence-score@appspot.gserviceaccount.com"
}

variable "name" {
  description = "A user-defined name of the function."
  type        = string
  default     = "Image-Processing-safe-store"
}

variable "location" {
  description = "The location of this cloud function."
  type        = string
  default     = "europe-west1"
}

variable "description" {
  description = "User-provided description of a function."
  type        = string
  default     = "Cloud function example managed by Terraform"
}

variable "labels" {
  description = "A set of key/value label pairs associated with this Cloud Function."
  type        = map(string)
  default     = {}
}

variable "runtime" {
  description = "The runtime in which to run the function. Required when deploying a new function, optional when updating an existing function."
  type        = string
  default     = "python39"
}

variable "entry_point" {
  description = "The name of the function (as defined in source code) that will be executed. Defaults to the resource name suffix, if not specified. For backward compatibility, if function with given name is not found, then the system will try to use function named \"function\". For Node.js this is name of a function exported by the module specified in source_location."
  type        = string
  default     = "imageProcessing"
}

variable "build_test" {
  type        = string
  default     = "build_test"
}

variable "min_instance_count" {
  description = "(Optional) The limit on the minimum number of function instances that may coexist at a given time."
  type        = number
  default     = 1
}

variable "max_instance_count" {
  description = "(Optional) The limit on the maximum number of function instances that may coexist at a given time."
  type        = number
  default     = 2
}

variable "timeout_seconds" {
  description = "(Optional) The function execution timeout. Execution is considered failed and can be terminated if the function is not completed at the end of the timeout period. Defaults to 60 seconds."
  type        = number
  default     = 240
}

variable "ingress_settings" {
  description = "(Optional) Available ingress settings. Defaults to \"ALLOW_ALL\" if unspecified. Default value is ALLOW_ALL. Possible values are ALLOW_ALL, ALLOW_INTERNAL_ONLY, and ALLOW_INTERNAL_AND_GCLB."
  type        = string
  default     = "ALLOW_INTERNAL_ONLY"
}

variable "pubsub_topic" {
  default = "my-topic"
  description = "Pub/Sub topic name"
  type        = string
}

variable "pubstopic" {
  description = "Pub/Sub topic name"
  type        = string
}