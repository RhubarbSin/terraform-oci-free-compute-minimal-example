resource "oci_core_vcn" "this" {
  compartment_id = var.tenancy_ocid

  cidr_blocks = [var.cidr_block]
}

resource "oci_core_internet_gateway" "this" {
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.this.id
}

resource "oci_core_default_route_table" "this" {
  manage_default_resource_id = oci_core_vcn.this.default_route_table_id

  route_rules {
    network_entity_id = oci_core_internet_gateway.this.id

    destination = "0.0.0.0/0"
  }
}

resource "oci_core_subnet" "this" {
  cidr_block     = oci_core_vcn.this.cidr_blocks.0
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.this.id
}

resource "oci_core_instance" "this" {
  availability_domain = local.availability_domain_micro
  compartment_id      = var.tenancy_ocid
  shape               = local.shape_micro

  create_vnic_details {
    subnet_id = oci_core_subnet.this.id
  }

  source_details {
    source_id   = data.oci_core_images.this.images.0.id
    source_type = "image"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }
}
