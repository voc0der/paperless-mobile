# Complete Secrets Setup Guide

This guide will walk you through generating all the secrets needed to build your own version of Paperless Mobile.

## Prerequisites

- `keytool` (comes with Java JDK)
- `gpg` (GNU Privacy Guard)
- `gh` (GitHub CLI) - Optional but recommended

Install missing tools:
```bash
# Ubuntu/Debian
sudo apt install default-jdk gnupg gh

# Arch Linux
sudo pacman -S jdk-openjdk gnupg github-cli

# macOS
brew install openjdk gnupg gh
```

## Quick Setup (Automated)

### Step 1: Generate Android Keystore

Run the automated script:
```bash
cd /home/vocoder/Code/paperless-mobile
./scripts/generate_keystore.sh
```

This will:
1. Ask you for keystore details (passwords, certificate info)
2. Generate a keystore file
3. Encrypt it with GPG
4. Save all secrets to `~/.android-signing/github-secrets.txt`

**Example answers:**
- Key alias: `paperless-mobile-key`
- Keystore password: (choose a strong password)
- Key password: (can be same as keystore password)
- Your name: `Your Name` (can be anything for testing)
- Organization: `Personal`
- City/State/Country: (can be anything)

### Step 2: Set Up All Secrets on GitHub

#### Option A: Automatic (Using gh CLI)

```bash
./scripts/setup_github_secrets.sh
```

This will:
1. Read the secrets from the file generated in Step 1
2. Ask you for a GitHub Personal Access Token (see below)
3. Optionally ask for Play Store credentials
4. Upload all secrets to your GitHub repository

#### Option B: Manual

1. View your secrets:
```bash
cat ~/.android-signing/github-secrets.txt
```

2. Go to your GitHub repository:
   - Navigate to: **Settings** → **Secrets and variables** → **Actions**
   - Click **New repository secret**

3. Add each secret from the file (copy/paste the values)

## Detailed Setup (Manual)

### 1. Generate Android Keystore

If you want to do this manually instead of using the script:

```bash
# Create directory
mkdir -p ~/.android-signing
cd ~/.android-signing

# Generate keystore
keytool -genkeypair \
    -v \
    -keystore paperless-mobile-release.jks \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -alias paperless-mobile-key \
    -dname "CN=Your Name, OU=Personal, L=City, ST=State, C=US"

# It will ask for:
# - Keystore password (choose one, remember it)
# - Key password (can be same as keystore password)

# Encrypt with GPG
gpg --symmetric --cipher-algo AES256 paperless-mobile-release.jks
# Enter a passphrase when prompted

# Convert to base64
cat paperless-mobile-release.jks.gpg | base64 -w 0 > keystore.base64
```

Save these values:
- **KEYSTORE_KEY_ALIAS**: `paperless-mobile-key` (or whatever you chose)
- **KEYSTORE_STORE_PASSWORD**: The keystore password you entered
- **KEYSTORE_KEY_PASSWORD**: The key password you entered
- **RELEASE_KEYSTORE_PASSPHRASE**: The GPG passphrase you entered
- **RELEASE_KEYSTORE**: The contents of `keystore.base64` file

### 2. Generate GitHub Personal Access Token

1. Go to: https://github.com/settings/tokens/new

2. Configure the token:
   - **Note**: `Paperless Mobile Release`
   - **Expiration**: 90 days (or longer)
   - **Scopes**: Check **`repo`** (Full control of private repositories)

3. Click **Generate token**

4. **COPY THE TOKEN IMMEDIATELY** - you won't see it again!

5. Save as secret:
   - **Name**: `GH_ACCESS_TOKEN`
   - **Value**: The token you just copied

### 3. Google Play Store Credentials (Optional)

Only needed if you want to publish to Play Store.

#### Create Service Account

1. Go to [Google Play Console](https://play.google.com/console)

2. Select your app (or create a new one)

3. Go to: **Setup** → **API access**

4. Click **Create new service account**:
   - Follow the link to Google Cloud Console
   - Click **Create Service Account**
   - Name: `Paperless Mobile CI`
   - Click **Create and Continue**
   - Role: Select **Service Accounts** → **Service Account User**
   - Click **Done**

5. Create JSON key:
   - Click on the service account you just created
   - Go to **Keys** tab
   - Click **Add Key** → **Create new key**
   - Choose **JSON**
   - Click **Create** (downloads a JSON file)

6. Grant permissions in Play Console:
   - Go back to Play Console → API access
   - Find your service account
   - Click **Grant access**
   - Under **App permissions**, select your app
   - Under **Account permissions**:
     - Check **View app information and download bulk reports**
     - Check **Create and edit draft releases**
     - Check **Release to production, exclude devices, and use Play App Signing**
   - Click **Invite user** → **Send invite**

7. Save the JSON file contents as:
   - **Name**: `PLAY_STORE_CREDENTIALS`
   - **Value**: Entire contents of the JSON file

## Setting Secrets on GitHub

### Using GitHub CLI (Recommended)

```bash
# Set a secret
echo "secret-value" | gh secret set SECRET_NAME

# Example:
echo "my-key-alias" | gh secret set KEYSTORE_KEY_ALIAS

# Or from file:
gh secret set PLAY_STORE_CREDENTIALS < service-account.json

# List all secrets
gh secret list
```

### Using GitHub Web UI

1. Go to your repository on GitHub

2. Click **Settings** → **Secrets and variables** → **Actions**

3. Click **New repository secret**

4. Enter **Name** and **Value**

5. Click **Add secret**

6. Repeat for each secret

## Required Secrets Summary

| Secret Name | Description | How to Get |
|-------------|-------------|------------|
| `RELEASE_KEYSTORE` | Base64-encoded encrypted keystore | Run `./scripts/generate_keystore.sh` |
| `RELEASE_KEYSTORE_PASSPHRASE` | GPG passphrase for keystore | Run `./scripts/generate_keystore.sh` |
| `KEYSTORE_KEY_ALIAS` | Keystore key alias | Run `./scripts/generate_keystore.sh` |
| `KEYSTORE_KEY_PASSWORD` | Key password | Run `./scripts/generate_keystore.sh` |
| `KEYSTORE_STORE_PASSWORD` | Keystore password | Run `./scripts/generate_keystore.sh` |
| `GH_ACCESS_TOKEN` | GitHub Personal Access Token | https://github.com/settings/tokens/new |
| `PLAY_STORE_CREDENTIALS` | Service account JSON (optional) | Google Play Console → API access |

## Verifying Setup

Check that all secrets are set:

```bash
gh secret list
```

You should see:
```
RELEASE_KEYSTORE                   Updated YYYY-MM-DD
RELEASE_KEYSTORE_PASSPHRASE        Updated YYYY-MM-DD
KEYSTORE_KEY_ALIAS                 Updated YYYY-MM-DD
KEYSTORE_KEY_PASSWORD              Updated YYYY-MM-DD
KEYSTORE_STORE_PASSWORD            Updated YYYY-MM-DD
GH_ACCESS_TOKEN                    Updated YYYY-MM-DD
PLAY_STORE_CREDENTIALS             Updated YYYY-MM-DD (if set)
```

## Testing Your Setup

Run a test build:

1. Go to your repository on GitHub
2. Click **Actions**
3. Select **Create GitHub Release**
4. Click **Run workflow**
5. Choose branch: `development`
6. Check **Mark as draft**: `true`
7. Click **Run workflow**

The build should complete successfully and create a draft release with APK files.

## Troubleshooting

### "keytool: command not found"
Install Java JDK:
```bash
sudo apt install default-jdk     # Ubuntu/Debian
sudo pacman -S jdk-openjdk       # Arch
brew install openjdk             # macOS
```

### "gpg: command not found"
Install GPG:
```bash
sudo apt install gnupg           # Ubuntu/Debian
sudo pacman -S gnupg             # Arch
brew install gnupg               # macOS
```

### "gh: command not found"
Install GitHub CLI:
```bash
sudo apt install gh              # Ubuntu/Debian
sudo pacman -S github-cli        # Arch
brew install gh                  # macOS
```

Or use manual setup instead.

### "Error decrypting keystore" in GitHub Actions
- Double-check `RELEASE_KEYSTORE_PASSPHRASE` matches what you used with GPG
- Make sure `RELEASE_KEYSTORE` is the complete base64 string (no line breaks)

### "Could not find keystore"
- Verify all 5 keystore-related secrets are set correctly
- Check that `KEYSTORE_KEY_ALIAS` matches what you used when generating

## Security Notes

- **Keep your keystore file safe!** Store it in a secure location
- **Keep the secrets file safe!** It contains sensitive passwords
- **Never commit** keystore files or secrets to git
- **Backup your keystore!** You need the same one to update your app
- The keystore is stored in: `~/.android-signing/`
- The secrets file is: `~/.android-signing/github-secrets.txt`

## Next Steps

After setting up secrets:

1. Update the repository name in [android/fastlane/Fastfile](android/fastlane/Fastfile) (already done: `voc0der/paperless-mobile`)
2. Optionally change the app ID in `android/app/build.gradle`
3. Run a test build via GitHub Actions
4. Install the APK and test the TLS certificate fix

See [FORKING_GUIDE.md](FORKING_GUIDE.md) for more information.
