resource "aws_iam_role" "execute_role" {
  name               = "${var.name}-ecs-execute"
  assume_role_policy = local.ecs_assume_role_policy

  tags = merge(
    var.tags,
    {
      Name = "${var.name} ECS Execute Role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "execute_role_ecs_attachment" {
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.execute_role.name
}

resource "aws_iam_role" "task_role" {
  name               = "${var.name}-ecs"
  assume_role_policy = local.ecs_assume_role_policy

  tags = merge(
    var.tags,
    {
      Name = "${var.name} - ECS Task Role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "task_role_attachment" {
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
  role       = aws_iam_role.task_role.name
}
