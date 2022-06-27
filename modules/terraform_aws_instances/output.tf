output "private_vms_ips" {
  value       = [aws_instance.testvms.*.private_ip]
  description = "private machines ips"
}

output "bastion_public_ip" {
  value       = [aws_instance.bastion_instance.*.public_ip]
  description = "bastion machine ip"
}

output "ssh_key" {
  value = aws_key_pair.deployer-key.public_key
}
