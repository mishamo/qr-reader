package storage

import (
	"io"
	
	"fyne.io/fyne/v2"
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
	writer, err := s.store.Create(keyToken)
	if err != nil {
		return err
	}
	defer writer.Close()

	_, err = writer.Write([]byte(token))
	return err
}

func (s *Storage) GetToken() string {
	reader, err := s.store.Open(keyToken)
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
	s.store.Remove(keyToken)
}

func (s *Storage) SaveActiveSheet(sheetID string) error {
	writer, err := s.store.Create(keyActiveSheet)
	if err != nil {
		return err
	}
	defer writer.Close()

	_, err = writer.Write([]byte(sheetID))
	return err
}

func (s *Storage) GetActiveSheet() string {
	reader, err := s.store.Open(keyActiveSheet)
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
	writer, err := s.store.Create(keyDuplicateMode)
	if err != nil {
		return err
	}
	defer writer.Close()

	_, err = writer.Write([]byte(mode))
	return err
}

func (s *Storage) GetDuplicateMode() string {
	reader, err := s.store.Open(keyDuplicateMode)
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
	writer, err := s.store.Create(keyUserEmail)
	if err != nil {
		return err
	}
	defer writer.Close()

	_, err = writer.Write([]byte(email))
	return err
}

func (s *Storage) GetUserEmail() string {
	reader, err := s.store.Open(keyUserEmail)
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
		s.store.Remove(key)
	}
}