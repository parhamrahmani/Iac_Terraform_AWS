# Find the latest Ubuntu AMI for the specified region
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# Create the EC2 instances
resource "aws_instance" "ec2-1" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_1.id  # Updated to use the correct subnet ID
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
  key_name               = aws_key_pair.keypair.key_name  # Adding key pair for SSH access

  user_data = <<-EOF
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

  tags = {
    Name = "ec2-1"
  }
}

resource "aws_instance" "ec2-2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_2.id
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
  key_name               = aws_key_pair.keypair.key_name
  user_data = <<-EOF
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

  tags = {
    Name = "ec2-2"
  }
}

resource "aws_instance" "ec2-3" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public_3.id
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  key_name = aws_key_pair.keypair.key_name
  user_data = <<-EOF
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

tags = {
    Name = "ec2-3"
  }
}


resource "aws_instance" "db-server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_1.id
  vpc_security_group_ids = [aws_security_group.db_security_group.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
  key_name               = aws_key_pair.keypair.key_name

  user_data = <<-EOF
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
              sudo docker pull ${var.docker_hub_username}/database-image-repository:latest
              # run the database container
              sudo docker run -d \
              --name my-container \
              -e MYSQL_ROOT_PASSWORD=${var.ROOT_DB_PASSWORD} \
              -e MYSQL_DATABASE=${var.DB_NAME} \
              -e MYSQL_USER=${var.DB_USER} \
              -e MYSQL_PASSWORD=${var.DB_PASSWORD} \
              -p 3306:3306 \
              ${var.docker_hub_username}/database-image-repository:latest
              EOF

  tags = {
    Name = "db-server"
  }
}

# 4th EC2 instance
resource "aws_instance" "ec2-4" {

    ami = data.aws_ami.ubuntu.id
    instance_type = "t2.micro"
    subnet_id = aws_subnet.public_4.id
    vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
    iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
    key_name = aws_key_pair.keypair.key_name
    user_data = <<-EOF
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

    tags = {
        Name = "ec2-4"
    }

}








