# OnAlert Firebase Cloud Functions

## Why you saw the error

If you run `npm install` from the **project root** (`alerts/`), npm looks for `alerts/package.json`, which does not exist.

The Node project is here:

```
alerts/firebase/functions/package.json
```

## Prerequisites (install once on your PC)

1. **Node.js 18+** — download from https://nodejs.org/ (LTS). This also installs `npm`.
2. **Firebase CLI** (after Node is installed):
   ```powershell
   npm install -g firebase-tools
   ```

Verify:

```powershell
node -v
npm -v
firebase --version
```

## Install function dependencies

From PowerShell:

```powershell
cd C:\Users\hp\Desktop\Project\alerts\firebase\functions
npm install
```

Or from the project root (after Node is installed):

```powershell
cd C:\Users\hp\Desktop\Project\alerts
npm install --prefix firebase/functions
```

## Deploy (Spark / free plan)

Cloud Functions require the Blaze plan. This project uses the **free Spark plan** — accident alerts run via the Flutter app's Realtime Database listener instead.

Deploy only rules:

```powershell
cd C:\Users\hp\Desktop\Project\alerts
firebase login
firebase use --add
firebase deploy --only firestore,database
```

The code in `index.js` is kept for reference if you upgrade to Blaze later.

## Project layout

- `firebase/functions/index.js` — sends FCM when ESP32 sets `alert: ACCIDENT_DETECTED`
- `firebase.json` (project root) — Firebase deploy config
- `firestore.rules` — Firestore security rules
- `database.rules.json` — Realtime Database rules
