variable "ssh_public_key" {
  type        = string
  description = "The SSH key used to access the server."
}

variable "region" {
  type        = string
  description = "The server's desired region. Valid regions at https://docs.oracle.com/en-us/iaas/Content/General/Concepts/regions.htm."
  default     = "us-ashburn-1"
}

variable "tenancy_ocid" {
  type        = string
  description = "OCID of your root tenancy."
}

variable "config_file_profile" {
  type        = string
  description = "The named config file profile."
  default     = "DEFAULT"
}

variable "vpc_cidr_block" {
  type        = string
  description = "The vpc cidr block to use."
  default     = "10.1.0.0/16"
}

variable "activation_code" {
  type        = string
  description = "The SSM activation code."
}

variable "ssm_activation_pair" {
  type        = string
  description = "The ssm activation pair."
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "ecs_cluster" {
  type    = string
  default = "nginx-cluster"
}
