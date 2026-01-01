# Quick Setup Instructions

## TL;DR - Get Building in 5 Minutes

```bash
# Step 1: Generate Android signing keystore
./scripts/generate_keystore.sh

# Step 2: Set up all secrets on GitHub
./scripts/setup_github_secrets.sh

# Step 3: Go to GitHub Actions and run "Create GitHub Release"
# That's it!
```

---

## What This Fixes

Issue #369: TLS certificate errors when using nginx client certificate authentication.

**Root cause:** Outdated Flutter version with old BoringSSL library
**Solution:** Build with Flutter 3.35.4 (includes updated BoringSSL)

---

## What Was Changed

### ✅ GitHub Actions Updated
All 4 workflow files now use **Flutter 3.35.4** instead of the git submodule:
- [build_app.yml](.github/workflows/build_app.yml)
- [create_release.yml](.github/workflows/create_release.yml)
- [create-github-release.yml](.github/workflows/create-github-release.yml)
- [release-deploy-play-store.yml](.github/workflows/release-deploy-play-store.yml)

### ✅ Repository Name Updated
- [android/fastlane/Fastfile](android/fastlane/Fastfile) line 58: `voc0der/paperless-mobile`

---

## Setup Steps

### Prerequisites

Install required tools (if not already installed):

```bash
# Ubuntu/Debian
sudo apt install default-jdk gnupg gh

# Arch Linux
sudo pacman -S jdk-openjdk gnupg github-cli

# macOS
brew install openjdk gnupg gh
```

### Step 1: Generate Keystore (2 minutes)

Run the interactive script:

```bash
./scripts/generate_keystore.sh
```

It will ask you for:
- **Key alias**: e.g., `paperless-mobile-key` (any name you want)
- **Passwords**: Choose strong passwords (write them down!)
- **Certificate info**: Name, organization, etc. (can be anything for testing)

**Output:** All secrets saved to `~/.android-signing/github-secrets.txt`

### Step 2: Set Up GitHub Secrets (2 minutes)

#### Option A: Automatic (Recommended)

```bash
./scripts/setup_github_secrets.sh
```

You'll need to provide:
1. GitHub Personal Access Token (the script will tell you how to create one)
2. (Optional) Google Play service account JSON file path

#### Option B: Manual

1. View secrets:
   ```bash
   cat ~/.android-signing/github-secrets.txt
   ```

2. Go to GitHub: **Settings** → **Secrets and variables** → **Actions**

3. Click **New repository secret** and add each one

See [SECRETS_SETUP_GUIDE.md](SECRETS_SETUP_GUIDE.md) for detailed manual instructions.

### Step 3: Build Your App (5 minutes)

1. Go to your repository on GitHub
2. Click **Actions** tab
3. Select **Create GitHub Release** workflow
4. Click **Run workflow**
5. Select branch: `development`
6. Check **Mark as draft**: ✓ (recommended for testing)
7. Click **Run workflow**

Wait ~5 minutes for the build to complete.

### Step 4: Download and Test

1. Go to **Releases** (should see a new draft release)
2. Download the APK (probably want `app-arm64-v8a-release.apk` for most phones)
3. Install on your Android device
4. Test with your nginx client certificate setup
5. The TLS error should be GONE! 🎉

---

## File Reference

| File | Purpose |
|------|---------|
| [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md) | This file - quick start guide |
| [SECRETS_SETUP_GUIDE.md](SECRETS_SETUP_GUIDE.md) | Detailed secrets setup with troubleshooting |
| [FORKING_GUIDE.md](FORKING_GUIDE.md) | Complete forking guide with all details |
| [scripts/generate_keystore.sh](scripts/generate_keystore.sh) | Automated keystore generation |
| [scripts/setup_github_secrets.sh](scripts/setup_github_secrets.sh) | Automated secrets upload |

---

## Troubleshooting

### Build fails with "keystore not found"
- Make sure you ran both scripts
- Check that all 7 secrets are set: `gh secret list`

### Build fails with "GitHub token error"
- Your `GH_ACCESS_TOKEN` needs `repo` scope
- Create new token at: https://github.com/settings/tokens/new

### Script says "command not found"
- Install missing prerequisites (see top of this file)

### APK won't install over existing app
- You're using a different keystore than the original app
- Uninstall the old app first, or change the app ID in `android/app/build.gradle`

### Still getting TLS errors after installing
- Make sure you downloaded the APK from **your build**, not the original
- Check GitHub Actions logs to verify it used Flutter 3.35.4
- Try the universal APK (`app-release.apk`) instead of split APK

---

## Advanced Options

### Change App ID (Recommended)

To install alongside the original app:

**File:** `android/app/build.gradle`

```gradle
defaultConfig {
    applicationId "com.yourname.paperless_mobile"  // Change this line
    // ... rest of config
}
```

### Publish to Play Store

1. Set up service account (see [SECRETS_SETUP_GUIDE.md](SECRETS_SETUP_GUIDE.md))
2. Add `PLAY_STORE_CREDENTIALS` secret
3. Run **Create new release** workflow instead
4. Choose track: internal/alpha/beta/production

### Update Flutter Version

To update to a newer Flutter version:

1. Edit [.fvmrc](.fvmrc):
   ```json
   {"flutter": "3.40.0"}
   ```

2. Update all workflow files:
   ```yaml
   flutter-version: '3.40.0'
   ```

---

## Security Reminder

- ✓ Keystore saved to: `~/.android-signing/`
- ✓ Secrets saved to: `~/.android-signing/github-secrets.txt`
- ⚠️ **BACKUP THESE FILES!** You need them to update your app
- ⚠️ **NEVER commit these files to git**
- ⚠️ Keep passwords safe - write them down somewhere secure

---

## Support

- **Issue #369**: https://github.com/astubenbord/paperless-mobile/issues/369
- **Original comment**: https://github.com/astubenbord/paperless-mobile/issues/369#issuecomment-3693140787
- **Flutter 3.35.4 release**: https://docs.flutter.dev/release/release-notes

---

## Quick Reference

```bash
# Generate keystore
./scripts/generate_keystore.sh

# Set up GitHub secrets
./scripts/setup_github_secrets.sh

# View secrets file
cat ~/.android-signing/github-secrets.txt

# List secrets on GitHub
gh secret list

# Check if gh is authenticated
gh auth status

# Login to gh
gh auth login

# Trigger build manually
gh workflow run "Create GitHub Release" --ref development
```

---

**You're all set!** 🚀

Go to **Actions** on GitHub and start your first build!
