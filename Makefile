# Makefile for Custom Text Transformer IME
# This replaces the manual build.sh script with a proper build system

APP_NAME = CustomTextTransformer
BUNDLE_ID = xyz.cedwards.inputmethod.CustomTextTransformer
BUILD_DIR = build
INSTALL_DIR = $(HOME)/Library/Input Methods

# Architectures for universal binary
ARCHS = arm64 x86_64

# Build configuration
SWIFT_FLAGS = -c release -Xswiftc -suppress-warnings
FRAMEWORKS = -framework Cocoa -framework InputMethodKit
MIN_MACOS = 11.0

.PHONY: all clean install uninstall run build-arm64 build-x86_64 universal

all: universal

# Build for Apple Silicon (arm64)
build-arm64:
	@echo "🔨 Building for arm64 (Apple Silicon)..."
	@swift build $(SWIFT_FLAGS) --arch arm64

# Build for Intel (x86_64)
build-x86_64:
	@echo "🔨 Building for x86_64 (Intel)..."
	@swift build $(SWIFT_FLAGS) --arch x86_64

# Create universal binary
universal: build-arm64 build-x86_64
	@echo "🔨 Creating universal binary..."
	@rm -rf "$(BUILD_DIR)/$(APP_NAME).app"
	@mkdir -p "$(BUILD_DIR)/$(APP_NAME).app/Contents/MacOS"
	@mkdir -p "$(BUILD_DIR)/$(APP_NAME).app/Contents/Resources"

	@echo "🔗 Creating universal binary with lipo..."
	@lipo -create \
		.build/arm64-apple-macosx/release/$(APP_NAME) \
		.build/x86_64-apple-macosx/release/$(APP_NAME) \
		-output "$(BUILD_DIR)/$(APP_NAME).app/Contents/MacOS/$(APP_NAME)"

	@echo "📝 Copying Info.plist..."
	@cp Resources/Info.plist "$(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist"

	@echo "🎨 Copying resources..."
	@cp Resources/icon.tiff "$(BUILD_DIR)/$(APP_NAME).app/Contents/Resources/icon.tiff"
	@cp -r Resources/en.lproj "$(BUILD_DIR)/$(APP_NAME).app/Contents/Resources/en.lproj"

	@echo "📦 Creating PkgInfo..."
	@echo "APPL????" > "$(BUILD_DIR)/$(APP_NAME).app/Contents/PkgInfo"

	@echo "✍️  Code signing..."
	@codesign --force --deep --sign - "$(BUILD_DIR)/$(APP_NAME).app"

	@echo "✅ Universal binary build complete!"
	@echo ""
	@file "$(BUILD_DIR)/$(APP_NAME).app/Contents/MacOS/$(APP_NAME)"

# Install to system
install: universal
	@echo "📦 Installing $(APP_NAME)..."
	@killall "$(APP_NAME)" 2>/dev/null && echo "✓ Killed $(APP_NAME)" || echo "No running instances"
	@rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"
	@mkdir -p "$(INSTALL_DIR)"
	@cp -r "$(BUILD_DIR)/$(APP_NAME).app" "$(INSTALL_DIR)/"
	@echo "✅ Installation complete!"
	@echo ""
	@echo "♻️  Restarting input menu..."
	@killall TextInputMenuAgent 2>/dev/null || true
	@echo ""
	@echo "📋 Next steps:"
	@echo "  1. Go to System Settings → Keyboard → Input Sources"
	@echo "  2. Click '+' and add 'Text Transformer'"
	@echo "  3. Start using it!"

# Uninstall from system
uninstall:
	@echo "🗑️  Uninstalling $(APP_NAME)..."
	@killall "$(APP_NAME)" 2>/dev/null || true
	@rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"
	@echo "✅ Uninstalled successfully"

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf .build
	@rm -rf "$(BUILD_DIR)"
	@echo "✅ Clean complete"

# Run the app (for testing)
run: install
	@echo "🚀 Launching $(APP_NAME)..."
	@open "$(INSTALL_DIR)/$(APP_NAME).app"

# Help
help:
	@echo "Custom Text Transformer IME - Build System"
	@echo ""
	@echo "Usage:"
	@echo "  make              Build universal binary (arm64 + x86_64)"
	@echo "  make install      Build and install to ~/Library/Input Methods/"
	@echo "  make uninstall    Remove from system"
	@echo "  make clean        Remove build artifacts"
	@echo "  make run          Install and launch"
	@echo "  make help         Show this help message"
