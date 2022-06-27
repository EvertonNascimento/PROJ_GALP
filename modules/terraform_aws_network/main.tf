
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
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  #route {
  #  ipv6_cidr_block        = "::/0"
  #  egress_only_gateway_id = aws_egress_only_internet_gateway.example.id
  #}

  tags = {
    Name = "internet gw route"
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
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_outbound.id
  }

  #route {
  #  ipv6_cidr_block        = "::/0"
  #  egress_only_gateway_id = aws_egress_only_internet_gateway.example.id
  #}

  tags = {
    Name = "nat outbound route"
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


resource "aws_eip" "nat-outbound-ip" {
  #instance = aws_instance.bastion_instance.id
  vpc      = true
}


#outbound internet nat gateway
resource "aws_nat_gateway" "nat_outbound" {
  allocation_id = aws_eip.nat-outbound-ip.id
  connectivity_type = "public"
  subnet_id = aws_subnet.pubsub[0].id

  tags = {
    Name = "gw NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}



resource "aws_route_table_association" "public_association" {
  count = var.n_subnets
  subnet_id      = aws_subnet.pubsub[count.index].id
  route_table_id = aws_route_table.rt_internet_gateway.id
}


resource "aws_route_table_association" "private_association" {
  count = var.n_subnets
  subnet_id      = aws_subnet.privsub[count.index].id
  route_table_id = aws_route_table.rt_nat_outbound.id
}
