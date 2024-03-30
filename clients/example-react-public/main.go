package main

import (
	"bytes"
	"embed"
	"encoding/json"
	"flag"
	"fmt"
	"io/fs"
	"log"
	"net/http"
	"net/url"
	"os"
	"time"
)

//go:embed build/*
var content embed.FS

func main() {
	log.SetFlags(0)

	var listenAddress = flag.String("listen", ":8083", "Listen address.")

	flag.Parse()

	if flag.NArg() != 0 {
		flag.Usage()
		log.Fatalf("\nERROR You MUST NOT pass any positional arguments")
	}

	oidcRedirectURI := os.Getenv("EXAMPLE_OIDC_REDIRECT_URI")
	if oidcRedirectURI == "" {
		log.Fatalf("ERROR You MUST set the EXAMPLE_OIDC_REDIRECT_URI environment variable")
	}

	oidcAuthority := os.Getenv("EXAMPLE_OIDC_AUTHORITY")
	if oidcAuthority == "" {
		log.Fatalf("ERROR You MUST set the EXAMPLE_OIDC_AUTHORITY environment variable")
	}

	oidcClientID := os.Getenv("EXAMPLE_OIDC_CLIENT_ID")
	if oidcClientID == "" {
		log.Fatalf("ERROR You MUST set the EXAMPLE_OIDC_CLIENT_ID environment variable")
	}

	listenURL, err := url.Parse(oidcRedirectURI)
	if err != nil {
		log.Panicf("Failed to parse the listen URL: %v", err)
	}
	listenScheme := listenURL.Scheme
	if listenScheme != "http" && listenScheme != "https" {
		log.Fatalf("ERROR Invalid listen URL scheme")
	}
	listenDomain := listenURL.Hostname()

	config := struct {
		Authority   string `json:"authority"`
		ClientID    string `json:"clientId"`
		RedirectURI string `json:"redirectUri"`
	}{
		oidcAuthority,
		oidcClientID,
		oidcRedirectURI,
	}

	configJson, err := json.Marshal(config)
	if err != nil {
		log.Fatalf("failed to marshal config: %v", err)
	}

	content, err := fs.Sub(content, "build")
	if err != nil {
		log.Fatalf("failed to create the content subtree %v", err)
	}

	t := time.Now()

	http.HandleFunc("/config.json", func(w http.ResponseWriter, r *http.Request) {
		http.ServeContent(w, r, "config.json", t, bytes.NewReader(configJson))
	})

	http.Handle("/", http.FileServer(http.FS(content)))

	log.Printf("Listening at %s://%s", listenScheme, *listenAddress)

	switch listenScheme {
	case "http":
		err = http.ListenAndServe(*listenAddress, nil)
	case "https":
		err = http.ListenAndServeTLS(
			*listenAddress,
			fmt.Sprintf("/etc/ssl/private/%s-crt.pem", listenDomain),
			fmt.Sprintf("/etc/ssl/private/%s-key.pem", listenDomain),
			nil)
	default:
		log.Fatal("Invalid protocol scheme")
	}
	if err != nil {
		log.Fatalf("Failed to listen: %v", err)
	}
}
