package main

import (
	"bytes"
	"embed"
	"encoding/json"
	"flag"
	"io/fs"
	"log"
	"net/http"
	"os"
	"time"
)

//go:embed build/*
var content embed.FS

func main() {
	log.SetFlags(0)

	var listenAddress = flag.String("listen", "0.0.0.0:8083", "Listen address.")

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

	log.Printf("Listening at http://%s", *listenAddress)

	err = http.ListenAndServe(*listenAddress, nil)
	if err != nil {
		log.Fatalf("Failed to ListenAndServe: %v", err)
	}
}
