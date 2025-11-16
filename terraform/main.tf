terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.19.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "epicbook-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${var.vpc_name}-vpc"
  }
}

data "aws_availability_zones" "aws_tf_available" {
  state = "available"
}

# Public Subnet for the EC2 instance
resource "aws_subnet" "epicbook-pub-subnet" {
  vpc_id            = aws_vpc.epicbook-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.aws_tf_available.names[0]

  tags = {
    Name = "${var.vpc_name}-pub-subnet"
  }
}

# Private Subnet for the RDS 
resource "aws_subnet" "epicbook-priv-subnet1" {
  vpc_id            = aws_vpc.epicbook-vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.aws_tf_available.names[0]

  tags = {
    Name = "${var.vpc_name}-priv-subnet1"
  }
}

resource "aws_subnet" "epicbook-priv-subnet2" {
  vpc_id            = aws_vpc.epicbook-vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.aws_tf_available.names[1]

  tags = {
    Name = "${var.vpc_name}-priv-subnet2"
  }
}

resource "aws_network_interface" "epicbook_network_interface" {
  subnet_id   = aws_subnet.epicbook-pub-subnet.id
  private_ips = ["10.0.1.10"]

  tags = {
    Name = "epicbook-network-interface"
  }
}

resource "aws_internet_gateway" "epicbook-igw" {
  vpc_id = aws_vpc.epicbook-vpc.id

  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

resource "aws_route_table" "epicbook-pub-rt" {
  vpc_id = aws_vpc.epicbook-vpc.id

  tags = {
    Name = "epicbook-public-rt"
  }
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.epicbook-pub-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.epicbook-igw.id
}

resource "aws_route_table_association" "epicbook_pub_rt-assoc" {
  subnet_id      = aws_subnet.epicbook-pub-subnet.id
  route_table_id = aws_route_table.epicbook-pub-rt.id
}

resource "aws_security_group" "ec2_sg" {
  name        = "${var.ec2_name}-sg"
  description = "Allow SSH and HTTP access"
  vpc_id      = aws_vpc.epicbook-vpc.id

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2_security_group"
  }
}

resource "aws_security_group" "rds_ec2_sg" {
  name        = "ec2-to-rds-sg"
  description = "Allow EC2 to RDS access"
  vpc_id      = aws_vpc.epicbook-vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  tags = {
    Name = "rds_ec2_security_group"
  }
}

resource "aws_key_pair" "key_pair" {
  key_name   = var.key_pair
  public_key = file(var.key_name)
}

# data "aws_ami" "ec2_ami" {
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["amzn2-ami-hvm-*-x86_64-gp2"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }

#   owners = ["137112412989"] # Amazon
# }

resource "aws_instance" "epicbook_ec2" {
  ami                         = var.ec2_ami
  instance_type               = var.ec2_instance_type
  subnet_id                   = aws_subnet.epicbook-pub-subnet.id
  security_groups             = [aws_security_group.ec2_sg.id]
  key_name                    = aws_key_pair.key_pair.key_name
  associate_public_ip_address = true

  tags = {
    Name = var.ec2_name
  }
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "main"
  subnet_ids = [aws_subnet.epicbook-priv-subnet1.id, aws_subnet.epicbook-priv-subnet2.id]

  tags = {
    Name = "rds-subnet-group"
  }
}

resource "aws_db_instance" "rds_instance" {
  allocated_storage    = 10
  # db_name              = "mysql_db"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = var.rds_instance_class
  username             = var.rds_username
  password             = var.rds_password
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  publicly_accessible  = false

  vpc_security_group_ids = [aws_security_group.rds_ec2_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name

  tags = {
    Name = var.rds_name
  }
}
