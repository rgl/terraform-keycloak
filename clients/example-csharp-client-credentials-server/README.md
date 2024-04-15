# Usage

```bash
docker compose rm --stop --force  example-csharp-client-credentials-server
install -d tmp
sudo install -o "$USER" -m 400 "$PWD/../../tmp/keycloak-ca/example-csharp-client-credentials-server.test-key.p12" tmp
export EXAMPLE_TLS_KEY_PATH="$PWD/tmp/example-csharp-client-credentials-server.test-key.p12"
export EXAMPLE_URL='https://example-csharp-client-credentials-server.test:8027'
export EXAMPLE_OIDC_ISSUER_URL='https://keycloak.test:8443/realms/example'
export SSL_CERT_FILE="$PWD/../../tmp/keycloak-ca/keycloak-ca-crt.pem"
dotnet run
```

# References

* https://github.com/dotnet/aspnetcore/tree/v8.0.4/src/Security/Authentication/JwtBearer
