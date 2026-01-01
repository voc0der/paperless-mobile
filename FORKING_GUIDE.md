# Guide: Forking and Building Your Own Version

This guide helps you set up your own fork of paperless-mobile with all the necessary GitHub Actions configurations.

## What Was Fixed

The TLS certificate issue (#369) was caused by an outdated Flutter version using an old BoringSSL library. The workflows have been updated to use **Flutter 3.35.4** instead of the outdated submodule version.

## Required GitHub Secrets

To build and release your own version, you need to configure these secrets in your repository.

### Quick Setup (Recommended)

**See [SECRETS_SETUP_GUIDE.md](SECRETS_SETUP_GUIDE.md) for complete instructions with automated scripts.**

**Quick start:**
```bash
# 1. Generate keystore and all secrets
./scripts/generate_keystore.sh

# 2. Set up secrets on GitHub automatically
./scripts/setup_github_secrets.sh
```

### Manual Setup

If you prefer to set up manually, you need these 7 secrets:

#### Android Signing (Required for Releases)

1. **`RELEASE_KEYSTORE`** - Your Android keystore file, encrypted with GPG and base64-encoded
2. **`RELEASE_KEYSTORE_PASSPHRASE`** - The passphrase you used for GPG encryption
3. **`KEYSTORE_KEY_ALIAS`** - The alias you used when generating the keystore
4. **`KEYSTORE_KEY_PASSWORD`** - The key password from keystore generation
5. **`KEYSTORE_STORE_PASSWORD`** - The store password from keystore generation

#### GitHub Releases

6. **`GH_ACCESS_TOKEN`** - GitHub Personal Access Token with `repo` scope
   - Create at: https://github.com/settings/tokens/new

#### Google Play Store (Optional)

7. **`PLAY_STORE_CREDENTIALS`** - Google Play Service Account JSON (only needed for Play Store publishing)

**For detailed instructions, see [SECRETS_SETUP_GUIDE.md](SECRETS_SETUP_GUIDE.md)**

## Workflow Files Updated

All these files have been updated to use Flutter 3.35.4:

- [.github/workflows/build_app.yml](.github/workflows/build_app.yml) - Manual app builds
- [.github/workflows/create_release.yml](.github/workflows/create_release.yml) - Create releases (Play Store + GitHub)
- [.github/workflows/create-github-release.yml](.github/workflows/create-github-release.yml) - GitHub-only releases
- [.github/workflows/release-deploy-play-store.yml](.github/workflows/release-deploy-play-store.yml) - Play Store deployment

## Required Changes for Your Fork

### 1. Update Repository References

In [android/fastlane/Fastfile](android/fastlane/Fastfile) line 58:

**Already updated to:** `voc0der/paperless-mobile` ✓

### 2. Update Application ID (Recommended)

To avoid conflicts with the original app, change the application ID:

**File:** `android/app/build.gradle`
```gradle
android {
    defaultConfig {
        applicationId "com.yourname.paperless_mobile"  // Change this
    }
}
```

### 3. Configure Repository Secrets

1. Go to your repository on GitHub
2. Navigate to: **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret listed above

## Building Your Own Release

### Option 1: GitHub Release Only

Run the **Create GitHub Release** workflow:
```
Actions → Create GitHub Release → Run workflow
```

This creates:
- Split APKs for each architecture (arm64-v8a, armeabi-v7a, x86_64)
- Universal APK
- GitHub release with auto-generated notes

### Option 2: Play Store + GitHub Release

Run the **Create new release** workflow:
```
Actions → Create new release → Run workflow
```

Choose track: `internal`, `alpha`, `beta`, or `production`

### Option 3: Play Store Only

Run the **Release on Play Store** workflow:
```
Actions → Release on Play Store → Run workflow
```

## Testing the Fix

After building with Flutter 3.35.4:
1. Download the APK from your GitHub release
2. Install on your device
3. Test with your nginx client certificate setup
4. The TLS error should be resolved

## Maintenance

### Updating Flutter Version

To update to a newer Flutter version in the future:

1. Update [.fvmrc](.fvmrc):
   ```json
   {
     "flutter": "3.40.0",  // New version
     "flavors": {},
     "updateGitIgnore": true
   }
   ```

2. Update all workflow files, changing:
   ```yaml
   - name: Setup Flutter
     uses: subosito/flutter-action@v2
     with:
       flutter-version: '3.40.0'  # Match .fvmrc version
   ```

## Troubleshooting

### Build Fails: "Keystore not found"
- Check that all 5 keystore secrets are set correctly
- Verify the base64 encoding of your encrypted keystore

### Build Fails: "GitHub token insufficient"
- Ensure `GH_ACCESS_TOKEN` has `repo` scope
- Token must not be expired

### APK installs but shows signature error
- You're using a different keystore than before
- Uninstall the old app first, or use a different application ID

### Flutter version mismatch
- All workflow files must use the same Flutter version
- Match the version in [.fvmrc](.fvmrc)

## Original Issue Reference

- Issue: https://github.com/astubenbord/paperless-mobile/issues/369
- Fix suggested in: https://github.com/astubenbord/paperless-mobile/issues/369#issuecomment-3693140787
- Root cause: Outdated BoringSSL in Flutter submodule
- Solution: Build with Flutter 3.35.4 or newer
