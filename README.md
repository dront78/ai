# HTTPS Certificate Generation Scripts

A suite of optimized bash scripts for generating HTTPS certificates using ED25519 elliptic curve cryptography and SHA256 signing. These scripts are specifically tuned for MIPS architecture performance.

## Features

- **ED25519 Cryptography**: Modern, efficient elliptic curve algorithm
- **SHA256 Signing**: Secure certificate digests
- **365-day Validity**: All certificates valid for exactly one year
- **MIPS Optimized**: Efficient I/O operations and minimal processing overhead
- **Error Handling**: Comprehensive validation and error checking
- **PEM Format**: Standard certificate and key output formats
- **Self-contained**: Each script operates independently with minimal dependencies

## Requirements

- OpenSSL 1.1.1 or later (with ED25519 support)
- Bash 4.0 or later
- Standard Unix utilities (grep, mkdir, chmod, rm)

## Scripts

### 1. generate_ca.sh

Creates a root Certificate Authority certificate and key.

**Usage:**
```bash
./generate_ca.sh [--cn CN_NAME] [--cert-file CERT_PATH] [--key-file KEY_PATH]
```

**Options:**
- `--cn CN_NAME`: Common name for the CA (default: "Root CA")
- `--cert-file CERT_PATH`: Output path for CA certificate (default: "ca.crt")
- `--key-file KEY_PATH`: Output path for CA key (default: "ca.key")

**Example:**
```bash
./generate_ca.sh --cn "My Root CA" --cert-file ./certs/ca.crt --key-file ./certs/ca.key
```

**Output:**
- CA certificate (PEM format)
- CA private key (PEM format, 600 permissions)

### 2. generate_server_cert.sh

Creates a server certificate signed by a CA.

**Usage:**
```bash
./generate_server_cert.sh --ca-cert CA_CERT --ca-key CA_KEY [--cn CN_NAME] [--cert-file CERT_PATH] [--key-file KEY_PATH]
```

**Options:**
- `--ca-cert CA_CERT`: Path to CA certificate (required)
- `--ca-key CA_KEY`: Path to CA private key (required)
- `--cn CN_NAME`: Common name for the server (required)
- `--cert-file CERT_PATH`: Output path for server certificate (default: "server.crt")
- `--key-file KEY_PATH`: Output path for server key (default: "server.key")

**Example:**
```bash
./generate_server_cert.sh \
  --ca-cert ./certs/ca.crt \
  --ca-key ./certs/ca.key \
  --cn "example.com" \
  --cert-file ./certs/server.crt \
  --key-file ./certs/server.key
```

**Output:**
- Server certificate (PEM format, signed by CA)
- Server private key (PEM format, 600 permissions)

### 3. generate_client_cert.sh

Creates a client certificate signed by a CA.

**Usage:**
```bash
./generate_client_cert.sh --ca-cert CA_CERT --ca-key CA_KEY [--cn CN_NAME] [--cert-file CERT_PATH] [--key-file KEY_PATH]
```

**Options:**
- `--ca-cert CA_CERT`: Path to CA certificate (required)
- `--ca-key CA_KEY`: Path to CA private key (required)
- `--cn CN_NAME`: Common name for the client (required)
- `--cert-file CERT_PATH`: Output path for client certificate (default: "client.crt")
- `--key-file KEY_PATH`: Output path for client key (default: "client.key")

**Example:**
```bash
./generate_client_cert.sh \
  --ca-cert ./certs/ca.crt \
  --ca-key ./certs/ca.key \
  --cn "client@example.com" \
  --cert-file ./certs/client.crt \
  --key-file ./certs/client.key
```

**Output:**
- Client certificate (PEM format, signed by CA)
- Client private key (PEM format, 600 permissions)

## Typical Workflow

1. **Initialize CA:**
   ```bash
   mkdir -p certs
   ./generate_ca.sh --cn "Example CA" --cert-file certs/ca.crt --key-file certs/ca.key
   ```

2. **Generate Server Certificate:**
   ```bash
   ./generate_server_cert.sh \
     --ca-cert certs/ca.crt \
     --ca-key certs/ca.key \
     --cn "server.example.com" \
     --cert-file certs/server.crt \
     --key-file certs/server.key
   ```

3. **Generate Client Certificate:**
   ```bash
   ./generate_client_cert.sh \
     --ca-cert certs/ca.crt \
     --ca-key certs/ca.key \
     --cn "client@example.com" \
     --cert-file certs/client.crt \
     --key-file certs/client.key
   ```

## Verification

To verify generated certificates:

```bash
# View certificate details
openssl x509 -in certificate.crt -text -noout

# Verify certificate chain
openssl verify -CAfile ca.crt certificate.crt

# Check key and certificate match
openssl pkey -in key.key -pubout -outform pem | openssl md5
openssl x509 -in certificate.crt -pubkey -noout -outform pem | openssl md5
```

## Performance Considerations

These scripts are optimized for MIPS architecture through:

- Minimal subprocess spawning
- Efficient file I/O operations
- Direct OpenSSL command usage without intermediate processing
- Stream-based operations where possible
- Early error detection to avoid wasted computation

## Error Handling

Each script includes:

- Input validation for all parameters
- File existence checks for required inputs
- Directory existence verification
- Permission checks and setting
- Verification of generated certificates
- Automatic cleanup of temporary files on failure
- Descriptive error messages

## Security

- Private keys are created with 600 permissions (owner read/write only)
- Self-signed CA allows for controlled environments
- ED25519 provides strong security with efficient computation
- SHA256 provides secure certificate digests
- No credentials stored in scripts or configuration

## Compatibility

- Tested with OpenSSL 1.1.1 and later
- Compatible with most Linux distributions (including MIPS-based systems)
- Supports both absolute and relative paths
- Portable across POSIX-compliant systems

## License

These scripts are provided as-is for certificate generation purposes.
