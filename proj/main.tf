#meter isto como environment variable
provider "aws" {
 
}


module "network" {
  source       = "../modules/terraform_aws_network"
  network_cidr = var.network_cidr
  n_subnets    = var.n_subnets
  infra_name   = var.infra_name
  tags         = { infra = "test" }

}


/*module "golden_image" {
  source = "../modules/terraform_aws_instances"

    ami           = "ami-052efd3df9dad4825" # ubuntu 22.04
    instance_type = "t2.micro"
    network_interface_ids = module.network.nicids
  
}
*/


module "instances" {
  source        = "../modules/terraform_aws_instances"
  ami           = var.ami # ubuntu 22.04 eu-west
  instance_type = var.instance_type
  public_key = var.public_key
  #n_subnets = ceil((var.n_subnets)/2)
  n_subnets = var.n_subnets #3 is the max number of subnets
  bastion_subnet         = module.network.network_info.public_subnets[0]
  private_subnets        = module.network.network_info.private_subnets
  public_subnets         = module.network.network_info.public_subnets
  bastion_nic            = module.network.network_info.bastion_nic
  private_nics           = module.network.network_info.private_nics
  public_security_group  = module.network.network_info.public_security_group
  private_security_group = module.network.network_info.private_security_group
  bastion_security_group = module.network.network_info.bastion_security_group
  loadbalancer_sg        = module.network.network_info.loadbalancer_sg
  target_group_arn       = module.network.network_info.target_group_arn

}


output "vm_ips" {
  value = module.instances.private_vms_ips
}
output "bastion_ip" {
  value = module.instances.bastion_public_ip
}
output "public_key" {
  value = module.instances.ssh_key
}

output "Load_balancer_HTTP_Content" {
  value = module.network.network_info.loadbalancer_dns
}
