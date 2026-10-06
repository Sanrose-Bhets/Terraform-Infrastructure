/*
1. create a ec2 instance resource
2, new security group resource
    - 22 (ssh)
    - 443 (https)
    - 3000 (nodejs) // ip:3000
*/

resource "aws_key_pair" "tf_key_pair" {
  key_name   = "deployer"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC9dVU6w8TsY6NjaJw9Km2BQgesNrBhWX0a3mg3JlokQST+Poh59xdFmiLcfy5V0+m0RV0t5l9geewuSRHQ9HGkttqTE1Fjlj+rAErdlkm2sEmG7AB6LDmmbdXWAcvCEVmqWzGx6L2lMuvVvuvHSR6U/8qoB0v+PMpbMMsK5MpVpXif0GdjVlHCExgrkL9tjPrvXvIGfBZ2Ce2kyyqRaJUTEFiTLj80VQGz+mraQQr8H7h/0RI10Fmo+be2Ih00nnCWUcOFnZwqhvJVt6438n1iShy+46Sms9jXOPRIisd/7/T0+sKRkB6hR1PO6kxaCfTA/8a7bnZ+NvbL6tGZNiCBk5tLjYa6WWaZuMHWr5OTwFWVxGw3cecIXhfa2tpStdcnn7D4jGt89g2fCijDR0MYwcDqJGveT8CNL1qKz8smh61LH7HBV4BHfQHTYQQucFp+DT/QEBU6GY6Rr/Gs1ykfOdHab08sigdb+9HFLoRWeKcTzUdPZ3TD4LK40EcCdvPyilYk8Dm13bsIYQ8exP2WIujbQeAJOM2RSSID3OPuoYrgOpWhfTVC4MhVHth0mxg5F3ScYFbSA1R56hpFRohphkvjFDtbBNNZL+Z8RfGkNX2L73+mOmLoHgq+n8LWSmB1hiAY4d8DvCdid+PRtwT5woYRIMy1wWvZvGvod2rYFQ== deployer"
}


resource "aws_instance" "tf_ec2_instance" {
  ami           = "ami-0b6d9d3d33ba97d99" # ubuntu img
  instance_type = "t3.micro"
  associate_public_ip_address = true
  key_name = aws_key_pair.tf_key_pair.key_name //base configuration
  vpc_security_group_ids = [aws_security_group.tf_ec2_security_group.id] // could have multiple security groups 
  depends_on = [ aws_s3_bucket.tf_s3_bucket ]
  user_data = <<-EOF
              #!/bin/bash
              git clone https://github.com/Sanrose-Bhets/Terraform-Infrastructure.git /home/ubuntu/Terraform-Infrastructure
              cd /home/ubuntu/Terraform-Infrastructure/nodejs-mysql
              

              #install node
              sudo apt update -y 
              sudo apt install -y nodejs npm

              #edit env vars
              echo "DB_HOST=" | sudo tee .env
              echo "DB_USER=" | sudo tee -a .env
              sudo echo "DB_PASS=" | sudo tee -a .env
              echo "DB_NAME=" | sudo tee -a .env
              echo "TABLE_NAME=" | sudo tee -a .env
              echo "PORT=" | sudo tee -a .env

              #start server
              npm install
            EOF
  user_data_replace_on_change = true
  tags = {
    Name = "NodeJS server"
  }
}

#Security group for the ec2 instance
resource "aws_security_group" "tf_ec2_security_group" {
  name        = "ec2_security_group"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = "vpc-0f1da3a9297448ad5"

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.tf_ec2_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv6" {
  security_group_id = aws_security_group.tf_ec2_security_group.id
  cidr_ipv6         = "::/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.tf_ec2_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}
resource "aws_vpc_security_group_ingress_rule" "allow_app_ipv4" {
  security_group_id = aws_security_group.tf_ec2_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 3000
  ip_protocol       = "tcp"
  to_port           = 3000
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.tf_ec2_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
  security_group_id = aws_security_group.tf_ec2_security_group.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


#OUTPUT
output "ec2_public_ip" {
  value = "ssh -i ~/.ssh/deployer-key ubuntu@${aws_instance.tf_ec2_instance.public_ip}"
}