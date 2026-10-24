output "tenancy_name" {
  description = "The name of the OCI tenancy"
  value       = data.oci_identity_tenancy.this.name
}

output "home_region_key" {
  description = "The key of the tenancy's home region"
  value       = data.oci_identity_tenancy.this.home_region_key
}

output "availability_domain_names" {
  description = "List of availability domain names in the tenancy"
  value       = data.oci_identity_availability_domains.this.availability_domains[*].name
}

output "compartment_id" {
  description = "The OCID of the project compartment"
  value       = oci_identity_compartment.project.id
}

output "compartment_name" {
  description = "The name of the project compartment"
  value       = oci_identity_compartment.project.name
}

output "vcn_id" {
  description = "The OCID of the main VCN"
  value       = oci_core_vcn.main.id
}

output "public_subnet_id" {
  description = "The OCID of the public subnet"
  value       = oci_core_subnet.public.id
}

output "app_nsg_id" {
  description = "The OCID of the application network security group"
  value       = oci_core_network_security_group.app.id
}

output "instance_id" {
  description = "The OCID of the compute instance"
  value       = oci_core_instance.app.id
}

output "instance_public_ip" {
  description = "The public IP address of the compute instance"
  value       = oci_core_instance.app.public_ip
}

output "ssh_command" {
  description = "SSH connection command for the instance"
  value       = "ssh -i $HOME\\.ssh\\oci_sourcing ubuntu@${oci_core_instance.app.public_ip}"
}

output "object_storage_namespace" {
  description = "The Object Storage namespace for the tenancy"
  value       = data.oci_objectstorage_namespace.this.namespace
}

output "backups_bucket_name" {
  description = "The name of the backups Object Storage bucket"
  value       = oci_objectstorage_bucket.backups.name
}

output "vault_id" {
  description = "The OCID of the OCI KMS vault"
  value       = oci_kms_vault.main.id
}

output "secrets_key_id" {
  description = "The OCID of the master encryption key for secrets"
  value       = oci_kms_key.secrets.id
}

output "placeholder_secret_id" {
  description = "The OCID of the placeholder redis-password secret"
  value       = oci_vault_secret.placeholder.id
}

output "dynamic_group_name" {
  description = "The name of the IAM dynamic group for the compute VM"
  value       = oci_identity_dynamic_group.vm.name
}

output "vm_access_policy_id" {
  description = "The OCID of the IAM policy granting VM access"
  value       = oci_identity_policy.vm_access.id
}



