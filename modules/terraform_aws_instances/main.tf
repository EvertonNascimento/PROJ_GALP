#loop nos valores de nics e vms
#meter usernames
#
resource "aws_key_pair" "deployer-key" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDLug4pJFWqb+A2nTK5yEFd+IX8X+ziTngZWcZslhGRPM/kOKxBDAvWZS0qYAXe1RobN0IftZbehGp5ScPVXBy0Tq4/PmJUg6r4w2KjJlAYv6gPDzNvZjnZ7TOOchZNCHxttJHNt5FvLu53r4GGtu9hk9P4tATazW21qGR0YmGtHT7dD1mSIXsMqQoyXxicJ7S0cU0vVX0a1XsYANwZ+Y1O0XfMe25vn8JF2gHY2ZMD7qGAAWheBheTpwCHwz9Te3I38DL7NH1mqCvAC9QIUSJaslNWfuEqMp4oFsdl6GDimVK3AK/bCaooYJq5PyyaZPU3i0PenS6ZEFvKw5csFJCR6kHyMSGKUB3p0Ab4RXCtDpl37PCcnirIn1KaR/zvl0yBNDRz0lFLHzkNNXA8/dsDK9aUI9urcAKvJoTWE09C7iPFOwjd7Ap3u5FGB3MjHcZHZsQ+VRCIVluBfze/dnHYpge7/0x/ktWCzwRHxyJrhyy3vuTW+NIJq7ss7NhmhNM= timestamp/everton.nascimento@TSSILAP0465"
}


resource "aws_instance" "bastion_instance" {
  ami           = var.ami # ubuntu 22.04
  instance_type = var.instance_type
  #security_groups = aws_security_group.public_sg.id
  #security_groups = [var.bastion_security_group]
  key_name         = "deployer-key"
  network_interface {
    network_interface_id = var.bastion_nic
    device_index         = 0
        }

  
}

resource "aws_eip" "bastion-ip" {
  instance = aws_instance.bastion_instance.id
  vpc      = true
}



resource "aws_instance" "testvms" {
  count = var.n_subnets
  ami           = var.ami # ubuntu 22.04
  instance_type = var.instance_type
  #security_groups = aws_security_group.private_sg.id
  #security_groups = [var.private_security_group]

  network_interface {
    #network_interface_id = aws_network_interface.test_nic1.id
    network_interface_id = var.private_nics[count.index]
    device_index         = 0
    }
}

/*
#instances are associated with target group
resource "aws_lb_target_group_attachment" "private_subs_attachment" {
  target_group_arn = aws_lb_target_group.private_target_group.id
  target_id        = aws_instance.testvms.*.id
  port             = 80
}
*/