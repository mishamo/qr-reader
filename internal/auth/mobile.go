package auth

import (
	"context"
	"fmt"
	"net/url"
	"time"
)

// MobileAuthError is returned when mobile authentication requires manual code entry
type MobileAuthError struct {
	AuthURL string
}

func (e *MobileAuthError) Error() string {
	return "mobile_auth_required"
}

// parseURL safely parses a URL string
func parseURL(urlStr string) *url.URL {
	u, _ := url.Parse(urlStr)
	return u
}

// ExchangeCode exchanges an authorization code for a token (used for mobile flow)
func (m *Manager) ExchangeCode(code string) error {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	
	// Use the OOB redirect URI for the exchange
	config := *m.config
	config.RedirectURL = "urn:ietf:wg:oauth:2.0:oob"
	
	token, err := config.Exchange(ctx, code)
	if err != nil {
		return fmt.Errorf("failed to exchange code for token: %w", err)
	}
	
	m.token = token
	m.client = m.config.Client(ctx, token)
	
	if err := m.fetchUserInfo(); err != nil {
		return fmt.Errorf("failed to fetch user info: %w", err)
	}
	
	if err := m.storeToken(); err != nil {
		return fmt.Errorf("failed to store token: %w", err)
	}
	
	return nil
}