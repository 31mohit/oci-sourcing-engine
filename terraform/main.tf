locals {
  common_tags = {
    project     = var.project_name
    environment = var.environment
    owner       = var.owner
    managed_by  = "terraform"
  }
}

data "oci_identity_tenancy" "this" {
  tenancy_id = var.tenancy_ocid
}

data "oci_identity_availability_domains" "this" {
  compartment_id = var.tenancy_ocid
}

resource "oci_identity_compartment" "project" {
  compartment_id = var.tenancy_ocid
  name           = var.project_name
  description    = "Compartment for the Mini Sourcing Engine project"
  enable_delete  = true

  freeform_tags = local.common_tags
}
