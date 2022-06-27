#meter isto como environment variable
provider "aws" {
 
}


module network {
    source = "../modules/terraform_aws_network"
    #network_cidr = var.network_cidr
    #network_cidr = "172.168.0.0/16"
    #n_subnets = ceil((var.n_subnets)/2)
    #n_subnets = "6"
    #name = "test"
    #tags = "test"
    #infra_name = var.infra_name
    #tags = var.tags
    network_cidr = "172.168.0.0/16"
    n_subnets = "3"
    infra_name = "test_sre"
    tags = { infra = "test"}

}


/*module "golden_image" {
  source = "../modules/terraform_aws_instances"

    ami           = "ami-052efd3df9dad4825" # ubuntu 22.04
    instance_type = "t2.micro"
    network_interface_ids = module.network.nicids
  
}
*/

module "instances" {
    source = "../modules/terraform_aws_instances"
    ami           = "ami-09e513e9eacab10c1" # ubuntu 22.04 eu-west
    instance_type = "t2.micro"
    #n_subnets = ceil((var.n_subnets)/2)
    n_subnets = "3" #3 is the max number of subnets
    #networks = module.network.networks
    bastion_subnet = module.network.network_info.public_subnets[0]
    private_subnets = module.network.network_info.private_subnets
    public_subnets = module.network.network_info.public_subnets
    bastion_nic = module.network.network_info.bastion_nic
    private_nics = module.network.network_info.private_nics
    public_security_group = module.network.network_info.public_security_group
    private_security_group = module.network.network_info.private_security_group
    bastion_security_group = module.network.network_info.bastion_security_group
    loadbalancer_sg = module.network.network_info.loadbalancer_sg
    
}
