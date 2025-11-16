#!/bin/bash

# CountScore - Screenshot Capture Helper Script
#
# This script automates screenshot capture via ADB for Play Store listing.
#
# Prerequisites:
# - Android device connected via USB (or emulator running)
# - ADB installed and in PATH
# - USB debugging enabled on device
# - CountScore app installed and populated with test data
#
# Usage:
#   chmod +x scripts/capture_screenshots.sh
#   ./scripts/capture_screenshots.sh

set -e  # Exit on error

echo "========================================="
echo "CountScore Screenshot Capture Tool"
echo "========================================="
echo ""

# Configuration
SCREENSHOT_DIR="store_listing/assets/screenshots/phone"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TEMP_DIR="/tmp/countscore_screenshots_$TIMESTAMP"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if ADB is installed
if ! command -v adb &> /dev/null; then
    echo -e "${RED}❌ ERROR: ADB not found${NC}"
    echo "Please install Android SDK Platform Tools"
    echo "https://developer.android.com/tools/releases/platform-tools"
    exit 1
fi

# Check if device is connected
echo "Checking for connected devices..."
DEVICE_COUNT=$(adb devices | grep -v "List" | grep "device" | wc -l)

if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo -e "${RED}❌ ERROR: No Android device connected${NC}"
    echo ""
    echo "Please:"
    echo "1. Connect your Android device via USB, OR"
    echo "2. Start an Android emulator"
    echo "3. Enable USB debugging on your device"
    echo "4. Run 'adb devices' to verify connection"
    exit 1
fi

if [ "$DEVICE_COUNT" -gt 1 ]; then
    echo -e "${YELLOW}⚠️  WARNING: Multiple devices connected${NC}"
    echo "Connected devices:"
    adb devices | grep "device$"
    echo ""
    echo "This script will use the first device."
    echo "To specify a device, use: adb -s DEVICE_ID"
    echo ""
    read -p "Continue? (y/n): " confirm
    echo ""
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

DEVICE_MODEL=$(adb shell getprop ro.product.model | tr -d '\r')
echo -e "${GREEN}✓ Connected to: $DEVICE_MODEL${NC}"
echo ""

# Create directories
mkdir -p "$SCREENSHOT_DIR"
mkdir -p "$TEMP_DIR"

# Screenshot list
declare -a SCREENSHOTS=(
    "01_main_screen|Main Score Tracking Screen|Show active game with 3-4 players and scores"
    "02_player_management|Player Management|Show player list or add player dialog"
    "03_game_types|Game Type Selection|Show game types (ZapZap, Uno, Scrabble, custom)"
    "04_game_history|Game History|Show past games list with dates and results"
    "05_game_board|Game Board View (Optional)|Full game board during play"
    "06_customization|Customization (Optional)|Settings or game type customization"
    "07_score_entry|Score Entry (Optional)|Score input interface"
    "08_statistics|Statistics (Optional)|Player stats or analytics"
)

echo "========================================="
echo "Screenshot Capture Instructions"
echo "========================================="
echo ""
echo "You will be prompted to capture ${#SCREENSHOTS[@]} screenshots."
echo "For each screenshot:"
echo "  1. Navigate to the specified screen in CountScore"
echo "  2. Ensure the screen looks good (clean UI, realistic data)"
echo "  3. Press ENTER to capture"
echo "  4. Review the captured screenshot"
echo "  5. Choose to keep or retake"
echo ""
echo -e "${YELLOW}TIP: Keep CountScore app open and ready!${NC}"
echo ""
read -p "Press ENTER to start capturing screenshots..."
echo ""

# Capture function
capture_screenshot() {
    local filename=$1
    local title=$2
    local description=$3
    local temp_file="$TEMP_DIR/${filename}.png"
    local final_file="$SCREENSHOT_DIR/${filename}.png"

    while true; do
        echo "========================================="
        echo -e "${BLUE}📸 Screenshot: $title${NC}"
        echo "========================================="
        echo ""
        echo "Description: $description"
        echo ""
        echo "Steps:"
        echo "  1. Navigate to this screen in CountScore"
        echo "  2. Check that UI looks clean and professional"
        echo "  3. Press ENTER when ready to capture"
        echo ""
        read -p "Ready? Press ENTER to capture (or 's' to skip): " -r
        echo ""

        if [[ $REPLY =~ ^[Ss]$ ]]; then
            echo -e "${YELLOW}⏭️  Skipped $filename${NC}"
            echo ""
            return
        fi

        # Capture screenshot
        echo "Capturing..."
        adb exec-out screencap -p > "$temp_file"

        if [ $? -eq 0 ] && [ -f "$temp_file" ]; then
            FILE_SIZE=$(ls -lh "$temp_file" | awk '{print $5}')
            echo -e "${GREEN}✓ Captured successfully ($FILE_SIZE)${NC}"
            echo "Temporary file: $temp_file"
            echo ""

            # Show file info
            if command -v file &> /dev/null; then
                file "$temp_file" | grep -o "[0-9]* x [0-9]*" || echo "Image format: PNG"
            fi

            echo ""
            echo "Options:"
            echo "  [k] Keep this screenshot"
            echo "  [r] Retake screenshot"
            echo "  [v] View screenshot (if viewer available)"
            echo "  [s] Skip this screenshot"
            echo ""
            read -p "Choose option [k/r/v/s]: " choice
            echo ""

            case $choice in
                [Kk])
                    mv "$temp_file" "$final_file"
                    echo -e "${GREEN}✅ Saved as: $final_file${NC}"
                    echo ""
                    return
                    ;;
                [Rr])
                    echo "Retaking screenshot..."
                    echo ""
                    continue
                    ;;
                [Vv])
                    if command -v xdg-open &> /dev/null; then
                        xdg-open "$temp_file" &
                        echo "Opening screenshot viewer..."
                        echo ""
                        continue
                    else
                        echo "No image viewer found. Continuing..."
                        continue
                    fi
                    ;;
                [Ss])
                    rm -f "$temp_file"
                    echo -e "${YELLOW}⏭️  Skipped $filename${NC}"
                    echo ""
                    return
                    ;;
                *)
                    echo "Invalid option. Retaking screenshot..."
                    echo ""
                    continue
                    ;;
            esac
        else
            echo -e "${RED}❌ ERROR: Failed to capture screenshot${NC}"
            echo "Retrying..."
            echo ""
            continue
        fi
    done
}

# Capture all screenshots
CAPTURED_COUNT=0
for screenshot in "${SCREENSHOTS[@]}"; do
    IFS='|' read -r filename title description <<< "$screenshot"
    capture_screenshot "$filename" "$title" "$description"
    if [ -f "$SCREENSHOT_DIR/${filename}.png" ]; then
        CAPTURED_COUNT=$((CAPTURED_COUNT + 1))
    fi
done

# Cleanup temp directory
rm -rf "$TEMP_DIR"

# Summary
echo ""
echo "========================================="
echo "Capture Complete!"
echo "========================================="
echo ""
echo -e "${GREEN}✓ Captured: $CAPTURED_COUNT / ${#SCREENSHOTS[@]} screenshots${NC}"
echo ""

if [ "$CAPTURED_COUNT" -lt 2 ]; then
    echo -e "${RED}⚠️  WARNING: Google Play Store requires minimum 2 screenshots${NC}"
    echo "You have captured: $CAPTURED_COUNT"
    echo "Please capture at least 2 screenshots."
    echo ""
fi

if [ "$CAPTURED_COUNT" -ge 2 ] && [ "$CAPTURED_COUNT" -lt 4 ]; then
    echo -e "${YELLOW}💡 TIP: 4-8 screenshots recommended for best results${NC}"
    echo "Current count: $CAPTURED_COUNT"
    echo ""
fi

# List captured screenshots
if [ "$CAPTURED_COUNT" -gt 0 ]; then
    echo "Captured screenshots:"
    ls -lh "$SCREENSHOT_DIR"/*.png 2>/dev/null || echo "No screenshots found"
    echo ""
fi

# Next steps
echo "========================================="
echo "Next Steps"
echo "========================================="
echo ""
echo "1. Review screenshots:"
echo "   cd $SCREENSHOT_DIR && ls -lh"
echo ""
echo "2. Optional: Enhance screenshots"
echo "   - Add device frames"
echo "   - Add text overlays"
echo "   - See: store_listing/SCREENSHOT_GUIDE.md"
echo ""
echo "3. Verify requirements:"
echo "   - Minimum 2 screenshots: $([ $CAPTURED_COUNT -ge 2 ] && echo '✓' || echo '✗')"
echo "   - Recommended 4-8: $([ $CAPTURED_COUNT -ge 4 ] && echo '✓' || echo '○')"
echo "   - File size < 8MB each: (check manually)"
echo "   - Format PNG or JPEG: ✓"
echo ""
echo "4. Upload to Play Console"
echo "   Store presence > Main store listing > Phone screenshots"
echo ""
echo -e "${GREEN}Happy publishing! 🚀${NC}"
