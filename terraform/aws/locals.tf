locals {
  partition      = data.aws_partition.this.partition
  vpc_id         = data.aws_vpc.default.id
  lb_subnet_ids  = slice(data.aws_subnets.subnets.ids, 0, 3)
  ecs_subnet_ids = slice(data.aws_subnets.subnets.ids, 0, 3)
  ecs_assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "1"
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}
