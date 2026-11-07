# Release paperwork

Drafts prepared by the agent for maintainer review. The maintainer submits every answer in App Store Connect.

## Status

| When | Item | Draft | Owner | Status |
|---|---|---|---|---|
| v0 | Apple Developer Program License Agreement | | Maintainer | Open |
| v0 | App Store Connect app record | Values in the laptop checklist | Maintainer | Open |
| v0 | Export compliance | [Below](#export-compliance) | Agent drafts, maintainer confirms | Drafted |
| v0 | Privacy manifests, app and Share extension | [`PrivacyInfo-app.xcprivacy`](PrivacyInfo-app.xcprivacy), [`PrivacyInfo-share.xcprivacy`](PrivacyInfo-share.xcprivacy) | Agent drafts, maintainer reviews | Drafted |
| v0 | CloudKit schema deploy to Production | | Maintainer, ask first | Open (M3) |
| v0 | Sabrina added to internal testing | | Maintainer, ask first | Open (M4) |
| v1 | Privacy policy | [`privacy-policy.md`](privacy-policy.md) | Agent drafts, maintainer approves hosting | Drafted |
| v1 | App Privacy answers | [Below](#app-privacy-answers) | Maintainer | Drafted |
| v1 | Age rating answers | [Below](#age-rating) | Maintainer | Drafted |
| v1 | Accessibility Nutrition Labels | Decision 0015, item A10 | Maintainer | Open |
| v1 | Description, keywords, screenshots, support page, copyright line | | Agent drafts, maintainer submits | Open |
| v1 | EU trader status, or a storefront list that excludes the EU | | Maintainer | Open |
| v1 | Name check for "Wishfully" | | Maintainer | Open |

## Export compliance

The app uses encryption provided by iOS exclusively: HTTPS through `URLSession`, CloudKit transport and iOS Data Protection. That use is exempt from export documentation.

Info.plist entry for the app and the Share extension:

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

With this key present, App Store Connect skips the export compliance question on each build upload (inferred, 90%).

## Privacy manifests

Every binary declares its own manifest, so the app and the Share extension each get one. Both declare tracking off, zero tracking domains and zero collected data types.

| API category | Reason | Why | Binary |
|---|---|---|---|
| User defaults | `1C8F.1` | Settings shared between the app and the extension through the App Group | App, extension |
| User defaults | `CA92.1` | Settings read by the app alone | App |
| File timestamp | `C617.1` | Snapshot retention reads creation dates of files in the App Group container | App |

| Statement | Status |
|---|---|
| The reason codes above match Apple's published definitions | Inferred, 90%; checked against Apple's required-reason API page when the manifests move into the app targets |
| The manifests stay accurate as features land | Each slice that adds a required-reason API updates the table and the files |

## App Privacy answers

Expected answer for every data type: **Data Not Collected**.

| Statement | Status |
|---|---|
| List data lives on the phones and in each person's iCloud account, which the developer cannot read; that storage is outside the App Privacy definition of collection | Inferred, 85% |
| Diagnostics stay on the phone and leave it only when the maintainer exports them | Decision 0016 |
| Crash reports gathered by Apple from users who opt in to share analytics are outside the developer's disclosure | Inferred, 75% |

## Age rating

Expected rating: the lowest age band. Every content question is answered None or No. Product links open in Safari, outside the app, so the unrestricted web access question is answered No (inferred, 80%; the age rating questionnaire wording is confirmed at submission).
