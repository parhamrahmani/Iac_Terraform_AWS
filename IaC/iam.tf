# Fetch current AWS account ID
data "aws_caller_identity" "current" {}

# IAM Role for EC2 Instances
resource "aws_iam_role" "ec2_role" {
  name = "ec2-role-${random_string.random_id.result}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  lifecycle {
    ignore_changes = [
      name
    ]
  }
}

resource "aws_iam_role_policy_attachment" "ec2_role_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile-${random_string.random_id.result}"
  role = aws_iam_role.ec2_role.name
}

# Policy to allow iam:PassRole for the tfadm user
resource "aws_iam_policy" "tfadm_passrole_policy" {
  name = "tfadm-passrole-policy-${random_string.random_id.result}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ec2-role-*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "tfadm_passrole_attach" {
  user       = "tfadm"
  policy_arn = aws_iam_policy.tfadm_passrole_policy.arn
}

# random number generation
resource "random_string" "random_id" {
  length  = 8
  special = false
}
