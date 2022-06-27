
resource "aws_key_pair" "deployer-key" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDG3BCPh2N+4GYqQVfv4zT8m/JzRNxOhnHAfXaphMuH0y9+Q1TDfsYnna/UqZSy2c5Df5wONS8oNgkESDCK9s+qZEJAf+y8pMZ2uZ05BrKhKtzaKGGFh8WQ8M+cJpVlWQy9J3Joiyo7VO0eDnj+Gr16FkHM1l5B9BQ3s/HZwHdtHFG4/TsrmwS3cUq1jgPgYKVqPKx0jeSToQCOxQnID/EZ0ruoa3jzlG7COjU7hpP8sQiSlfrw+WQq4su+p8gAlE0glrrM7u/tPbAE8TER31OLp51MBHWN96zxyG9VyhhHVV00lk2YsT4c6dThBMYWaqaUgRR7shWDPsRjCa2OPq/8Xo3sjUpu5dL2nxsOBHCcTesBtPhAL/Mg+7WbzKI73pwoprfJxV49RLnzpVFQC1Te4lXJXBI/4PrCOehfHYf7lKmGCMgbku9Z7nQO69tu8RUsNHQbNfI+8sNmIvAIHN3HtK55hqDsAvbDRXCA4WzdUU7QxKdbJwsqRfEc1iQdyhs="
}


resource "aws_instance" "bastion_instance" {
  ami           = var.ami # ubuntu 22.04
  instance_type = var.instance_type
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
  key_name         = "deployer-key"

  network_interface {
    network_interface_id = var.private_nics[count.index]
    device_index         = 0
    }
user_data = <<EOF
#!/bin/bash
sudo apt update -y
sudo apt install -y apache2
sudo chown -R ubuntu:ubuntu /var/www
sudo chmod 2775 /var/www
find /var/www -type d -exec chmod 2775 {} \;
find /var/www -type f -exec chmod 0664 {} \;
echo "<!DOCTYPE html><html><body><p>Hello World at "$(date +"%Y-%m-%d")"</p></body></html>" > /var/www/html/index.html
EOF
}


resource "aws_network_interface_sg_attachment" "sg_bastion_attachment" {
  security_group_id    = var.bastion_security_group
  network_interface_id = var.bastion_nic
}


resource "aws_network_interface_sg_attachment" "priv_sub_attachment" {
  count = var.n_subnets
  security_group_id    = var.private_security_group
  network_interface_id = var.private_nics[count.index]
}



resource "aws_lb_target_group_attachment" "alb_attachment" {
  count = var.n_subnets
  target_group_arn = var.target_group_arn
  target_id        = aws_instance.testvms[count.index].id
  port             = 80
}
