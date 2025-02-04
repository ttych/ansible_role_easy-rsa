#!/bin/sh

set -e

EASY_RSA_CA_DIR="{{ easy_rsa_ca_dir }}"
EASY_RSA_CA_PKI_DIR="{{ easy_rsa_ca_pki_dir }}"
EASY_RSA_BIN="{{ easy_rsa_dist_bin }}"

EASY_RSA_TYPE="${EASY_RSA_TYPE:-serverClient}"

if [ -z "$1" ]; then
    echo >&2 "$0 <REQUEST>"
    exit 1
fi
REQ="$1"
CN="$2"

cd "$EASY_RSA_CA_DIR"

if [ -z "$CN" ]; then
    CN=$(openssl req -in "$REQ" -noout -subject | sed -n 's/.*CN=\([^,]*\).*/\1/p')
fi

# import request
"$EASY_RSA_BIN" --batch import-req "$REQ" "$CN"

# sign request
"$EASY_RSA_BIN" --batch --copy-ext --passin=file:passphrase sign-req "$EASY_RSA_TYPE" "$CN"
