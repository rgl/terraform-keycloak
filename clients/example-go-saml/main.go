package main

import (
	"context"
	"crypto/rsa"
	"crypto/tls"
	"crypto/x509"
	"encoding/xml"
	"flag"
	"html/template"
	"log"
	"net/http"
	"net/url"
	"os"
	"sort"
	"strings"
	"time"

	"github.com/crewjam/saml"
	"github.com/crewjam/saml/samlsp"
)

var indexTextTemplate = template.Must(template.New("Index").Parse(`# Session Claims
{{- range $kv := .SessionClaims }}
{{- range .Values }}
{{$kv.Name}}: {{.}}
{{- end}}
{{- end}}

# SAML Attributes
{{- range $kv := .SAMLClaims }}
{{- range .Values }}
{{$kv.Name}}: {{.}}
{{- end}}
{{- end}}
`))

var indexTemplate = template.Must(template.New("Index").Parse(`<!DOCTYPE html>
<html>
<head>
<title>example-go-saml</title>
<link rel="shortcut icon" href="#"/>
<style>
body {
	font-family: monospace;
	color: #555;
	background: #e6edf4;
	padding: 1.25rem;
	margin: 0;
}
table {
	background: #fff;
	border: .0625rem solid #c4cdda;
	border-radius: 0 0 .25rem .25rem;
	border-spacing: 0;
	margin-bottom: 1.25rem;
	padding: .75rem 1.25rem;
	text-align: left;
	white-space: pre;
}
table > caption {
	background: #f1f6fb;
	text-align: left;
	font-weight: bold;
	padding: .75rem 1.25rem;
	border: .0625rem solid #c4cdda;
	border-radius: .25rem .25rem 0 0;
	border-bottom: 0;
}
table td, table th {
	padding: .25rem;
}
table > tbody > tr:hover {
	background: #f1f6fb;
}
</style>
</head>
<body>
	<table>
		<caption>Actions</caption>
		<tbody>
			<tr><td><a href="/">home</a></td></tr>
			<tr><td><a href="/login">login</a></td></tr>
			<tr><td><a href="/logout">logout</a> (not yet working)</td></tr>
			<tr><td><a href="/saml/metadata">metadata</a></td></tr>
		</tbody>
	</table>
	{{- if .SessionClaims }}
	<table>
		<caption>Session Claims</caption>
		<tbody>
			{{- range $kv := .SessionClaims }}
			{{- range .Values }}
			<tr>
				<th>{{$kv.Name}}</th>
				<td data-session-claim="{{$kv.Name}}">{{.}}</td>
			</tr>
			{{- end}}
			{{- end}}
		</tbody>
	</table>
	{{- end}}
	{{- if .SAMLClaims }}
	<table>
		<caption>SAML Claims</caption>
		<tbody>
			{{- range $kv := .SAMLClaims }}
			{{- range .Values }}
			<tr>
				<th>{{$kv.Name}}</th>
				<td data-saml-claim="{{$kv.Name}}">{{.}}</td>
			</tr>
			{{- end}}
			{{- end}}
		</tbody>
	</table>
	{{- end}}
</body>
</html>
`))

type keyValue struct {
	Name   string
	Values []string
}

type keyValues []keyValue

func (a keyValues) Len() int      { return len(a) }
func (a keyValues) Swap(i, j int) { a[i], a[j] = a[j], a[i] }
func (a keyValues) Less(i, j int) bool {
	return strings.ToLower(a[i].Name) < strings.ToLower(a[j].Name)
}

type indexData struct {
	SessionClaims keyValues
	SAMLClaims    keyValues
}

func OptionalAccount(m *samlsp.Middleware, handler http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		session, _ := m.Session.GetSession(r)
		if session != nil {
			r = r.WithContext(samlsp.ContextWithSession(r.Context(), session))
		}
		handler.ServeHTTP(w, r)
	})
}

func getSessionClaims(s samlsp.Session) keyValues {
	if s == nil {
		return keyValues{}
	}
	sc, ok := s.(samlsp.JWTSessionClaims)
	if !ok {
		return keyValues{}
	}
	result := keyValues{
		{
			// see https://github.com/crewjam/saml/blob/v0.4.12/samlsp/session_jwt.go#L46
			Name:   "Subject (SAML Subject NameID)",
			Values: []string{sc.Subject},
		},
	}
	sort.Sort(result)
	return result
}

func getSAMLClaims(s samlsp.Session) keyValues {
	if s == nil {
		return keyValues{}
	}
	sa, ok := s.(samlsp.SessionWithAttributes)
	if !ok {
		return keyValues{}
	}
	attributes := sa.GetAttributes()
	result := make(keyValues, 0, len(attributes))
	for k := range attributes {
		result = append(result, keyValue{
			Name:   k,
			Values: attributes[k],
		})
	}
	sort.Sort(result)
	return result
}

func index(w http.ResponseWriter, r *http.Request) {
	s := samlsp.SessionFromContext(r.Context())
	sessionClaims := getSessionClaims(s)
	samlClaims := getSAMLClaims(s)

	var t *template.Template
	var contentType string

	switch r.URL.Query().Get("format") {
	case "text":
		t = indexTextTemplate
		contentType = "text/plain"
	default:
		t = indexTemplate
		contentType = "text/html"
	}

	w.Header().Set("Content-Type", contentType)

	err := t.ExecuteTemplate(w, "Index", indexData{
		SessionClaims: sessionClaims,
		SAMLClaims:    samlClaims,
	})
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}

// TODO understand why this is not working with keycloak.
// TODO why samltest.id ends up in a redirect to http://localhost:8082/saml/slo?
// see https://github.com/crewjam/saml/issues/489
func logout(samlMiddleware *samlsp.Middleware, w http.ResponseWriter, r *http.Request) {
	var u *url.URL
	var err error

	session, _ := samlMiddleware.Session.GetSession(r)
	if session != nil {
		sa, ok := session.(samlsp.SessionWithAttributes)
		if !ok {
			http.Error(w, "unable to cast session", http.StatusInternalServerError)
			return
		}

		samlAttributes := sa.GetAttributes()

		// handle samltest.id.
		samlSubjectNameID := samlAttributes.Get("urn:oasis:names:tc:SAML:attribute:subject-id")

		// handle azure ad.
		if samlSubjectNameID == "" {
			samlSubjectNameID = samlAttributes.Get("http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name")
		}

		// handle everything else (hopefully).
		if samlSubjectNameID == "" {
			if sc, ok := session.(samlsp.JWTSessionClaims); ok {
				samlSubjectNameID = sc.Subject
			}
		}

		if samlSubjectNameID == "" {
			http.Error(w, "unable to infer the SAML Subject NameID", http.StatusBadRequest)
			return
		}

		// TODO why does azure ad still prompts us to choose the account to logout from?

		u, err = samlMiddleware.ServiceProvider.MakeRedirectLogoutRequest(samlSubjectNameID, "")
		if err != nil {
			http.Error(w, "unable to create redirect url", http.StatusInternalServerError)
			log.Panicf("Failed to MakeRedirectLogoutRequest: %s", err)
			return
		}
	} else {
		u = &url.URL{
			Path: "/",
		}
	}

	err = samlMiddleware.Session.DeleteSession(w, r)
	if err != nil {
		log.Panicf("Failed to delete session: %s", err)
	}

	w.Header().Add("Location", u.String())
	w.WriteHeader(http.StatusFound)
}

func main() {
	log.SetFlags(0)

	var listenFlag = flag.String("listen", "http://example-go-saml.test:8082", "Listen URL")
	var entityIDFlag = flag.String("entity-id", "urn:example:example-go-saml", "Service provider Entity ID")
	var idpMetadataFlag = flag.String("idp-metadata", "https://samltest.id/saml/idp", "IDP Metadata URL")

	flag.Parse()

	if flag.NArg() != 0 {
		flag.Usage()
		log.Fatalf("\nERROR You MUST NOT pass any positional arguments")
	}

	log.Printf("Loading the service provider key pair...")
	keyPair, err := tls.LoadX509KeyPair(
		"example-go-saml-crt.pem",
		"example-go-saml-key.pem")
	if err != nil {
		log.Panicf("Failed to load the service provider key pair: %v", err)
	}
	keyPair.Leaf, err = x509.ParseCertificate(keyPair.Certificate[0])
	if err != nil {
		log.Panicf("Failed to parse the service provider certificate: %v", err)
	}

	log.Printf("Fetching the IDP metadata...")
	idpMetadataURL, err := url.Parse(*idpMetadataFlag)
	if err != nil {
		log.Panicf("Failed to parse the IDP metadata url: %v", err)
	}
	var idpMetadata *saml.EntityDescriptor
	for {
		idpMetadata, err = samlsp.FetchMetadata(
			context.Background(),
			http.DefaultClient,
			*idpMetadataURL)
		if err != nil {
			log.Printf("WARNING Failed to fetch the IDP metadata: %v. Retrying in a bit.", err)
			time.Sleep(3 * time.Second)
		} else {
			break
		}
	}

	rootURL, err := url.Parse(*listenFlag)
	if err != nil {
		log.Panicf("Failed to parse the service provider url: %v", err)
	}

	samlMiddleware, _ := samlsp.New(samlsp.Options{
		EntityID:          *entityIDFlag,
		URL:               *rootURL,
		Key:               keyPair.PrivateKey.(*rsa.PrivateKey),
		Certificate:       keyPair.Leaf,
		IDPMetadata:       idpMetadata,
		AllowIDPInitiated: true,
		SignRequest:       true,
	})

	buf, err := xml.MarshalIndent(samlMiddleware.ServiceProvider.Metadata(), "", "  ")
	if err != nil {
		log.Panicf("Failed to marshal the service provider metadata: %v", err)
	}
	err = os.WriteFile("example-go-saml-metadata.xml", buf, 0664)
	if err != nil {
		log.Printf("Warning: failed to save the service provider metadata to local file: %v", err)
	}

	http.Handle("/", OptionalAccount(samlMiddleware, http.HandlerFunc(index)))
	http.Handle("/login", samlMiddleware.RequireAccount(http.HandlerFunc(index)))
	http.HandleFunc("/logout", func(w http.ResponseWriter, r *http.Request) {
		logout(samlMiddleware, w, r)
	})
	http.HandleFunc("/saml/slo", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Add("Location", "/")
		w.WriteHeader(http.StatusFound)
	})
	http.Handle("/saml/", samlMiddleware)
	log.Printf("Starting the service provider at %s", rootURL)
	http.ListenAndServe(":"+rootURL.Port(), nil)
}
