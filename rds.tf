terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.27.0"
    }
  }
}

provider "aws" {
  region= "ap-south-1"
}
resource "aws_vpc" "local" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "myvpc"
  }
}
resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.local.id

  tags = {
    Name = "IGW"
  }
}
resource "aws_subnet" "publicsubnet" {
  vpc_id     = aws_vpc.local.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "pubsub"
  }
}
resource "aws_subnet" "privatesubnet" {
  vpc_id     = aws_vpc.local.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    Name = "pvtsub"
  }
}

resource "aws_db_subnet_group" "dbgroup" {
  name       = "main"
  subnet_ids = [aws_subnet.publicsubnet.id, aws_subnet.privatesubnet.id]

  tags = {
    Name = "My DB subnet group"
  }
}



resource "aws_security_group" "public_security" {
  name        = "public_security"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.local.id

  ingress {
    description = "TLS from VPC"
    from_port   = 0
    to_port     = 65535
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
    Name = "public_secure"
  }
}
resource "aws_db_instance" "mydb" {
  identifier                = "mydb"
  allocated_storage         = 20
  engine                    = "mysql"
  engine_version            = "5.6.35"
  instance_class            = "db.t2.micro"
  name                      = "mysqldb"
  username                  = "admin"
  password                  = "admin123"
  db_subnet_group_name      = aws_db_subnet_group.dbgroup.id
  vpc_security_group_ids    = [aws_security_group.public_security.id]
  skip_final_snapshot       = true
  final_snapshot_identifier = "Ignore"
}
