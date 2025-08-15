//go:build android
// +build android

package camera

import (
	"fmt"
	"image"
	"sync"
)

// AndroidCamera provides a mock camera implementation for Android
// Real camera access requires platform-specific bindings
type AndroidCamera struct {
	mu         sync.Mutex
	isActive   bool
	onFrame    func(image.Image)
	permission bool
}

func NewCamera() Camera {
	return &AndroidCamera{
		permission: true, // Auto-grant for now
	}
}

func (c *AndroidCamera) Start(onFrame func(image.Image)) error {
	c.mu.Lock()
	defer c.mu.Unlock()

	if c.isActive {
		return fmt.Errorf("camera already active")
	}

	if !c.permission {
		return fmt.Errorf("camera permission not granted")
	}

	c.onFrame = onFrame
	c.isActive = true

	// Mock implementation - real camera requires JNI bindings
	return nil
}

func (c *AndroidCamera) Stop() error {
	c.mu.Lock()
	defer c.mu.Unlock()

	if !c.isActive {
		return nil
	}

	c.isActive = false
	return nil
}

func (c *AndroidCamera) IsActive() bool {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.isActive
}

func (c *AndroidCamera) RequestPermission() error {
	// Permissions should be handled in AndroidManifest.xml
	// and requested through the Android system
	c.permission = true
	return nil
}