# Firebase App Check (Web)

App Check helps ensure Firestore, Storage, and Callable Functions requests come from your real app — not scripted clients or scrapers.

**Status:** Documented for setup; not yet enforced in the Flutter web client. Enabling enforcement without client integration will break production traffic.

## Recommended provider for web

Use **reCAPTCHA Enterprise** (preferred) or **reCAPTCHA v3** in Firebase Console.

| Provider | Pros | Cons |
|----------|------|------|
| reCAPTCHA Enterprise | Better fraud signal, Firebase-native | Requires Google Cloud billing / Enterprise setup |
| reCAPTCHA v3 | Simpler setup | Less granular; score-based |

## Firebase Console setup

1. Firebase Console → project **nightlife-app-19acd** → **App Check**.
2. Select the **Web** app (`1:931089492485:web:afd0dd062bf58a53d30a6c`).
3. Click **Register** and choose **reCAPTCHA Enterprise** or **reCAPTCHA v3**.
4. Create a site key in [Google Cloud Console](https://console.cloud.google.com/) if prompted.
5. Copy the **site key** — you will need it in the Flutter app.

### TODO: Site keys (fill after Console setup)

```
# reCAPTCHA Enterprise site key (web)
RECAPTCHA_ENTERPRISE_SITE_KEY=<paste from Firebase Console>

# OR reCAPTCHA v3 site key (web)
RECAPTCHA_V3_SITE_KEY=<paste from Firebase Console>
```

Add production domains to the reCAPTCHA key allowlist:

- `localhost`
- `vexda.co.uk`
- `www.vexda.co.uk`
- `nightlife-app-19acd.web.app`
- `nightlife-app-19acd.firebaseapp.com`

## Flutter web integration (when ready)

Add dependency to `nightlife_web/pubspec.yaml`:

```yaml
dependencies:
  firebase_app_check: ^0.3.2+10  # align with your firebase_core version
```

Initialize after `Firebase.initializeApp` in `lib/core/firebase/vexda_firebase.dart`:

```dart
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

// After Firebase.initializeApp succeeds:
if (kIsWeb) {
  await FirebaseAppCheck.instance.activate(
    // TODO: Replace with your site key from Firebase Console.
    webProvider: ReCaptchaEnterpriseProvider('RECAPTCHA_ENTERPRISE_SITE_KEY'),
    // Alternative:
    // webProvider: ReCaptchaV3Provider('RECAPTCHA_V3_SITE_KEY'),
  );
} else if (kDebugMode) {
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );
}
```

### Local development

- Keep App Check in **monitoring** mode in Console until the web client ships with `activate()`.
- For debug builds, use Firebase Console → App Check → **Manage debug tokens** and register tokens printed in the browser console.
- Do **not** commit debug tokens to git.

## Enforcement rollout (do not skip steps)

1. **Monitoring** — Enable App Check for Firestore, Storage, and Functions; leave enforcement off. Watch metrics for 1–2 weeks.
2. **Client release** — Ship web (and mobile) builds with App Check activated.
3. **Enforce** — Turn on enforcement per product:
   - Firestore
   - Storage
   - Cloud Functions (if used for auth-sensitive calls)

Enforcing before clients send App Check tokens will cause `permission-denied` / `unauthenticated` errors.

## Auth authorized domains

App Check is separate from Auth, but both depend on domain configuration. Ensure Auth **Authorized domains** includes all Hosting and custom domains (see [deployment_firebase_hosting.md](./deployment_firebase_hosting.md)).

## Related security docs

- [firebase_security_rules.md](./firebase_security_rules.md)
- [deployment_firebase_hosting.md](./deployment_firebase_hosting.md)
