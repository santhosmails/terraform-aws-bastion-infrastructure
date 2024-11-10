output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = "ssh ubuntu@${aws_instance.bastion.public_ip}"
}

output "database_private_ip" {
  description = "Private IP of the database instance"
  value       = "ssh -A -J ubuntu@${aws_instance.bastion.public_ip} ec2-user@${aws_instance.database.private_ip}"
}

output "backend_private_ip" {
  description = "Private IP of the backend instance"
  value       = "ssh -A -J ubuntu@${aws_instance.bastion.public_ip} ec2-user@${aws_instance.backend.private_ip}"
}
