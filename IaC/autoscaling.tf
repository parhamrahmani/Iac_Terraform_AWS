
resource "aws_launch_template" "lt" {
  name_prefix   = "launch-template-${random_string.random_id.result}"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.keypair.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ec2_security_group.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y python3 python3-pip ca-certificates curl
              sudo mkdir -p /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
              sudo apt update
              sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
              sudo usermod -aG docker ubuntu
              docker pull ${var.docker_hub_username}/flask-app-image-repository:latest
              docker run -d --name my-container -p 80:5000 ${var.docker_hub_username}/flask-app-image-repository:latest
              EOF
  )
}

resource "aws_autoscaling_group" "asg" {
  name = "ec2-auto-scaling-group"
  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }
  vpc_zone_identifier = [aws_subnet.public_1.id, aws_subnet.public_2.id, aws_subnet.public_3.id]
  min_size            = 1
  max_size            = 3
  desired_capacity    = 2
  target_group_arns   = [aws_lb_target_group.target_group_1.arn]

  tag {
    key                 = "Name"
    value               = "ec2-auto-scaling-instance"
    propagate_at_launch = true
  }
}
