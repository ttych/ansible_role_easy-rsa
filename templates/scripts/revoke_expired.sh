#!/bin/sh

set -e

EASY_RSA_CA_DIR="{{ easy_rsa_ca_dir }}"
EASY_RSA_CA_PKI_DIR="{{ easy_rsa_ca_pki_dir }}"
EASY_RSA_BIN="{{ easy_rsa_dist_bin }}"
EASY_RSA_INDEX_FILE="${EASY_RSA_CA_PKI_DIR}/index.txt"
EASY_RSA_CA_PASSPHRASE="{{ easy_rsa_ca_passphrase }}"

cd "$EASY_RSA_CA_DIR" || exit

# echo "Checking for expired certificates..."
while IFS= read -r line; do
    # Parse each line in the index.txt
    STATUS=$(echo "$line" | cut -d ' ' -f 1)
    EXPIRY_DATE=$(echo "$line" | cut -d ' ' -f 2)
    SERIAL=$(echo "$line" | awk '{print $4}')

    # Skip if not issued or already revoked
    if [ "$STATUS" != "V" ]; then
        continue
    fi

    # Convert expiry date to a timestamp
    EXPIRY_TIMESTAMP=$(date -d "$EXPIRY_DATE" +%s 2>/dev/null)

    # Get the current timestamp
    CURRENT_TIMESTAMP=$(date +%s)

    # Check if the certificate is expired
    if [ $CURRENT_TIMESTAMP -gt $EXPIRY_TIMESTAMP ]; then
        # echo "Certificate with serial $SERIAL has expired. Revoking..."
        "$EASY_RSA_BIN" --batch --passin=file:$EASY_RSA_CA_PASSPHRASE revoke "$SERIAL" || echo >&2 "Failed to revoke $SERIAL"
    fi
done < "$EASY_RSA_INDEX_FILE"

# echo "Generating updated CRL..."
"$EASY_RSA_BIN" --batch --passin=file:$EASY_RSA_CA_PASSPHRASE gen-crl

# echo "Expired certificates have been revoked and CRL updated."
