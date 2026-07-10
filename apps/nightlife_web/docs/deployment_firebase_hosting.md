# Firebase Hosting Deployment (Vexda Web)

This guide covers deploying the Flutter web app in `apps/nightlife_web` to Firebase Hosting for project `nightlife-app-19acd`.

Run commands from the Vexda monorepo root unless a path is shown.

## Project layout

| Path | Purpose |
|------|---------|
| `apps/nightlife_web/build/web` | Flutter web release output (Hosting `public` directory) |
| `apps/nightlife_web/firebase.json` | Hosting + SPA rewrite configuration |
| `apps/nightlife_web/.firebaserc` | Firebase project alias (`nightlife-app-19acd`) |
| `apps/nightlife_app/firestore.rules` | Canonical Firestore security rules |
| `apps/nightlife_app/storage.rules` | Canonical Storage security rules |

Security rules are referenced from `apps/nightlife_web/firebase.json` via relative paths to `../nightlife_app/`. Deploy rules from either app directory after editing the canonical files in `apps/nightlife_app/`.

## Build and deploy

Run from `apps/nightlife_web`:

```bash
flutter clean
flutter pub get
flutter build web --release --dart-define=PRIVATE_DEVELOPMENT_MODE=true
firebase deploy --only hosting
```

### Private Development Mode

While Vexda is in pre-launch, enable the temporary client-side gate so only approved Firebase Auth emails can see the app. Everyone else sees a branded holding page.

```bash
# Gate enabled (pre-launch)
flutter build web --release --dart-define=PRIVATE_DEVELOPMENT_MODE=true

# Gate disabled (public launch — default when flag omitted)
flutter build web --release --dart-define=PRIVATE_DEVELOPMENT_MODE=false
```

Approved emails are configured in `lib/core/config/development_gate_config.dart`. The list is compile-time only and can be inspected in release builds — it is a presentation convenience, not a confidential secret. Firebase Rules remain the real data security boundary.

#### Preview access for approved testers

1. Open the live holding page.
2. Click or tap the Vexda logo **five times** within about five seconds.
3. Sign in using an approved Firebase Auth account in the hidden dialog.
4. The full application loads only when the signed-in email is approved.

Signing out from the normal in-app account controls returns visitors to the holding page. Refreshing the browser preserves access while the approved Firebase session remains valid.

This gate is presentation-only — Firestore, Storage, and Auth security rules are unchanged.

### Deploy security rules (recommended before or with each release)

From `apps/nightlife_web` (rules paths resolve to `apps/nightlife_app/`):

```bash
firebase deploy --only firestore:rules,storage
```

Or from `apps/nightlife_app`:

```bash
firebase deploy --only firestore:rules,storage
```

### Full deploy (hosting + rules)

```bash
cd apps/nightlife_web
flutter build web --release
firebase deploy --only hosting,firestore:rules,storage
```

## Hosting configuration

`firebase.json` sets:

- **public**: `build/web`
- **SPA rewrite**: all routes fall back to `/index.html` for Flutter web routing
- **Cache headers**: long-lived cache for hashed JS/CSS; `index.html` is not cached

## Custom domain (vexda.co.uk)

### Firebase Console steps

1. Open [Firebase Console](https://console.firebase.google.com/) → project **nightlife-app-19acd** → **Hosting**.
2. Click **Add custom domain** and enter `vexda.co.uk` (and `www.vexda.co.uk` if needed).
3. Add the DNS records Firebase provides (A/AAAA or CNAME) at your domain registrar.
4. Wait for SSL provisioning (can take up to 24 hours).

### Firebase Auth authorized domains

1. Firebase Console → **Authentication** → **Settings** → **Authorized domains**.
2. Ensure these domains are listed:
   - `localhost` (local dev)
   - `nightlife-app-19acd.web.app` (default Hosting URL)
   - `nightlife-app-19acd.firebaseapp.com`
   - `vexda.co.uk`
   - `www.vexda.co.uk`
3. Remove any domains you no longer use.

Auth will reject sign-in redirects from domains not on this list.

## Storage CORS (required for Flutter Web map pins)

See [firebase_setup.md](./firebase_setup.md). Apply CORS for:

- `http://localhost:*`
- `https://vexda.co.uk`
- `https://www.vexda.co.uk`
- Your `*.web.app` / `*.firebaseapp.com` Hosting URLs

## Post-deploy verification

1. Open the Hosting URL and confirm the app loads.
2. Test public venue search (unauthenticated).
3. Test venue owner sign-in and dashboard writes.
4. Test admin sign-in and CRM reads.
5. Check browser console for Firestore permission errors.
6. Confirm Storage images load on venue pages and map pins.

## Rollback

```bash
firebase hosting:clone SOURCE_SITE_ID:CHANNEL_ID TARGET_SITE_ID:live
```

Or redeploy a previous `build/web` artifact from git.

## Related docs

- [firebase_security_rules.md](./firebase_security_rules.md) — rules model and collection review
- [firebase_app_check.md](./firebase_app_check.md) — App Check setup for web
