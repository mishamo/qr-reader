.PHONY: deps run build-android install-android clean test

APP_ID = com.qorda.qrscanner
APP_NAME = QRScanner

deps:
	go mod download
	go mod tidy

run:
	go run main.go

build-android:
	fyne package -os android -appID $(APP_ID) -name $(APP_NAME) -release

build-android-debug:
	fyne package -os android -appID $(APP_ID) -name $(APP_NAME)

install-android:
	adb install -r $(APP_NAME).apk

install-fyne:
	go install fyne.io/fyne/v2/cmd/fyne@latest

build-ios:
	fyne package -os ios -appID $(APP_ID) -name $(APP_NAME)

test:
	go test ./...

clean:
	rm -f $(APP_NAME).apk
	rm -f $(APP_NAME).aab
	rm -rf build/

format:
	go fmt ./...
	goimports -w .

run-mobile-sim:
	go run -tags mobile main.go