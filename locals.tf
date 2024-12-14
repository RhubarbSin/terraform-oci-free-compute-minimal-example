locals {
  shape = "VM.Standard.E2.1.Micro"

  availability_domain = one(
    [
      for m in data.oci_core_shapes.this :
      m.availability_domain
      if contains(m.shapes[*].name, local.shape)
    ]
  )
}
