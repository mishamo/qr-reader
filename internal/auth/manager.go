package auth

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"golang.org/x/oauth2"
	"golang.org/x/oauth2/google"
	"google.golang.org/api/drive/v3"
	"google.golang.org/api/option"
	"google.golang.org/api/sheets/v4"
	"github.com/qorda/qr-scanner/internal/storage"
)

const (
	redirectURL = "http://localhost:8080/callback"
	authTimeout = 5 * time.Minute
)

type Manager struct {
	config   *oauth2.Config
	token    *oauth2.Token
	storage  *storage.Storage
	client   *http.Client
	userInfo *UserInfo
}

type UserInfo struct {
	Email   string `json:"email"`
	Name    string `json:"name"`
	Picture string `json:"picture"`
}

func NewManager(store *storage.Storage) *Manager {
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
	codeChan := make(chan string, 1)
	errChan := make(chan error, 1)

	mux := http.NewServeMux()
	server := &http.Server{
		Addr:    ":8080",
		Handler: mux,
	}
	
	mux.HandleFunc("/callback", func(w http.ResponseWriter, r *http.Request) {
		code := r.URL.Query().Get("code")
		if code == "" {
			errChan <- fmt.Errorf("no authorization code received")
			fmt.Fprintf(w, "Authorization failed")
			return
		}
		
		codeChan <- code
		fmt.Fprintf(w, `
			<html>
			<body style="font-family: Arial; text-align: center; padding: 50px;">
				<h2>✅ Authentication Successful!</h2>
				<p>You can now close this window and return to the QR Scanner app.</p>
				<script>window.setTimeout(function(){window.close()}, 2000);</script>
			</body>
			</html>
		`)
	})

	go func() {
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			errChan <- err
		}
	}()

	authURL := m.config.AuthCodeURL("state", oauth2.AccessTypeOffline, oauth2.ApprovalForce)
	
	if err := OpenBrowser(authURL); err != nil {
		return fmt.Errorf("failed to open browser: %w", err)
	}

	select {
	case code := <-codeChan:
		server.Shutdown(context.Background())
		
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
		
	case err := <-errChan:
		server.Shutdown(context.Background())
		return err
		
	case <-time.After(authTimeout):
		server.Shutdown(context.Background())
		return fmt.Errorf("authentication timeout")
	}
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

	return m.storage.SetBytes("oauth_token", tokenJSON)
}

func (m *Manager) loadStoredToken() {
	tokenJSON, err := m.storage.GetBytes("oauth_token")
	if err != nil || len(tokenJSON) == 0 {
		return
	}

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
	m.storage.Delete("oauth_token")
}

