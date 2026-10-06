/*
    1. Create a RDS resource
    2. Create a security group for the RDS instance
        - 3306
            - security-grp => tf_sg
            - cidr_block => "local ip address"
    3. Create an output for the RDS instance endpoint
*/

#rds resource
resource "aws_db_instance" "tf_rds_instance" {
  allocated_storage    = 10
  identifier           = "tf-rds-instance"
  db_name              = "sanrosedemo"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = "admin123"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  publicly_accessible  = true
  vpc_security_group_ids = [aws_security_group.tf_rds_security_group.id]
}

resource "aws_security_group" "tf_rds_security_group" {
  name        = "rds_security_group"
  description = "allow mysql"
  vpc_id      = "vpc-0f1da3a9297448ad5"

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_vpc_security_group_ingress_rule" "mysql_from_ec2" {
  security_group_id            = aws_security_group.tf_rds_security_group.id
  referenced_security_group_id = aws_security_group.tf_ec2_security_group.id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
}

# From your laptop (optional)
resource "aws_vpc_security_group_ingress_rule" "mysql_from_my_ip" {
  security_group_id = aws_security_group.tf_rds_security_group.id
  cidr_ipv4         = "157.119.70.204/32"
  from_port         = 3306
  to_port           = 3306
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_rds_ipv4" {
  security_group_id = aws_security_group.tf_rds_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_rds_ipv6" {
  security_group_id = aws_security_group.tf_rds_security_group.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
