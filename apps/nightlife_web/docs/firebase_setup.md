# Firebase Setup Notes

## Firebase Storage CORS

Flutter Web needs Firebase Storage CORS configured so venue images can be fetched as bytes for custom Google Map pins.

Normal venue images may display in HTML image elements, but marker generation needs byte access. Without CORS, map pins can fall back to initials and the browser console may show:

```
Access to fetch has been blocked by CORS policy.
No Access-Control-Allow-Origin header is present.
```

## Current Bucket

```
nightlife-app-19acd.firebasestorage.app
```

## CORS File

Create:

```
cors.json
```

With:

```json
[
  {
    "origin": [
      "http://localhost:*",
      "https://vexda.co.uk",
      "https://www.vexda.co.uk"
    ],
    "method": ["GET", "HEAD", "OPTIONS"],
    "responseHeader": ["Content-Type", "Access-Control-Allow-Origin"],
    "maxAgeSeconds": 3600
  }
]
```

## Apply CORS

Run from Google Cloud SDK command prompt:

```bash
gsutil cors set cors.json gs://nightlife-app-19acd.firebasestorage.app
```

## Verify CORS

```bash
gsutil cors get gs://nightlife-app-19acd.firebasestorage.app
```

Expected output should show the configured origins, methods and response headers.

## Notes

- This is required for Flutter Web custom map marker logos.
- Do not remove this when changing Firebase rules.
- If a new Firebase Storage bucket is created, this CORS setup must be applied again.
- This is separate from Firestore rules and Storage security rules.
- Mobile app image rendering does not rely on this same browser CORS behaviour.
