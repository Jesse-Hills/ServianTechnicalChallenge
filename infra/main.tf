module "networking" {
  source = "./networking"
}

module "ecr" {
  source = "./ecr"
}

module "database" {
  source = "./database"

  db_subnets = module.networking.db_subnets
  db_sg      = module.networking.db_sg
  vpc_id     = module.networking.vpc.id

  depends_on = [module.networking, module.ecr]
}

module "app" {
  source = "./app"

  alb_subnets = module.networking.alb_subnets
  alb_sg      = module.networking.alb_sg
  vpc_id      = module.networking.vpc.id
  app_subnets = module.networking.app_subnets
  app_sg      = module.networking.app_sg
  db_config   = module.database.config
  image_url   = module.ecr.image_url

  depends_on = [module.networking, module.database, module.ecr]
}
