# Usage

```bash
export SSL_CERT_FILE="$PWD/../../tmp/keycloak-ca/keycloak-ca-crt.pem"
dotnet run
```

# References

* [Client credential flows](https://learn.microsoft.com/en-us/entra/msal/dotnet/acquiring-tokens/web-apps-apis/client-credential-flows).
* [Microsoft.Identity.Client source-code](https://github.com/AzureAD/microsoft-authentication-library-for-dotnet/tree/4.64.0/src).
* [Token cache serialization](https://learn.microsoft.com/en-us/entra/msal/dotnet/how-to/token-cache-serialization).
