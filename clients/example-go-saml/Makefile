run: build
	./example-go-saml

build: example-go-saml

example-go-saml: main.go example-go-saml-key.pem
	go build -o $@

# NB this key related certificate is shared with keycloak.
example-go-saml-key.pem:
	openssl req \
		-x509 \
		-newkey rsa:2048 \
		-sha256 \
		-keyout $@ \
		-out $(@:-key.pem=-crt.pem) \
		-days 365 \
		-nodes \
		-subj /CN=example-go-saml
	openssl x509 \
		-in $(@:-key.pem=-crt.pem) \
		-noout \
		-text

clean:
	rm -f example-go-saml example-go-saml-metadata.xml *.pem

.PHONY: build run clean
