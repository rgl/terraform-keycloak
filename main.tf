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

# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/group
resource "keycloak_group" "administrators" {
  realm_id = keycloak_realm.example.id
  name     = "administrators"
}

# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/group_roles
resource "keycloak_group_roles" "administrators" {
  realm_id = keycloak_group.administrators.realm_id
  group_id = keycloak_group.administrators.id
  role_ids = [
    keycloak_role.example_go_saml_administrator.id,
  ]
}

# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/group_memberships
resource "keycloak_group_memberships" "administrators" {
  realm_id = keycloak_realm.example.id
  group_id = keycloak_group.administrators.id
  members = [
    keycloak_user.alice.username,
  ]
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
  root_url              = "http://example-go-confidential.test:8081"
  base_url              = "/"
  valid_redirect_uris   = ["/auth/keycloak/callback"]
}

# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/saml_client
resource "keycloak_saml_client" "example_go_saml" {
  realm_id            = keycloak_realm.example.id
  description         = "Example Go SAML"
  client_id           = "example-go-saml"
  root_url            = "http://example-go-saml.test:8082"
  valid_redirect_uris = ["/saml/acs"]
  signing_certificate = file("/host/clients/example-go-saml/example-go-saml-crt.pem")
}

# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/saml_user_property_protocol_mapper
# see https://www.keycloak.org/docs-api/23.0.7/javadocs/org/keycloak/models/UserModel.html
resource "keycloak_saml_user_property_protocol_mapper" "example_go_saml_username" {
  realm_id                   = keycloak_saml_client.example_go_saml.realm_id
  client_id                  = keycloak_saml_client.example_go_saml.id
  name                       = "username"
  user_property              = "username"
  saml_attribute_name        = "username"
  saml_attribute_name_format = "Basic"
}

# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/saml_user_property_protocol_mapper
# see https://www.keycloak.org/docs-api/23.0.7/javadocs/org/keycloak/models/UserModel.html
resource "keycloak_saml_user_property_protocol_mapper" "example_go_saml_email" {
  realm_id                   = keycloak_saml_client.example_go_saml.realm_id
  client_id                  = keycloak_saml_client.example_go_saml.id
  name                       = "email"
  user_property              = "email"
  saml_attribute_name        = "email"
  saml_attribute_name_format = "Basic"
}

# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/saml_user_property_protocol_mapper
# see https://www.keycloak.org/docs-api/23.0.7/javadocs/org/keycloak/models/UserModel.html
resource "keycloak_saml_user_property_protocol_mapper" "example_go_saml_emailverified" {
  realm_id                   = keycloak_saml_client.example_go_saml.realm_id
  client_id                  = keycloak_saml_client.example_go_saml.id
  name                       = "emailverified"
  user_property              = "emailVerified"
  saml_attribute_name        = "emailverified"
  saml_attribute_name_format = "Basic"
}

# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/saml_user_property_protocol_mapper
# see https://www.keycloak.org/docs-api/23.0.7/javadocs/org/keycloak/models/UserModel.html
resource "keycloak_saml_user_property_protocol_mapper" "example_go_saml_firstname" {
  realm_id                   = keycloak_saml_client.example_go_saml.realm_id
  client_id                  = keycloak_saml_client.example_go_saml.id
  name                       = "firstname"
  user_property              = "firstName"
  saml_attribute_name        = "firstname"
  saml_attribute_name_format = "Basic"
}

# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/saml_user_property_protocol_mapper
# see https://www.keycloak.org/docs-api/23.0.7/javadocs/org/keycloak/models/UserModel.html
resource "keycloak_saml_user_property_protocol_mapper" "example_go_saml_lastname" {
  realm_id                   = keycloak_saml_client.example_go_saml.realm_id
  client_id                  = keycloak_saml_client.example_go_saml.id
  name                       = "lastname"
  user_property              = "lastName"
  saml_attribute_name        = "lastname"
  saml_attribute_name_format = "Basic"
}

# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/role
resource "keycloak_role" "example_go_saml_administrator" {
  realm_id  = keycloak_saml_client.example_go_saml.realm_id
  client_id = keycloak_saml_client.example_go_saml.id
  name      = "administrator"
}

# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/openid_client
resource "keycloak_openid_client" "example_react_public" {
  realm_id              = keycloak_realm.example.id
  description           = "Example React Public Client"
  client_id             = "example-react-public"
  access_type           = "PUBLIC"
  standard_flow_enabled = true
  root_url              = "http://example-react-public.test:8083"
  base_url              = "/"
  valid_redirect_uris   = ["/"]
  web_origins           = ["+"]
}

# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/openid_client
resource "keycloak_openid_client" "example_csharp_public_device" {
  realm_id                                  = keycloak_realm.example.id
  description                               = "Example Csharp Public Device Client"
  client_id                                 = "example-csharp-public-device"
  access_type                               = "PUBLIC"
  oauth2_device_authorization_grant_enabled = true
}
