# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/realm
resource "keycloak_realm" "example" {
  realm                    = "example"
  verify_email             = true
  login_with_email_allowed = true
  reset_password_allowed   = true
  smtp_server {
    host = "mail.test"
    port = 1025
    from = "keycloak@example.com"
  }
}

# NB this has to define all the user profile attributes, even the default
#    attributes. these were originally obtained at the Realm settings,
#    User profile, JSON editor tab.
# see https://keycloak.test:8443/admin/master/console/#/example/realm-settings/user-profile/json-editor
# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/realm_user_profile
resource "keycloak_realm_user_profile" "example" {
  realm_id = keycloak_realm.example.id
  attribute {
    name         = "username"
    display_name = "$${username}"
    validator {
      name = "length"
      config = {
        min = 3
        max = 255
      }
    }
    validator {
      name = "username-prohibited-characters"
    }
    validator {
      name = "up-username-not-idn-homograph"
    }
    permissions {
      view = ["admin", "user"]
      edit = ["admin"]
    }
  }
  attribute {
    name         = "email"
    display_name = "$${email}"
    validator {
      name = "email"
    }
    validator {
      name = "length"
      config = {
        max = 255
      }
    }
    required_for_roles = ["user"]
    permissions {
      view = ["admin", "user"]
      edit = ["admin", "user"]
    }
  }
  attribute {
    name         = "firstName"
    display_name = "$${firstName}"
    validator {
      name = "length"
      config = {
        max = 255
      }
    }
    validator {
      name = "person-name-prohibited-characters"
    }
    required_for_roles = ["user"]
    permissions {
      view = ["admin", "user"]
      edit = ["admin", "user"]
    }
  }
  attribute {
    name         = "lastName"
    display_name = "$${lastName}"
    validator {
      name = "length"
      config = {
        max = 255
      }
    }
    validator {
      name = "person-name-prohibited-characters"
    }
    required_for_roles = ["user"]
    permissions {
      view = ["admin", "user"]
      edit = ["admin", "user"]
    }
  }
  attribute {
    name         = "department"
    display_name = "Department"
    validator {
      name = "length"
      config = {
        max = 255
      }
    }
    permissions {
      view = ["admin", "user"]
      edit = ["admin"]
    }
  }
  group {
    name                = "user-metadata"
    display_header      = "User metadata"
    display_description = "Attributes, which refer to user metadata"
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
  attributes = {
    department = "example"
  }
  // NB in a real program, omit this initial_password section and force a
  //    password reset.
  initial_password {
    value     = "alice"
    temporary = false
  }
  depends_on = [
    keycloak_realm_user_profile.example
  ]
}

# NB Although this OAuth 2.0 Grant is supported by Keycloak, its not a [OAuth 2.0 Security Best Current Practice](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-security-topics#name-resource-owner-password-cre).
# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/openid_client
resource "keycloak_openid_client" "example_bash_password_client" {
  realm_id                     = keycloak_realm.example.id
  description                  = "Example Bash Password Client (OAuth 2.0 Resource Owner Password Credentials Grant aka Password Grant)"
  client_id                    = "example-bash-password-client"
  client_secret                = "example" # NB in a real program, this should be randomly generated.
  access_type                  = "CONFIDENTIAL"
  direct_access_grants_enabled = true
}

# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/openid_user_attribute_protocol_mapper
resource "keycloak_openid_user_attribute_protocol_mapper" "example_bash_password_client_department" {
  realm_id       = keycloak_realm.example.id
  client_id      = keycloak_openid_client.example_bash_password_client.id
  name           = "Department"
  user_attribute = "department"
  claim_name     = "department"
}

# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/openid_client
resource "keycloak_openid_client" "example_csharp_client_credentials_server" {
  realm_id                 = keycloak_realm.example.id
  description              = "Example C# Client Credentials Server (OAuth 2.0 Client Credentials Grant)"
  client_id                = "example-csharp-client-credentials-server"
  client_secret            = "example" # NB in a real program, this should be randomly generated.
  access_type              = "CONFIDENTIAL"
  service_accounts_enabled = true
}

# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/openid_client
resource "keycloak_openid_client" "example_csharp_client_credentials_server_test" {
  realm_id                 = keycloak_realm.example.id
  description              = "Example C# Client Credentials Server Test (OAuth 2.0 Client Credentials Grant)"
  client_id                = "example-csharp-client-credentials-server-test"
  client_secret            = "example" # NB in a real program, this should be randomly generated.
  access_type              = "CONFIDENTIAL"
  service_accounts_enabled = true
}

# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/openid_hardcoded_claim_protocol_mapper
resource "keycloak_openid_hardcoded_claim_protocol_mapper" "example_csharp_client_credentials_server_test_project" {
  realm_id    = keycloak_realm.example.id
  client_id   = keycloak_openid_client.example_csharp_client_credentials_server_test.id
  name        = "Project"
  claim_name  = "project"
  claim_value = "example"
}

# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/openid_client
resource "keycloak_openid_client" "example_go_client_credentials_server" {
  realm_id                 = keycloak_realm.example.id
  description              = "Example Go Client Credentials Server (OAuth 2.0 Client Credentials Grant)"
  client_id                = "example-go-client-credentials-server"
  client_secret            = "example" # NB in a real program, this should be randomly generated.
  access_type              = "CONFIDENTIAL"
  service_accounts_enabled = true
}

# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/openid_client
resource "keycloak_openid_client" "example_go_client_credentials_server_test" {
  realm_id                 = keycloak_realm.example.id
  description              = "Example Go Client Credentials Server Test (OAuth 2.0 Client Credentials Grant)"
  client_id                = "example-go-client-credentials-server-test"
  client_secret            = "example" # NB in a real program, this should be randomly generated.
  access_type              = "CONFIDENTIAL"
  service_accounts_enabled = true
}

# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/openid_hardcoded_claim_protocol_mapper
resource "keycloak_openid_hardcoded_claim_protocol_mapper" "example_go_client_credentials_server_test_project" {
  realm_id    = keycloak_realm.example.id
  client_id   = keycloak_openid_client.example_go_client_credentials_server_test.id
  name        = "Project"
  claim_name  = "project"
  claim_value = "example"
}

# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/openid_client
resource "keycloak_openid_client" "example_go_confidential" {
  realm_id              = keycloak_realm.example.id
  description           = "Example Go Confidential Client (OAuth 2.0 Authorization Code Grant)"
  client_id             = "example-go-confidential"
  client_secret         = "example" # NB in a real program, this should be randomly generated.
  access_type           = "CONFIDENTIAL"
  standard_flow_enabled = true
  root_url              = "https://example-go-confidential.test:8081"
  base_url              = "/"
  valid_redirect_uris   = ["/auth/keycloak/callback"]
}

# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/saml_client
resource "keycloak_saml_client" "example_go_saml" {
  realm_id            = keycloak_realm.example.id
  description         = "Example Go SAML"
  client_id           = "example-go-saml"
  root_url            = "https://example-go-saml.test:8082"
  valid_redirect_uris = ["/saml/acs"]
  signing_certificate = file("/host/clients/example-go-saml/example-go-saml-crt.pem")
}

# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/saml_user_property_protocol_mapper
# see https://www.keycloak.org/docs-api/24.0.3/javadocs/org/keycloak/models/UserModel.html
resource "keycloak_saml_user_property_protocol_mapper" "example_go_saml_username" {
  realm_id                   = keycloak_saml_client.example_go_saml.realm_id
  client_id                  = keycloak_saml_client.example_go_saml.id
  name                       = "username"
  user_property              = "username"
  saml_attribute_name        = "username"
  saml_attribute_name_format = "Basic"
}

# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/saml_user_property_protocol_mapper
# see https://www.keycloak.org/docs-api/24.0.3/javadocs/org/keycloak/models/UserModel.html
resource "keycloak_saml_user_property_protocol_mapper" "example_go_saml_email" {
  realm_id                   = keycloak_saml_client.example_go_saml.realm_id
  client_id                  = keycloak_saml_client.example_go_saml.id
  name                       = "email"
  user_property              = "email"
  saml_attribute_name        = "email"
  saml_attribute_name_format = "Basic"
}

# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/saml_user_property_protocol_mapper
# see https://www.keycloak.org/docs-api/24.0.3/javadocs/org/keycloak/models/UserModel.html
resource "keycloak_saml_user_property_protocol_mapper" "example_go_saml_emailverified" {
  realm_id                   = keycloak_saml_client.example_go_saml.realm_id
  client_id                  = keycloak_saml_client.example_go_saml.id
  name                       = "emailverified"
  user_property              = "emailVerified"
  saml_attribute_name        = "emailverified"
  saml_attribute_name_format = "Basic"
}

# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/saml_user_property_protocol_mapper
# see https://www.keycloak.org/docs-api/24.0.3/javadocs/org/keycloak/models/UserModel.html
resource "keycloak_saml_user_property_protocol_mapper" "example_go_saml_firstname" {
  realm_id                   = keycloak_saml_client.example_go_saml.realm_id
  client_id                  = keycloak_saml_client.example_go_saml.id
  name                       = "firstname"
  user_property              = "firstName"
  saml_attribute_name        = "firstname"
  saml_attribute_name_format = "Basic"
}

# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/saml_user_property_protocol_mapper
# see https://www.keycloak.org/docs-api/24.0.3/javadocs/org/keycloak/models/UserModel.html
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
  description           = "Example React Public Client (OAuth 2.0 Authorization Code Grant)"
  client_id             = "example-react-public"
  access_type           = "PUBLIC"
  standard_flow_enabled = true
  root_url              = "https://example-react-public.test:8083"
  base_url              = "/"
  valid_redirect_uris   = ["/"]
  web_origins           = ["+"]
}

# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/openid_client
resource "keycloak_openid_client" "example_csharp_public_device" {
  realm_id                                  = keycloak_realm.example.id
  description                               = "Example Csharp Public Device Client (OAuth 2.0 Device Authorization Grant)"
  client_id                                 = "example-csharp-public-device"
  access_type                               = "PUBLIC"
  oauth2_device_authorization_grant_enabled = true
}
