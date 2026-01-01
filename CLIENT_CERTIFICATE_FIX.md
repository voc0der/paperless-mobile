# Client Certificate Compatibility Fix for Flutter 3.35.4

## Problem

The new BoringSSL library in Flutter 3.35.4 is stricter about PKCS12 certificate formats. Older certificates may use encryption algorithms that are no longer supported by default.

## Error Message

```
Invalid argument(s): Expected private key, but none was found
```

## Solution: Re-export Your Certificate

You need to re-export your client certificate in a format compatible with the new BoringSSL.

### Option 1: Use Legacy PKCS12 Format (Recommended)

```bash
# If you have separate cert and key files:
openssl pkcs12 -export \
  -legacy \
  -in your-cert.crt \
  -inkey your-key.key \
  -out client-cert-new.pfx \
  -name "paperless-client"

# If you have an existing .pfx file to re-export:
openssl pkcs12 -in old-cert.pfx -out temp.pem -nodes
openssl pkcs12 -export -legacy -in temp.pem -out client-cert-new.pfx -name "paperless-client"
rm temp.pem  # Clean up temporary file
```

The `-legacy` flag tells OpenSSL to use older, more widely compatible encryption algorithms (3DES instead of AES-256).

### Option 2: Use Modern Format with Compatible Cipher

```bash
# Export with explicit cipher that BoringSSL supports
openssl pkcs12 -export \
  -in your-cert.crt \
  -inkey your-key.key \
  -out client-cert-new.pfx \
  -name "paperless-client" \
  -keypbe PBE-SHA1-3DES \
  -certpbe PBE-SHA1-3DES \
  -macalg SHA1
```

### After Re-exporting

1. In the Paperless Mobile app, go to Settings → Account
2. Remove the old client certificate
3. Import the new `client-cert-new.pfx` file
4. Enter the passphrase you used during export
5. Try connecting again

## Why This Happens

BoringSSL (Google's fork of OpenSSL used in Flutter/Dart) has deprecated support for certain older PKCS12 encryption algorithms. Modern OpenSSL versions default to algorithms that BoringSSL doesn't support well.

The `-legacy` flag makes OpenSSL use the older 3DES encryption which is universally supported, even though it's technically less secure than AES-256. For client certificates, this is usually acceptable.

## Sources

- [Dart SDK Issue #54719 - PKCS12 Parsing](https://github.com/dart-lang/sdk/issues/54719)
- [Flutter SDK SecurityContext Documentation](https://api.flutter.dev/flutter/dart-io/SecurityContext-class.html)

