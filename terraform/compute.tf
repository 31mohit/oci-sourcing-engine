# Compute resources for Mini Sourcing Engine

# 1. Query latest Canonical Ubuntu 24.04 image for Arm (VM.Standard.A1.Flex)
data "oci_core_images" "ubuntu_24_04" {
  compartment_id           = oci_identity_compartment.project.id
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# 2. Main Arm compute instance (A1.Flex Always Free compatible)
resource "oci_core_instance" "app" {
  compartment_id      = oci_identity_compartment.project.id
  display_name        = "sourcing-engine-vm"
  availability_domain = data.oci_identity_availability_domains.this.availability_domains[0].name
  fault_domain        = var.fault_domain
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = var.instance_ocpus
    memory_in_gbs = var.instance_memory_gb
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu_24_04.images[0].id
    boot_volume_size_in_gbs = 50
  }

  preserve_boot_volume = false

  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = true
    nsg_ids          = [oci_core_network_security_group.app.id]
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(file("${path.module}/cloud-init.yaml"))
  }

  # The image data source returns the latest Ubuntu image, so without this
  # a newer image would make Terraform replace the VM.
  lifecycle {
    ignore_changes = [source_details[0].source_id]
  }

  freeform_tags = local.common_tags
}
