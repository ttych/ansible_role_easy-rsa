#!/bin/sh

set -e

EASY_RSA_REQUEST_DIR="{{ easy_rsa_request_dir }}"
EASY_RSA_REQUEST_PKI_DIR="{{ easy_rsa_request_pki_dir }}"
EASY_RSA_CA_DIR="{{ easy_rsa_ca_dir }}"
EASY_RSA_CA_PKI_DIR="{{ easy_rsa_ca_pki_dir }}"
EASY_RSA_BIN="{{ easy_rsa_dist_bin }}"

EASY_RSA_TYPE="${EASY_RSA_TYPE:-serverClient}"

CN="$1"
if [ -z "$1" ]; then
    echo >&2 "$0 <CN> ALT_DNS..."
    exit 1
fi
shift

SAN=
for san; do
    san_full="${san}"
    san_short="${san%%.*}"
    [ "$san_full" = "$san_short" ] && san_short=""
    SAN="$SAN ${san_full:+--san=\"DNS:${san_full}\"} ${san_short:+--san=\"DNS:${san_short}\"}"
done

# create request
cd "$EASY_RSA_REQUEST_DIR"
"$EASY_RSA_BIN" --batch --san="DNS:${CN}" --san="DNS:${CN%%.*}" $SAN --req-cn="${CN}" gen-req "${CN}" nopass

# import request
cd "$EASY_RSA_CA_DIR"
"$EASY_RSA_BIN" --batch import-req "$EASY_RSA_REQUEST_PKI_DIR/reqs/${CN}.req" "${CN}"

# sign request
cd "$EASY_RSA_CA_DIR"
"$EASY_RSA_BIN" --batch --copy-ext --passin=file:passphrase sign-req "${EASY_RSA_TYPE}" "${CN}"

# copy cert
cp "$EASY_RSA_CA_PKI_DIR/issued/${CN}.crt" "$EASY_RSA_REQUEST_PKI_DIR/certs/${CN}.crt"
