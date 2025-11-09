#!/bin/bash

# CountScore - Upload Keystore Generation Script
#
# This script generates a secure upload keystore for signing your Android app.
#
# CRITICAL SECURITY WARNINGS:
# 1. Run this script ONCE and store the keystore securely
# 2. NEVER commit the keystore or key.properties to version control
# 3. BACKUP the keystore file - losing it means you can't update your app
# 4. Store passwords securely (password manager recommended)
#
# Official Documentation:
# https://docs.flutter.dev/deployment/android#signing-the-app

set -e  # Exit on error

echo "========================================="
echo "CountScore Upload Keystore Generator"
echo "========================================="
echo ""

# Configuration
KEYSTORE_DIR="$HOME"
KEYSTORE_FILE="$KEYSTORE_DIR/countscore-upload-keystore.jks"
KEY_ALIAS="countscore-upload"
KEY_VALIDITY_DAYS=10000  # ~27 years

# Check if keystore already exists
if [ -f "$KEYSTORE_FILE" ]; then
    echo "⚠️  ERROR: Keystore already exists at: $KEYSTORE_FILE"
    echo ""
    echo "If you want to create a new keystore:"
    echo "1. Backup the existing keystore first"
    echo "2. Delete or rename the existing keystore"
    echo "3. Run this script again"
    echo ""
    echo "WARNING: Creating a new keystore means you cannot update your"
    echo "existing app on Play Store. You would need to publish as new app."
    exit 1
fi

# Verify keytool is available
if ! command -v keytool &> /dev/null; then
    echo "❌ ERROR: keytool not found"
    echo "Please install Java JDK (Java 11 or later recommended)"
    exit 1
fi

echo "This script will create an upload keystore for signing your Android app."
echo ""
echo "You will be prompted for:"
echo "  - Password for the keystore (store password)"
echo "  - Password for the key (key password)"
echo "  - Your name and organization information"
echo ""
echo "⚠️  IMPORTANT: Remember these passwords!"
echo "   Store them securely in a password manager."
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."
echo ""

# Generate the keystore
echo "Generating keystore..."
echo ""
echo "Enter the following information when prompted:"
echo "(You can use the same password for both store and key for simplicity)"
echo ""

keytool -genkey -v \
    -keystore "$KEYSTORE_FILE" \
    -storetype JKS \
    -keyalg RSA \
    -keysize 2048 \
    -validity $KEY_VALIDITY_DAYS \
    -alias "$KEY_ALIAS"

# Check if generation was successful
if [ $? -eq 0 ]; then
    echo ""
    echo "========================================="
    echo "✅ Keystore created successfully!"
    echo "========================================="
    echo ""
    echo "Keystore location: $KEYSTORE_FILE"
    echo "Key alias: $KEY_ALIAS"
    echo ""
    echo "NEXT STEPS:"
    echo ""
    echo "1. 🔐 BACKUP THIS KEYSTORE FILE SECURELY"
    echo "   Location: $KEYSTORE_FILE"
    echo "   Recommended: Store in multiple secure locations"
    echo "   (Password manager, encrypted cloud storage, encrypted USB)"
    echo ""
    echo "2. 📝 Create key.properties file:"
    echo "   Location: android/key.properties"
    echo "   Template provided in: android/key.properties.template"
    echo ""
    echo "3. ⚠️  Add to .gitignore:"
    echo "   - android/key.properties"
    echo "   - *.jks"
    echo "   - *.keystore"
    echo ""
    echo "4. 🔧 Update android/app/build.gradle.kts"
    echo "   Follow instructions in PUBLISHING.md"
    echo ""
    echo "⚠️  CRITICAL REMINDER:"
    echo "If you lose this keystore, you CANNOT update your app on Play Store."
    echo "You would have to publish it as a completely new application."
    echo ""
else
    echo ""
    echo "❌ Keystore generation failed"
    echo "Please check the errors above and try again"
    exit 1
fi
