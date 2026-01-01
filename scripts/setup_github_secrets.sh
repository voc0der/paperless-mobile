#!/usr/bin/env bash
set -e

# Script to set up all GitHub secrets automatically using gh CLI

echo "=========================================="
echo "GitHub Secrets Setup Script"
echo "=========================================="
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed."
    echo ""
    echo "Install it first:"
    echo "  Ubuntu/Debian: sudo apt install gh"
    echo "  Arch: sudo pacman -S github-cli"
    echo "  macOS: brew install gh"
    echo ""
    echo "Or visit: https://cli.github.com/"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo "You need to authenticate with GitHub first."
    echo "Running: gh auth login"
    echo ""
    gh auth login
fi

echo ""
echo "This script will help you set up all required GitHub secrets."
echo ""

# Get repository info
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")

if [ -z "$REPO" ]; then
    echo "Error: Could not detect repository. Are you in the git directory?"
    exit 1
fi

echo "Repository detected: $REPO"
echo ""

# Check if secrets file exists
SECRETS_FILE="$HOME/.android-signing/github-secrets.txt"

if [ ! -f "$SECRETS_FILE" ]; then
    echo "Error: Secrets file not found: $SECRETS_FILE"
    echo ""
    echo "Please run ./scripts/generate_keystore.sh first to generate your Android keystore."
    exit 1
fi

echo "Found secrets file: $SECRETS_FILE"
echo ""

# Parse the secrets file
echo "Reading keystore secrets from file..."

# Extract values (this is a bit hacky but works)
RELEASE_KEYSTORE=$(sed -n '/^Secret Name: RELEASE_KEYSTORE$/,/^----------------------------------------$/p' "$SECRETS_FILE" | sed '1,2d;$d' | tr -d '\n')
RELEASE_KEYSTORE_PASSPHRASE=$(sed -n '/^Secret Name: RELEASE_KEYSTORE_PASSPHRASE$/,/^----------------------------------------$/p' "$SECRETS_FILE" | sed '1,2d;$d' | tr -d '\n')
KEYSTORE_KEY_ALIAS=$(sed -n '/^Secret Name: KEYSTORE_KEY_ALIAS$/,/^----------------------------------------$/p' "$SECRETS_FILE" | sed '1,2d;$d' | tr -d '\n')
KEYSTORE_KEY_PASSWORD=$(sed -n '/^Secret Name: KEYSTORE_KEY_PASSWORD$/,/^----------------------------------------$/p' "$SECRETS_FILE" | sed '1,2d;$d' | tr -d '\n')
KEYSTORE_STORE_PASSWORD=$(sed -n '/^Secret Name: KEYSTORE_STORE_PASSWORD$/,/^----------------------------------------$/p' "$SECRETS_FILE" | sed '1,2d;$d' | tr -d '\n')

# Now we need the GitHub Personal Access Token
echo ""
echo "=========================================="
echo "GitHub Personal Access Token"
echo "=========================================="
echo ""
echo "You need a Personal Access Token (PAT) with 'repo' scope."
echo ""
echo "To create one:"
echo "1. Visit: https://github.com/settings/tokens/new"
echo "2. Give it a name: 'Paperless Mobile Release'"
echo "3. Set expiration: 90 days (or longer)"
echo "4. Check the 'repo' scope (full control of private repositories)"
echo "5. Click 'Generate token'"
echo "6. Copy the token (you won't see it again!)"
echo ""
read -sp "Paste your GitHub Personal Access Token: " GH_ACCESS_TOKEN
echo ""

if [ -z "$GH_ACCESS_TOKEN" ]; then
    echo "Error: Token cannot be empty"
    exit 1
fi

# Optional: Play Store credentials
echo ""
echo "=========================================="
echo "Google Play Store Credentials (Optional)"
echo "=========================================="
echo ""
echo "Do you want to publish to Google Play Store?"
read -p "Enter 'yes' to set up Play Store credentials, or press Enter to skip: " SETUP_PLAYSTORE

PLAY_STORE_CREDENTIALS=""
if [ "$SETUP_PLAYSTORE" = "yes" ]; then
    echo ""
    echo "You need a Google Play Service Account JSON file."
    echo ""
    echo "To create one:"
    echo "1. Go to: https://play.google.com/console"
    echo "2. Select your app (or create one)"
    echo "3. Go to: Setup → API access"
    echo "4. Create a service account or use existing"
    echo "5. Grant permissions: 'Admin' (or at least 'Release Manager')"
    echo "6. Download the JSON key file"
    echo ""
    read -p "Enter the path to your service account JSON file: " JSON_PATH

    if [ -f "$JSON_PATH" ]; then
        PLAY_STORE_CREDENTIALS=$(cat "$JSON_PATH")
        echo "✓ Play Store credentials loaded"
    else
        echo "Warning: File not found. Skipping Play Store credentials."
    fi
fi

# Now set all the secrets
echo ""
echo "=========================================="
echo "Setting Secrets on GitHub"
echo "=========================================="
echo ""

echo "Setting RELEASE_KEYSTORE..."
echo "$RELEASE_KEYSTORE" | gh secret set RELEASE_KEYSTORE -R "$REPO"

echo "Setting RELEASE_KEYSTORE_PASSPHRASE..."
echo "$RELEASE_KEYSTORE_PASSPHRASE" | gh secret set RELEASE_KEYSTORE_PASSPHRASE -R "$REPO"

echo "Setting KEYSTORE_KEY_ALIAS..."
echo "$KEYSTORE_KEY_ALIAS" | gh secret set KEYSTORE_KEY_ALIAS -R "$REPO"

echo "Setting KEYSTORE_KEY_PASSWORD..."
echo "$KEYSTORE_KEY_PASSWORD" | gh secret set KEYSTORE_KEY_PASSWORD -R "$REPO"

echo "Setting KEYSTORE_STORE_PASSWORD..."
echo "$KEYSTORE_STORE_PASSWORD" | gh secret set KEYSTORE_STORE_PASSWORD -R "$REPO"

echo "Setting GH_ACCESS_TOKEN..."
echo "$GH_ACCESS_TOKEN" | gh secret set GH_ACCESS_TOKEN -R "$REPO"

if [ -n "$PLAY_STORE_CREDENTIALS" ]; then
    echo "Setting PLAY_STORE_CREDENTIALS..."
    echo "$PLAY_STORE_CREDENTIALS" | gh secret set PLAY_STORE_CREDENTIALS -R "$REPO"
fi

echo ""
echo "=========================================="
echo "✓ All secrets set successfully!"
echo "=========================================="
echo ""
echo "Secrets configured:"
echo "  ✓ RELEASE_KEYSTORE"
echo "  ✓ RELEASE_KEYSTORE_PASSPHRASE"
echo "  ✓ KEYSTORE_KEY_ALIAS"
echo "  ✓ KEYSTORE_KEY_PASSWORD"
echo "  ✓ KEYSTORE_STORE_PASSWORD"
echo "  ✓ GH_ACCESS_TOKEN"
if [ -n "$PLAY_STORE_CREDENTIALS" ]; then
    echo "  ✓ PLAY_STORE_CREDENTIALS"
fi
echo ""
echo "You can now run GitHub Actions workflows to build and release your app!"
echo ""
echo "To verify secrets were set:"
echo "  gh secret list -R $REPO"
echo ""
