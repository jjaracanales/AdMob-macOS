#!/bin/bash
# ============================================================
# AdMob Widget - macOS Installer
# One-command installation script
# ============================================================

set -e

APP_NAME="AdMob Widget"
BUNDLE_NAME="AdMob Widget.app"
INSTALL_DIR="/Applications"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)/AdMobWidget"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     AdMob Widget - macOS Installer     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Step 1: Check macOS version
echo -e "${YELLOW}[1/5]${NC} Checking macOS version..."
MACOS_VERSION=$(sw_vers -productVersion)
MAJOR=$(echo "$MACOS_VERSION" | cut -d. -f1)
if [ "$MAJOR" -lt 14 ]; then
    echo -e "${RED}Error: macOS 14.0 (Sonoma) or later is required.${NC}"
    echo "You have macOS $MACOS_VERSION."
    exit 1
fi
echo -e "  ${GREEN}✓${NC} macOS $MACOS_VERSION"

# Step 2: Check Xcode
echo -e "${YELLOW}[2/5]${NC} Checking Xcode..."
if ! xcode-select -p &>/dev/null; then
    echo -e "${RED}Error: Xcode is not installed.${NC}"
    echo "Install it from the Mac App Store: https://apps.apple.com/app/xcode/id497799835"
    exit 1
fi
XCODE_VERSION=$(xcodebuild -version 2>/dev/null | head -1 || echo "Unknown")
echo -e "  ${GREEN}✓${NC} $XCODE_VERSION"

# Step 3: Check/install xcodegen
echo -e "${YELLOW}[3/5]${NC} Checking xcodegen..."
if ! command -v xcodegen &>/dev/null; then
    echo "  xcodegen not found. Installing via Homebrew..."
    if ! command -v brew &>/dev/null; then
        echo -e "${RED}Error: Homebrew is not installed.${NC}"
        echo "Install it first: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
    brew install xcodegen
fi
echo -e "  ${GREEN}✓${NC} xcodegen $(xcodegen --version 2>/dev/null || echo 'installed')"

# Step 4: Generate Xcode project and build
echo -e "${YELLOW}[4/5]${NC} Building app..."
cd "$PROJECT_DIR"

echo "  Generating Xcode project..."
xcodegen generate 2>/dev/null

echo "  Compiling (this may take a minute)..."
BUILD_OUTPUT=$(xcodebuild \
    -scheme AdMobWidget \
    -configuration Release \
    -derivedDataPath build \
    build 2>&1)

if echo "$BUILD_OUTPUT" | grep -q "BUILD SUCCEEDED"; then
    echo -e "  ${GREEN}✓${NC} Build succeeded"
else
    echo -e "${RED}Build failed. See output below:${NC}"
    echo "$BUILD_OUTPUT" | grep "error:" | head -10
    exit 1
fi

# Step 5: Install to /Applications
echo -e "${YELLOW}[5/5]${NC} Installing to $INSTALL_DIR..."
BUILD_APP="$PROJECT_DIR/build/Build/Products/Release/$BUNDLE_NAME"

if [ ! -d "$BUILD_APP" ]; then
    echo -e "${RED}Error: Built app not found at $BUILD_APP${NC}"
    exit 1
fi

# Remove old version if exists
if [ -d "$INSTALL_DIR/$BUNDLE_NAME" ]; then
    echo "  Removing previous version..."
    rm -rf "$INSTALL_DIR/$BUNDLE_NAME"
fi

cp -R "$BUILD_APP" "$INSTALL_DIR/"
echo -e "  ${GREEN}✓${NC} Installed to $INSTALL_DIR/$BUNDLE_NAME"

# Launch the app
echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║       Installation complete! 🎉        ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo "Launching $APP_NAME..."
open "$INSTALL_DIR/$BUNDLE_NAME"
echo ""
echo "Look for the \$ icon in your menu bar (top right)."
echo "Click it to start the setup wizard."
echo ""
echo -e "${BLUE}Need help?${NC} https://github.com/jjaracanales/widget-admob"
echo -e "${YELLOW}Like it?${NC}   https://buymeacoffee.com/jjaracanales"
echo ""
