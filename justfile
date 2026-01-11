# justfile for ProIME
# This replaces the Makefile with a just-based build system

app_name := "ProIME"
bundle_id := "xyz.cedwards.inputmethod.ProIME"
build_dir := "build"
install_dir := env_var('HOME') / "Library/Input Methods"

# Architectures for universal binary
archs := "arm64 x86_64"

# Build configuration
swift_flags := "-c release -Xswiftc -suppress-warnings"
frameworks := "-framework Cocoa -framework InputMethodKit"
min_macos := "12.0"

# Default recipe - build universal binary
default: universal

# Build for Apple Silicon (arm64)
build-arm64:
    @echo "🔨 Building for arm64 (Apple Silicon)..."
    @swift build {{swift_flags}} --arch arm64

# Build for Intel (x86_64)
build-x86_64:
    @echo "🔨 Building for x86_64 (Intel)..."
    @swift build {{swift_flags}} --arch x86_64

# Create universal binary
universal: build-arm64 build-x86_64
    @echo "🔨 Creating universal binary..."
    @rm -rf "{{build_dir}}/{{app_name}}.app"
    @mkdir -p "{{build_dir}}/{{app_name}}.app/Contents/MacOS"
    @mkdir -p "{{build_dir}}/{{app_name}}.app/Contents/Resources"
    @echo "🔗 Creating universal binary with lipo..."
    @lipo -create \
        .build/arm64-apple-macosx/release/{{app_name}} \
        .build/x86_64-apple-macosx/release/{{app_name}} \
        -output "{{build_dir}}/{{app_name}}.app/Contents/MacOS/{{app_name}}"
    @echo "📝 Copying Info.plist..."
    @cp Resources/Info.plist "{{build_dir}}/{{app_name}}.app/Contents/Info.plist"
    @echo "🎨 Copying resources..."
    @cp Resources/icon.tiff "{{build_dir}}/{{app_name}}.app/Contents/Resources/icon.tiff"
    @cp -r Resources/en.lproj "{{build_dir}}/{{app_name}}.app/Contents/Resources/en.lproj"
    @echo "📦 Creating PkgInfo..."
    @echo "APPL????" > "{{build_dir}}/{{app_name}}.app/Contents/PkgInfo"
    @echo "✍️  Code signing..."
    @codesign --force --deep --sign - "{{build_dir}}/{{app_name}}.app"
    @echo "✅ Universal binary build complete!"
    @echo ""
    @file "{{build_dir}}/{{app_name}}.app/Contents/MacOS/{{app_name}}"

# Install to system
install: universal
    @echo "📦 Installing {{app_name}}..."
    @killall "{{app_name}}" 2>/dev/null && echo "✓ Killed {{app_name}}" || echo "No running instances"
    @rm -rf "{{install_dir}}/{{app_name}}.app"
    @mkdir -p "{{install_dir}}"
    @cp -r "{{build_dir}}/{{app_name}}.app" "{{install_dir}}/"
    @echo "✅ Installation complete!"
    @echo ""
    @echo "♻️  Restarting input menu..."
    @killall TextInputMenuAgent 2>/dev/null || true
    @echo ""
    @echo "📋 Next steps:"
    @echo "  1. Go to System Settings → Keyboard → Input Sources"
    @echo "  2. Click '+' and add 'ProIME'"
    @echo "  3. Start using it!"

# Uninstall from system
uninstall:
    @echo "🗑️  Uninstalling {{app_name}}..."
    @killall "{{app_name}}" 2>/dev/null || true
    @rm -rf "{{install_dir}}/{{app_name}}.app"
    @echo "✅ Uninstalled successfully"

# Clean build artifacts
clean:
    @echo "🧹 Cleaning build artifacts..."
    @rm -rf .build
    @rm -rf "{{build_dir}}"
    @echo "✅ Clean complete"

# Run the app (for testing)
run: install
    @echo "🚀 Launching {{app_name}}..."
    @open "{{install_dir}}/{{app_name}}.app"

# Show this help message
help:
    @echo "ProIME - Build System"
    @echo ""
    @echo "Usage:"
    @echo "  just              Build universal binary (arm64 + x86_64)"
    @echo "  just install      Build and install to ~/Library/Input Methods/"
    @echo "  just uninstall    Remove from system"
    @echo "  just clean        Remove build artifacts"
    @echo "  just run          Install and launch"
    @echo "  just help         Show this help message"
