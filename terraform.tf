#Initialize Terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS provider
provider "aws" {
  region = "ap-south-1"
}
# Creating a VPC
resource "aws_vpc" "proj-vpc" {
 cidr_block = "10.0.0.0/16"
}

# Create an Internet Gateway
resource "aws_internet_gateway" "proj-ig" {
 vpc_id = aws_vpc.proj-vpc.id
 tags = {
 Name = "gateway1"
 }
}

# Setting up the route table
resource "aws_route_table" "proj-rt" {
 vpc_id = aws_vpc.proj-vpc.id
 route {
 # pointing to the internet
 cidr_block = "0.0.0.0/0"
 gateway_id = aws_internet_gateway.proj-ig.id
 }
 route {
 ipv6_cidr_block = "::/0"
 gateway_id = aws_internet_gateway.proj-ig.id
 }
 tags = {
 Name = "rt1"
 }
}

# Setting up the subnet
resource "aws_subnet" "proj-subnet" {
 vpc_id = aws_vpc.proj-vpc.id
 cidr_block = "10.0.1.0/24"
 availability_zone = "ap-south-1b"
 tags = {
 Name = "subnet1"
 }
}

# Associating the subnet with the route table
resource "aws_route_table_association" "proj-rt-sub-assoc" {
subnet_id = aws_subnet.proj-subnet.id
route_table_id = aws_route_table.proj-rt.id
}

# Creating a Security Group
resource "aws_security_group" "proj-sg" {
 name = "proj-sg"
 description = "Enable web traffic for the project"
 vpc_id = aws_vpc.proj-vpc.id
 ingress {
 description = "HTTPS traffic"
 from_port = 443
 to_port = 443
 protocol = "tcp"
 cidr_blocks = ["0.0.0.0/0"]
 }
 ingress {
 description = "HTTP traffic"
 from_port = 0
 to_port = 65000
 protocol = "tcp"
 cidr_blocks = ["0.0.0.0/0"]
 }
 ingress {
 description = "Allow port 80 inbound"
 from_port   = 80
 to_port     = 80
 protocol    = "tcp"
 cidr_blocks = ["0.0.0.0/0"]
  }
 egress {
 from_port = 0
 to_port = 0
 protocol = "-1"
 cidr_blocks = ["0.0.0.0/0"]
 ipv6_cidr_blocks = ["::/0"]
 }
 tags = {
 Name = "proj-sg1"
 }
}

# Creating a new network interface
resource "aws_network_interface" "proj-ni" {
 subnet_id = aws_subnet.proj-subnet.id
 private_ips = ["10.0.1.10"]
 security_groups = [aws_security_group.proj-sg.id]
}

# Creating an ubuntu EC2 instance
resource "aws_instance" "Prod-Server" {
 ami = "ami-0ef82eeba2c7a0eeb"
 instance_type = "t2.medium"
 availability_zone = "ap-south-1b"
 key_name = "chefkeypair"
 network_interface {
 device_index = 0
 network_interface_id = aws_network_interface.proj-ni.id
 }
 user_data  = <<-EOF
 #!/bin/bash
     sudo apt-get update
     sudo curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.24.9/2023-01-11/bin/linux/amd64/kubectl
     sudo chmod +x ./kubectl
     sudo mv ./kubectl /usr/local/bin/kubectl
     sudo apt update && sudo apt install docker.io -y
     sudo curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin
     sudo apt install conntrack -y
     sudo git clone https://github.com/Mirantis/cri-dockerd.git
     sudo wget https://storage.googleapis.com/golang/getgo/installer_linux
     sudo chmod +x ./installer_linux
     sudo ./installer_linux
     sudo source ~/.bash_profile
     sudo cd cri-dockerd
     sudo mkdir bin
     sudo go get && go build -o bin/cri-dockerd
     sudo mkdir -p /usr/local/bin
     sudo install -o root -g root -m 0755 bin/cri-dockerd /usr/local/bin/cri-dockerd
     sudo cp -a packaging/systemd/* /etc/systemd/system
     sudo sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service
     sudo systemctl daemon-reload
     sudo systemctl enable cri-docker.service
     sudo systemctl enable --now cri-docker.socket
     sudo VERSION="v1.24.1" # check latest version in /releases page
     curl -L https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-${VERSION}-linux-amd64.tar.gz --output crictl-${VERSION}-linux-amd64.tar.gz
     sudo tar zxvf crictl-$VERSION-linux-amd64.tar.gz -C /usr/local/bin
     sudo rm -f crictl-$VERSION-linux-amd64.tar.gz
     sudo cp /usr/local/bin/cri-dockerd /usr/bin/
     sudo systemctl status cri-docker
     sudo systemctl start cri-docker
     sudo systemctl status cri-docker
     minikube start --vm-driver=none
     sudo curl https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/canal.yaml -O
     kubectl apply -f canal.yaml
     kubectl create deployment insureme --image=vikuldocker/insureme:1.0
     kubectl expose deployment insureme --type=NodePort --port=8081
     sudo docker run -p 9090:9090 prom/prometheus
     sudo docker run -d -p 3000:3000 grafana/grafana-enterprise
     sudo systemctl daemon-reload
     sudo systemctl start grafana-server
 EOF
 tags = {
 Name = "Prod-Server"
 }
}
