#!/bin/bash
# tools/sign_manifest.sh
# Digital signature generator for manifest.sha256
# Creates RSA digital signatures for integrity verification

set -u

# Script directory and project base
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load environment variables (if exists)
ENV_FILE="$BASE_DIR/config/health-monitor.env"
if [[ -f "$ENV_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$ENV_FILE"
fi

# Load logger
source "$BASE_DIR/lib/logger.sh"

# Configuration
MANIFEST_FILE="${MANIFEST_FILE:-$BASE_DIR/manifest.sha256}"
SIGNATURE_FILE="${SIGNATURE_FILE:-$BASE_DIR/manifest.sha256.sig}"
PRIVATE_KEY_FILE="${PRIVATE_KEY_FILE:-$BASE_DIR/keys/private_key.pem}"
HASH_ALGORITHM="${HASH_ALGORITHM:-sha256}"

# Logging functions
sign_log_info() {
    log_info "[SIGN] $1"
}

sign_log_warn() {
    log_warn "[SIGN] $1"
}

sign_log_error() {
    log_error "[SIGN] $1"
}

# Display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Digital Signature Generator for Manifest Files"
    echo ""
    echo "Options:"
    echo "  sign         Sign the manifest file"
    echo "  verify       Verify existing signature"
    echo "  help         Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  MANIFEST_FILE      Manifest file to sign (default: ./manifest.sha256)"
    echo "  SIGNATURE_FILE     Output signature file (default: ./manifest.sha256.sig)"
    echo "  PRIVATE_KEY_FILE   Private key file (default: ./keys/private_key.pem)"
    echo "  HASH_ALGORITHM     Hash algorithm (default: sha256)"
    echo ""
    echo "Examples:"
    echo "  $0 sign                           # Sign default manifest"
    echo "  $0 verify                         # Verify default signature"
    echo "  MANIFEST_FILE=custom.manifest $0 sign"
}

# Check OpenSSL availability
check_dependencies() {
    sign_log_info "Checking dependencies..."
    
    if ! command -v openssl >/dev/null 2>&1; then
        sign_log_error "OpenSSL is required but not installed"
        sign_log_error "Install with: sudo apt-get install openssl"
        exit 1
    fi
    
    sign_log_info "OpenSSL found: $(openssl version)"
}

# Check required files
check_required_files() {
    sign_log_info "Checking required files..."
    
    # Check manifest file
    if [[ ! -f "$MANIFEST_FILE" ]]; then
        sign_log_error "Manifest file not found: $MANIFEST_FILE"
        sign_log_error "Generate manifest first: bash tools/gen_hash.sh generate"
        exit 1
    fi
    
    sign_log_info "Manifest file found: $MANIFEST_FILE"
    
    # Check private key file
    if [[ ! -f "$PRIVATE_KEY_FILE" ]]; then
        sign_log_error "Private key not found: $PRIVATE_KEY_FILE"
        sign_log_error "Generate key pair first: bash tools/gen_keypair.sh generate"
        exit 1
    fi
    
    sign_log_info "Private key found: $PRIVATE_KEY_FILE"
    
    # Check private key permissions
    local key_perms
    key_perms=$(stat -c "%a" "$PRIVATE_KEY_FILE" 2>/dev/null)
    if [[ "$key_perms" != "600" ]]; then
        sign_log_warn "Private key permissions are $key_perms (recommended: 600)"
        sign_log_warn "Set with: chmod 600 $PRIVATE_KEY_FILE"
    fi
}

# Backup existing signature
backup_existing_signature() {
    if [[ -f "$SIGNATURE_FILE" ]]; then
        local backup_file="${SIGNATURE_FILE}.backup_$(date +%Y%m%d_%H%M%S)"
        sign_log_warn "Existing signature found, creating backup..."
        cp "$SIGNATURE_FILE" "$backup_file"
        sign_log_info "Signature backed up to: $backup_file"
    fi
}

# Create digital signature
create_signature() {
    sign_log_info "Creating digital signature..."
    sign_log_info "Manifest file: $MANIFEST_FILE"
    sign_log_info "Signature file: $SIGNATURE_FILE"
    sign_log_info "Private key: $PRIVATE_KEY_FILE"
    sign_log_info "Hash algorithm: $HASH_ALGORITHM"
    
    # Calculate manifest hash for reference
    local manifest_hash
    manifest_hash=$(openssl dgst -"$HASH_ALGORITHM" "$MANIFEST_FILE" | cut -d' ' -f2)
    sign_log_info "Manifest hash: $manifest_hash"
    
    # Create digital signature
    sign_log_info "Generating signature..."
    if openssl dgst -"$HASH_ALGORITHM" -sign "$PRIVATE_KEY_FILE" -out "$SIGNATURE_FILE" "$MANIFEST_FILE" 2>/dev/null; then
        sign_log_info "Signature created successfully"
    else
        sign_log_error "Failed to create signature"
        exit 1
    fi
    
    # Set signature file permissions
    chmod 644 "$SIGNATURE_FILE"
    sign_log_info "Signature file permissions set to 644"
    
    # Display signature information
    display_signature_info "$manifest_hash"
}

# Display signature information
display_signature_info() {
    local manifest_hash="$1"
    
    sign_log_info "Digital signature created successfully!"
    sign_log_info "Files:"
    sign_log_info "  Manifest:   $MANIFEST_FILE"
    sign_log_info "  Signature:  $SIGNATURE_FILE"
    sign_log_info "  Private:    $PRIVATE_KEY_FILE"
    
    # Display signature details
    local signature_size
    signature_size=$(stat -c "%s" "$SIGNATURE_FILE" 2>/dev/null)
    sign_log_info "Signature details:"
    sign_log_info "  Algorithm:  RSA-$HASH_ALGORITHM"
    sign_log_info "  Size:       $signature_size bytes"
    sign_log_info "  Hash:       $manifest_hash"
    
    # Display signature fingerprint
    local sig_fingerprint
    sig_fingerprint=$(openssl dgst -"$HASH_ALGORITHM" "$SIGNATURE_FILE" | cut -d' ' -f2)
    sign_log_info "  Fingerprint: $sig_fingerprint"
    
    sign_log_info "Security reminder:"
    sign_log_info "  - Keep private key secure and never share it"
    sign_log_info "  - Backup signature file in a secure location"
    sign_log_info "  - Verify signature before distribution"
}

# Verify existing signature
verify_signature() {
    sign_log_info "Verifying digital signature..."
    
    # Check required files
    if [[ ! -f "$MANIFEST_FILE" ]]; then
        sign_log_error "Manifest file not found: $MANIFEST_FILE"
        exit 1
    fi
    
    if [[ ! -f "$SIGNATURE_FILE" ]]; then
        sign_log_error "Signature file not found: $SIGNATURE_FILE"
        exit 1
    fi
    
    # Find public key file
    local public_key_file="${PUBLIC_KEY_FILE:-$BASE_DIR/keys/public_key.pem}"
    if [[ ! -f "$public_key_file" ]]; then
        sign_log_error "Public key not found: $public_key_file"
        exit 1
    fi
    
    sign_log_info "Files:"
    sign_log_info "  Manifest:   $MANIFEST_FILE"
    sign_log_info "  Signature:  $SIGNATURE_FILE"
    sign_log_info "  Public:     $public_key_file"
    
    # Verify signature
    sign_log_info "Verifying signature..."
    if openssl dgst -"$HASH_ALGORITHM" -verify "$public_key_file" -signature "$SIGNATURE_FILE" "$MANIFEST_FILE" 2>/dev/null; then
        sign_log_info "✅ Signature verification PASSED"
        
        # Display verification details
        local manifest_hash
        manifest_hash=$(openssl dgst -"$HASH_ALGORITHM" "$MANIFEST_FILE" | cut -d' ' -f2)
        sign_log_info "Manifest hash: $manifest_hash"
        
        local signature_size
        signature_size=$(stat -c "%s" "$SIGNATURE_FILE" 2>/dev/null)
        sign_log_info "Signature size: $signature_size bytes"
        
        return 0
    else
        sign_log_error "📍 Signature verification FAILED"
        sign_log_error "Possible causes:"
        sign_log_error "  - Manifest file has been modified"
        sign_log_error "  - Signature file is corrupted"
        sign_log_error "  - Wrong public key used"
        sign_log_error "  - Signature was created with different private key"
        return 1
    fi
}

# Display verification help
display_verification_help() {
    sign_log_info "Signature verification help:"
    sign_log_info "1. Ensure manifest.sha256 is unchanged"
    sign_log_info "2. Use correct public key file"
    sign_log_info "3. Check signature file integrity"
    sign_log_info "4. Verify key pair matches"
    
    # Show key pair verification
    local public_key_file="${PUBLIC_KEY_FILE:-$BASE_DIR/keys/public_key.pem}"
    if [[ -f "$public_key_file" ]]; then
        sign_log_info "Public key fingerprint: $(openssl pkey -pubin -in "$public_key_file" -outform DER 2>/dev/null | openssl dgst -sha256 -hex | cut -d' ' -f2)"
    fi
}

# Main execution
main() {
    local command="${1:-help}"
    
    case "$command" in
        "sign")
            check_dependencies
            check_required_files
            backup_existing_signature
            create_signature
            ;;
        "verify")
            check_dependencies
            if ! verify_signature; then
                display_verification_help
                exit 1
            fi
            ;;
        "help"|"-h"|"--help")
            usage
            exit 0
            ;;
        *)
            sign_log_error "Unknown command: $command"
            usage
            exit 1
            ;;
    esac
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
