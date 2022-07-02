module "networking" {
  source = "./networking"
}

module "app" {
  source = "./app"

  alb_subnets = module.networking.alb_subnets
  alb_sg      = module.networking.alb_sg
  vpc_id      = module.networking.vpc.id
  app_subnets = module.networking.app_subnets
  app_sg      = module.networking.app_sg

  depends_on = [module.networking]
}
