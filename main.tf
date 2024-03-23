provider "aws" {
  region = "us-east-1"
  access_key = "your-access-key"
  secret_key = "your-secret-key"
}

# resource "<provider>-<resource-type>" "name" {
#   configutaion.....
# }

# 1. Create a VPC- Done
# 2. Create Internet Gateway
# 3. Create Custom Route Table
# 4. Create a subnet
# 5. Associate Subnet with route Table
# 6. Create security group to allow port 22, 80, 443
# 7. Create a network interface with an ip in the subnet that was created in step 4
# 8. Assign an elastic ip to the network interface created in step 7
# 9. Create Ubuntu Server and install/enable apache2


#Creation of VPC
resource "aws_vpc" "vpc-one" {
  cidr_block = "10.0.0.0/16"
}

#Create Internet Gateway

resource "aws_internet_gateway" "ig-one" {
  vpc_id = aws_vpc.vpc-one.id
  tags = {
    name = "my-ig"
  }  

}

#Create custom route table

resource "aws_route_table" "rt-one" {
  vpc_id = aws_vpc.vpc-one.id
  tags = {
    name = "my-rt"
  }

  #Define routes to the route table
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig-one.id
  }
  # route {
  #   ipv6_cidr_block = "::/0"
  #   egress_only_gateway_id = aws_internet_gateway.ig-one.id
  # }

  
}
#Create a subnet
resource "aws_subnet" "subnet-1" {
  cidr_block = "10.0.1.0/24"
  vpc_id = aws_vpc.vpc-one.id
  tags = {
    name = "my-subnet-1"
  }

  
}

resource "aws_route_table_association" "rt-assoc" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.rt-one.id
}

resource "aws_security_group" "sg-group" {
  name = "allow-traffic"
  description = "Allow traffic from 22, 443, 80"
  vpc_id = aws_vpc.vpc-one.id

  ingress {
    description ="HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0"]
    
  }
  ingress {
    
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port =  0 
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  }

resource "aws_network_interface" "my-ni" {
  description = "my network interface"
  subnet_id = aws_subnet.subnet-1.id
  private_ips = ["10.0.1.50"]
  security_groups = [ aws_security_group.sg-group.id ]
}

resource "aws_eip" "one" {

  domain                    = "vpc"
  network_interface         = aws_network_interface.my-ni.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [ aws_internet_gateway.ig-one ]
}

resource "aws_instance" "ec2" {
  ami = "ami-080e1f13689e07408"
  instance_type = "t2.micro"
  key_name = "pn3270_AWS_KEY"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.my-ni.id
  }
  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo your very first web server > /var/www/html/index.html'
                EOF
  tags = {
    Name = "web-activity"
  }
  
}
