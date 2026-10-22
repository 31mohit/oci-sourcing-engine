variable "tenancy_ocid" {
  description = "The OCID of the root tenancy"
  type        = string
}

variable "region" {
  description = "The OCI region to connect to"
  type        = string
  default     = "ap-mumbai-1"
}

variable "project_name" {
  description = "The project name used for resource naming and tagging"
  type        = string
  default     = "sourcing-engine"
}

variable "environment" {
  description = "The deployment environment"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "The owner of the project"
  type        = string
  default     = "mohit"
}
