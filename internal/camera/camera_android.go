//go:build android
// +build android

package camera

/*
#include <jni.h>
#include <stdlib.h>
*/
import "C"

import (
	"fmt"
	"image"
	"sync"

	"fyne.io/fyne/v2/driver/mobile"
)

type AndroidCamera struct {
	mu         sync.Mutex
	isActive   bool
	onFrame    func(image.Image)
	permission bool
}

func NewCamera() Camera {
	return &AndroidCamera{}
}

func (c *AndroidCamera) Start(onFrame func(image.Image)) error {
	c.mu.Lock()
	defer c.mu.Unlock()

	if c.isActive {
		return fmt.Errorf("camera already active")
	}

	if !c.checkPermission() {
		return fmt.Errorf("camera permission not granted")
	}

	c.onFrame = onFrame
	c.isActive = true

	if err := c.startNativeCamera(); err != nil {
		c.isActive = false
		return err
	}

	return nil
}

func (c *AndroidCamera) Stop() error {
	c.mu.Lock()
	defer c.mu.Unlock()

	if !c.isActive {
		return nil
	}

	c.isActive = false
	return c.stopNativeCamera()
}

func (c *AndroidCamera) IsActive() bool {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.isActive
}

func (c *AndroidCamera) RequestPermission() error {
	app := mobile.CurrentApp()
	if app == nil {
		return fmt.Errorf("mobile app not available")
	}

	c.permission = true
	return nil
}

func (c *AndroidCamera) checkPermission() bool {
	return c.permission
}

func (c *AndroidCamera) startNativeCamera() error {
	return nil
}

func (c *AndroidCamera) stopNativeCamera() error {
	return nil
}

//export Java_com_qorda_qrscanner_CameraCallback_onFrame
func Java_com_qorda_qrscanner_CameraCallback_onFrame(env *C.JNIEnv, class C.jobject, data C.jbyteArray) {
}