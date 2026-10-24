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

variable "allowed_cidr" {
  description = "CIDR block permitted to access the application and SSH (must be /24 to /32, not 0.0.0.0/0)"
  type        = string

  validation {
    condition = (
      can(cidrhost(var.allowed_cidr, 0)) &&
      var.allowed_cidr != "0.0.0.0/0" &&
      try(tonumber(split("/", var.allowed_cidr)[1]) >= 24, false)
    )
    error_message = "The allowed_cidr value must be a valid IPv4 CIDR block with a prefix length between /24 and /32, and cannot be 0.0.0.0/0."
  }
}

variable "ssh_public_key" {
  description = "Public SSH key for the instance"
  type        = string

  validation {
    condition     = startswith(var.ssh_public_key, "ssh-")
    error_message = "The ssh_public_key value must start with 'ssh-' (e.g. 'ssh-ed25519' or 'ssh-rsa')."
  }
}

variable "instance_ocpus" {
  description = "Number of OCPUs for the VM.Standard.A1.Flex instance"
  type        = number
  default     = 2
}

variable "instance_memory_gb" {
  description = "Memory in GB for the VM.Standard.A1.Flex instance"
  type        = number
  default     = 12
}

variable "fault_domain" {
  description = "The fault domain for instance placement (null lets OCI choose)"
  type        = string
  default     = null
}
