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