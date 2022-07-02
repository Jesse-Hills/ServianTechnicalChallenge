variable "alb_subnets" {
  description = "List of subnets to attach App ALB to."
  type        = list(string)
}

variable "alb_sg" {
  description = "Security group to assign to App ALB."
  type        = string
}

variable "vpc_id" {
  description = "VPC to associate with ALB."
  type        = string
}

variable "app_subnets" {
  description = "List of subnets to use for ECS service."
  type        = list(string)
}

variable "app_sg" {
  description = "Security group to assign to ECS service."
  type        = string
}
