#!/bin/bash
# scripts/verify_signature.sh
# Digital signature verification plugin
# Verifies RSA digital signatures for manifest files

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

# Load logger and return codes
source "$BASE_DIR/lib/logger.sh"
source "$BASE_DIR/lib/return_codes.sh"

# Configuration
MANIFEST_FILE="${MANIFEST_FILE:-$BASE_DIR/manifest.sha256}"
SIGNATURE_FILE="${SIGNATURE_FILE:-$BASE_DIR/manifest.sha256.sig}"
PUBLIC_KEY_FILE="${PUBLIC_KEY_FILE:-$BASE_DIR/keys/public_key.pem}"
HASH_ALGORITHM="${HASH_ALGORITHM:-sha256}"

# Plugin metadata
verify_signature_description() {
    echo "Verifies RSA digital signatures for manifest files to ensure authenticity and integrity"
}

# Logging functions
verify_signature_log_info() {
    log_info "[SIGVERIFY] $1"
}

verify_signature_log_warn() {
    log_warn "[SIGVERIFY] $1"
}

verify_signature_log_error() {
    log_error "[SIGVERIFY] $1"
}

# Check OpenSSL availability
check_openssl() {
    if ! command -v openssl >/dev/null 2>&1; then
        verify_signature_log_error "OpenSSL is required but not installed"
        return $RC_DEPENDENCY_ERROR
    fi
    return $RC_OK
}

# Check required files
check_required_files() {
    local missing_files=()
    
    # Check manifest file
    if [[ ! -f "$MANIFEST_FILE" ]]; then
        missing_files+=("manifest: $MANIFEST_FILE")
    fi
    
    # Check signature file
    if [[ ! -f "$SIGNATURE_FILE" ]]; then
        missing_files+=("signature: $SIGNATURE_FILE")
    fi
    
    # Check public key file
    if [[ ! -f "$PUBLIC_KEY_FILE" ]]; then
        missing_files+=("public key: $PUBLIC_KEY_FILE")
    fi
    
    # Report missing files
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        verify_signature_log_error "Missing required files:"
        for file in "${missing_files[@]}"; do
            verify_signature_log_error "  - $file"
        done
        
        verify_signature_log_error "Setup instructions:"
        verify_signature_log_error "  1. Generate manifest: bash tools/gen_hash.sh generate"
        verify_signature_log_error "  2. Generate keys: bash tools/gen_keypair.sh generate"
        verify_signature_log_error "  3. Sign manifest: bash tools/sign_manifest.sh sign"
        
        return $RC_CONFIG_ERROR
    fi
    
    return 0
}

# Verify digital signature
verify_signature() {
    verify_signature_log_info "Starting signature verification..."
    verify_signature_log_info "Manifest: $MANIFEST_FILE"
    verify_signature_log_info "Signature: $SIGNATURE_FILE"
    verify_signature_log_info "Public key: $PUBLIC_KEY_FILE"
    verify_signature_log_info "Algorithm: $HASH_ALGORITHM"
    
    # Perform signature verification
    local verify_output
    verify_output=$(openssl dgst -"$HASH_ALGORITHM" -verify "$PUBLIC_KEY_FILE" \
                   -signature "$SIGNATURE_FILE" "$MANIFEST_FILE" 2>&1)
    local verify_result=$?
    
    if [[ $verify_result -eq $RC_OK ]]; then
        verify_signature_log_info "✅ Signature verification PASSED"
        
        # Extract manifest hash for additional verification
        local manifest_hash
        manifest_hash=$(openssl dgst -"$HASH_ALGORITHM" "$MANIFEST_FILE" | cut -d' ' -f2)
        verify_signature_log_info "Manifest hash: $manifest_hash"
        
        # Display verification details
        local signature_size
        signature_size=$(stat -c "%s" "$SIGNATURE_FILE" 2>/dev/null)
        verify_signature_log_info "Signature size: $signature_size bytes"
        
        # Display public key fingerprint
        local key_fingerprint
        key_fingerprint=$(openssl pkey -pubin -in "$PUBLIC_KEY_FILE" -outform DER 2>/dev/null | openssl dgst -sha256 -hex | cut -d' ' -f2)
        verify_signature_log_info "Public key fingerprint: $key_fingerprint"
        
        return $RC_OK
    else
        verify_signature_log_error "❌ Signature verification FAILED"
        verify_signature_log_error "OpenSSL output: $verify_output"
        
        # Provide troubleshooting information
        verify_signature_log_error "Possible causes:"
        verify_signature_log_error "  - Manifest file has been modified"
        verify_signature_log_error "  - Signature file is corrupted or tampered"
        verify_signature_log_error "  - Wrong public key used"
        verify_signature_log_error "  - Signature created with different private key"
        
        return $RC_SIGNATURE_FAILED
    fi
}

# Display verification status
display_verification_status() {
    local result=$1
    
    if [[ $result -eq 0 ]]; then
        verify_signature_log_info "SIGNATURE STATUS: VERIFIED"
        verify_signature_log_info "Manifest authenticity and integrity confirmed"
    else
        verify_signature_log_error "SIGNATURE STATUS: INVALID"
        verify_signature_log_error "Manifest authenticity or integrity compromised"
    fi
}

# Plugin check function
verify_signature_check() {
    # Check dependencies
    if ! check_openssl; then
        verify_signature_log_error "Dependency check failed"
        return $RC_DEPENDENCY_ERROR
    fi
    
    # Check required files
    if ! check_required_files; then
        verify_signature_log_error "Required files check failed"
        return $RC_CONFIG_ERROR
    fi
    
    # Perform verification
    if verify_signature; then
        display_verification_status $RC_OK
        return $RC_OK  # OK
    else
        display_verification_status $RC_SIGNATURE_FAILED
        return $RC_SIGNATURE_FAILED  # ERROR
    fi
}

# Standalone execution functions
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Digital Signature Verification Plugin"
    echo ""
    echo "Options:"
    echo "  check        Run signature verification (plugin interface)"
    echo "  verify       Run standalone verification"
    echo "  status       Show verification status"
    echo "  help         Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  MANIFEST_FILE      Manifest file (default: ./manifest.sha256)"
    echo "  SIGNATURE_FILE     Signature file (default: ./manifest.sha256.sig)"
    echo "  PUBLIC_KEY_FILE    Public key file (default: ./keys/public_key.pem)"
    echo "  HASH_ALGORITHM     Hash algorithm (default: sha256)"
    echo ""
    echo "Exit Codes:"
    echo "  0  - Verification passed"
    echo "  1  - Warning (missing files, etc.)"
    echo "  2  - Error (verification failed)"
}

# Standalone verification
standalone_verify() {
    verify_signature_check
    local result=$?
    
    if [[ $result -eq 0 ]]; then
        echo "✅ Signature verification PASSED"
    else
        echo "❌ Signature verification FAILED"
    fi
    
    return $result
}

# Show verification status
show_status() {
    verify_signature_log_info "Signature verification status check..."
    
    # Check if all files exist
    local status="UNKNOWN"
    local details=""
    
    if [[ -f "$MANIFEST_FILE" && -f "$SIGNATURE_FILE" && -f "$PUBLIC_KEY_FILE" ]]; then
        if verify_signature >/dev/null 2>&1; then
            status="VERIFIED"
            details="All files present and signature valid"
        else
            status="INVALID"
            details="Files present but signature verification failed"
        fi
    else
        status="MISSING_FILES"
        details="One or more required files are missing"
    fi
    
    echo "Status: $status"
    echo "Details: $details"
    echo ""
    echo "Files:"
    echo "  Manifest:   $MANIFEST_FILE $([[ -f "$MANIFEST_FILE" ]] && echo "✅" || echo "❌")"
    echo "  Signature:  $SIGNATURE_FILE $([[ -f "$SIGNATURE_FILE" ]] && echo "✅" || echo "❌")"
    echo "  Public:     $PUBLIC_KEY_FILE $([[ -f "$PUBLIC_KEY_FILE" ]] && echo "✅" || echo "❌")"
}

# Main execution
main() {
    local command="${1:-check}"
    
    case "$command" in
        "check")
            verify_signature_check
            ;;
        "verify")
            standalone_verify
            ;;
        "status")
            show_status
            ;;
        "help"|"-h"|"--help")
            show_usage
            exit 0
            ;;
        *)
            verify_signature_log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
