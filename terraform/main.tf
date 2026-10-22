data "oci_identity_tenancy" "this" {
  tenancy_id = var.tenancy_ocid
}

data "oci_identity_availability_domains" "this" {
  compartment_id = var.tenancy_ocid
}
