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
