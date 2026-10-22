provider "oci" {
  config_file_profile = "DEFAULT"
  region              = var.region
  tenancy_ocid        = var.tenancy_ocid
}
