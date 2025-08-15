package storage

import (
	"io"
	
	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/storage"
)

const (
	keyToken          = "auth_token"
	keyActiveSheet    = "active_sheet"
	keyDuplicateMode  = "duplicate_mode"
	keyUserEmail      = "user_email"
	keyScanHistory    = "scan_history"
	keySheetCache     = "sheet_cache"
)

type Storage struct {
	store fyne.Storage
}

func New(store fyne.Storage) *Storage {
	return &Storage{
		store: store,
	}
}

func (s *Storage) SaveToken(token string) error {
	uri, err := storage.ParseURI("file://" + keyToken)
	if err != nil {
		return err
	}
	
	writer, err := storage.Writer(uri)
	if err != nil {
		return err
	}
	defer writer.Close()

	_, err = writer.Write([]byte(token))
	return err
}

func (s *Storage) GetToken() string {
	uri, err := storage.ParseURI("file://" + keyToken)
	if err != nil {
		return ""
	}
	
	reader, err := storage.Reader(uri)
	if err != nil {
		return ""
	}
	defer reader.Close()

	data, err := io.ReadAll(reader)
	if err != nil {
		return ""
	}

	return string(data)
}

func (s *Storage) DeleteToken() {
	uri, _ := storage.ParseURI("file://" + keyToken)
	storage.Delete(uri)
}

func (s *Storage) SaveActiveSheet(sheetID string) error {
	uri, err := storage.ParseURI("file://" + keyActiveSheet)
	if err != nil {
		return err
	}
	
	writer, err := storage.Writer(uri)
	if err != nil {
		return err
	}
	defer writer.Close()

	_, err = writer.Write([]byte(sheetID))
	return err
}

func (s *Storage) GetActiveSheet() string {
	uri, err := storage.ParseURI("file://" + keyActiveSheet)
	if err != nil {
		return ""
	}
	
	reader, err := storage.Reader(uri)
	if err != nil {
		return ""
	}
	defer reader.Close()

	data, err := io.ReadAll(reader)
	if err != nil {
		return ""
	}

	return string(data)
}

func (s *Storage) SetDuplicateMode(mode string) error {
	uri, err := storage.ParseURI("file://" + keyDuplicateMode)
	if err != nil {
		return err
	}
	
	writer, err := storage.Writer(uri)
	if err != nil {
		return err
	}
	defer writer.Close()

	_, err = writer.Write([]byte(mode))
	return err
}

func (s *Storage) GetDuplicateMode() string {
	uri, err := storage.ParseURI("file://" + keyDuplicateMode)
	if err != nil {
		return "Allow Duplicates"
	}
	
	reader, err := storage.Reader(uri)
	if err != nil {
		return "Allow Duplicates"
	}
	defer reader.Close()

	data, err := io.ReadAll(reader)
	if err != nil {
		return "Allow Duplicates"
	}

	return string(data)
}

func (s *Storage) SaveUserEmail(email string) error {
	uri, err := storage.ParseURI("file://" + keyUserEmail)
	if err != nil {
		return err
	}
	
	writer, err := storage.Writer(uri)
	if err != nil {
		return err
	}
	defer writer.Close()

	_, err = writer.Write([]byte(email))
	return err
}

func (s *Storage) GetUserEmail() string {
	uri, err := storage.ParseURI("file://" + keyUserEmail)
	if err != nil {
		return ""
	}
	
	reader, err := storage.Reader(uri)
	if err != nil {
		return ""
	}
	defer reader.Close()

	data, err := io.ReadAll(reader)
	if err != nil {
		return ""
	}

	return string(data)
}

func (s *Storage) ClearAll() {
	keys := []string{keyToken, keyActiveSheet, keyDuplicateMode, keyUserEmail, keyScanHistory, keySheetCache}
	for _, key := range keys {
		if uri, err := storage.ParseURI("file://" + key); err == nil {
			storage.Delete(uri)
		}
	}
}