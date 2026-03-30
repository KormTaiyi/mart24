# Firebase Phone Auth Setup

This app now uses real Firebase Authentication phone auth for Android and iOS.

## 1. Enable Phone Authentication in Firebase

1. Open Firebase Console.
2. Go to Authentication > Sign-in method.
3. Enable the `Phone` provider.

Note: Firebase states that end-user phone numbers are sent to Google for spam and abuse prevention, so your production app should collect appropriate user consent before phone sign-in.

Official docs:
- Flutter setup: https://firebase.google.com/docs/flutter/setup
- Flutter phone auth: https://firebase.google.com/docs/auth/flutter/phone-auth

## 2. Configure Firebase for Flutter

Recommended:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Firebase documents that `flutterfire configure` creates `lib/firebase_options.dart` and keeps platform configuration up to date.

This repo already contains a runtime-friendly `lib/firebase_options.dart` fallback, so you can also pass values via `--dart-define` if you are not ready to run FlutterFire yet:

```bash
flutter run \
  --dart-define=FIREBASE_PROJECT_ID=your-project-id \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=your-sender-id \
  --dart-define=FIREBASE_ANDROID_API_KEY=your-android-api-key \
  --dart-define=FIREBASE_ANDROID_APP_ID=your-android-app-id \
  --dart-define=FIREBASE_IOS_API_KEY=your-ios-api-key \
  --dart-define=FIREBASE_IOS_APP_ID=your-ios-app-id \
  --dart-define=FIREBASE_IOS_BUNDLE_ID=com.example.mart24
```

If you run `flutterfire configure`, it is fine for the generated file to replace the fallback `lib/firebase_options.dart`.

Alternative native-file setup:

- iOS: add `ios/Runner/GoogleService-Info.plist` to the `Runner` target in Xcode.
- Android: add `android/app/google-services.json`.

The app bootstrap now attempts native Firebase initialization first when generated Dart options are not available.

## 3. Android Production Checklist

Firebase’s Android phone auth docs require:

1. Add your Android app to Firebase.
2. Register your app SHA-1 fingerprint in Firebase Console.
3. Register your app SHA-256 fingerprint in Firebase Console so Play Integrity can be used for app verification.

Important notes from Firebase:
- Automatic SMS verification is Android-only when the device supports automatic SMS code resolution.
- If Play Integrity cannot be used, Firebase can fall back to reCAPTCHA, which requires SHA-1 to be associated with the app.

Official doc:
- https://firebase.google.com/docs/auth/android/phone-auth

## 4. iOS Production Checklist

Firebase’s Apple-platform phone auth docs require:

1. Enable Push Notifications capability in Xcode.
2. Upload an APNs authentication key to Firebase Console > Project Settings > Cloud Messaging.
3. Enable Background Modes and check:
   - `Background fetch`
   - `Remote notifications`

This repo already enables the Info.plist background modes needed by the Firebase flow.

Important notes from Firebase:
- iOS phone auth uses silent APNs notifications for app verification.
- If silent push cannot be used, Firebase falls back to reCAPTCHA.
- Test on a real device with Background App Refresh both enabled and disabled.

Official doc:
- https://firebase.google.com/docs/auth/ios/phone-auth

## 5. Real-Device Testing

Test these paths before release:

1. Android real device with Play Services.
2. Android real device without a recently used OTP session.
3. iPhone real device with Background App Refresh enabled.
4. iPhone real device with Background App Refresh disabled.
5. Invalid phone number.
6. Incorrect OTP.
7. Expired OTP.
8. Resend OTP.
9. No internet connection.
10. Too many requests / quota handling.

## 6. Backend Session Exchange

After Firebase verification succeeds, the app will attempt to exchange the Firebase ID token with your backend using:

`POST /auth/phone/login/firebase`

If that endpoint is not ready yet, Firebase sign-in still succeeds and the app session continues locally.
