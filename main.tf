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
