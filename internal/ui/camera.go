package ui

import (
	"image"
	"image/color"
	"sync"
	"time"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/canvas"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/widget"
	"github.com/makiuchi-d/gozxing"
	"github.com/makiuchi-d/gozxing/qrcode"
	"github.com/qorda/qr-scanner/internal/camera"
)

type CameraWidget struct {
	widget.BaseWidget
	
	onScan      func(string)
	isRunning   bool
	mu          sync.Mutex
	
	camera      camera.Camera
	preview     *canvas.Image
	overlay     *canvas.Rectangle
	statusLabel *widget.Label
	qrReader    gozxing.Reader
	
	lastScan    string
	lastScanTime time.Time
}

func NewCameraWidget(onScan func(string)) *CameraWidget {
	w := &CameraWidget{
		onScan:      onScan,
		camera:      camera.NewCamera(),
		qrReader:    qrcode.NewQRCodeReader(),
		statusLabel: widget.NewLabel("Point camera at QR code"),
	}
	
	w.preview = canvas.NewImageFromImage(w.createPlaceholderImage())
	w.preview.FillMode = canvas.ImageFillContain
	
	w.overlay = canvas.NewRectangle(color.RGBA{R: 0, G: 255, B: 0, A: 100})
	w.overlay.Hide()
	
	w.statusLabel.Alignment = fyne.TextAlignCenter
	w.statusLabel.TextStyle = fyne.TextStyle{Bold: true}
	
	w.ExtendBaseWidget(w)
	return w
}

func (w *CameraWidget) CreateRenderer() fyne.WidgetRenderer {
	viewfinderOverlay := w.createViewfinderOverlay()
	
	content := container.NewMax(
		w.preview,
		viewfinderOverlay,
		container.NewBorder(
			container.NewCenter(container.NewPadded(w.statusLabel)),
			nil, nil, nil,
			container.NewCenter(w.overlay),
		),
	)
	
	return widget.NewSimpleRenderer(content)
}

func (w *CameraWidget) Start() {
	w.mu.Lock()
	defer w.mu.Unlock()
	
	if w.isRunning {
		return
	}
	
	w.isRunning = true
	w.statusLabel.SetText("Scanning...")
	
	w.camera.RequestPermission()
	w.camera.Start(w.processFrame)
}

func (w *CameraWidget) Stop() {
	w.mu.Lock()
	defer w.mu.Unlock()
	
	w.isRunning = false
	w.statusLabel.SetText("Camera stopped")
	w.camera.Stop()
}

func (w *CameraWidget) IsRunning() bool {
	w.mu.Lock()
	defer w.mu.Unlock()
	return w.isRunning
}


func (w *CameraWidget) processFrame(img image.Image) {
	w.preview.Image = img
	w.preview.Refresh()
	
	source := gozxing.NewLuminanceSourceFromImage(img)
	binaryBitmap, _ := gozxing.NewBinaryBitmap(gozxing.NewHybridBinarizer(source))
	
	result, err := w.qrReader.Decode(binaryBitmap, nil)
	if err == nil && result != nil {
		data := result.GetText()
		if data != "" && !w.isDuplicateScan(data) {
			w.handleSuccessfulScan(data)
		}
	}
}

func (w *CameraWidget) handleSuccessfulScan(data string) {
	w.mu.Lock()
	w.lastScan = data
	w.lastScanTime = time.Now()
	w.mu.Unlock()
	
	w.overlay.Show()
	w.statusLabel.SetText("QR Code Detected!")
	
	time.AfterFunc(500*time.Millisecond, func() {
		w.overlay.Hide()
		if w.onScan != nil {
			w.onScan(data)
		}
	})
}

func (w *CameraWidget) isDuplicateScan(data string) bool {
	w.mu.Lock()
	defer w.mu.Unlock()
	
	if w.lastScan == data && time.Since(w.lastScanTime) < 2*time.Second {
		return true
	}
	return false
}

func (w *CameraWidget) createViewfinderOverlay() fyne.CanvasObject {
	cornerSize := float32(50)
	cornerWidth := float32(4)
	
	topLeft := w.createCorner(cornerSize, cornerWidth, true, true)
	topRight := w.createCorner(cornerSize, cornerWidth, false, true)
	bottomLeft := w.createCorner(cornerSize, cornerWidth, true, false)
	bottomRight := w.createCorner(cornerSize, cornerWidth, false, false)
	
	return container.NewWithoutLayout(
		topLeft,
		topRight,
		bottomLeft,
		bottomRight,
	)
}

func (w *CameraWidget) createCorner(size, width float32, isLeft, isTop bool) fyne.CanvasObject {
	corner := canvas.NewRectangle(color.RGBA{R: 255, G: 255, B: 255, A: 200})
	corner.StrokeWidth = width
	corner.StrokeColor = color.RGBA{R: 66, G: 133, B: 244, A: 255}
	return corner
}

func (w *CameraWidget) createPlaceholderImage() image.Image {
	img := image.NewRGBA(image.Rect(0, 0, 400, 400))
	
	for y := 0; y < 400; y++ {
		for x := 0; x < 400; x++ {
			img.Set(x, y, color.RGBA{R: 200, G: 200, B: 200, A: 255})
		}
	}
	
	for y := 180; y < 220; y++ {
		for x := 180; x < 220; x++ {
			img.Set(x, y, color.RGBA{R: 100, G: 100, B: 100, A: 255})
		}
	}
	
	return img
}

