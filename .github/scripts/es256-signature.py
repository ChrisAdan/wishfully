#!/usr/bin/env python3
"""Converts an OpenSSL ECDSA P-256 signature (DER) into the JOSE form a JWT needs.

App Store Connect API tokens are ES256 JWTs. OpenSSL writes the signature as an ASN.1
SEQUENCE of two INTEGERs (r, s); JWS (RFC 7515, appendix A.3) wants r and s as 32-byte
big-endian values, concatenated and base64url-encoded without padding. Standard library only.

    python3 es256-signature.py signature.der
"""
import base64
import pathlib
import sys

# Bytes per coordinate for the P-256 curve (RFC 7518, section 3.4).
COORDINATE_BYTES = 32


def read_length(data, offset):
    first = data[offset]
    if first < 0x80:
        return first, offset + 1
    count = first & 0x7F
    return int.from_bytes(data[offset + 1 : offset + 1 + count], "big"), offset + 1 + count


def read_integer(data, offset):
    if data[offset] != 0x02:
        raise ValueError("expected an ASN.1 INTEGER")
    length, start = read_length(data, offset + 1)
    value = data[start : start + length].lstrip(b"\x00")
    if len(value) > COORDINATE_BYTES:
        raise ValueError("integer too long for P-256")
    return value.rjust(COORDINATE_BYTES, b"\x00"), start + length


def main():
    der = pathlib.Path(sys.argv[1]).read_bytes()
    if der[0] != 0x30:
        raise ValueError("expected an ASN.1 SEQUENCE")
    _, offset = read_length(der, 1)
    r, offset = read_integer(der, offset)
    s, _ = read_integer(der, offset)
    print(base64.urlsafe_b64encode(r + s).rstrip(b"=").decode("ascii"))


if __name__ == "__main__":
    main()
