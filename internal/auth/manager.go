package auth

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"fyne.io/fyne/v2"
	"golang.org/x/oauth2"
	"golang.org/x/oauth2/google"
	"google.golang.org/api/drive/v3"
	"google.golang.org/api/option"
	"google.golang.org/api/sheets/v4"
	"github.com/mishamo/qr-reader/internal/storage"
)

const (
	redirectURL = "https://mishamo.github.io/qr-reader/oauth-callback"
	authTimeout = 5 * time.Minute
)

type Manager struct {
	config   *oauth2.Config
	token    *oauth2.Token
	storage  *storage.Storage
	client   *http.Client
	userInfo *UserInfo
	app      fyne.App  // Added for mobile URL handling
}

type UserInfo struct {
	Email   string `json:"email"`
	Name    string `json:"name"`
	Picture string `json:"picture"`
}

func NewManager(store *storage.Storage, app fyne.App) *Manager {
	clientID, clientSecret := GetOAuthConfig()
	
	config := &oauth2.Config{
		ClientID:     clientID,
		ClientSecret: clientSecret,
		RedirectURL:  redirectURL,
		Scopes: []string{
			sheets.SpreadsheetsScope,
			"https://www.googleapis.com/auth/drive",
			"https://www.googleapis.com/auth/userinfo.email",
			"https://www.googleapis.com/auth/userinfo.profile",
		},
		Endpoint: google.Endpoint,
	}

	m := &Manager{
		config:  config,
		storage: store,
		app:     app,
	}

	m.loadStoredToken()
	return m
}

func (m *Manager) IsAuthenticated() bool {
	if m.token == nil {
		return false
	}
	return m.token.Valid()
}

func (m *Manager) Authenticate() error {
	// Mobile-only OAuth flow with manual code entry
	authURL := m.config.AuthCodeURL("state", oauth2.AccessTypeOffline, oauth2.ApprovalForce)
	
	// Open the auth URL in the browser
	if m.app != nil {
		if err := m.app.OpenURL(parseURL(authURL)); err != nil {
			return fmt.Errorf("failed to open browser: %w", err)
		}
	}
	
	// Return a special error that tells the UI to show the code entry dialog
	return &MobileAuthError{AuthURL: authURL}
}

func (m *Manager) GetClient() *http.Client {
	if m.client == nil && m.token != nil {
		m.client = m.config.Client(context.Background(), m.token)
	}
	return m.client
}

func (m *Manager) GetSheetsService() (*sheets.Service, error) {
	client := m.GetClient()
	if client == nil {
		return nil, fmt.Errorf("not authenticated")
	}
	return sheets.NewService(context.Background(), option.WithHTTPClient(client))
}

func (m *Manager) GetDriveService() (*drive.Service, error) {
	client := m.GetClient()
	if client == nil {
		return nil, fmt.Errorf("not authenticated")
	}
	return drive.NewService(context.Background(), option.WithHTTPClient(client))
}

func (m *Manager) fetchUserInfo() error {
	client := m.GetClient()
	if client == nil {
		return fmt.Errorf("no client available")
	}

	resp, err := client.Get("https://www.googleapis.com/oauth2/v2/userinfo")
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	userInfo := &UserInfo{}
	if err := json.NewDecoder(resp.Body).Decode(userInfo); err != nil {
		return err
	}

	m.userInfo = userInfo
	return nil
}

func (m *Manager) GetUserEmail() string {
	if m.userInfo != nil {
		return m.userInfo.Email
	}
	return "Unknown"
}

func (m *Manager) GetUserName() string {
	if m.userInfo != nil {
		return m.userInfo.Name
	}
	return "Unknown User"
}

func (m *Manager) storeToken() error {
	if m.token == nil {
		return fmt.Errorf("no token to store")
	}

	tokenJSON, err := json.Marshal(m.token)
	if err != nil {
		return err
	}

	return m.storage.SaveToken(string(tokenJSON))
}

func (m *Manager) loadStoredToken() {
	tokenStr := m.storage.GetToken()
	if tokenStr == "" {
		return
	}
	tokenJSON := []byte(tokenStr)

	token := &oauth2.Token{}
	if err := json.Unmarshal(tokenJSON, token); err == nil {
		m.token = token
		m.fetchUserInfo()
	}
}

func (m *Manager) SignOut() {
	m.token = nil
	m.client = nil
	m.userInfo = nil
	m.storage.DeleteToken()
}

func (m *Manager) ExchangeCode(code string) error {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	
	token, err := m.config.Exchange(ctx, code)
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

