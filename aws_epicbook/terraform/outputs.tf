output "ec2_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.epicbook_ec2.public_ip
}

# output "vpc_id" {
#   value = aws_vpc.epicbook-vpc.id
# }

# output "ec2_instance_id" {
#   value = aws_instance.epicbook_ec2.id
# }

output "rds_endpoint" {
  value = aws_db_instance.rds_instance.endpoint
}