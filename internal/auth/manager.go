package auth

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
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
	config       *oauth2.Config
	token        *oauth2.Token
	storage      *storage.Storage
	client       *http.Client
	userInfo     *UserInfo
	service      *sheets.Service // For service account mode
	driveService *drive.Service  // For service account mode
}

type UserInfo struct {
	Email   string `json:"email"`
	Name    string `json:"name"`
	Picture string `json:"picture"`
}

func NewManager(store *storage.Storage) *Manager {
	// Check if we have service account credentials
	if _, err := os.Stat("credentials.json"); err == nil {
		// Use service account mode
		m := &Manager{
			storage: store,
			userInfo: &UserInfo{
				Email: "scanner@misha-project.com",
				Name:  "QR Scanner Service",
			},
		}
		m.initServiceAccount()
		return m
	}
	
	// Use OAuth mode
	config := &oauth2.Config{
		ClientID:     getClientID(),
		ClientSecret: getClientSecret(),
		RedirectURL:  redirectURL,
		Scopes: []string{
			sheets.SpreadsheetsScope,
			"https://www.googleapis.com/auth/drive.file",
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

func (m *Manager) initServiceAccount() error {
	ctx := context.Background()
	
	// Read the service account key file
	jsonKey, err := ioutil.ReadFile("credentials.json")
	if err != nil {
		return fmt.Errorf("failed to read credentials.json: %w", err)
	}
	
	// Parse to get the service account email
	var keyData map[string]interface{}
	if err := json.Unmarshal(jsonKey, &keyData); err == nil {
		if email, ok := keyData["client_email"].(string); ok {
			fmt.Printf("Using service account: %s\n", email)
		}
	}
	
	// Create the Sheets service
	service, err := sheets.NewService(ctx, option.WithCredentialsJSON(jsonKey))
	if err != nil {
		return fmt.Errorf("failed to create sheets service: %w", err)
	}
	
	// Create the Drive service
	driveService, err := drive.NewService(ctx, option.WithCredentialsJSON(jsonKey))
	if err != nil {
		return fmt.Errorf("failed to create drive service: %w", err)
	}
	
	m.service = service
	m.driveService = driveService
	return nil
}

func (m *Manager) IsAuthenticated() bool {
	// Service account mode
	if m.service != nil {
		return true
	}
	
	// OAuth mode
	if m.token == nil {
		return false
	}
	return m.token.Valid()
}

func (m *Manager) Authenticate() error {
	// Service account mode - just initialize
	if m.config == nil && m.service == nil {
		return m.initServiceAccount()
	}
	
	// OAuth mode
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
			<body>
				<h2>Authorization successful!</h2>
				<p>You can close this window and return to the app.</p>
				<script>window.close();</script>
			</body>
			</html>
		`)
	})

	go func() {
		if err := server.ListenAndServe(); err != http.ErrServerClosed {
			errChan <- err
		}
	}()

	authURL := m.config.AuthCodeURL("state", oauth2.AccessTypeOffline)
	
	if err := openBrowser(authURL); err != nil {
		server.Shutdown(context.Background())
		return fmt.Errorf("failed to open browser: %w", err)
	}

	select {
	case code := <-codeChan:
		server.Shutdown(context.Background())
		
		token, err := m.config.Exchange(context.Background(), code)
		if err != nil {
			return fmt.Errorf("failed to exchange token: %w", err)
		}
		
		m.token = token
		m.client = m.config.Client(context.Background(), token)
		
		if err := m.fetchUserInfo(); err != nil {
			return fmt.Errorf("failed to fetch user info: %w", err)
		}
		
		if err := m.saveToken(); err != nil {
			return fmt.Errorf("failed to save token: %w", err)
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
	// Service account mode
	if m.service != nil {
		return m.service, nil
	}
	
	// OAuth mode
	client := m.GetClient()
	if client == nil {
		return nil, fmt.Errorf("not authenticated")
	}
	return sheets.NewService(context.Background(), option.WithHTTPClient(client))
}

func (m *Manager) GetDriveService() (*drive.Service, error) {
	// Service account mode
	if m.driveService != nil {
		return m.driveService, nil
	}
	
	// OAuth mode
	client := m.GetClient()
	if client == nil {
		return nil, fmt.Errorf("not authenticated")
	}
	return drive.NewService(context.Background(), option.WithHTTPClient(client))
}

func (m *Manager) GetUserEmail() string {
	if m.userInfo != nil {
		return m.userInfo.Email
	}
	return ""
}

func (m *Manager) SignOut() {
	m.token = nil
	m.client = nil
	m.userInfo = nil
	m.storage.DeleteToken()
}

func (m *Manager) fetchUserInfo() error {
	resp, err := m.client.Get("https://www.googleapis.com/oauth2/v2/userinfo")
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	var info UserInfo
	if err := json.NewDecoder(resp.Body).Decode(&info); err != nil {
		return err
	}

	m.userInfo = &info
	return nil
}

func (m *Manager) saveToken() error {
	tokenData, err := json.Marshal(m.token)
	if err != nil {
		return err
	}
	return m.storage.SaveToken(string(tokenData))
}

func (m *Manager) loadStoredToken() {
	tokenData := m.storage.GetToken()
	if tokenData == "" {
		return
	}

	var token oauth2.Token
	if err := json.Unmarshal([]byte(tokenData), &token); err != nil {
		return
	}

	m.token = &token
	m.client = m.config.Client(context.Background(), &token)
	m.fetchUserInfo()
}

func getClientID() string {
	return "YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com"
}

func getClientSecret() string {
	return "YOUR_GOOGLE_CLIENT_SECRET"
}