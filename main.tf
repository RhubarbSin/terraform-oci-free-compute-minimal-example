resource "random_integer" "this" {
  min = 0
  max = 255
}

resource "oci_core_vcn" "this" {
  compartment_id = var.tenancy_ocid

  cidr_blocks  = [coalesce(var.cidr_block, "192.168.${random_integer.this.result}.0/24")]
  display_name = var.name
}

resource "oci_core_internet_gateway" "this" {
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.this.id

  display_name = var.name
}

resource "oci_core_default_route_table" "this" {
  manage_default_resource_id = oci_core_vcn.this.default_route_table_id

  display_name = var.name

  route_rules {
    network_entity_id = oci_core_internet_gateway.this.id

    destination = "0.0.0.0/0"
  }
}

resource "oci_core_subnet" "this" {
  cidr_block     = oci_core_vcn.this.cidr_blocks.0
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.this.id

  display_name = var.name
}

resource "oci_core_instance" "this" {
  availability_domain = local.availability_domain_micro
  compartment_id      = var.tenancy_ocid
  shape               = local.shape_micro

  display_name = var.name

  create_vnic_details {
    display_name = var.name
    subnet_id    = oci_core_subnet.this.id
  }

  source_details {
    source_id   = data.oci_core_images.this.images.0.id
    source_type = "image"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }

  lifecycle {
    ignore_changes = [source_details.0.source_id]
  }
}
