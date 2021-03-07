resource "aws_iam_role" "node" {
  name               = "node"
  assume_role_policy = templatefile("${path.module}/assume-role-policy.json", {})
  tags               = map("Name", "node")
}

resource "aws_iam_instance_profile" "node" {
  name = "node"
  role = aws_iam_role.node.name
}

resource "aws_iam_role_policy" "node" {
  name = "node"
  role = aws_iam_role.node.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "amazon_ssm_managed_instance_core" {
  role       = aws_iam_role.node.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}