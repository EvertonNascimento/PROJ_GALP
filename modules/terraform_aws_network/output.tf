output "network_info" {
  value       = {
    vpc_id        = aws_vpc.my_vpc.id
    public_subnets  = aws_subnet.pubsub.*.id
    private_subnets = aws_subnet.privsub.*.id
    bastion_nic = aws_network_interface.bastion_nic.id
    private_nics = aws_network_interface.priv_nics.*.id
    private_security_group = aws_security_group.private_sg.id
    public_security_group = aws_security_group.public_sg.id
    bastion_security_group = aws_security_group.bastion_sg.id
    loadbalancer_sg = aws_security_group.loadbalancer_sg.id
  }
  description = "VPC id, List of all public, private and db subnet IDs"
}

output "loadbalancer_dns" {
  value = aws_lb.alb.dns_name
}