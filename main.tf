provider "aws" {
  region = "us-east-2"
  

}

resource "aws_vpc" "main-cicd" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-cicd"
  }
}


resource "aws_subnet" "public_1a" {
  vpc_id                  = aws_vpc.main-cicd.id
  availability_zone       = "us-east-2a"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_1a"
  }
}

#iGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main-cicd.id

  tags = {
    Name = "igw"
  }

}
#Public route

resource "aws_route_table" "route_public1" {
  vpc_id = aws_vpc.main-cicd.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "route_public1"
  }
}

resource "aws_route_table_association" "public_assoc1" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.route_public1.id

}

#key name
resource "aws_key_pair" "cicd-keys" {
  key_name   = "cicd-keys"
  public_key = file("key.pem.pub")
}

# ec2 
resource "aws_instance" "web_server" {
  ami                         = var.ami
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_1a.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.web-sg.id]
  key_name                    = aws_key_pair.cicd-keys.key_name
  iam_instance_profile        = aws_iam_instance_profile.codedeploy_profile.name


  #cloud watch agent
  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo amazon-linux-extras enable nginx1
    sudo yum install -y nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx
    sudo yum install -y ruby wget   
    cd /home/ec2-user
    wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
    chmod +x ./install
    sudo ./install auto
    sudo service codedeploy-agent start
  EOF



  tags = {
    Name = "web_server"
  }



}

#sg
resource "aws_security_group" "web-sg" {
  name        = "public_sg"
  description = "allow HTTP AND SSH acess"
  vpc_id      = aws_vpc.main-cicd.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# Instance Profile for EC2
resource "aws_iam_instance_profile" "codedeploy_profile" {
  name = "codedeploy-profile"
  role = aws_iam_role.codedeploy_role.name
}

#s3
resource "aws_s3_bucket" "new_bucket" {
    bucket = "my-codepipeline-bucket-sa-liv-sa1"

    tags = {
      Name = "my-codepipeline-bucket-sa-liv-sa1"
    }
  
}