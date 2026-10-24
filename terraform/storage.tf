# Object Storage resources for backups (Phase 3, Step 5)

# 1. Object Storage namespace for tenancy
data "oci_objectstorage_namespace" "this" {
  compartment_id = var.tenancy_ocid
}

# 2. Backups bucket with versioning enabled
resource "oci_objectstorage_bucket" "backups" {
  compartment_id = oci_identity_compartment.project.id
  name           = "sourcing-engine-backups"
  namespace      = data.oci_objectstorage_namespace.this.namespace
  access_type    = "NoPublicAccess"
  storage_tier   = "Standard"
  versioning     = "Enabled"
  auto_tiering   = "Disabled"

  freeform_tags = local.common_tags
}

# 3. IAM policy allowing Object Storage service to manage objects in the project compartment for lifecycle rules
resource "oci_identity_policy" "objectstorage_lifecycle" {
  compartment_id = var.tenancy_ocid
  name           = "${var.project_name}-objectstorage-lifecycle"
  description    = "Allow Object Storage service to manage object-family in compartment ${var.project_name} for lifecycle rules"
  statements = [
    "Allow service objectstorage-${var.region} to manage object-family in compartment ${var.project_name}"
  ]

  freeform_tags = local.common_tags
}

# 4. Object lifecycle policy for backups bucket
resource "oci_objectstorage_object_lifecycle_policy" "backups" {
  bucket     = oci_objectstorage_bucket.backups.name
  namespace  = data.oci_objectstorage_namespace.this.namespace
  depends_on = [oci_identity_policy.objectstorage_lifecycle]

  rules {
    name        = "delete-objects-older-than-30-days"
    action      = "DELETE"
    is_enabled  = true
    target      = "objects"
    time_amount = 30
    time_unit   = "DAYS"
  }

  rules {
    name        = "delete-previous-versions-older-than-7-days"
    action      = "DELETE"
    is_enabled  = true
    target      = "previous-object-versions"
    time_amount = 7
    time_unit   = "DAYS"
  }
}
