package main

import (
	"bufio"
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"os/exec"
	"regexp"
	"strings"

	"github.com/chromedp/chromedp"
)

func main() {
	log.SetFlags(0)

	flag.Parse()

	if flag.NArg() != 0 {
		flag.Usage()
		log.Fatal("\nERROR You MUST NOT pass any positional arguments")
	}

	username := os.Getenv("EXAMPLE_USERNAME")
	if username == "" {
		log.Fatal("ERROR You MUST set the EXAMPLE_USERNAME environment variable")
	}

	password := os.Getenv("EXAMPLE_PASSWORD")
	if password == "" {
		log.Fatal("ERROR You MUST set the EXAMPLE_PASSWORD environment variable")
	}

	appPath := os.Getenv("EXAMPLE_APP_PATH")
	if appPath == "" {
		appPath = "/ExampleCsharpPublicDevice"
	}

	app := NewExampleCsharpPublicDevice(appPath)

	loginURL := app.GetLoginURL()

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

	var screenshot []byte
	err := chromedp.Run(ctx, authenticate(
		loginURL,
		username,
		password,
		&screenshot))
	if err != nil {
		log.Fatal(err)
	}

	claims := app.GetClaims()

	usernameClaim := claims["PreferredUsername"]
	emailClaim := claims["Email"]

	if usernameClaim != username {
		log.Fatal("failed to login")
	}

	fmt.Printf("Authenticated as %s (%s)\n", usernameClaim, emailClaim)

	if err := os.WriteFile("screenshot.png", screenshot, 0o644); err != nil {
		log.Fatal(err)
	}
}

var (
	appClaimRegexp = regexp.MustCompile(`^  ([A-Za-z]+): (.+)$`)
)

type App struct {
	appPath      string
	done         chan struct{}
	exitCode     int
	loginURLDone chan struct{}
	loginURL     string
	claims       map[string]string
}

func NewExampleCsharpPublicDevice(appPath string) *App {
	app := App{
		done:         make(chan struct{}),
		exitCode:     -1,
		loginURLDone: make(chan struct{}),
		appPath:      appPath,
		claims:       make(map[string]string),
	}
	go app.run()
	return &app
}

func (a *App) run() {
	cmd := exec.Command(a.appPath)

	output, err := cmd.StdoutPipe()
	if err != nil {
		log.Fatalf("failed to create stdout pipe: %v", err)
	}
	scanner := bufio.NewScanner(output)

	err = cmd.Start()
	if err != nil {
		log.Fatalf("failed to start %s: %v", a.appPath, err)
	}

	// wait for the VerificationUriComplete line.
	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(line, "  VerificationUriComplete: ") {
			a.loginURL = line[len("  VerificationUriComplete: "):]
			break
		}
	}
	if err := scanner.Err(); err != nil {
		log.Fatalf("failed to wait for the login url: %v", err)
	}
	close(a.loginURLDone)

	// wait for the claims.
	for scanner.Scan() {
		line := scanner.Text()
		if line == "IdToken Claims:" {
			break
		}
	}
	if err := scanner.Err(); err != nil {
		log.Fatalf("failed to wait for the claims block: %v", err)
	}
	for scanner.Scan() {
		line := scanner.Text()
		m := appClaimRegexp.FindStringSubmatch(line)
		if m == nil {
			continue
		}
		a.claims[m[1]] = m[2]
	}
	if err := scanner.Err(); err != nil {
		log.Fatalf("failed to wait for the claims: %v", err)
	}

	err = cmd.Wait()
	if err != nil {
		log.Fatalf("failed to wait for app to finish: %v", err)
	}

	a.exitCode = cmd.ProcessState.ExitCode()

	close(a.done)
}

func (a *App) GetLoginURL() string {
	<-a.loginURLDone
	return a.loginURL
}

func (a *App) GetClaims() map[string]string {
	<-a.done
	return a.claims
}

func authenticate(loginUrl, username, password string, screenshot *[]byte) chromedp.Tasks {
	usernameSelector := `//form[@id="kc-form-login"]//input[@id="username"]`
	passwordSelector := `//form[@id="kc-form-login"]//input[@id="password"]`
	grantAccessPrivilegesSelector := `//div[@id="kc-oauth"]//input[@id="kc-login"]`
	deviceLoginSuccessfulSelector := `//*[@id="kc-page-title" and contains(., "Device Login Successful")]`
	return chromedp.Tasks{
		// navigate to the application login page.
		// NB this should redirect the browser to the keycloak
		//    authentication page.
		chromedp.Navigate(loginUrl),
		// authenticate into keycloak.
		// NB after the authentication succeeds, this should redirect the
		//    browser to the device grant access privileges page.
		chromedp.WaitVisible(usernameSelector),
		chromedp.SendKeys(usernameSelector, username),
		chromedp.SendKeys(passwordSelector, password),
		chromedp.Submit(usernameSelector),
		// wait for the grant access privileges page.
		chromedp.WaitVisible(grantAccessPrivilegesSelector),
		// grant access privileges.
		chromedp.Submit(grantAccessPrivilegesSelector),
		// wait for device login successful page.
		chromedp.WaitVisible(deviceLoginSuccessfulSelector),
		chromedp.FullScreenshot(screenshot, 100),
	}
}
