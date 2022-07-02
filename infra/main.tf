module "networking" {
  source = "./networking"
}

module "app" {
  source     = "./app"
  depends_on = [module.networking]
}
