terraform {
  required_version = ">= 0.13.1"

  required_providers {
    shoreline = {
      source  = "shorelinesoftware/shoreline"
      version = ">= 1.11.0"
    }
  }
}

provider "shoreline" {
  retries = 2
  debug = true
}

module "ingress_controller_route_distribution_issues" {
  source    = "./modules/ingress_controller_route_distribution_issues"

  providers = {
    shoreline = shoreline
  }
}