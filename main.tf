# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/realm
resource "keycloak_realm" "example" {
  realm                    = "example"
  verify_email             = true
  login_with_email_allowed = true
  reset_password_allowed   = true
  smtp_server {
    host = "mailhog"
    port = 1025
    from = "keycloak@example.com"
  }
}

# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/user
resource "keycloak_user" "alice" {
  realm_id       = keycloak_realm.example.id
  username       = "alice"
  email          = "alice@example.com"
  email_verified = true
  first_name     = "Alice"
  last_name      = "Doe"
  // NB in a real program, omit this initial_password section and force a
  //    password reset.
  initial_password {
    value     = "alice"
    temporary = false
  }
}

# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/openid_client
resource "keycloak_openid_client" "example_go_confidential" {
  realm_id              = keycloak_realm.example.id
  description           = "Example Go Confidential Client"
  client_id             = "example-go-confidential"
  client_secret         = "example" # NB in a real program, this should be randomly generated.
  access_type           = "CONFIDENTIAL"
  standard_flow_enabled = true
  root_url              = "http://localhost:8081"
  base_url              = "/"
  valid_redirect_uris   = ["/auth/keycloak/callback"]
}
