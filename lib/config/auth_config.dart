/// Optional Web OAuth client ID from Firebase / Google Cloud Console.
///
/// Required when [google-services.json] has no `oauth_client` entries.
/// Find it in Firebase Console → Project settings → Your apps → Web app,
/// or in google-services.json under oauth_client with client_type 3.
const String kGoogleSignInWebClientId = '';

/// Debug keystore SHA-1 — add this in Firebase Console → Project settings →
/// Your Android app → Add fingerprint, then re-download google-services.json.
const String kAndroidDebugSha1 =
    'B0:57:BD:75:BE:17:44:11:D3:E7:83:78:20:05:08:1E:9D:D4:95:D1';
