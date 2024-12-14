data "oci_identity_availability_domains" "this" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_shapes" "this" {
  for_each = toset(data.oci_identity_availability_domains.this.availability_domains[*].name)

  compartment_id = var.tenancy_ocid

  availability_domain = each.key
}

data "oci_core_images" "this" {
  compartment_id = var.tenancy_ocid

  operating_system = "Oracle Linux"
  shape            = local.shape
  sort_by          = "DISPLAYNAME"
  sort_order       = "DESC"
  state            = "available"
}
