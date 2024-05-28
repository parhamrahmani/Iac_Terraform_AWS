# IT-Infrastructure-Project Documentation


### Parham Rahmani 580200 SoSe 2024


## <a id="description"></a>Description

In this document, i show the steps to create a simple server based infrastructure on AWS using Terraform. Then
I will create a CI/CD pipeline using GitHub Actions and Docker Hub to automate the deployment process for a simple
Flask application.

Check out the diagram page to see the infrastructure diagrams and workflows more clearly.

The infrastructure consists of the following components:

- VPC
- Subnets
- Security Groups
- Application Load Balancer
- EC2 Instances
- Auto-Scaling Group
- CI/CD Pipeline
- Docker Images on Docker Hub deployed on EC2 instances
- Flask Application

## <a id="diagrams"></a>Diagrams

![alt text](static/digfin.drawio.svg)

## <a id="requirements"></a>Requirements


- Install docker and git. Clone the repository and install the required packages.
- Create .env file and add the following environment variables:
    - FLASK_KEY="<your_secret_key>"
    - AWS_ACCESS_KEY_ID="<your_aws_access_key>"
    - AWS_SECRET_ACCESS_KEY="<your_aws_secret_key>"
    - AWS_REGION="<your_aws_region>"
    - DOCKER_HUB_USERNAME="<your_docker_hub_username>"
    - DOCKER_HUB_ACCESS_TOKEN="<your_docker_hub_access_token>"
    - DOCKER_HUB_PASSWORD="<your_docker_hub_password>"
    - SPOTIFY_CLIENT_ID="<your_spotify_client_id>"
    - SPOTIFY_CLIENT_SECRET="<your_spotify_client_secret>"
    - DB_USER="<your_db_user>"
    - DB_PASSWORD="<your_db_password>"
    - DB_ROOT_PASSWORD="<your_db_root_password>"
- create a terraform.tfvars file and add the following variables:
    - docker_hub_username="<your_docker_hub_username>"
    - public_key_path="<path_to_your_public_key>"
    - aws_region="<your_aws_region>"
    - aws_access_key="<your_aws_access_key>"
    - aws_secret_key="<your_aws_secret_key>"
    - aws_region="<your_aws_region>"
    - db_user="<your_db_user>"
    - db_password="<your_db_password>"
    - db_root_password="<your_db_root_password>"
    - db_name="<your_db_name>"
- add these variables to the github secrets
  - ##### VERY IMPORTANT: IMPORT YOUR SSH KEY AS PRIVATE_SSH_KEY IN GITHUB SECRETS
  - use cat <your_key_pair>.pem to get the private key and then copy it to the github secrets
  - it should look like this:
    - PRIVATE_SSH_KEY: "-----BEGIN RSA PRIVATE KEY----- blah blah blah -----END RSA PRIVATE KEY-----"
  - copy the whole thing and paste it in the github secrets
- Check the namings based on the yml file and the terraform files so that they match and no errors occur
- The next environment variables will be added after terraform apply:
    - EC2_DB_IP="<your_ec2_db_ip>"
- Create a Docker Hub account and two repositories 
    - pushing the Docker image for flask app to Docker Hub is done in the CI/CD pipeline
    - pushing the initial Docker image of Database is done manually
    - pay attention to naming the repositories correctly
- Install Terraform
- Install AWS CLI (for terraform) 
  - configure the AWS CLI with your access key and secret key
  - make to have the user created beforehand with all the necessary permissions -> terraform admin user
- Create an AWS account and have all necessary permissions
  - this can be tricky and normally won't be done by terraform
  - Have all the necessary permissions for the resources you want to create before running the terraform script
- Have a key pair for SSH access
  - add the key pair to the github secrets
  - also use it for terraform
- Gain AWS access and secret keys
- Build and run the docker images locally to test them and then push them to Docker Hub
- check out the Dockerfile and the docker-compose file to understand the structure of the images and the containers


## <a id="steps"></a>Steps

## After setting up the environment and the requirements, follow these steps to create the infrastructure and the CI/CD pipeline.

### 1. Write your terraform code to build the infrastructure


- specify the provider


```hcl
provider "aws" {
  region = var.aws_region
}
```

- create a VPC


```hcl
# Define the main VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}
```

- create public subnets and a private subnet 


```hcl
# Define subnets in different Availability Zones
resource "aws_subnet" "public_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-central-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-central-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-2"
  }
}

resource "aws_subnet" "public_3" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "eu-central-1c"
  map_public_ip_on_launch = true

    tags = {
        Name = "public-subnet-3"
    }

}

resource "aws_subnet" "private_1" {
  vpc_id = aws_vpc.main.id
    cidr_block = "10.0.5.0/24"
    availability_zone = "eu-central-1a"
    map_public_ip_on_launch = false

    tags = {
        Name = "private-subnet-1"
    }
}
```

- create route table and internet gateway


```hcl
# Create an Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

    tags = {
      Name = "private-route-table"
    }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

# attach the route table to the second subnet
resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# attach the route table to the third subnet
resource "aws_route_table_association" "public_3" {
  subnet_id      = aws_subnet.public_3.id
  route_table_id = aws_route_table.public.id
}

# attach the route table to the first private subnet
resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}
```

- create security groups


```hcl
# Security Groups
resource "aws_security_group" "ec2_security_group" {

  vpc_id = aws_vpc.main.id

  name        = "ec2-security-group"
  description = "Allow SSH, HTTP, HTTPS, and application-specific traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-security-group"
  }
}

resource "aws_security_group" "alb_security_group" {
  vpc_id = aws_vpc.main.id

  name        = "alb-security-group"
  description = "Allow HTTP and HTTPS inbound traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-security-group"
  }
}

resource "aws_security_group" "db_security_group" {
    vpc_id = aws_vpc.main.id

    name        = "db-security-group"
    description = "Allow HTTP inbound traffic"

    ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      Name = "db-security-group"
    }
}

```

- create an application load balancer


```hcl
resource "aws_lb" "alb" {
  name                 = "alb"
  internal             = false
  load_balancer_type   = "application"
  security_groups      = [aws_security_group.alb_security_group.id]
  subnets              = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id,
    aws_subnet.public_3.id
  ]
  enable_deletion_protection = false
  tags = {
    Name = "alb"
  }
}

resource "aws_lb_target_group" "target_group_1" {
  name     = "target-group-1"
  port     = 80
  protocol = "HTTP"
  target_type = "instance"
  vpc_id   = aws_vpc.main.id
  health_check {
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    interval            = 30
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  lifecycle {
    ignore_changes = [
      name
    ]
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group_1.arn
  }
}

```


- configure roles IAM

#### Warning: This step is the most potential step to have errors.

Make sure to have the correct permissions and policies for the roles and policies beforehand (iam:PassRole for example)
This part can be wrong in your case, make sure to set it up correctly to your environment.

```hcl
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

```

- create and define your ec2 instances

#### Warning: This step is the most potential step to have errors.

Make sure to have the correct permissions (permission to run an ec2 and also managing , creating it etc.)


```hcl
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
```
- create an auto scaling group

```hcl

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

```

- define your key pair


```hcl
resource "aws_key_pair" "keypair" {
  key_name   = "keypair"
  public_key = file(var.public_key_path)
}
```

- define variables

#### Warning: This step is the most potential step to have errors in terraform code

change the variables based on your environment and the resources you want to create

```hcl
variable "public_key_path" {
  description = "Path to the public key used for SSH access"
}

variable "dockerhub_username" {
  description = "DockerHub username for pulling the Flask app image"
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy the resources"
  type        = string
}

variable "docker_hub_username" {
    description = "DockerHub username for pulling the Flask app image"
    type        = string
}

variable "DB_NAME" {
    description = "Database name"
    type        = string
}
variable "DB_USER" {
    description = "Database user"
    type        = string
}
variable "DB_PASSWORD" {
    description = "Database password"
    type        = string
}
variable "ROOT_DB_PASSWORD" {
    description = "Root database password"
    type        = string
}
```

- define your values for the variables in terraform.tfvars (DO NOT COMMIT THIS FILE)

#### Warning: This step is the most potential step for security issues

DO NOT COMMIT THIS FILE TO GITHUB OR ANY OTHER PLATFORM !!


```hcl
docker_hub_username = "your_docker_hub_username"
aws_region = "your_aws_region"
public_key_path = "your_public_key_path"
DB_NAME= "recommedations"
DB_USER= "your_db_user"
DB_PASSWORD= "your_db_password"
ROOT_DB_PASSWORD= "your_db_root_password"

```

- define your outputs

#### Warning: This step is optional but can be useful for debugging and testing

These are the outputs of the resources you created and will be shown after a successful terraform apply.
I use it for debugging and seeing what resources are created and what are their IDs.

```hcl
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



```

### 2. Perform the following steps to deploy the infrastructure
- Run `terraform init` to initialize the working directory
- Run `terraform validate` to validate the configuration files
- Run `terraform plan` to create an execution plan
- Important! Review the execution plan to ensure that the changes are as expected
- Run `terraform apply` to apply the changes -> this will create the infrastructure in real-time. Do not forget 
to confirm the changes by typing `yes`. 
- After the infrastructure is created, you can access the instances by using the public IP addresses of the instances.

#### Warning: This step is very crucial and can be very annoying if you don't pay attention to the details

1. Make sure to have the correct permissions for the resources you want to create
2. Make sure to have the correct values for the variables in the terraform.tfvars file
3. Make sure that terraform plan shows the correct resources and the correct changes
4. make sure your aws client has programmatic access and the correct permissions
5. terrafrom plan and validate are very importtant before applying something. Make sure to check the output and 
the plan before applying the changes

### 3. Go to the AWS console and check if the resources are created successfully and also make ssh connections to the instances
and check if the docker images are running correctly.

```bash
ssh -i <path_to_your_private_key> ubuntu@<public_ip_address>
```

- If needed, to destroy the infrastructure, run `terraform destroy` and confirm the changes by typing `yes`.

- In the end you have the infrastructure created and the instances running with the docker images running on them.
The infrastructure is drawn in the diagram at the start of the document.

### 4. Dockerfile explanation and docker-compose file explanation

#### Dockerfile for the Flask app

set the official python image as the base image (version 3.8-slim in this case) and then set the environment variables
install the required packages and copy the files to the working directory. Expose the port 5000 and run the flask app.

```Dockerfile

# flask.Dockerfile for the Flask App
FROM python:3.8-slim

WORKDIR /app


ARG FLASK_KEY
ARG SPOTIFY_CLIENT_ID
ARG SPOTIFY_SECRET_ID
ARG ENVIRONMENT


ENV FLASK_KEY=$FLASK_KEY
ENV SPOTIFY_CLIENT_ID=$SPOTIFY_CLIENT_ID
ENV SPOTIFY_SECRET_ID=$SPOTIFY_SECRET_ID
ENV ENVIRONMENT=$ENVIRONMENT

COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["flask", "run", "--host=0.0.0.0", "--port=5000"]


```

#### Dockerfile for the Database

set the official mysql image as the base image and set the environment variables for the database name,
user, password and root password. use init.sql to create the database and the tables. expose the port 3306.

```Dockerfile
# Dockerfile for MySQL database
FROM mysql:8.0

ENV MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
ENV MYSQL_DATABASE=${MYSQL_DATABASE}
ENV MYSQL_USER=${MYSQL_USER}
ENV MYSQL_PASSWORD=${MYSQL_PASSWORD}

COPY ./init.sql /docker-entrypoint-initdb.d/

EXPOSE 3306

    
```
```sql

CREATE DATABASE IF NOT EXISTS recommendations;
USE recommendations;

CREATE TABLE recommendations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    seed_tracks TEXT NOT NULL,
    market VARCHAR(255),
    min_energy FLOAT,
    max_energy FLOAT,
    target_popularity INT,
    target_acousticness FLOAT,
    target_instrumentalness FLOAT,
    target_tempo INT,
    song_title VARCHAR(255),
    album_title VARCHAR(255),
    year INT,
    artist_name VARCHAR(255)
);

```    
#### docker-compose file

this file is used to run the database and the flask app together. The flask app is dependent on the database and the database 

```yaml
services:
  infra-test:
    build:
      context: .
      dockerfile: flask.Dockerfile
    ports:
      - "5000:5000"
  database:
    build:
      context: .
      dockerfile: database.Dockerfile
    ports:
      - "3306:3306"
    environment:
      - MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      - MYSQL_DATABASE: ${MYSQL_DATABASE}
      - MYSQL_USER: ${MYSQL_USER}
      - MYSQL_PASSWORD: ${MYSQL_PASSWORD}
```
### 5. Create a CI/CD pipeline


- Make sure you have all of the variables set up in the .env file and the terraform.tfvars file in github secrets

- For the CI/CD pipeline, we use GitHub Actions and Docker Hub. We create a workflow file in the `.github/workflows` directory.


```yaml
name: Build and Deploy to AWS

on:
  push:
    branches:
      - main

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v2

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v1

      - name: Log in to Docker Hub
        uses: docker/login-action@v1
        with:
          username: ${{ secrets.DOCKER_HUB_USERNAME }}
          password: ${{ secrets.DOCKER_HUB_ACCESS_TOKEN }}

      - name: Build and push Docker image of Flask app
        uses: docker/build-push-action@v2
        with:
          context: .
          file: ./flask.Dockerfile
          push: true
          tags: ${{ secrets.DOCKER_HUB_USERNAME }}/flask-app-image-repository:latest
          build-args: |
            FLASK_KEY=${{ secrets.FLASK_KEY }}
            SPOTIFY_CLIENT_ID=${{ secrets.SPOTIFY_CLIENT_ID }}
            SPOTIFY_SECRET_ID=${{ secrets.SPOTIFY_SECRET_ID }}
            ENVIRONMENT=${{ secrets.ENVIRONMENT }}

      - name: Set up AWS CLI
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_REGION }}

      - name: Retrieve EC2 instance IPs
        id: get_instances_ips
        run: |
          aws ec2 describe-instances --filters "Name=tag:Name,Values=ec2-1" "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].PublicIpAddress" --output text > ec2_instance_ip_1.txt
          echo "EC2_1_IP=$(cat ec2_instance_ip_1.txt)" >> $GITHUB_ENV
          aws ec2 describe-instances --filters "Name=tag:Name,Values=ec2-2" "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].PublicIpAddress" --output text > ec2_instance_ip_2.txt
          echo "EC2_2_IP=$(cat ec2_instance_ip_2.txt)" >> $GITHUB_ENV
          aws ec2 describe-instances --filters "Name=tag:Name,Values=ec2-3" "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].PublicIpAddress" --output text > ec2_instance_ip_3.txt
          echo "EC2_3_IP=$(cat ec2_instance_ip_3.txt)" >> $GITHUB_ENV

      - name: Create .ssh directory
        run: mkdir -p /home/runner/.ssh

      - name: Create SSH key file
        run: echo "${{ secrets.SSH_PRIVATE_KEY }}" > /home/runner/.ssh/id_rsa

      - name: Set SSH key permissions
        run: chmod 600 /home/runner/.ssh/id_rsa

      - name: Update EC2 with new Docker image
        run: |
          ssh -o StrictHostKeyChecking=no -i /home/runner/.ssh/id_rsa ubuntu@${{ env.EC2_1_IP }} << 'EOF'
            docker pull ${{ secrets.DOCKER_HUB_USERNAME }}/flask-app-image-repository:latest
            docker stop my-container || true
            docker rm my-container || true
            docker run -d --name my-container -p 80:5000 ${{ secrets.DOCKER_HUB_USERNAME }}/flask-app-image-repository:latest
          EOF
          ssh -o StrictHostKeyChecking=no -i /home/runner/.ssh/id_rsa ubuntu@${{ env.EC2_2_IP }} << 'EOF'
            docker pull ${{ secrets.DOCKER_HUB_USERNAME }}/flask-app-image-repository:latest
            docker stop my-container || true
            docker rm my-container || true
            docker run -d --name my-container -p 80:5000 ${{ secrets.DOCKER_HUB_USERNAME }}/flask-app-image-repository:latest
          EOF
          ssh -o StrictHostKeyChecking=no -i /home/runner/.ssh/id_rsa ubuntu@${{ env.EC2_3_IP }} << 'EOF'
            docker pull ${{ secrets.DOCKER_HUB_USERNAME }}/flask-app-image-repository:latest
            docker stop my-container || true
            docker rm my-container || true
            docker run -d --name my-container -p 80:5000 ${{ secrets.DOCKER_HUB_USERNAME }}/flask-app-image-repository:latest
          EOF

      - name: Retrieve Autoscaling EC2 server IPs and update them with new Docker image
        id: get_autoscaling_instances_ips
        run: |
          aws autoscaling describe-auto-scaling-instances --query "AutoScalingInstances[*].InstanceId" --output text > autoscaling_instance_ids.txt 
          aws ec2 describe-instances --instance-ids $(cat autoscaling_instance_ids.txt) --query "Reservations[*].Instances[*].PublicIpAddress" --output text > autoscaling_instance_ips.txt
          ips_file="autoscaling_instance_ips.txt"
          mapfile -t ips < "$ips_file"          
          for ip in "${ips[@]}"; do
            touch update_instance_$ip.sh
            echo '#!/bin/bash' > "update_instance_$ip.sh"
            echo '' >> update_instance_$ip.sh
            echo "Updating instance with IP: $ip" >> "update_instance_$ip.sh"
            echo "ssh -o StrictHostKeyChecking=no -i /home/runner/.ssh/id_rsa ubuntu@$ip <<EOF" >> "update_instance_$ip.sh"
            echo "docker pull ${{ secrets.DOCKER_HUB_USERNAME }}/flask-app-image-repository:latest" >> "update_instance_$ip.sh"
            echo "docker stop my-container || true" >> "update_instance_$ip.sh"
            echo "docker rm my-container || true" >> "update_instance_$ip.sh"
            echo "docker run -d --name my-container -p 80:5000 ${{ secrets.DOCKER_HUB_USERNAME }}/flask-app-image-repository:latest" >> "update_instance_$ip.sh"
            echo "EOF" >> "update_instance_$ip.sh"
            echo "shell script created for $ip"
            echo "Running shell script for $ip"
            chmod +x "update_instance_$ip.sh"
            cat "update_instance_$ip.sh"
            ./update_instance_$ip.sh             
          done
    env:
      AWS_DEFAULT_REGION: ${{ secrets.AWS_DEFAULT_REGION }}
      AWS_REGION: ${{ secrets.AWS_REGION }}
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      DOCKER_HUB_USERNAME: ${{ secrets.DOCKER_HUB_USERNAME }}


```


#### Explanation:
- The workflow is triggered on a push event to the master branch.
- The workflow consists of several steps:
  - Checkout code: This step checks out the code from the repository.
  - Set up Docker Buildx: This step sets up Docker Buildx for building the Docker image.
  - Log in to Docker Hub: This step logs in to Docker Hub using the provided credentials.
  - Build and push Docker image: This step builds the Docker image and pushes it to Docker Hub.
  - Set up AWS CLI: This step sets up the AWS CLI for interacting with AWS services.
  - Retrieve EC2 instance IP: This step retrieves the public IP addresses of the EC2 instances.
  - Create .ssh directory: This step creates the .ssh directory.
  - Create SSH key file: This step creates an SSH key file based on the provided private key.
  - Set SSH key permissions: This step sets the permissions for the SSH key file.
  - Update EC2 with new Docker image: This step updates the EC2 instances with the new Docker image.
  - Retrieve Autoscaling EC2 server IPs and update them with new Docker imaage:
     - Basically retrieves the autoscaling instances and updates them with the new docker image by making a shell script

##### Why is the building and pushing and updating the image of database in not included in the workflow?

The database unlike code is not maintained and edited locally and is being written in the database server by the requests
that is done live by users. The database is constantly changing live in production (again unlike the code) and is not
a part of the codebase and is not being maintained in the repository. The database server updates the dockerhub. 
That's why it is not relevant to update the database server with the new image in the workflow, however the updating 
of the database server with the new image can be done via a script but it still doesn't concern the ci/cd pipeline.

We should have another pipeline for the database to constantly push the changes to the database image in the dockerhub,
so in case of a failure or a problem, we can easily rollback to the previous version of the database image and not lose the data.
This can be done via some scripts and some monitoring tools that can be used to monitor the database and the changes in the database,
or can be manually done by the database administrator.


### <a id="conclusion"></a>Conclusion


In this project, we have created a AWS Infrastructure using Terraform. We have also created a CI/CD pipeline using 
GitHub Actions and Docker Hub that automates the deployment process by building and pushing the Docker image to 
Docker Hub and updating the EC2 instances with the new Docker image. 

The infrastructure can be easily created and destroyed using Terraform, and the CI/CD pipeline automates the 
deployment process, making it easy to deploy changes to the application.




