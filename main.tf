terraform {
 required_providers {
     aws = {
         source = "hashicorp/aws"
         version = "~>3.0"
     }
 }
}

# Configure the AWS provider

provider "aws" {
    region = "us-east-2"
}


# Create a VPC

resource "aws_vpc" "MyLab-VPC"{
    cidr_block = var.cidr_block[0]

    tags = {
        Name = "MyLab-VPC"
    }

}

# Create Subnet

resource "aws_subnet" "MyLab-Subnet1" {
    vpc_id = aws_vpc.MyLab-VPC.id
    cidr_block = var.cidr_block[1]

    tags = {
        Name = "MyLab-Subnet1"
    }
}

# Create Internet Gateway

resource "aws_internet_gateway" "MyLab-IntGW" {
    vpc_id = aws_vpc.MyLab-VPC.id

    tags = {
        Name = "MyLab-InternetGW"
    }
}


# Create Secutity Group

resource "aws_security_group" "MyLab_Sec_Group" {
  name = "MyLab Security Group"
  description = "To allow inbound and outbound traffic to mylab"
  vpc_id = aws_vpc.MyLab-VPC.id

  dynamic ingress {
      iterator = port
      for_each = var.ports
       content {
            from_port = port.value
            to_port = port.value
            protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
       }

  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  } 

  tags = {
      Name = "mylab_traffic"
  }

}

# Create route table and association

resource "aws_route_table" "MyLab_RouteTable" {
    vpc_id = aws_vpc.MyLab-VPC.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.MyLab-IntGW.id
    }

    tags = {
        Name = "MyLab_Routetable"
    }
}

# Create route table association
resource "aws_route_table_association" "MyLab_Assn" {
    subnet_id = aws_subnet.MyLab-Subnet1.id
    route_table_id = aws_route_table.MyLab_RouteTable.id
}

# Create an AWS EC2 Instance to host Jenkins

resource "aws_instance" "Jenkins" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name = var.key_name
  vpc_security_group_ids = ["sg-04f4aff6296bd5706"]
  subnet_id = var.subnet
  associate_public_ip_address = true
  user_data = <<EOF
  #!/bin/bash
sudo yum update –y
sudo wget -O /etc/yum.repos.d/jenkins.repo \https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum upgrade
sudo amazon-linux-extras install java-openjdk11 -y
sudo yum install jenkins -y
sudo systemctl enable jenkins
sudo systemctl start jenkins
sudo systemctl status jenkins
EOF
  tags = {
    Name = "Jenkins-Server"
  }
}


# Create an AWS EC2 Instance to host Ansible Controller (Control node)

resource "aws_instance" "AnsibleController" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name = var.key_name
  vpc_security_group_ids = ["sg-04f4aff6296bd5706"]
  subnet_id = var.subnet
  associate_public_ip_address = true
  user_data = <<EOF
  #!/bin/bash
sudo yum update -y 
sudo yum-config-manager --enable epel
sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo yum install epel-release-latest-7.noarch.rpm
sudo amazon-linux-extras list 
grep ansible2
sudo yum install python python-devel python-pip openssl ansible -y
sudo amazon-linux-extras enable ansible2 
sudo yum update -y
sudo yum install -y ansible
sudo amazon-linux-extras install ansible2 -y
sudo amazon-linux-extras install epel -y
sudo yum-config-manager --enable epel
sudo yum install python3 -y
python3 --version -y 
EOF
  tags = {
    Name = "Ansible-ControlNode"
  }
}

# Create/Launch an AWS EC2 Instance(Ansible Managed Node1) to host Apache Tomcat server

resource "aws_instance" "AnsibleManagedNode1" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name = var.key_name
  vpc_security_group_ids = ["sg-04f4aff6296bd5706"]
  subnet_id = var.subnet
  associate_public_ip_address = true
  user_data = <<EOF
  #! /bin/bash
# add the user ansible admin
useradd ansibleadmin
# set password : the below command will avoid re entering the password
echo "ansibleansible" | passwd --stdin ansibleadmin
# modify the sudoers file at /etc/sudoers and add entry
echo 'ansibleadmin     ALL=(ALL)      NOPASSWD: ALL' | sudo tee -a /etc/sudoers
echo 'ec2-user     ALL=(ALL)      NOPASSWD: ALL' | sudo tee -a /etc/sudoers
# this command is to add an entry to file : 
echo 'PasswordAuthentication yes' | sudo tee -a /etc/ssh/sshd_config
# the below sed command will find and replace words with spaces "PasswordAuthentication no" to "PasswordAuthentication yes"
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
service sshd restart
EOF
  tags = {
    Name = "AnsibleMN-ApacheTomcat"
  }
}
/*
# Create/Launch an AWS EC2 Instance(Ansible Managed Node2) to host DOCKERHOST

resource "aws_instance" "AnsibleMN-DockerHost" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name = var.key_name
  vpc_security_group_ids = ["sg-04f4aff6296bd5706"]
  subnet_id = var.subnet
  associate_public_ip_address = true
  user_data = file("./Docker.sh")

  tags = {
    Name = "AnsibleMN-DockerHost"
  }
}
*/
# Create/Launch an AWS EC2 Instance to host Sonatype Nexus

resource "aws_instance" "Nexus" {
  ami           = var.ami
  instance_type = var.instance_type_for_nexus
  key_name = var.key_name
  vpc_security_group_ids = ["sg-04f4aff6296bd5706"]
  subnet_id = var.subnet
  associate_public_ip_address = true
  user_data = <<EOF
  yum remove java* -y
  sudo yum install java-1.8.0-openjdk.x86_64 -y
  cd /opt
  wget https://sonatype-download.global.ssl.fastly.net/nexus/3/latest-unix.tar.gz
  tar -zxvf latest-unix.tar.gz
  mv /opt/nexus-3.* /opt/nexus
  sudo adduser nexus  
  sudo chown -R nexus:nexus /opt/nexus
  touch /opt/nexus/bin/nexus.rc
  sudo echo 'run_as_user="nexus"' | sudo tee -a /opt/nexus3/bin/nexus.rc
  sudo ln -s /opt/nexus/bin/nexus /etc/init.d/nexus
  su - nexus
  service nexus start
  EOF
  tags = {
    Name = "Nexus-Server"
  }
}  
