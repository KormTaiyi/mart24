# Google Sign-In Setup (Google Console)

This app already has Google login/register API calls wired in Flutter.
To make Google authentication work, you must configure OAuth clients in Google Console and pass client IDs at runtime.

## 1. Use a stable app ID

Google OAuth clients are tied to package/bundle IDs.

- Android package ID: `android/app/build.gradle.kts` -> `applicationId`
- iOS bundle ID: Xcode Runner target -> `PRODUCT_BUNDLE_IDENTIFIER`

Do not keep placeholder IDs like `com.example.*` for production.

## 2. Configure OAuth consent screen

In Google Cloud Console:

1. Open **APIs & Services** -> **OAuth consent screen**.
2. Choose app type.
3. Fill required fields (app name, support email, developer email).
4. Add test users while app is still in testing mode.

## 3. Create OAuth clients

In **APIs & Services** -> **Credentials**, create:

1. **Web application** OAuth client
2. **Android** OAuth client
3. **iOS** OAuth client (if building iOS)

### Web client (required for backend token validation)

- Save its Client ID as `GOOGLE_SERVER_CLIENT_ID`.
- Alias supported in this app: `GOOGLE_WEB_CLIENT_ID`.
- Example format: `1234567890-abcxyz.apps.googleusercontent.com`

### Android client

Needs:

- Package name = your Android `applicationId`
- SHA-1 (and optionally SHA-256) fingerprints

Get SHA fingerprints:

```bash
cd android
./gradlew signingReport
```

Use the SHA values for debug and release keystores as needed.

### iOS client

Needs:

- Bundle ID = your iOS bundle identifier

Also add the reversed iOS client ID URL scheme in `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_REVERSED_IOS_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

## 4. Run/build with dart-defines

Pass OAuth client IDs to Flutter:

```bash
flutter run \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID \
  --dart-define=GOOGLE_IOS_CLIENT_ID=YOUR_IOS_CLIENT_ID
```

For Android-only development, `GOOGLE_IOS_CLIENT_ID` can be omitted.

Optional hosted-domain restriction:

```bash
--dart-define=GOOGLE_HOSTED_DOMAIN=your-company.com
```

## 5. Backend expectation

This app sends Google `idToken` (and optional `accessToken`) to:

- `/auth/google/login/client`
- `/auth/google/register/client`

Your backend must verify the `idToken` against your Google project/web client.
