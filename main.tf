provider "aws" {
  region = "us-east-1"
}

# Get the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Fetch default VPC
data "aws_vpc" "default" {
  default = true
}

# Fetch default subnet IDs
#data "aws_subnet_ids" "default" {
 # vpc_id = data.aws_vpc.default.id
#}

#data "aws_subnets" "default" {
 # filter {
  #  name   = "vpc-id"
   # values = [var.vpc_id]
  #}
#}


# Security Group that allows all traffic (not recommended for production)
resource "aws_security_group" "allow_all" {
  name        = "allow_all_traffic"
  description = "Allow all inbound and outbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create two EC2 instances and run a shell script on boot
resource "aws_instance" "example" {
  count                  = 2
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"
  #subnet_id              = data.aws_subnets.default.ids[count.index]
  vpc_security_group_ids = [aws_security_group.allow_all.id]
  key_name               = "stark" # Replace with your actual key name
user_data =  "${file("script.sh")}"
   tags = {
    Name = "AmazonLinux-${count.index}"
  }
}

//s3 bucket creation from here
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "general_bucket" {
  bucket = "my-general-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "GeneralBucket"
    Environment = "Dev"
  }
}



# Output instance public IPs
output "instance_public_ips" {
  value = [for i in aws_instance.example : i.public_ip]
}
