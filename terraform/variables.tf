variable "tenancy_ocid" {
  description = "The OCID of the root tenancy"
  type        = string
}

variable "region" {
  description = "The OCI region to connect to"
  type        = string
  default     = "ap-mumbai-1"
}
