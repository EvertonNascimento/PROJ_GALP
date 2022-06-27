/*
input:
- Network_CIDR (string, required). Set the IP address configuration to be configured into VPC and all
required network resources.
- N_subnets (integer, required). Set the total subnets to create into VPC. This input variable can only
accept an even number, except if the "plus" of this module (see below) is done, then this condition
does not apply.
- Name (string, required). To set the name value on Tags or resources field if the resource support or
require it (Caution! sometimes the name fields existing in some resources must be unique regarding
other resources, thus, it must be handled)
- Tags (key/value dictionary or map, optional). Set the defined tags on the resources that support it.



output:
The module must response the following output variables:
- Network (key/value dictionary or map). A dictionary or map with all information regarding the VPC,
subnets, and any existing settings and resources related to the creation and configuration of networking in this module.

*/

/*
provider "aws" {
  region = "us-east-1"
  access_key = "AKIATEMBSVXNIGAP2DMN"
  secret_key = "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"
}

*/


#posso meter source com o github até
/*module network {
    #source = "git::https:EvertonNascimento/GALP/tree/main/modules/terraform_aws_network"
    #source =  "git::ssh://EvertonNascimento@github.com/GALP/tree/main/modules/terraform_aws_network"
    source = "../modules/terraform_aws_network"
    
    network_cidr = var.network_cidr
    n_subnets = var.n_subnets
    name = var.name
    tags = var.tags
}



output "network_nics_ids" {

    value = module.network.nicids
  
}*/


data "aws_availability_zones" "available" {}


resource "aws_vpc" "my_vpc" {
  cidr_block = var.network_cidr
  #cidr_block = "172.168.0.0/16"

  tags = {
    Name = "test vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "test gateway"
  }
}

#connects to public subnets
resource "aws_route_table" "rt_internet_gateway" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "10.0.1.0/24"
    gateway_id = aws_internet_gateway.gw.id
  }

  #route {
  #  ipv6_cidr_block        = "::/0"
  #  egress_only_gateway_id = aws_egress_only_internet_gateway.example.id
  #}

  tags = {
    Name = "example"
  }
}

resource "aws_security_group" "public_sg" {
  name        = "public_sg"
  description = "public sg"
  vpc_id      = aws_vpc.my_vpc.id

  tags = {
    Name = "public_sg"
  }
}


#

#connects to private subnets
resource "aws_route_table" "rt_nat_outbound" {
  vpc_id = aws_vpc.my_vpc.id

 #internet route, nats f
  route {
    cidr_block = "0.0.0.0/24"
    gateway_id = aws_nat_gateway.nat_outbound.id
  }

  #route {
  #  ipv6_cidr_block        = "::/0"
  #  egress_only_gateway_id = aws_egress_only_internet_gateway.example.id
  #}

  tags = {
    Name = "nat outbound"
  }
}

resource "aws_security_group" "private_sg" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.my_vpc.id

  tags = {
    Name = "private_sg"
  }
}


resource "aws_security_group" "bastion_sg" {
  name        = "bastion_sg"
  description = "bastion_sg"
  vpc_id      = aws_vpc.my_vpc.id

  tags = {
    Name = "bastion_sg"
  }
}

#private security group rules
resource "aws_security_group_rule" "allow_ssh_rule" {
  type              = "ingress"
  from_port        = 22
  to_port          = 22
  protocol          = "tcp"
  #cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.private_sg.id
  source_security_group_id = aws_security_group.bastion_sg.id
}

resource "aws_security_group_rule" "allow_lb_rule" {
  type              = "ingress"
  from_port        = 80
  to_port          = 80
  protocol          = "tcp"
  #cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.private_sg.id
  source_security_group_id = aws_security_group.loadbalancer_sg.id
}



#public security group rules

resource "aws_security_group_rule" "allow_internet_lb_rule" {
  type              = "ingress"
  from_port        = 80
  to_port          = 80
  protocol          = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.loadbalancer_sg.id
}

#bastion sg rule, preencher
resource "aws_security_group_rule" "bastion_sg_rule" {
  type              = "ingress"
  from_port        = 80
  to_port          = 80
  protocol          = "tcp"
  #cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.private_sg.id
  source_security_group_id = aws_security_group.bastion_sg.id
}


resource "aws_security_group_rule" "bastion_sg_rule2" {
  type              = "ingress"
  from_port        = 22
  to_port          = 22
  protocol          = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion_sg.id
  
}



#loop
resource "aws_subnet" "pubsub" {
  count = var.n_subnets
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "172.168.${count.index}.0/24"
  #availability_zone = "us-east-${count.index + 1}a"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "public subnet"
  }
}

#loop
resource "aws_subnet" "privsub" {
  count = var.n_subnets
  vpc_id            = aws_vpc.my_vpc.id
  #calculate cidr block
  cidr_block        = "172.168.${count.index + var.n_subnets}.0/24"
  #availability_zone = "us-east-${count.index + 1}b"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "private subnet"
  }
}

#jump box nic
resource "aws_network_interface" "bastion_nic" {
  
  subnet_id   = aws_subnet.pubsub[0].id
 

  tags = {
    Name = "nic of bastion"
  }
}


#loop
resource "aws_network_interface" "priv_nics" {
  count = var.n_subnets
  subnet_id   = aws_subnet.privsub[count.index].id
  #private_ips = ["172.16.10.100"]

  tags = {
    Name = "nics for private machines"
  }
}


resource "aws_security_group" "loadbalancer_sg" {
  name        = "lb_sg"
  description = "security group of aplication load balancer"
  vpc_id      = aws_vpc.my_vpc.id


  tags = {
    Name = "load balancer sg"
  }
}

#fazer as duas com as instancias
resource "aws_lb_target_group" "private_target_group" {
  name     = "privatetargetgroup"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id
  load_balancing_algorithm_type = "round_robin"

}



#associate load balancer to public sgs
resource "aws_lb" "alb" {
  name               = "myvpcapploadbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.loadbalancer_sg.id]
  #subnets            = [jsonencode(aws_subnet.pubsub.*.id)]
  subnets = [for subnet in aws_subnet.pubsub : subnet.id]
  enable_deletion_protection = false


  tags = {
    Name = "Load Balancer"
    Environment = "production"
  }


}



#para teste




/*


resource "aws_network_interface" "test_nic" {
  subnet_id   = aws_subnet.pubsub.id
  #private_ips = ["172.16.10.100"]

  tags = {
    Name = "test nic for pub ec2"
  }
}


resource "aws_instance" "test_instance" {
  ami           = "ami-052efd3df9dad4825" # ubuntu 22.04
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = aws_network_interface.test_nic.id
    device_index         = 0
        }
}


resource "aws_eip" "example_ip" {
  vpc = true

  instance                  = aws_instance.test_instance.id
  associate_with_private_ip = "10.0.0.12"
  depends_on                = [aws_internet_gateway.gw]
}
*/



#outbound internet nat gateway
resource "aws_nat_gateway" "nat_outbound" {
  #allocation_id = aws_eip.example_ip.id
  #test
  connectivity_type = "private"
  #jsonencode(var.allowed_ips.*.ip_address)
  #subnet_id     = jsonencode(aws_subnet.privsub.*.id)
  subnet_id = aws_subnet.pubsub[0].id

  tags = {
    Name = "gw NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}