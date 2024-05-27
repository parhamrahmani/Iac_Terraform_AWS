output "provider" {
  value = "provider: aws"
}

output "aws_region" {
  value = var.aws_region
}

output "internet_gateway_id" {
  value = aws_internet_gateway.igw.id
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_route_table_id" {
  value = aws_route_table.public.id
}

output "private_route_table_id" {
  value = aws_route_table.private.id
}

output "public_subnet_1_id" {
  value = aws_subnet.public_1.id
}

output "public_subnet_2_id" {
  value = aws_subnet.public_2.id
}

output "public_subnet_3_id" {
  value = aws_subnet.public_3.id
}

output "private_subnet_1_id" {
  value = aws_subnet.private_1.id
}

output "ec2_security_group_id" {
  value = aws_security_group.ec2_security_group.id
}

output "alb_security_group_id" {
  value = aws_security_group.alb_security_group.id
}

output "alb_id" {
  value = aws_lb.alb.id
}

output "target_group_1_id" {
  value = aws_lb_target_group.target_group_1.id
}

output "listener_id" {
  value = aws_lb_listener.listener.id
}

output "ec2_instance_profile_id" {
  value = aws_iam_instance_profile.ec2_instance_profile.name
}

output "ec2_role_id" {
  value = aws_iam_role.ec2_role.name
}

output "ec2_role_policy_attachment_id" {
  value = aws_iam_role_policy_attachment.ec2_role_attach.id
}

output "auto_scaling_group_id" {
  value = aws_autoscaling_group.asg.id
}

output "auto_scaling_group_name" {
  value = aws_autoscaling_group.asg.name
}

output "launch_template_name" {
  value = aws_launch_template.lt.name
}

output "launch_template_id" {
  value = aws_launch_template.lt.id
}

output "launch_template_image_id" {
  value = aws_launch_template.lt.image_id
}

output "ec2-1_instance_id" {
  value = aws_instance.ec2-1.id
}

output "ec2-1_instance_public_ip" {
  value = aws_instance.ec2-1.public_ip
}

output "ec2-2_instance_id" {
  value = aws_instance.ec2-2.id
}

output "ec2-2_instance_public_ip" {
  value = aws_instance.ec2-2.public_ip
}

output "ec2-3_instance_id" {
  value = aws_instance.ec2-3.id
}

output "ec2-3_instance_public_ip" {
  value = aws_instance.ec2-3.public_ip
}

