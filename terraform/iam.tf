# IAM Dynamic Group and Policies for VM Instance Principals (Phase 3, Step 6b)

# 1. Dynamic group containing the VM instance only
resource "oci_identity_dynamic_group" "vm" {
  compartment_id = var.tenancy_ocid
  name           = "${var.project_name}-vm-dg"
  description    = "Dynamic group containing the application VM instance for instance-principal authentication"
  matching_rule  = "instance.id = '${oci_core_instance.app.id}'"

  freeform_tags = local.common_tags
}

# 2. Least-privilege policy granting the VM access to secrets and the backups bucket
resource "oci_identity_policy" "vm_access" {
  compartment_id = var.tenancy_ocid
  name           = "${var.project_name}-vm-access"
  description    = "Least-privilege policy for application VM instance-principal to read secrets and manage backup bucket objects"
  depends_on     = [oci_identity_dynamic_group.vm]

  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.vm.name} to read secret-bundles in compartment ${var.project_name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.vm.name} to manage objects in compartment ${var.project_name} where target.bucket.name = '${oci_objectstorage_bucket.backups.name}'"
  ]

  freeform_tags = local.common_tags
}
