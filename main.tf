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

module "nodes_with_pid_pressure_in_kubernetes" {
  source    = "./modules/nodes_with_pid_pressure_in_kubernetes"

  providers = {
    shoreline = shoreline
  }
}