/*
=======================================================================================================================================
API Route: well_known
=======================================================================================================================================
Method: GET (this route serves static JSON to the operating system, not JSON to the app)
Purpose: Serves the two association files that let Android and iOS open splitleague.noodev8.com/l/<code>
         links directly in the app instead of the browser. Without these files the OS has no proof that
         we own both the domain and the app, so every shared league link opens in a browser forever.
=======================================================================================================================================
Endpoints:
  GET /.well-known/assetlinks.json              - Android App Links
  GET /.well-known/apple-app-site-association   - iOS Universal Links

Request Payload: none - the operating system fetches these itself, unauthenticated

Success Response: the JSON documents below, with Content-Type: application/json
=======================================================================================================================================
Return Codes:
None. These are not app endpoints and deliberately do NOT carry return_code - the OS expects
exactly the documented shape and nothing else.
=======================================================================================================================================
Three rules that will silently break verification if broken. There is no error message anywhere
when this goes wrong - the link just quietly opens in a browser:

  1. Must be served over HTTPS with NO redirect. Android will not follow one.
  2. Must be Content-Type: application/json. The Apple file has no .json extension, so the
     type has to be set by hand - express would otherwise send it as text.
  3. Must never sit behind auth, and must never 404 for an unauthenticated fetch.
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();


// The Android app's signing certificate fingerprints
//
// BOTH are needed, and for different reasons:
//
//  - The Play app signing key is what Google re-signs the app with, so it is the certificate
//    actually present on a user's device. This is the one that matters in production. It was
//    read from the Play-signed APK pulled off a real device, not from the local keystore.
//  - The debug keystore key is what `flutter run` signs with. Without it, App Links do not
//    work on a development build and the feature looks broken while it is being built.
//
// Android accepts a list, so shipping both is normal and safe - a fingerprint only grants the
// right to handle our own links.
const ANDROID_FINGERPRINTS = [
  // Play app signing key (production - Google Play re-signs every release with this)
  '83:87:E9:71:D6:2B:7D:03:4F:D0:42:22:E7:08:DD:43:F0:64:55:08:A8:0C:87:C5:3A:6F:5A:42:97:D1:FA:4B',

  // Local debug keystore (~/.android/debug.keystore - development builds only)
  '47:2D:B6:BF:68:5D:C4:A5:00:11:A5:69:EF:31:54:34:B9:01:E2:0F:4F:08:B9:33:A1:70:8E:08:9A:3A:4A:5D'
];


// Android App Links association
//
// 'delegate_permission/common.handle_all_urls' is what grants the app the right to open our
// links. Android fetches this when the app is installed and caches the result.
const assetLinks = [
  {
    relation: ['delegate_permission/common.handle_all_urls'],
    target: {
      namespace: 'android_app',
      package_name: 'com.noodev8.splitleague',
      sha256_cert_fingerprints: ANDROID_FINGERPRINTS
    }
  }
];


// iOS Universal Links association
//
// appID is always <TeamID>.<BundleID>. The path list is restricted to /l/* on purpose: every
// other URL on this domain - the API endpoints the app itself calls over HTTPS - must keep
// going to the network layer rather than being hijacked into opening the app.
const appleAppSiteAssociation = {
  applinks: {
    apps: [],
    details: [
      {
        appID: '43A5Y7KJMA.com.noodev8.splitleague',
        paths: ['/l/*']
      }
    ]
  }
};


// GET /.well-known/assetlinks.json
router.get('/assetlinks.json', (req, res) => {
  res.type('application/json').send(JSON.stringify(assetLinks, null, 2));
});


// GET /.well-known/apple-app-site-association
//
// Served with no file extension, exactly as Apple requires. res.type is set explicitly
// because express cannot infer a type from a name with no extension.
router.get('/apple-app-site-association', (req, res) => {
  res.type('application/json').send(JSON.stringify(appleAppSiteAssociation, null, 2));
});


module.exports = router;
