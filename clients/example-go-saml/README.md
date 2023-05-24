# About

This is an example SAML Service Provider.

This was based on https://github.com/rgl/example-saml-service-provider.

# Usage (SAMLtest IdP)

Build and run in foreground:

```bash
make
```

Open the [testing samltest.id IdP page](https://samltest.id) at:

https://samltest.id/upload.php

And upload the `example-go-saml-metadata.xml` file (you can see
it at http://localhost:8082/saml/metadata too).

Open this example Service Provider page, and click the `login` link to go
tru the authentication flow:

http://localhost:8082

# Usage (Keycloak)

Search for `keycloak_saml_` in [main.tf](../../main.tf).

# Troubleshoot

* To debug a SAML request inside a URL redirect, edit the `url` property inside
  the `decode-saml-request-url.py` file and execute it to see the SAML request
  XML document.
  * The `SAMLRequest` query string value is encoded as
    `zlib.deflate(base64encode(saml_request_xml_document))`.
