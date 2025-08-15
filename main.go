package main

import (
	"fmt"
	"log"
	"os"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/widget"
	"github.com/qorda/qr-scanner/internal/auth"
	"github.com/qorda/qr-scanner/internal/scanner"
	"github.com/qorda/qr-scanner/internal/sheets"
	"github.com/qorda/qr-scanner/internal/storage"
	"github.com/qorda/qr-scanner/internal/ui"
)

const appID = "com.qorda.qrscanner"

type QRScannerApp struct {
	app               fyne.App
	window            fyne.Window
	authManager       *auth.Manager
	sheetManager      *sheets.Manager
	scanner           *scanner.Scanner
	storage           *storage.Storage
	currentSheetLabel *widget.Label
}

func main() {
	myApp := app.NewWithID(appID)
	myApp.Settings().SetTheme(&ui.QRScannerTheme{})

	qrApp := &QRScannerApp{
		app:     myApp,
		window:  myApp.NewWindow("QR Scanner"),
		storage: storage.New(myApp.Storage()),
	}

	qrApp.setupManagers()
	qrApp.setupUI()

	qrApp.window.Resize(fyne.NewSize(400, 700))
	qrApp.window.CenterOnScreen()
	qrApp.window.ShowAndRun()
}

func (a *QRScannerApp) setupManagers() {
	a.authManager = auth.NewManager(a.storage)
	a.sheetManager = sheets.NewManager(a.authManager)
	a.scanner = scanner.NewScanner(a.sheetManager)
}

func (a *QRScannerApp) setupUI() {
	if !a.authManager.IsAuthenticated() {
		a.showLoginScreen()
	} else {
		a.showMainScreen()
	}
}

func (a *QRScannerApp) showLoginScreen() {
	welcome := widget.NewLabel("Welcome to QR Scanner")
	welcome.Alignment = fyne.TextAlignCenter
	welcome.TextStyle = fyne.TextStyle{Bold: true}

	// Check if we have credentials.json (service account mode)
	if _, err := os.Stat("credentials.json"); err == nil {
		description := widget.NewLabel("Initializing with service account...")
		description.Alignment = fyne.TextAlignCenter
		
		content := container.NewVBox(
			widget.NewLabel(""),
			welcome,
			description,
		)
		a.window.SetContent(container.NewPadded(content))
		
		// Auto-authenticate with service account
		go func() {
			if err := a.authManager.Authenticate(); err != nil {
				log.Printf("Service account init failed: %v", err)
				a.showError("Service account init failed", err)
				return
			}
			a.showMainScreen()
		}()
		return
	}

	// OAuth mode
	description := widget.NewLabel("Sign in with Google to sync scans to Google Sheets")
	description.Alignment = fyne.TextAlignCenter
	description.Wrapping = fyne.TextWrapWord

	loginBtn := widget.NewButton("Sign in with Google", func() {
		go func() {
			if err := a.authManager.Authenticate(); err != nil {
				log.Printf("Authentication failed: %v", err)
				a.showError("Authentication failed", err)
				return
			}
			a.window.Canvas().Content().Refresh()
			a.showMainScreen()
		}()
	})
	loginBtn.Importance = widget.HighImportance

	content := container.NewVBox(
		widget.NewLabel(""), 
		welcome,
		description,
		widget.NewLabel(""),
		container.NewCenter(loginBtn),
	)

	a.window.SetContent(container.NewPadded(content))
}

func (a *QRScannerApp) showMainScreen() {
	tabs := container.NewAppTabs(
		container.NewTabItem("Scanner", a.createScannerTab()),
		container.NewTabItem("Sheets", a.createSheetsTab()),
		container.NewTabItem("Settings", a.createSettingsTab()),
	)

	a.window.SetContent(tabs)
}

func (a *QRScannerApp) createScannerTab() fyne.CanvasObject {
	statusLabel := widget.NewLabel("Ready to scan")
	statusLabel.Alignment = fyne.TextAlignCenter

	scanBtn := widget.NewButton("Start Scanning", func() {
		a.startScanning()
	})
	scanBtn.Importance = widget.HighImportance

	recentScans := widget.NewList(
		func() int { return 0 },
		func() fyne.CanvasObject {
			return widget.NewLabel("")
		},
		func(i widget.ListItemID, o fyne.CanvasObject) {},
	)

	return container.NewBorder(
		container.NewVBox(
			statusLabel,
			container.NewCenter(scanBtn),
			widget.NewSeparator(),
		),
		nil, nil, nil,
		container.NewVBox(
			widget.NewLabel("Recent Scans:"),
			recentScans,
		),
	)
}

func (a *QRScannerApp) createSheetsTab() fyne.CanvasObject {
	a.currentSheetLabel = widget.NewLabel("No active sheet")
	if sheet := a.sheetManager.GetActiveSheet(); sheet != nil {
		a.currentSheetLabel.SetText("Active: " + sheet.Name)
	}

	instructionsLabel := widget.NewLabel("To use this app:\n1. Create a Google Sheet at sheets.new\n2. Share it with:\n   qr-scanner@misha-project-469120.iam.gserviceaccount.com\n3. Click 'Select Sheet' below")
	instructionsLabel.Wrapping = fyne.TextWrapWord

	selectBtn := widget.NewButton("Select Sheet", func() {
		a.showSelectSheetDialog()
	})
	selectBtn.Importance = widget.HighImportance

	// Hardcode your test sheet for now
	useTestSheetBtn := widget.NewButton("Use Test Sheet", func() {
		testSheet := &sheets.Sheet{
			ID:   "1y6iMUDynDcKvoX4x29yoqUSRvwVcyRSAWBYHa35hZGA",
			Name: "QR Scanner Test Sheet",
			URL:  "https://docs.google.com/spreadsheets/d/1y6iMUDynDcKvoX4x29yoqUSRvwVcyRSAWBYHa35hZGA",
		}
		a.sheetManager.SetActiveSheet(testSheet)
		a.currentSheetLabel.SetText("Active: " + testSheet.Name)
		a.showSuccess("Sheet Selected", "Using test sheet for scanning")
	})

	return container.NewVBox(
		widget.NewCard("Current Sheet", "", a.currentSheetLabel),
		widget.NewLabel(""),
		widget.NewCard("Instructions", "", instructionsLabel),
		widget.NewLabel(""),
		selectBtn,
		useTestSheetBtn,
	)
}

func (a *QRScannerApp) createSettingsTab() fyne.CanvasObject {
	duplicateOptions := []string{"Allow Duplicates", "Skip Duplicates", "Update Existing"}
	duplicateSelect := widget.NewSelect(duplicateOptions, func(value string) {
		a.storage.SetDuplicateMode(value)
	})
	duplicateSelect.SetSelectedIndex(0)

	signOutBtn := widget.NewButton("Sign Out", func() {
		a.authManager.SignOut()
		a.showLoginScreen()
	})
	signOutBtn.Importance = widget.DangerImportance

	userInfo := widget.NewLabel("Signed in as: " + a.authManager.GetUserEmail())

	return container.NewVBox(
		widget.NewCard("Account", "", userInfo),
		widget.NewLabel(""),
		widget.NewCard("Duplicate Handling", "", duplicateSelect),
		widget.NewLabel(""),
		container.NewCenter(signOutBtn),
	)
}

func (a *QRScannerApp) startScanning() {
	// Check if a sheet is selected first
	if a.sheetManager.GetActiveSheet() == nil {
		a.showError("No Sheet Selected", fmt.Errorf("Please select a sheet first in the Sheets tab"))
		return
	}
	
	scanWindow := a.app.NewWindow("QR Scanner")
	scanWindow.Resize(fyne.NewSize(400, 600))
	
	cameraWidget := ui.NewCameraWidget(func(data string) {
		if err := a.scanner.ProcessScan(data); err != nil {
			a.showError("Scan Error", err)
		} else {
			scanWindow.Close()
			a.showSuccess("Scan Successful", "Data saved to sheet")
		}
	})

	stopBtn := widget.NewButton("Stop Scanning", func() {
		cameraWidget.Stop()
		scanWindow.Close()
	})

	content := container.NewBorder(
		nil,
		container.NewPadded(stopBtn),
		nil, nil,
		cameraWidget,
	)

	scanWindow.SetContent(content)
	scanWindow.Show()
	cameraWidget.Start()
}

func (a *QRScannerApp) showCreateSheetDialog() {
	nameEntry := widget.NewEntry()
	nameEntry.SetPlaceHolder("Sheet Name")

	dialog := widget.NewForm(
		widget.NewFormItem("Name", nameEntry),
	)

	var popup *widget.PopUp
	
	confirmBtn := widget.NewButton("Create", func() {
		if nameEntry.Text != "" {
			popup.Hide()
			go func() {
				if err := a.sheetManager.CreateSheet(nameEntry.Text); err != nil {
					a.showError("Failed to create sheet", err)
				} else {
					a.showSuccess("Success", "Sheet created successfully")
					a.window.Content().Refresh()
				}
			}()
		}
	})
	
	cancelBtn := widget.NewButton("Cancel", func() {
		popup.Hide()
	})

	popup = widget.NewModalPopUp(
		container.NewVBox(
			widget.NewLabel("Create New Sheet"),
			dialog,
			container.NewGridWithColumns(2, cancelBtn, confirmBtn),
		),
		a.window.Canvas(),
	)
	popup.Show()
}

func (a *QRScannerApp) showSelectSheetDialog() {
	sheets, err := a.sheetManager.ListSheets()
	if err != nil {
		a.showError("Failed to list sheets", err)
		return
	}

	if len(sheets) == 0 {
		a.showError("No sheets found", fmt.Errorf("Please create a sheet and share it with qr-scanner@misha-project-469120.iam.gserviceaccount.com"))
		return
	}

	var sheetNames []string
	for _, sheet := range sheets {
		sheetNames = append(sheetNames, sheet.Name)
	}

	var popup *widget.PopUp
	
	sheetSelect := widget.NewSelect(sheetNames, func(value string) {
		if value == "" {
			return
		}
		for _, sheet := range sheets {
			if sheet.Name == value {
				a.sheetManager.SetActiveSheet(sheet)
				if a.currentSheetLabel != nil {
					a.currentSheetLabel.SetText("Active: " + sheet.Name)
				}
				popup.Hide()
				a.showSuccess("Sheet Selected", fmt.Sprintf("Now using: %s", sheet.Name))
				break
			}
		}
	})

	popup = widget.NewModalPopUp(
		container.NewVBox(
			widget.NewLabel("Select Sheet"),
			sheetSelect,
			widget.NewButton("Cancel", func() {
				popup.Hide()
			}),
		),
		a.window.Canvas(),
	)
	popup.Show()
}

func (a *QRScannerApp) showError(title string, err error) {
	var dialog *widget.PopUp
	dialog = widget.NewModalPopUp(
		container.NewVBox(
			widget.NewLabel(title),
			widget.NewLabel(err.Error()),
			widget.NewButton("OK", func() {
				dialog.Hide()
			}),
		),
		a.window.Canvas(),
	)
	dialog.Show()
}

func (a *QRScannerApp) showSuccess(title, message string) {
	var dialog *widget.PopUp
	dialog = widget.NewModalPopUp(
		container.NewVBox(
			widget.NewLabel(title),
			widget.NewLabel(message),
			widget.NewButton("OK", func() {
				dialog.Hide()
			}),
		),
		a.window.Canvas(),
	)
	dialog.Show()
}