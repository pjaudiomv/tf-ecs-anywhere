output "instance_info" {
  value = {
    nsg_ids    = oci_core_instance.this.create_vnic_details[0].nsg_ids
    public_ip  = oci_core_public_ip.this.ip_address
    private_ip = oci_core_instance.this.private_ip
  }
}
