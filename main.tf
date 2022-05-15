terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 4.75.0"
    }
  }
}

variable "tenancy_ocid" {
  description = "OCID of the tenancy"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block of the VCN"
  type        = string
  default     = "10.10.10.0/24"

  validation {
    condition     = can(cidrsubnets(var.cidr_block, 2))
    error_message = "The value of cidr_block variable must be a valid CIDR address with a prefix no greater than 30."
  }
}

variable "ssh_public_key" {
  description = "Public key to be used for SSH access to compute instances"
  type        = string
}

resource "oci_core_vcn" "this" {
  compartment_id = var.tenancy_ocid

  cidr_blocks = [var.cidr_block]
}

resource "oci_core_subnet" "this" {
  cidr_block     = oci_core_vcn.this.cidr_blocks.0
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.this.id
}

data "oci_identity_availability_domains" "this" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_shapes" "this" {
  for_each       = toset(data.oci_identity_availability_domains.this.availability_domains[*].name)
  compartment_id = var.tenancy_ocid

  availability_domain = each.key
}

locals {
  shape_micro = "VM.Standard.E2.1.Micro"
}

locals {
  availability_domain_micro = one(
    [
      for m in data.oci_core_shapes.this :
      m.availability_domain
      if contains(m.shapes[*].name, local.shape_micro)
    ]
  )
}

data "oci_core_images" "this" {
  compartment_id = var.tenancy_ocid

  operating_system = "Oracle Linux"
  shape            = local.shape_micro
  sort_by          = "TIMECREATED"
  sort_order       = "DESC"
  state            = "available"
}

resource "oci_core_instance" "this" {
  availability_domain = local.availability_domain_micro
  compartment_id      = var.tenancy_ocid
  shape               = local.shape_micro

  create_vnic_details {
    subnet_id = oci_core_subnet.this.id
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }

  source_details {
    source_id   = data.oci_core_images.this.images.0.id
    source_type = "image"
  }
}
