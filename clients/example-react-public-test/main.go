package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"

	"github.com/chromedp/chromedp"
)

func main() {
	log.SetFlags(0)

	flag.Parse()

	if flag.NArg() != 0 {
		flag.Usage()
		log.Fatalf("\nERROR You MUST NOT pass any positional arguments")
	}

	loginUrl := os.Getenv("EXAMPLE_LOGIN_URL")
	if loginUrl == "" {
		log.Fatalf("ERROR You MUST set the EXAMPLE_LOGIN_URL environment variable")
	}

	username := os.Getenv("EXAMPLE_USERNAME")
	if username == "" {
		log.Fatalf("ERROR You MUST set the EXAMPLE_USERNAME environment variable")
	}

	password := os.Getenv("EXAMPLE_PASSWORD")
	if password == "" {
		log.Fatalf("ERROR You MUST set the EXAMPLE_PASSWORD environment variable")
	}

	options := append(
		chromedp.DefaultExecAllocatorOptions[:],
		//chromedp.Flag("headless", false),
		chromedp.WindowSize(1024, 768))

	allocatorCtx, cancel := chromedp.NewExecAllocator(
		context.Background(),
		options...)
	defer cancel()

	ctx, cancel := chromedp.NewContext(
		allocatorCtx,
		//chromedp.WithDebugf(log.Printf),
		chromedp.WithLogf(log.Printf),
		chromedp.WithErrorf(log.Printf))
	defer cancel()

	var usernameClaim string
	var emailClaim string
	var screenshot []byte
	err := chromedp.Run(ctx, authenticate(
		loginUrl,
		username,
		password,
		&usernameClaim,
		&emailClaim,
		&screenshot))
	if err != nil {
		log.Fatal(err)
	}

	if usernameClaim != username {
		log.Fatal("failed to login")
	}

	fmt.Printf("Authenticated as %s (%s)\n", usernameClaim, emailClaim)

	if err := os.WriteFile("screenshot.png", screenshot, 0o644); err != nil {
		log.Fatal(err)
	}
}

func authenticate(loginUrl, username, password string, usernameClaim, emailClaim *string, screenshot *[]byte) chromedp.Tasks {
	usernameSelector := `//form[@id="kc-form-login"]//input[@id="username"]`
	passwordSelector := `//form[@id="kc-form-login"]//input[@id="password"]`
	return chromedp.Tasks{
		// navigate to the application login page.
		// NB this should redirect the browser to the keycloak
		//    authentication page.
		chromedp.Navigate(loginUrl),
		// authenticate into keycloak.
		// NB after the authentication succeeds, this should
		//    redirect the browser to the application page.
		chromedp.WaitVisible(usernameSelector),
		chromedp.SendKeys(usernameSelector, username),
		chromedp.SendKeys(passwordSelector, password),
		chromedp.Submit(usernameSelector),
		// wait for keycloak to redirect back to the application.
		chromedp.WaitVisible(`//th[.="Email"]`),
		chromedp.Text(`//th[.="Email"]/../td`, emailClaim),
		chromedp.Text(`//th[.="PreferredUsername"]/../td`, usernameClaim),
		chromedp.FullScreenshot(screenshot, 100),
	}
}
