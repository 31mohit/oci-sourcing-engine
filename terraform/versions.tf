terraform {
  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 6.0"
    }
  }

  backend "oci" {
    bucket              = "sourcing-engine-tfstate"
    namespace           = "bml8qoqosnrz"
    key                 = "sourcing-engine/terraform.tfstate"
    region              = "ap-mumbai-1"
    config_file_profile = "DEFAULT"
  }
}