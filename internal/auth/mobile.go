package auth

import (
	"net/url"
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