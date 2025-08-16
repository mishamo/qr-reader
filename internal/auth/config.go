package auth

import (
	"os"
)

// GetOAuthConfig returns OAuth configuration from environment or defaults
// This allows credentials to be injected at build time
func GetOAuthConfig() (clientID, clientSecret string) {
	// Try environment variables first (used in CI/CD)
	clientID = os.Getenv("GOOGLE_CLIENT_ID")
	clientSecret = os.Getenv("GOOGLE_CLIENT_SECRET")
	
	// If not in environment, try build-time constants
	// These will be set during the build process
	if clientID == "" {
		clientID = buildTimeClientID
	}
	if clientSecret == "" {
		clientSecret = buildTimeClientSecret
	}
	
	// If still empty, use defaults (for development)
	if clientID == "" {
		clientID = "YOUR_CLIENT_ID.apps.googleusercontent.com"
	}
	if clientSecret == "" {
		clientSecret = "YOUR_CLIENT_SECRET"
	}
	
	return clientID, clientSecret
}

// These variables can be set at build time using ldflags
var (
	buildTimeClientID     = ""
	buildTimeClientSecret = ""
)