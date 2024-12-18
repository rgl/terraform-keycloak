# see https://github.com/hashicorp/terraform
terraform {
  required_version = "1.10.1"
  required_providers {
    # see https://github.com/mrparkers/terraform-provider-keycloak
    # see https://registry.terraform.io/providers/mrparkers/keycloak
    keycloak = {
      source  = "mrparkers/keycloak"
      version = "4.4.0"
    }
  }
  backend "local" {
  }
}

provider "keycloak" {
  client_id = "admin-cli"
  username  = "admin"
  password  = "admin"
  url       = "https://keycloak.test:8443"
}
