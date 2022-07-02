resource "aws_vpc" "vpc" {
  cidr_block           = "192.168.0.0/20"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.natgw.id
  subnet_id     = aws_subnet.alb["A"].id

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_eip" "natgw" {}

resource "aws_subnet" "alb" {
  for_each = local.availability_zones

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "192.168.${0 + each.value}.0/24"
  availability_zone = "ap-southeast-2${lower(each.key)}"
}

resource "aws_subnet" "app" {
  for_each = local.availability_zones

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "192.168.${3 + each.value}.0/24"
  availability_zone = "ap-southeast-2${lower(each.key)}"
}

resource "aws_subnet" "db" {
  for_each = local.availability_zones

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "192.168.${6 + each.value}.0/24"
  availability_zone = "ap-southeast-2${lower(each.key)}"
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw.id
  }
}

resource "aws_route_table_association" "alb" {
  for_each = aws_subnet.alb

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "app" {
  for_each = aws_subnet.app

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "db" {
  for_each = aws_subnet.db

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "alb" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_security_group" "app" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_security_group" "db" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_security_group_rule" "world_to_alb_ingress" {
  type              = "ingress"
  from_port         = "80"
  to_port           = "80"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_to_app_egress" {
  type                     = "egress"
  from_port                = "80"
  to_port                  = "80"
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_to_app_ingress" {
  type                     = "ingress"
  from_port                = "80"
  to_port                  = "80"
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.app.id
}

resource "aws_security_group_rule" "app_to_world_egress" {
  type              = "egress"
  from_port         = "443"
  to_port           = "443"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app.id
}

resource "aws_security_group_rule" "app_to_db_egress" {
  type                     = "egress"
  from_port                = "5432"
  to_port                  = "5432"
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.db.id
  security_group_id        = aws_security_group.app.id
}

resource "aws_security_group_rule" "app_to_db_ingress" {
  type                     = "ingress"
  from_port                = "5432"
  to_port                  = "5432"
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = aws_security_group.db.id
}

output "vpc" {
  value = aws_vpc.vpc
}

output "alb_subnets" {
  value = [for subnet in aws_subnet.alb : subnet.id]
}

output "alb_sg" {
  value = aws_security_group.alb.id
}

output "app_subnets" {
  value = [for subnet in aws_subnet.app : subnet.id]
}

output "app_sg" {
  value = aws_security_group.app.id
}

output "db_subnets" {
  value = [for subnet in aws_subnet.db : subnet.id]
}

output "db_sg" {
  value = aws_security_group.db.id
}
