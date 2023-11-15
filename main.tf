terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "eu-west-2"
}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_default_subnet" "default_az1" {
  availability_zone = "eu-west-2b"

  tags = {
    Name = "Default subnet for eu-west-2b"
  }
}

resource "aws_security_group" "local_only" {
  name   = "local_only"
  vpc_id = aws_default_vpc.default.id
}

resource "aws_security_group_rule" "ingress_local" {
  type              = "ingress"
  security_group_id = aws_security_group.local_only.id

  from_port   = 0
  to_port     = 65535
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egress_all_ports" {
  type              = "egress"
  security_group_id = aws_security_group.local_only.id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_db_instance" "auth_db" {
  allocated_storage      = 10
  db_name                = "auth"
  engine                 = "mysql"
  engine_version         = "8.0.33"
  instance_class         = "db.t3.micro"
  username               = "admin"
  password               = var.admin_pass
  skip_final_snapshot    = true
  port                   = 3306
  vpc_security_group_ids = [aws_security_group.local_only.id]
  apply_immediately      = true

  network_type        = "IPV4"
  publicly_accessible = true
}

resource "template_dir" "config" {
  source_dir      = "sql_templates"
  destination_dir = "sql_scripts"

  vars = {
    USER_PASS = "${var.user_pass}"
    SERVER_IP = "${var.server_ip}"
  }
}

resource "terraform_data" "init_user_db" {
  provisioner "local-exec" {
    command = "mysql -uadmin -p${var.admin_pass} -h ${aws_db_instance.auth_db.address} < ${template_dir.config.destination_dir}/init_db.sql"
  }
}
