# VCN and Networking resources for Mini Sourcing Engine

# 1. Main Virtual Cloud Network (VCN)
resource "oci_core_vcn" "main" {
  compartment_id = oci_identity_compartment.project.id
  cidr_blocks    = ["10.0.0.0/16"]
  display_name   = "sourcing-engine-vcn"
  dns_label      = "sourcing"

  freeform_tags = local.common_tags
}

# 2. Internet Gateway
resource "oci_core_internet_gateway" "main" {
  compartment_id = oci_identity_compartment.project.id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "sourcing-engine-igw"
  enabled        = true

  freeform_tags = local.common_tags
}

# 3. Public Route Table routing all outbound internet traffic to the Internet Gateway
resource "oci_core_route_table" "public" {
  compartment_id = oci_identity_compartment.project.id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "sourcing-engine-public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.main.id
  }

  freeform_tags = local.common_tags
}

# 4. Adopt VCN Default Security List
# The default security list created by OCI includes an open ingress rule allowing
# SSH (port 22) from 0.0.0.0/0. By managing the default security list and removing
# all ingress rules, we enforce a strict default-deny posture. All incoming traffic
# is instead explicitly governed via Network Security Groups (NSGs). We retain a single
# stateful egress rule allowing all outbound connections for updates and package installation.
resource "oci_core_default_security_list" "default" {
  manage_default_resource_id = oci_core_vcn.main.default_security_list_id
  display_name               = "sourcing-engine-default-sl"

  egress_security_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = false
  }

  freeform_tags = local.common_tags
}

# 5. Public Regional Subnet
resource "oci_core_subnet" "public" {
  compartment_id             = oci_identity_compartment.project.id
  vcn_id                     = oci_core_vcn.main.id
  cidr_block                 = "10.0.1.0/24"
  display_name               = "sourcing-engine-public-subnet"
  dns_label                  = "public"
  route_table_id             = oci_core_route_table.public.id
  security_list_ids          = [oci_core_default_security_list.default.id]
  prohibit_public_ip_on_vnic = false

  freeform_tags = local.common_tags
}

# 6. Network Security Group (NSG) and Security Rules
resource "oci_core_network_security_group" "app" {
  compartment_id = oci_identity_compartment.project.id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "sourcing-engine-app-nsg"

  freeform_tags = local.common_tags
}

resource "oci_core_network_security_group_security_rule" "ingress_ssh" {
  network_security_group_id = oci_core_network_security_group.app.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = var.allowed_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }

  description = "Allow inbound SSH from authorized CIDR"
}

resource "oci_core_network_security_group_security_rule" "ingress_app" {
  network_security_group_id = oci_core_network_security_group.app.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = var.allowed_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 8000
      max = 8000
    }
  }

  description = "Allow inbound application traffic on port 8000 from authorized CIDR"
}

resource "oci_core_network_security_group_security_rule" "egress_all" {
  network_security_group_id = oci_core_network_security_group.app.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  stateless                 = false

  description = "Allow all outbound stateful traffic"
}
