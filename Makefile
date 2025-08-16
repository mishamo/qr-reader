.PHONY: build run test clean install-tools build-android

# Default target
all: build

# Install development tools
install-tools:
	go install fyne.io/tools/cmd/fyne@latest
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Install dependencies
deps:
	go mod download
	go mod tidy

# Build for current platform
build:
	@if [ -f .env ]; then \
		export $$(grep -v '^#' .env | grep -v '^$$' | xargs) && go build -o qr-scanner main.go; \
	else \
		go build -o qr-scanner main.go; \
	fi

# Run the application
run:
	@if [ -f .env ]; then \
		export $$(grep -v '^#' .env | grep -v '^$$' | xargs) && go run main.go; \
	else \
		echo "⚠️  No .env file found. Run ./setup_credentials.sh first!"; \
		echo ""; \
		go run main.go; \
	fi

# Run tests
test:
	go test ./...

# Run tests with coverage
test-coverage:
	go test -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out

# Format code
format:
	go fmt ./...
	gofmt -s -w .

# Lint code
lint:
	golangci-lint run

# Clean build artifacts
clean:
	rm -f qr-scanner
	rm -f QR_Scanner.apk
	rm -f coverage.out
	rm -rf apk-download

# Build Android APK (requires Android SDK/NDK)
build-android:
	fyne package --target android \
		--app-id com.mishamo.qrreader \
		--name "QR Scanner" \
		--icon Icon.png \
		--release

# Build for all platforms
build-all: build build-android

# Run on mobile simulator
run-mobile:
	go run -tags mobile main.go

# Help target
help:
	@echo "Available targets:"
	@echo "  make              - Build for current platform"
	@echo "  make run          - Run the application"
	@echo "  make test         - Run tests"
	@echo "  make build-android - Build Android APK"
	@echo "  make clean        - Clean build artifacts"
	@echo "  make install-tools - Install development tools"
	@echo "  make help         - Show this help message"