# Create a Security Group for RDS (PostgreSQL) allowing access only from the EC2's security group
resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.public_sg.id]  # Corrected to use security_groups
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}

# Create a subnet group for RDS using the private subnet
resource "aws_db_subnet_group" "my_db_subnet_group" {
  name       = "my-db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet.id, aws_subnet.public_subnet.id]
  # Place RDS in the private subnet

  tags = {
    Name = "my-db-subnet-group"
  }
}

# Create a Free Tier PostgreSQL RDS instance in the private subnet
resource "aws_db_instance" "my_postgres" {
  allocated_storage       = 20             # 20 GB is free tier eligible
  engine                  = "postgres"
  instance_class          = "db.t3.micro"  # Free Tier eligible instance type
  db_name                 = "mydb"         # Corrected: Use db_name instead of name
  username                = "dbadmin"
  password                = "Ajith1234"    # Updated password (remove invalid characters)
  db_subnet_group_name    = aws_db_subnet_group.my_db_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]  # Attach the RDS security group
  skip_final_snapshot     = true           # Set to true to avoid snapshot at deletion

  multi_az                = false          # Disable Multi-AZ deployment (not eligible for free tier)
  publicly_accessible     = false          # Ensure it's not publicly accessible

  tags = {
    Name = "my-postgres-db"
  }
}

