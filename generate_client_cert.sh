#!/bin/bash

# Client Certificate Generation Script
# Creates a client certificate signed by a CA using ED25519
# Optimized for MIPS architecture
# Usage: ./generate_client_cert.sh --ca-cert CA_CERT --ca-key CA_KEY [--cn CN_NAME] [--cert-file CERT_PATH] [--key-file KEY_PATH]

set -e

# Default values
CN=""
CERT_FILE="client.crt"
KEY_FILE="client.key"
CA_CERT=""
CA_KEY=""
VALIDITY_DAYS=365
CSR_FILE=".client_csr_temp"

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --ca-cert)
            CA_CERT="$2"
            shift 2
            ;;
        --ca-key)
            CA_KEY="$2"
            shift 2
            ;;
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
            echo "Usage: $0 --ca-cert CA_CERT --ca-key CA_KEY [--cn CN_NAME] [--cert-file CERT_PATH] [--key-file KEY_PATH]"
            exit 1
            ;;
    esac
done

# Validate required parameters
if [ -z "$CA_CERT" ] || [ -z "$CA_KEY" ] || [ -z "$CN" ]; then
    echo "Error: Missing required arguments"
    echo "Usage: $0 --ca-cert CA_CERT --ca-key CA_KEY [--cn CN_NAME] [--cert-file CERT_PATH] [--key-file KEY_PATH]"
    exit 1
fi

# Validate CA files exist
if [ ! -f "$CA_CERT" ]; then
    echo "Error: CA certificate file not found: $CA_CERT"
    exit 1
fi

if [ ! -f "$CA_KEY" ]; then
    echo "Error: CA key file not found: $CA_KEY"
    exit 1
fi

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

# Check if output files already exist
if [ -f "$CERT_FILE" ] || [ -f "$KEY_FILE" ]; then
    echo "Error: Certificate or key file already exists"
    echo "  Cert: $CERT_FILE"
    echo "  Key:  $KEY_FILE"
    exit 1
fi

# Generate ED25519 private key for client
echo "Generating ED25519 client private key..."
openssl genpkey -algorithm ED25519 -out "$KEY_FILE" 2>/dev/null

# Check key generation success
if [ ! -f "$KEY_FILE" ]; then
    echo "Error: Failed to generate client private key"
    exit 1
fi

chmod 600 "$KEY_FILE"

# Generate Certificate Signing Request (CSR)
echo "Generating certificate signing request..."
openssl req -new \
    -key "$KEY_FILE" \
    -out "$CSR_FILE" \
    -subj "/CN=$CN" 2>/dev/null

# Check CSR generation success
if [ ! -f "$CSR_FILE" ]; then
    echo "Error: Failed to generate certificate signing request"
    rm -f "$KEY_FILE"
    exit 1
fi

# Sign the CSR with CA key using SHA256
echo "Signing client certificate with CA..."
openssl x509 -req -in "$CSR_FILE" \
    -CA "$CA_CERT" \
    -CAkey "$CA_KEY" \
    -CAcreateserial \
    -out "$CERT_FILE" \
    -days "$VALIDITY_DAYS" \
    -sha256 2>/dev/null

# Check certificate generation success
if [ ! -f "$CERT_FILE" ]; then
    echo "Error: Failed to sign client certificate"
    rm -f "$KEY_FILE" "$CSR_FILE"
    exit 1
fi

# Clean up temporary CSR file
rm -f "$CSR_FILE"

# Verify certificate properties
echo "Verifying certificate..."
openssl x509 -in "$CERT_FILE" -noout -text 2>/dev/null | grep -q "ED25519" || {
    echo "Error: Certificate does not use ED25519"
    rm -f "$CERT_FILE" "$KEY_FILE"
    exit 1
}

echo "Successfully created client certificate and key:"
echo "  Certificate: $CERT_FILE"
echo "  Key: $KEY_FILE"
echo "  CN: $CN"
echo "  Signed by: $CA_CERT"
echo "  Validity: $VALIDITY_DAYS days"
echo "  Algorithm: ED25519"
echo "  Digest: SHA256"
