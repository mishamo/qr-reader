package ui

import (
	"image/color"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/theme"
)

type QRScannerTheme struct{}

func (t *QRScannerTheme) Color(name fyne.ThemeColorName, variant fyne.ThemeVariant) color.Color {
	switch name {
	case theme.ColorNamePrimary:
		return color.RGBA{R: 66, G: 133, B: 244, A: 255}
	case theme.ColorNameButton:
		return color.RGBA{R: 66, G: 133, B: 244, A: 255}
	case theme.ColorNameBackground:
		if variant == theme.VariantLight {
			return color.RGBA{R: 248, G: 249, B: 250, A: 255}
		}
		return color.RGBA{R: 32, G: 33, B: 36, A: 255}
	case theme.ColorNameForeground:
		if variant == theme.VariantLight {
			return color.RGBA{R: 32, G: 33, B: 36, A: 255}
		}
		return color.RGBA{R: 248, G: 249, B: 250, A: 255}
	default:
		return theme.DefaultTheme().Color(name, variant)
	}
}

func (t *QRScannerTheme) Font(style fyne.TextStyle) fyne.Resource {
	return theme.DefaultTheme().Font(style)
}

func (t *QRScannerTheme) Icon(name fyne.ThemeIconName) fyne.Resource {
	return theme.DefaultTheme().Icon(name)
}

func (t *QRScannerTheme) Size(name fyne.ThemeSizeName) float32 {
	switch name {
	case theme.SizeNamePadding:
		return 8
	case theme.SizeNameText:
		return 14
	default:
		return theme.DefaultTheme().Size(name)
	}
}