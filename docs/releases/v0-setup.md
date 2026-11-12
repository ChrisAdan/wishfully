# v0 setup: from the repository to two phones

Steps for the maintainer, in order. Every step runs in a browser; none needs a Mac. Steps 1 to 4 happen once.

## 1. Identifiers on developer.apple.com

Certificates, Identifiers & Profiles, team `LAAMNM3P5V`:

1. **App Group** (Identifiers, App Groups, +): `group.com.cambrium.wishfully`, description "Wishfully".
2. **iCloud container** (Identifiers, iCloud Containers, +): `iCloud.com.cambrium.wishfully`, description "Wishfully".
3. **App ID for the app** (Identifiers, App IDs, App): bundle ID `com.cambrium.wishfully` (explicit), description "Wishfully". Capabilities: **App Groups** and **iCloud** (choose "Include CloudKit support"). Save, then open the App ID again and use **Configure** next to each capability to select the App Group and the iCloud container from items 1 and 2.
4. **App ID for the Share extension**: bundle ID `com.cambrium.wishfully.share`, description "Wishfully Share", with the same two capabilities configured with the same App Group and container.

## 2. The app record in App Store Connect

Apps, +, New App: platform iOS, name **Wishfully** (or a variant if the name is taken), primary language English (U.S.), bundle ID `com.cambrium.wishfully`, SKU `wishfully`, full access.

## 3. Secrets on the GitHub repository

Settings, Environments, New environment: `release`. Optionally add the maintainer as a required reviewer, so each run waits for approval. Environment secrets:

| Secret | Value |
|---|---|
| `ASC_KEY_ID` | The same App Store Connect API key Sonder uses (Admin role) |
| `ASC_ISSUER_ID` | Its issuer ID |
| `ASC_KEY_P8` | The full text of its `.p8` file |
| `CLOUDKIT_MANAGEMENT_TOKEN` | A management token from the CloudKit Console (container `iCloud.com.cambrium.wishfully`, Settings, Tokens & Keys, new management token) |

## 4. The CloudKit schema

1. Run the **cloudkit-schema** workflow (Actions tab). It imports `App/CloudKit/schema.ckdb` into the Development environment and prints the result.
2. In the CloudKit Console (icloud.developer.apple.com), open the container, choose **Deploy Schema Changes**, review the three record types (Wishlist, Wish, Overlay) and deploy to Production. This is an ask-first step; the maintainer approved it with this slice.

Without the token, the record types can be created by hand in the Console's Development schema with the fields listed in `schema.ckdb`, then deployed the same way.

## 5. A TestFlight build

Run the **testflight** workflow (Actions tab, Run workflow, with a purpose), or push a commit whose message contains `[testflight]`. The run creates a certificate and profiles, archives, uploads and revokes the certificate. The build appears in App Store Connect, TestFlight, after 5 to 30 minutes of processing.

## 6. The phones

1. App Store Connect, TestFlight, Internal Testing: add the maintainer and Sabrina to a group and add the build. Internal testers are App Store Connect users on the team, so Sabrina first gets an App Store Connect invitation (Users and Access, role Customer Support or Developer). Both install TestFlight from the App Store and accept the invitation.
2. **Sabrina** opens Wishfully, creates her list, then taps **More, Share list** and sends the link to the maintainer in Messages. The default permission lets the maintainer add items.
3. **The maintainer** taps the link; Wishfully opens with Sabrina's list under "Shopping for". The maintainer imports the existing note (**More, Import from a note**) or adds items with **+**.
4. **Sabrina** adds from Safari or a store app: Share, then Wishfully in the row of apps. If Wishfully is missing from the row, scroll to the end, tap **More** and switch it on.

## Checks on the phones

| Check | Expected |
|---|---|
| Share a product page from Safari on Sabrina's phone | Title, photo and price fill in; Save adds it to her list |
| Open Wishfully on the maintainer's phone | The new wish appears within 60 seconds |
| Tick a wish on the maintainer's phone | It moves to Bought; Sabrina's phone shows no mark |
| Tap a wish, then "Open at" the store | Safari opens the product page |
| Settings on either phone | Account "Signed in", a recent "Last synced", no error |
