#!/bin/bash

# CA Initialization Script
# Creates a root Certificate Authority certificate and key using ED25519
# Optimized for MIPS architecture
# Usage: ./generate_ca.sh [--cn CN_NAME] [--cert-file CERT_PATH] [--key-file KEY_PATH]

set -e

# Default values
CN="Root CA"
CERT_FILE="ca.crt"
KEY_FILE="ca.key"
VALIDITY_DAYS=365

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --cn)
            CN="$2"
            shift 2
            ;;
        --cert-file)
            CERT_FILE="$2"
            shift 2
            ;;
        --key-file)
            KEY_FILE="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--cn CN_NAME] [--cert-file CERT_PATH] [--key-file KEY_PATH]"
            exit 1
            ;;
    esac
done

# Validate output paths
CERT_DIR=$(dirname "$CERT_FILE")
KEY_DIR=$(dirname "$KEY_FILE")

if [ ! -d "$CERT_DIR" ]; then
    echo "Error: Certificate directory does not exist: $CERT_DIR"
    exit 1
fi

if [ ! -d "$KEY_DIR" ]; then
    echo "Error: Key directory does not exist: $KEY_DIR"
    exit 1
fi

# Check if files already exist
if [ -f "$CERT_FILE" ] || [ -f "$KEY_FILE" ]; then
    echo "Error: Certificate or key file already exists"
    echo "  Cert: $CERT_FILE"
    echo "  Key:  $KEY_FILE"
    exit 1
fi

# Generate ED25519 private key
# Optimized for MIPS: generate directly without extra processing
echo "Generating ED25519 private key..."
openssl genpkey -algorithm ED25519 -out "$KEY_FILE" 2>/dev/null

# Check key generation success
if [ ! -f "$KEY_FILE" ]; then
    echo "Error: Failed to generate private key"
    exit 1
fi

# Set restrictive permissions on key file
chmod 600 "$KEY_FILE"

# Generate self-signed CA certificate
# Using SHA256 digest and 365-day validity
echo "Generating self-signed CA certificate..."
openssl req -new -x509 \
    -key "$KEY_FILE" \
    -out "$CERT_FILE" \
    -days "$VALIDITY_DAYS" \
    -subj "/CN=$CN" \
    -sha256 2>/dev/null

# Verify certificate was created
if [ ! -f "$CERT_FILE" ]; then
    echo "Error: Failed to generate certificate"
    rm -f "$KEY_FILE"
    exit 1
fi

# Verify certificate properties
echo "Verifying certificate..."
openssl x509 -in "$CERT_FILE" -noout -text 2>/dev/null | grep -q "ED25519" || {
    echo "Error: Certificate does not use ED25519"
    rm -f "$CERT_FILE" "$KEY_FILE"
    exit 1
}

echo "Successfully created CA certificate and key:"
echo "  Certificate: $CERT_FILE"
echo "  Key: $KEY_FILE"
echo "  CN: $CN"
echo "  Validity: $VALIDITY_DAYS days"
echo "  Algorithm: ED25519"
echo "  Digest: SHA256"
