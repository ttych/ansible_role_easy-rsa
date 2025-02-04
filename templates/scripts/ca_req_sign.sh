#!/bin/sh

set -e

EASY_RSA_CA_DIR="{{ easy_rsa_ca_dir }}"
EASY_RSA_CA_PKI_DIR="{{ easy_rsa_ca_pki_dir }}"
EASY_RSA_BIN="{{ easy_rsa_dist_bin }}"

EASY_RSA_TYPE="${EASY_RSA_TYPE:-serverClient}"


echo2()
{
    echo >&2 "$@"
}


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


if [ -r "${EASY_RSA_CA_PKI_DIR}/reqs/${CN}.req" ]; then
    echo2 "request for ${CN} already exists at ${EASY_RSA_CA_PKI_DIR}/reqs/${CN}.req"
    exit 1
fi
if [ -r "${EASY_RSA_CA_PKI_DIR}/private/${CN}.key" ]; then
    echo2 "key for ${CN} already exists at ${EASY_RSA_CA_PKI_DIR}/private/${CN}.key"
    exit 1
fi
if [ -r "${EASY_RSA_CA_PKI_DIR}/pki/issued/${CN}.crt" ]; then
    echo2 "certificate for ${CN} already exists at ${EASY_RSA_CA_PKI_DIR}/pki/issued/${CN}.crt"
    exit 1
fi


# create request
cd "$EASY_RSA_CA_DIR"
"$EASY_RSA_BIN" --batch --san="DNS:${CN}" --san="DNS:${CN%%.*}" $SAN --req-cn="${CN}" gen-req "${CN}" nopass

# sign request
cd "$EASY_RSA_CA_DIR"
"$EASY_RSA_BIN" --batch --copy-ext --passin=file:passphrase sign-req "${EASY_RSA_TYPE}" "${CN}"
