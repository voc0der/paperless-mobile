#!/usr/bin/env bash
set -e

# Script to generate Android signing keystore and prepare secrets for GitHub Actions

echo "=========================================="
echo "Android Keystore Generator"
echo "=========================================="
echo ""

# Configuration
KEYSTORE_DIR="$HOME/.android-signing"
KEYSTORE_FILE="$KEYSTORE_DIR/paperless-mobile-release.jks"
SECRETS_FILE="$KEYSTORE_DIR/github-secrets.txt"

# Create directory if it doesn't exist
mkdir -p "$KEYSTORE_DIR"

echo "This script will generate an Android keystore for signing your app."
echo "You'll need to provide some information."
echo ""

# Prompt for keystore details
read -p "Enter key alias (e.g., paperless-mobile-key): " KEY_ALIAS
read -sp "Enter keystore password (min 6 characters): " STORE_PASSWORD
echo ""
read -sp "Confirm keystore password: " STORE_PASSWORD_CONFIRM
echo ""

if [ "$STORE_PASSWORD" != "$STORE_PASSWORD_CONFIRM" ]; then
    echo "Error: Passwords don't match!"
    exit 1
fi

read -sp "Enter key password (can be same as store password): " KEY_PASSWORD
echo ""
read -sp "Confirm key password: " KEY_PASSWORD_CONFIRM
echo ""

if [ "$KEY_PASSWORD" != "$KEY_PASSWORD_CONFIRM" ]; then
    echo "Error: Passwords don't match!"
    exit 1
fi

echo ""
echo "Certificate Information (you can use fake/generic info for testing):"
read -p "Your name: " CN_NAME
read -p "Organization (e.g., Personal): " CN_ORG
read -p "City: " CN_CITY
read -p "State/Province: " CN_STATE
read -p "Country code (e.g., US): " CN_COUNTRY

echo ""
echo "Generating keystore..."

# Generate the keystore
keytool -genkeypair \
    -v \
    -keystore "$KEYSTORE_FILE" \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -alias "$KEY_ALIAS" \
    -storepass "$STORE_PASSWORD" \
    -keypass "$KEY_PASSWORD" \
    -dname "CN=$CN_NAME, OU=$CN_ORG, L=$CN_CITY, ST=$CN_STATE, C=$CN_COUNTRY"

echo ""
echo "✓ Keystore created: $KEYSTORE_FILE"
echo ""

# Now encrypt the keystore with GPG
read -sp "Enter a GPG passphrase for encrypting the keystore: " GPG_PASSPHRASE
echo ""
read -sp "Confirm GPG passphrase: " GPG_PASSPHRASE_CONFIRM
echo ""

if [ "$GPG_PASSPHRASE" != "$GPG_PASSPHRASE_CONFIRM" ]; then
    echo "Error: Passphrases don't match!"
    exit 1
fi

echo ""
echo "Encrypting keystore with GPG..."

# Encrypt the keystore
gpg --batch --yes --passphrase "$GPG_PASSPHRASE" --symmetric --cipher-algo AES256 "$KEYSTORE_FILE"

echo "✓ Encrypted keystore created: ${KEYSTORE_FILE}.gpg"
echo ""

# Convert to base64
echo "Converting to base64 for GitHub..."
ENCODED_KEYSTORE=$(cat "${KEYSTORE_FILE}.gpg" | base64 -w 0)

echo "✓ Keystore encoded"
echo ""

# Save all secrets to a file
cat > "$SECRETS_FILE" << EOF
========================================
GitHub Secrets for Repository
========================================

Copy and paste these values into your GitHub repository secrets:
Settings → Secrets and variables → Actions → New repository secret

IMPORTANT: When copying RELEASE_KEYSTORE, make sure it's all on ONE LINE!
The value below may appear wrapped in your text editor, but it must be
copied as a continuous string with NO line breaks.

Use the automated script instead: ./scripts/setup_github_secrets.sh

----------------------------------------
Secret Name: RELEASE_KEYSTORE
Secret Value:
$ENCODED_KEYSTORE
----------------------------------------

----------------------------------------
Secret Name: RELEASE_KEYSTORE_PASSPHRASE
Secret Value:
$GPG_PASSPHRASE
----------------------------------------

----------------------------------------
Secret Name: KEYSTORE_KEY_ALIAS
Secret Value:
$KEY_ALIAS
----------------------------------------

----------------------------------------
Secret Name: KEYSTORE_KEY_PASSWORD
Secret Value:
$KEY_PASSWORD
----------------------------------------

----------------------------------------
Secret Name: KEYSTORE_STORE_PASSWORD
Secret Value:
$STORE_PASSWORD
----------------------------------------

IMPORTANT: Save this file securely! You'll need these values.
The keystore files are stored in: $KEYSTORE_DIR

EOF

echo "=========================================="
echo "✓ All secrets generated!"
echo "=========================================="
echo ""
echo "Secrets have been saved to: $SECRETS_FILE"
echo ""
echo "IMPORTANT:"
echo "1. Keep the keystore file safe: $KEYSTORE_FILE"
echo "2. Keep the secrets file safe: $SECRETS_FILE"
echo "3. Never commit these files to git!"
echo "4. You'll need the same keystore to update your app in the future"
echo ""
echo "Next steps:"
echo "1. Open the secrets file: cat $SECRETS_FILE"
echo "2. Copy each secret to GitHub (see FORKING_GUIDE.md)"
echo "3. Generate your GitHub Personal Access Token (see next)"
echo ""
