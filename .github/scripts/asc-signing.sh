#!/usr/bin/env bash
# Signing for the TestFlight workflow, through the App Store Connect API (decision 0018).
#
#   asc-signing.sh setup    creates a distribution certificate and App Store profiles for this run
#   asc-signing.sh cleanup  revokes that certificate and deletes the profiles
#
# The maintainer works without a Mac, so certificates never leave CI: each run makes its own and
# revokes it at the end. Revoking a distribution certificate leaves builds already uploaded to
# App Store Connect valid. The bundle IDs, App Group and iCloud container are registered once by
# hand on developer.apple.com, because the API cannot assign containers to an identifier.
#
# Environment: ASC_KEY_ID, ASC_ISSUER_ID, KEY_PATH (the .p8 file), SIGNING_DIR (scratch folder).
set -euo pipefail

: "${ASC_KEY_ID:?}" "${ASC_ISSUER_ID:?}" "${KEY_PATH:?}" "${SIGNING_DIR:?}"
API="https://api.appstoreconnect.apple.com/v1"
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
KEYCHAIN="$SIGNING_DIR/signing.keychain-db"
# Bundle ID and the profile name the Xcode project names for it (PROVISIONING_PROFILE_SPECIFIER).
PROFILES=(
    "com.cambrium.wishfully|Wishfully CI App"
    "com.cambrium.wishfully.share|Wishfully CI Share"
)
# Apple's intermediate certificate for Apple Distribution certificates.
WWDR_URL="https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer"

b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }

token() {
    local now header payload
    now="$(date +%s)"
    header="$(printf '{"alg":"ES256","kid":"%s","typ":"JWT"}' "$ASC_KEY_ID" | b64url)"
    payload="$(printf '{"iss":"%s","iat":%d,"exp":%d,"aud":"appstoreconnect-v1"}' \
        "$ASC_ISSUER_ID" "$now" "$((now + 900))" | b64url)"
    printf '%s.%s' "$header" "$payload" | openssl dgst -sha256 -sign "$KEY_PATH" -out "$SIGNING_DIR/jwt.der"
    printf '%s.%s.%s' "$header" "$payload" "$(python3 "$SCRIPTS/es256-signature.py" "$SIGNING_DIR/jwt.der")"
}

# api <method> <path> [json-body]
api() {
    local args=(--silent --show-error --fail-with-body -X "$1" -H "Authorization: Bearer $(token)")
    if [ -n "${3:-}" ]; then
        args+=(-H "Content-Type: application/json" --data "$3")
    fi
    curl "${args[@]}" "$API$2"
}

uri() { jq -rn --arg value "$1" '$value | @uri'; }

setup() {
    mkdir -p "$SIGNING_DIR"
    local password
    password="$(openssl rand -hex 16)"

    echo "Creating a distribution certificate for this run"
    openssl req -new -newkey rsa:2048 -nodes -keyout "$SIGNING_DIR/dist.key" \
        -subj "/CN=Wishfully CI/O=Wishfully" -out "$SIGNING_DIR/dist.csr" 2> /dev/null
    local body response
    body="$(jq -n --rawfile csr "$SIGNING_DIR/dist.csr" \
        '{data: {type: "certificates", attributes: {certificateType: "DISTRIBUTION", csrContent: $csr}}}')"
    response="$(api POST /certificates "$body")" || {
        echo "Certificate creation failed: $response" >&2
        exit 1
    }
    jq -r .data.id <<< "$response" > "$SIGNING_DIR/certificate-id"
    jq -r .data.attributes.certificateContent <<< "$response" | base64 --decode > "$SIGNING_DIR/dist.cer"
    openssl x509 -inform DER -in "$SIGNING_DIR/dist.cer" -out "$SIGNING_DIR/dist.pem"
    # macOS imports PKCS#12 files written with the legacy algorithms; LibreSSL writes those.
    /usr/bin/openssl pkcs12 -export -inkey "$SIGNING_DIR/dist.key" -in "$SIGNING_DIR/dist.pem" \
        -out "$SIGNING_DIR/dist.p12" -passout "pass:$password"

    echo "Installing it in a temporary keychain"
    security create-keychain -p "$password" "$KEYCHAIN"
    security set-keychain-settings -lut 21600 "$KEYCHAIN"
    security unlock-keychain -p "$password" "$KEYCHAIN"
    curl --silent --show-error --fail --location --output "$SIGNING_DIR/wwdr.cer" "$WWDR_URL"
    security import "$SIGNING_DIR/wwdr.cer" -k "$KEYCHAIN" -T /usr/bin/codesign || true
    security import "$SIGNING_DIR/dist.p12" -k "$KEYCHAIN" -P "$password" -T /usr/bin/codesign -T /usr/bin/security
    security set-key-partition-list -S apple-tool:,apple: -s -k "$password" "$KEYCHAIN" > /dev/null
    local existing
    existing="$(security list-keychains -d user | tr -d '"' | xargs)"
    # shellcheck disable=SC2086
    security list-keychains -d user -s "$KEYCHAIN" $existing
    security find-identity -v -p codesigning "$KEYCHAIN"

    local certificate_id entry bundle name bundle_ref old profile uuid
    certificate_id="$(cat "$SIGNING_DIR/certificate-id")"
    for folder in "$HOME/Library/MobileDevice/Provisioning Profiles" \
        "$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"; do
        mkdir -p "$folder"
    done
    for entry in "${PROFILES[@]}"; do
        bundle="${entry%%|*}"
        name="${entry#*|}"
        bundle_ref="$(api GET "/bundleIds?filter%5Bidentifier%5D=$(uri "$bundle")&limit=200" |
            jq -r --arg id "$bundle" '.data[] | select(.attributes.identifier == $id) | .id' | head -n 1)"
        if [ -z "$bundle_ref" ]; then
            echo "The bundle ID $bundle is not registered. Register it on developer.apple.com" \
                "(Identifiers) with iCloud (CloudKit) and App Groups; see docs/releases/v0-setup.md." >&2
            exit 1
        fi
        for old in $(api GET "/profiles?filter%5Bname%5D=$(uri "$name")&limit=200" | jq -r '.data[].id'); do
            api DELETE "/profiles/$old" > /dev/null
        done
        body="$(jq -n --arg name "$name" --arg bundle "$bundle_ref" --arg cert "$certificate_id" '{data: {
            type: "profiles",
            attributes: {name: $name, profileType: "IOS_APP_STORE"},
            relationships: {
                bundleId: {data: {type: "bundleIds", id: $bundle}},
                certificates: {data: [{type: "certificates", id: $cert}]}
            }}}')"
        profile="$(api POST /profiles "$body")" || {
            echo "Profile creation failed for $bundle: $profile" >&2
            exit 1
        }
        jq -r .data.id <<< "$profile" >> "$SIGNING_DIR/profile-ids"
        uuid="$(jq -r .data.attributes.uuid <<< "$profile")"
        for folder in "$HOME/Library/MobileDevice/Provisioning Profiles" \
            "$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"; do
            jq -r .data.attributes.profileContent <<< "$profile" | base64 --decode > "$folder/$uuid.mobileprovision"
        done
        echo "Installed profile \"$name\" for $bundle"
    done
}

cleanup() {
    if [ -f "$SIGNING_DIR/profile-ids" ]; then
        while read -r id; do
            api DELETE "/profiles/$id" > /dev/null || echo "Could not delete profile $id" >&2
        done < "$SIGNING_DIR/profile-ids"
    fi
    if [ -f "$SIGNING_DIR/certificate-id" ]; then
        api DELETE "/certificates/$(cat "$SIGNING_DIR/certificate-id")" > /dev/null ||
            echo "Could not revoke the run's certificate" >&2
    fi
    security delete-keychain "$KEYCHAIN" 2> /dev/null || true
    rm -rf "$SIGNING_DIR"
}

case "${1:-}" in
    setup) setup ;;
    cleanup) cleanup ;;
    *)
        echo "usage: $0 setup|cleanup" >&2
        exit 2
        ;;
esac
