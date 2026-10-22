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
