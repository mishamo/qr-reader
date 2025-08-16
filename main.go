package main

import (
	"fmt"
	"log"

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

	description := widget.NewLabel("Sign in with your Google account to start scanning")
	description.Alignment = fyne.TextAlignCenter
	description.Wrapping = fyne.TextWrapWord

	features := widget.NewLabel("✓ Create sheets in your Google Drive\n✓ Share sheets with your team\n✓ Everyone scans to the same sheet")
	features.Alignment = fyne.TextAlignCenter

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
		features,
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

	createBtn := widget.NewButton("Create New Sheet", func() {
		a.showCreateSheetDialog()
	})
	createBtn.Importance = widget.HighImportance

	selectBtn := widget.NewButton("Select Existing Sheet", func() {
		a.showSelectSheetDialog()
	})

	shareBtn := widget.NewButton("Share Current Sheet", func() {
		if sheet := a.sheetManager.GetActiveSheet(); sheet != nil {
			a.showShareDialog(sheet)
		} else {
			a.showError("No Sheet Selected", fmt.Errorf("Please select or create a sheet first"))
		}
	})

	instructionsLabel := widget.NewLabel("How to collaborate:\n1. Create or select a sheet\n2. Share it with team members\n3. They sign in with their Google account\n4. Everyone selects the same sheet\n5. All scans go to the shared sheet!")
	instructionsLabel.Wrapping = fyne.TextWrapWord

	return container.NewVBox(
		widget.NewCard("Current Sheet", "", a.currentSheetLabel),
		widget.NewLabel(""),
		container.NewGridWithColumns(2,
			createBtn,
			selectBtn,
		),
		widget.NewLabel(""),
		shareBtn,
		widget.NewLabel(""),
		widget.NewCard("Collaboration", "", instructionsLabel),
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
	nameEntry.SetPlaceHolder("My Conference Scans")

	var popup *widget.PopUp
	
	confirmBtn := widget.NewButton("Create", func() {
		if nameEntry.Text != "" {
			popup.Hide()
			go func() {
				if err := a.sheetManager.CreateSheet(nameEntry.Text); err != nil {
					a.showError("Failed to create sheet", err)
				} else {
					if a.currentSheetLabel != nil {
						sheet := a.sheetManager.GetActiveSheet()
						if sheet != nil {
							a.currentSheetLabel.SetText("Active: " + sheet.Name)
						}
					}
					a.showSuccess("Sheet Created!", "Your sheet is ready for scanning")
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
			widget.NewLabel("This will create a sheet in your Google Drive"),
			nameEntry,
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

func (a *QRScannerApp) showShareDialog(sheet *sheets.Sheet) {
	var popup *widget.PopUp
	
	urlEntry := widget.NewEntry()
	urlEntry.SetText(sheet.URL)
	urlEntry.Disable()
	
	copyBtn := widget.NewButton("Copy Link", func() {
		a.window.Clipboard().SetContent(sheet.URL)
		a.showSuccess("Copied!", "Sheet link copied to clipboard")
	})
	
	instructions := widget.NewLabel("To share this sheet:\n1. Open the link in Google Sheets\n2. Click Share button\n3. Add team members' email addresses\n4. They can then use this app to scan")
	instructions.Wrapping = fyne.TextWrapWord
	
	popup = widget.NewModalPopUp(
		container.NewVBox(
			widget.NewLabel("Share Sheet: " + sheet.Name),
			widget.NewLabel(""),
			widget.NewLabel("Sheet URL:"),
			urlEntry,
			copyBtn,
			widget.NewLabel(""),
			instructions,
			widget.NewLabel(""),
			widget.NewButton("Close", func() {
				popup.Hide()
			}),
		),
		a.window.Canvas(),
	)
	popup.Show()
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