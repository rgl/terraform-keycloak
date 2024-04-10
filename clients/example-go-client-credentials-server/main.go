package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"strings"

	"golang.org/x/oauth2"
)

type tokenContextKey struct{}

func main() {
	log.SetFlags(0)

	var listenAddress = flag.String("listen", ":8026", "Listen address.")

	flag.Parse()

	if flag.NArg() != 0 {
		flag.Usage()
		log.Fatalf("\nERROR You MUST NOT pass any positional arguments")
	}

	listenURL := os.Getenv("EXAMPLE_URL")
	if listenURL == "" {
		log.Fatalf("ERROR You MUST set the EXAMPLE_URL environment variable")
	}
	parsedListenURL, err := url.Parse(listenURL)
	if err != nil {
		log.Fatalf("ERROR Failed to parse EXAMPLE_URL")
	}
	listenScheme := parsedListenURL.Scheme
	if listenScheme != "http" && listenScheme != "https" {
		log.Fatalf("ERROR Invalid EXAMPLE_URL scheme")
	}
	listenDomain := parsedListenURL.Hostname()

	oauthClientID := os.Getenv("EXAMPLE_OAUTH_CLIENT_ID")
	if oauthClientID == "" {
		log.Fatalf("ERROR You MUST set the EXAMPLE_OAUTH_CLIENT_ID environment variable")
	}

	oauthClientSecret := os.Getenv("EXAMPLE_OAUTH_CLIENT_SECRET")
	if oauthClientSecret == "" {
		log.Fatalf("ERROR You MUST set the EXAMPLE_OAUTH_CLIENT_SECRET environment variable")
	}

	oauthTokenIntrospectionURL := os.Getenv("EXAMPLE_OAUTH_TOKEN_INTROSPECTION_URL")
	if oauthTokenIntrospectionURL == "" {
		log.Fatalf("ERROR You MUST set the EXAMPLE_OAUTH_TOKEN_INTROSPECTION_URL environment variable")
	}

	http.HandleFunc("/",
		validate(
			oauthClientID,
			oauthClientSecret,
			oauthTokenIntrospectionURL,
			home))

	fmt.Printf("Listening at %s://%s\n", listenScheme, *listenAddress)

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

func home(w http.ResponseWriter, r *http.Request) {
	token, ok := r.Context().Value(tokenContextKey{}).(*oauth2.Token)
	if !ok {
		http.Error(w, "failed to get token", http.StatusInternalServerError)
		return
	}
	claims := map[string]interface{}{
		"client_id": token.Extra("client_id"),
		"username":  token.Extra("username"),
	}
	payload, err := json.Marshal(claims)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.Write(payload)
}

func validate(oauthClientID, oauthClientSecret, oauthTokenIntrospectionURL string, next http.HandlerFunc) http.HandlerFunc {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			http.Error(w, "Unauthorized", http.StatusUnauthorized)
			return
		}
		bearerToken := strings.TrimPrefix(authHeader, "Bearer ")
		if bearerToken == "" {
			http.Error(w, "Unauthorized", http.StatusUnauthorized)
			return
		}
		token, err := validateToken(oauthClientID, oauthClientSecret, oauthTokenIntrospectionURL, bearerToken)
		if err != nil || !token.Valid() {
			http.Error(w, "Unauthorized", http.StatusUnauthorized)
			return
		}
		ctx := context.WithValue(r.Context(), tokenContextKey{}, token)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func validateToken(oauthClientID, oauthClientSecret, oauthTokenIntrospectionURL, token string) (*oauth2.Token, error) {
	client := &http.Client{}

	request, err := http.NewRequest("POST", oauthTokenIntrospectionURL, strings.NewReader("token="+token))
	if err != nil {
		return nil, err
	}
	request.SetBasicAuth(oauthClientID, oauthClientSecret)
	request.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	response, err := client.Do(request)
	if err != nil {
		return nil, err
	}
	defer response.Body.Close()

	responseBody, err := io.ReadAll(response.Body)
	if err != nil {
		return nil, err
	}

	var introspectionResponse struct {
		Active            bool   `json:"active"`
		TokenType         string `json:"typ"`
		Audience          string `json:"aud"`
		Issuer            string `json:"iss"`
		Subject           string `json:"sub"`
		ClientId          string `json:"client_id"`
		Username          string `json:"username"`
		PreferredUsername string `json:"preferred_username"`
	}
	err = json.Unmarshal(responseBody, &introspectionResponse)
	if err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}

	// TODO ensure the token audience has our service url instead?
	if introspectionResponse.Audience != "account" {
		return nil, fmt.Errorf("invalid token audience")
	}

	if introspectionResponse.Active {
		token := &oauth2.Token{
			TokenType:   introspectionResponse.TokenType,
			AccessToken: token,
		}
		return token.WithExtra(map[string]interface{}{
			"aud":                introspectionResponse.Audience,
			"iss":                introspectionResponse.Issuer,
			"sub":                introspectionResponse.Subject,
			"client_id":          introspectionResponse.ClientId,
			"username":           introspectionResponse.Username,
			"preferred_username": introspectionResponse.PreferredUsername,
		}), nil
	}

	return nil, fmt.Errorf("invalid token")
}
