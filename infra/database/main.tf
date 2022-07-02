resource "random_password" "db_pass" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_subnet_group" "db" {
  subnet_ids = var.db_subnets
}

resource "aws_db_instance" "db" {
  allocated_storage      = 10
  multi_az               = true
  engine                 = "postgres"
  engine_version         = "14.2"
  instance_class         = "db.t3.micro"
  username               = "servian"
  password               = random_password.db_pass.result
  skip_final_snapshot    = true
  vpc_security_group_ids = ["${var.db_sg}"]
  db_subnet_group_name   = aws_db_subnet_group.db.name
}

output "config" {
  value = {
    db_host = split(":", aws_db_instance.db.endpoint)[0]
    db_name = aws_db_instance.db.name
    db_pass = aws_db_instance.db.password
    db_user = aws_db_instance.db.username
  }
  sensitive = true
}
