resource "aws_ecr_repository" "this" {
  name         = var.name
  force_delete = true
}
