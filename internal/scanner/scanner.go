package scanner

import (
	"fmt"
	"image"
	"sync"
	"time"

	"github.com/makiuchi-d/gozxing"
	"github.com/makiuchi-d/gozxing/qrcode"
	"github.com/mishamo/qr-reader/internal/sheets"
)

type Scanner struct {
	sheetManager *sheets.Manager
	qrReader     gozxing.Reader
	isScanning   bool
	mu           sync.Mutex
	lastScan     string
	lastScanTime time.Time
	scanHistory  []ScanRecord
}

type ScanRecord struct {
	Data      string
	Timestamp time.Time
	Success   bool
	Error     string
}

func NewScanner(sheetManager *sheets.Manager) *Scanner {
	return &Scanner{
		sheetManager: sheetManager,
		qrReader:     qrcode.NewQRCodeReader(),
		scanHistory:  make([]ScanRecord, 0, 100),
	}
}

func (s *Scanner) ProcessImage(img image.Image) (string, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if !s.isScanning {
		return "", fmt.Errorf("scanner is not active")
	}

	source := gozxing.NewLuminanceSourceFromImage(img)
	binaryBitmap, _ := gozxing.NewBinaryBitmap(gozxing.NewHybridBinarizer(source))

	result, err := s.qrReader.Decode(binaryBitmap, nil)
	if err != nil {
		if err.Error() != "NotFoundException" {
			return "", fmt.Errorf("failed to decode QR: %w", err)
		}
		return "", nil
	}

	data := result.GetText()
	if data == "" {
		return "", nil
	}

	if s.isDuplicateScan(data) {
		return "", nil
	}

	s.lastScan = data
	s.lastScanTime = time.Now()

	return data, nil
}

func (s *Scanner) ProcessScan(data string) error {
	if data == "" {
		return fmt.Errorf("empty scan data")
	}

	record := ScanRecord{
		Data:      data,
		Timestamp: time.Now(),
		Success:   true,
	}

	if err := s.sheetManager.AppendScanData(data); err != nil {
		record.Success = false
		record.Error = err.Error()
		s.addToHistory(record)
		return fmt.Errorf("failed to save scan: %w", err)
	}

	s.addToHistory(record)
	return nil
}

func (s *Scanner) Start() {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.isScanning = true
}

func (s *Scanner) Stop() {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.isScanning = false
}

func (s *Scanner) IsScanning() bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.isScanning
}

func (s *Scanner) GetHistory() []ScanRecord {
	s.mu.Lock()
	defer s.mu.Unlock()
	
	historyCopy := make([]ScanRecord, len(s.scanHistory))
	copy(historyCopy, s.scanHistory)
	return historyCopy
}

func (s *Scanner) GetRecentScans(count int) []ScanRecord {
	history := s.GetHistory()
	
	if count > len(history) {
		count = len(history)
	}
	
	start := len(history) - count
	if start < 0 {
		start = 0
	}
	
	return history[start:]
}

func (s *Scanner) ClearHistory() {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.scanHistory = make([]ScanRecord, 0, 100)
}

func (s *Scanner) isDuplicateScan(data string) bool {
	if s.lastScan == data && time.Since(s.lastScanTime) < 2*time.Second {
		return true
	}
	return false
}

func (s *Scanner) addToHistory(record ScanRecord) {
	s.mu.Lock()
	defer s.mu.Unlock()
	
	s.scanHistory = append(s.scanHistory, record)
	
	if len(s.scanHistory) > 100 {
		s.scanHistory = s.scanHistory[1:]
	}
}

func (s *Scanner) GetLastScan() (string, time.Time) {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.lastScan, s.lastScanTime
}

func (s *Scanner) GetSuccessRate() float64 {
	s.mu.Lock()
	defer s.mu.Unlock()
	
	if len(s.scanHistory) == 0 {
		return 0
	}
	
	successCount := 0
	for _, record := range s.scanHistory {
		if record.Success {
			successCount++
		}
	}
	
	return float64(successCount) / float64(len(s.scanHistory)) * 100
}