package main

import (
	"context"
	"encoding/json"
	"io"
	"log"
	"net/http"
	"os"

	"golang.org/x/oauth2"
	"golang.org/x/oauth2/clientcredentials"
)

func main() {
	log.SetFlags(0)

	oauthClientID := os.Getenv("EXAMPLE_OAUTH_CLIENT_ID")
	if oauthClientID == "" {
		log.Fatalf("ERROR You MUST set the EXAMPLE_OAUTH_CLIENT_ID environment variable")
	}

	oauthClientSecret := os.Getenv("EXAMPLE_OAUTH_CLIENT_SECRET")
	if oauthClientSecret == "" {
		log.Fatalf("ERROR You MUST set the EXAMPLE_OAUTH_CLIENT_SECRET environment variable")
	}

	oauthTokenURL := os.Getenv("EXAMPLE_OAUTH_TOKEN_URL")
	if oauthTokenURL == "" {
		log.Fatalf("ERROR You MUST set the EXAMPLE_OAUTH_TOKEN_URL environment variable")
	}

	serverURL := os.Getenv("EXAMPLE_SERVER_URL")
	if serverURL == "" {
		log.Fatalf("ERROR You MUST set the EXAMPLE_SERVER_URL environment variable")
	}

	ctx := context.Background()

	config := &clientcredentials.Config{
		ClientID:     oauthClientID,
		ClientSecret: oauthClientSecret,
		TokenURL:     oauthTokenURL,
	}

	token, err := config.Token(ctx)
	if err != nil {
		log.Fatalf("Failed to retrieve access token: %v", err)
	}

	client := oauth2.NewClient(ctx, oauth2.StaticTokenSource(token))

	response, err := client.Get(serverURL)
	if err != nil {
		log.Fatalf("Failed to make request: %v", err)
	}
	defer response.Body.Close()

	responseBody, err := io.ReadAll(response.Body)
	if err != nil {
		log.Fatalf("Failed to read resource: %v", err)
	}

	switch response.StatusCode {
	case http.StatusOK: // 200.
		const expectedClientID = "example-go-client-credentials-server-test"
		const expectedUsername = "service-account-example-go-client-credentials-server-test"
		var data struct {
			ClientId string `json:"client_id"`
			Username string `json:"username"`
		}
		err = json.Unmarshal(responseBody, &data)
		if err != nil {
			log.Fatalf("failed to parse response: %v", err)
		}
		if data.ClientId != expectedClientID {
			log.Fatalf("expected client_id %s but got %s", expectedClientID, data.ClientId)
		}
		if data.Username != expectedUsername {
			log.Fatalf("expected username %s but got %s", expectedUsername, data.Username)
		}
		log.Printf("Hello, %s!", data.ClientId)
	case http.StatusUnauthorized: // 401.
		log.Printf("Response Body: %s", responseBody)
		log.Fatalf("Unauthorized: Failed to validate the access token: %v", err)
	default:
		log.Printf("Response Body: %s", responseBody)
		log.Fatalf("Failed to retrieve resource: %v", err)
	}
}
