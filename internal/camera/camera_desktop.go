//go:build !android && !ios
// +build !android,!ios

package camera

import (
	"fmt"
	"image"
	"image/color"
	"sync"
	"time"
)

type DesktopCamera struct {
	mu       sync.Mutex
	isActive bool
	onFrame  func(image.Image)
	stop     chan bool
}

func NewCamera() Camera {
	return &DesktopCamera{
		stop: make(chan bool, 1),
	}
}

func (c *DesktopCamera) Start(onFrame func(image.Image)) error {
	c.mu.Lock()
	defer c.mu.Unlock()

	if c.isActive {
		return fmt.Errorf("camera already active")
	}

	c.onFrame = onFrame
	c.isActive = true

	go c.generateMockFrames()

	return nil
}

func (c *DesktopCamera) Stop() error {
	c.mu.Lock()
	defer c.mu.Unlock()

	if !c.isActive {
		return nil
	}

	c.isActive = false
	c.stop <- true
	return nil
}

func (c *DesktopCamera) IsActive() bool {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.isActive
}

func (c *DesktopCamera) RequestPermission() error {
	return nil
}

func (c *DesktopCamera) generateMockFrames() {
	ticker := time.NewTicker(100 * time.Millisecond)
	defer ticker.Stop()

	frameCount := 0
	for {
		select {
		case <-c.stop:
			return
		case <-ticker.C:
			if c.onFrame != nil {
				frame := c.createMockFrame(frameCount)
				c.onFrame(frame)
				frameCount++
			}
		}
	}
}

func (c *DesktopCamera) createMockFrame(count int) image.Image {
	img := image.NewRGBA(image.Rect(0, 0, 640, 480))

	for y := 0; y < 480; y++ {
		for x := 0; x < 640; x++ {
			img.Set(x, y, color.RGBA{R: 240, G: 240, B: 240, A: 255})
		}
	}

	if count%20 < 10 {
		qrSize := 200
		qrX := 220
		qrY := 140

		for y := qrY; y < qrY+qrSize; y++ {
			for x := qrX; x < qrX+qrSize; x++ {
				if (x/10+y/10)%2 == 0 {
					img.Set(x, y, color.Black)
				} else {
					img.Set(x, y, color.White)
				}
			}
		}
	}

	return img
}