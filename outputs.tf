# Output the public IP of the EC2 instance (now in output.tf)
output "ec2_public_ip" {
  value = aws_instance.my_instance.public_ip
}

# Output the RDS instance endpoint
output "rds_endpoint" {
  value = aws_db_instance.my_postgres.endpoint
}
