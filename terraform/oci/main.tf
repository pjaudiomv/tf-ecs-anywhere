resource "oci_core_instance" "this" {
  availability_domain = oci_core_subnet.this.availability_domain
  compartment_id      = data.oci_identity_compartment.default.id
  display_name        = "ecs-${terraform.workspace}"
  shape               = "VM.Standard.A1.Flex" # VM.Standard.E2.1.Micro If Using AMD

  create_vnic_details {
    assign_public_ip = false
    display_name     = "eth01"
    hostname_label   = "ecs"
    nsg_ids          = [oci_core_network_security_group.this.id]
    subnet_id        = oci_core_subnet.this.id
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = data.cloudinit_config.this.rendered
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu_focal_arm.images.0.id
  }

  shape_config {
    ocpus         = 2
    memory_in_gbs = 8
  }
}

resource "oci_core_public_ip" "this" {
  compartment_id = data.oci_identity_compartment.default.id
  display_name   = "ecs-${terraform.workspace}"
  lifetime       = "RESERVED"
  private_ip_id  = data.oci_core_private_ips.this.private_ips[0]["id"]
}

data "oci_core_vnic_attachments" "this" {
  compartment_id      = data.oci_identity_compartment.default.id
  availability_domain = local.availability_domain
  instance_id         = oci_core_instance.this.id
}

data "oci_core_vnic" "this" {
  vnic_id = data.oci_core_vnic_attachments.this.vnic_attachments[0]["vnic_id"]
}

data "oci_core_private_ips" "this" {
  vnic_id = data.oci_core_vnic.this.id
}

data "oci_identity_compartment" "default" {
  id = var.tenancy_ocid
}

data "oci_identity_availability_domains" "this" {
  compartment_id = data.oci_identity_compartment.default.id
}

resource "oci_core_vcn" "this" {
  dns_label      = "ecs"
  cidr_block     = var.vpc_cidr_block
  compartment_id = data.oci_identity_compartment.default.id
  display_name   = "ecs-${terraform.workspace}"
}

resource "oci_core_internet_gateway" "this" {
  compartment_id = data.oci_identity_compartment.default.id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "ecs-${terraform.workspace}"
  enabled        = "true"
}

resource "oci_core_default_route_table" "this" {
  manage_default_resource_id = oci_core_vcn.this.default_route_table_id

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.this.id
  }
}

resource "oci_core_network_security_group" "this" {
  compartment_id = data.oci_identity_compartment.default.id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "ecs-nsg"
  freeform_tags  = { "Service" = "ecs" }
}

resource "oci_core_network_security_group_security_rule" "this_egress_rule" {
  network_security_group_id = oci_core_network_security_group.this.id
  direction                 = "EGRESS"
  protocol                  = "all"
  description               = "Egress All"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "this_ingress_ssh_rule" {
  network_security_group_id = oci_core_network_security_group.this.id
  direction                 = "INGRESS"
  protocol                  = "6"
  description               = "ssh-ingress"
  source                    = local.myip
  source_type               = "CIDR_BLOCK"

  tcp_options {
    source_port_range {
      max = 22
      min = 22
    }
  }
}

resource "oci_core_network_security_group_security_rule" "this_ingress_443_rule" {
  network_security_group_id = oci_core_network_security_group.this.id
  direction                 = "INGRESS"
  protocol                  = "6"
  description               = "443-ingress"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"

  tcp_options {
    source_port_range {
      max = 443
      min = 443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "this_ingress_80_rule" {
  network_security_group_id = oci_core_network_security_group.this.id
  direction                 = "INGRESS"
  protocol                  = "6"
  description               = "80-ingress"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"

  tcp_options {
    source_port_range {
      max = 80
      min = 80
    }
  }
}

resource "oci_core_security_list" "this" {
  compartment_id = data.oci_identity_compartment.default.id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "ecs-${terraform.workspace}"
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = "all"
    source   = "0.0.0.0/0"
  }
}

resource "oci_core_subnet" "this" {
  availability_domain        = local.availability_domain
  cidr_block                 = cidrsubnet(var.vpc_cidr_block, 8, 0)
  display_name               = "ecs-${terraform.workspace}"
  prohibit_public_ip_on_vnic = false
  dns_label                  = "ecs"
  compartment_id             = data.oci_identity_compartment.default.id
  vcn_id                     = oci_core_vcn.this.id
  route_table_id             = oci_core_default_route_table.this.id
  security_list_ids          = [oci_core_security_list.this.id]
  dhcp_options_id            = oci_core_vcn.this.default_dhcp_options_id
}

data "oci_core_images" "ubuntu_focal" {
  compartment_id   = data.oci_identity_compartment.default.id
  operating_system = "Canonical Ubuntu"
  filter {
    name   = "display_name"
    values = ["^Canonical-Ubuntu-20.04-([\\.0-9-]+)$"]
    regex  = true
  }
}

data "oci_core_images" "ubuntu_focal_arm" {
  compartment_id   = data.oci_identity_compartment.default.id
  operating_system = "Canonical Ubuntu"
  filter {
    name   = "display_name"
    values = ["^Canonical-Ubuntu-20.04-aarch64-([\\.0-9-]+)$"]
    regex  = true
  }
}

data "oci_core_images" "ubuntu_jammy" {
  compartment_id   = data.oci_identity_compartment.default.id
  operating_system = "Canonical Ubuntu"
  filter {
    name   = "display_name"
    values = ["^Canonical-Ubuntu-22.04-([\\.0-9-]+)$"]
    regex  = true
  }
}

data "oci_core_images" "ubuntu_jammy_arm" {
  compartment_id   = data.oci_identity_compartment.default.id
  operating_system = "Canonical Ubuntu"
  filter {
    name   = "display_name"
    values = ["^Canonical-Ubuntu-22.04-aarch64-([\\.0-9-]+)$"]
    regex  = true
  }
}

data "cloudinit_config" "this" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = <<EOF
#cloud-config

package_update: true
package_upgrade: true
packages:
  - awscli
  - curl
  - htop
  - jq
  - docker.io
  - docker-compose
EOF
  }

  part {
    content_type = "text/x-shellscript"
    content      = <<BOF
#!/bin/bash

curl -o "/tmp/ecs-anywhere-install.sh" "https://amazon-ecs-agent-packages-preview.s3.us-east-1.amazonaws.com/ecs-anywhere-install.sh"
cd /tmp
awk 'NR==433{print "sed -i '/After=cloud-final.service/d' /usr/lib/systemd/system/ecs.service"}1' /tmp/ecs-anywhere-install.sh >/tmp/ecs-anywhere-install.sh1 && mv /tmp/ecs-anywhere-install.sh1 /tmp/ecs-anywhere-install.sh
sudo chmod +x /tmp/ecs-anywhere-install.sh
sudo /tmp/ecs-anywhere-install.sh --cluster ${var.ecs_cluster} --activation-id ${var.ssm_activation_pair} --activation-code ${var.activation_code} --region ${var.aws_region}

mkdir -p /data/sourcefolder
mkdir -p /data/destinationfolder
BOF
  }
}

data "http" "ip" {
  url = "https://ifconfig.me/all.json"

  request_headers = {
    Accept = "application/json"
  }
}

locals {
  myip                = "${jsondecode(data.http.ip.body).ip_addr}/32"
  availability_domain = [for i in data.oci_identity_availability_domains.this.availability_domains : i if length(regexall("US-ASHBURN-AD-3", i.name)) > 0][0].name
}
