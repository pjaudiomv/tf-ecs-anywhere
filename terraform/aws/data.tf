data "aws_partition" "this" {}
data "aws_region" "this" {}

data "aws_route53_zone" "external" {
  name = "patrickj.org"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
