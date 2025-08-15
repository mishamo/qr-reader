package camera

import "image"

type Camera interface {
	Start(onFrame func(image.Image)) error
	Stop() error
	IsActive() bool
	RequestPermission() error
}