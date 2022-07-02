variable "db_subnets" {
  description = "List of subnets to attach database to."
  type        = list(string)
}

variable "db_sg" {
  description = "Security group to assign to database."
  type        = string
}

variable "vpc_id" {
  description = "VPC to associate with database."
  type        = string
}
