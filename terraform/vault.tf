# Vault and Secrets resources (Phase 3, Step 6a)

# 1. KMS Vault
# vault_type is DEFAULT (multi-tenant/shared partition, Always Free eligible).
# VIRTUAL_PRIVATE is a dedicated partition and incurs hourly costs.
resource "oci_kms_vault" "main" {
  compartment_id = oci_identity_compartment.project.id
  display_name   = "sourcing-engine-vault"
  vault_type     = "DEFAULT"

  freeform_tags = local.common_tags
}

# 2. Master Encryption Key for Secrets
# Software-protected keys are free; HSM keys only have a 20-key-version free allowance, so we use SOFTWARE.
resource "oci_kms_key" "secrets" {
  compartment_id      = oci_identity_compartment.project.id
  display_name        = "sourcing-engine-secrets-key"
  management_endpoint = oci_kms_vault.main.management_endpoint
  protection_mode     = "SOFTWARE"

  key_shape {
    algorithm = "AES"
    length    = 32
  }

  freeform_tags = local.common_tags
}

# 3. Placeholder Secret for redis-password
# The secret value is a placeholder; real values are set outside Terraform.
# lifecycle { ignore_changes = [secret_content] } ensures a real value added later
# outside Terraform is never overwritten and never lands in Terraform state.
resource "oci_vault_secret" "placeholder" {
  compartment_id = oci_identity_compartment.project.id
  secret_name    = "redis-password"
  vault_id       = oci_kms_vault.main.id
  key_id         = oci_kms_key.secrets.id
  description    = "Placeholder secret for redis-password; real values are set outside Terraform"

  secret_content {
    content_type = "BASE64"
    content      = base64encode("placeholder-not-a-real-secret")
  }

  lifecycle {
    ignore_changes = [secret_content]
  }

  freeform_tags = local.common_tags
}
