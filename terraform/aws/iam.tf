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



resource "aws_iam_role" "ecs_anywhere_role" {
  name = "${var.name}-ecs-anywhere"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ssm.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore-role-policy-attach" {
  role       = aws_iam_role.ecs_anywhere_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  depends_on = [aws_iam_role.ecs_anywhere_role]
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerServiceforEC2Role-role-policy-attach" {
  role       = aws_iam_role.ecs_anywhere_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  depends_on = [aws_iam_role.ecs_anywhere_role]
}

resource "aws_ssm_activation" "ssm_activation_pair" {
  name               = "ssm_activation_pair"
  description        = "ssmActivationPair"
  registration_limit = 1
  iam_role           = aws_iam_role.ecs_anywhere_role.id
  depends_on = [
    aws_iam_role_policy_attachment.AmazonSSMManagedInstanceCore-role-policy-attach,
    aws_iam_role_policy_attachment.AmazonEC2ContainerServiceforEC2Role-role-policy-attach
  ]
}
