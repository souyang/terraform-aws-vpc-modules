module "vpc_simple" {
  source      = "../"
  project     = "testing"
  environment = "dev"
  application = "microservices"
}

output "vpc_name" {
  value = module.vpc_simple.vpc_name
}