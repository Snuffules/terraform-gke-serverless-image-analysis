variable "nms" {
  description = "The name of the subnetwork"
  type        = string
}

variable "release" {
    default = "1"
}

variable "mongo_user" {
    default = "mongouser"
    sensitive = true
}

variable "mongo_password" {
    default = "mongopassword"
    sensitive = true    
}