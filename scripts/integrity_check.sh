#!/bin/bash
# scripts/integrity_check.sh
# Integrity verification plugin for ROT security
# Verifies file hashes against manifest.sha256

set -u

# Load environment variables for standalone execution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load environment variables (if exists)
ENV_FILE="$BASE_DIR/config/health-monitor.env"
if [[ -f "$ENV_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$ENV_FILE"
fi

# Load logger and signature verification
source "$BASE_DIR/lib/logger.sh"
source "$BASE_DIR/scripts/verify_signature.sh"

# Plugin metadata
integrity_check_description() {
    echo "Verifies file integrity using SHA256 hash comparison and digital signature verification"
}

# Configuration
MANIFEST_FILE="$BASE_DIR/manifest.sha256"

# Plugin-specific logging (using standard log functions)
integrity_check_log_info() {
    log_info "[INTEGRITY] $1"
}

integrity_check_log_warn() {
    log_warn "[INTEGRITY] $1"
}

integrity_check_log_error() {
    log_error "[INTEGRITY] $1"
}

# Check if manifest exists and is readable
check_manifest_exists() {
    if [[ ! -f "$MANIFEST_FILE" ]]; then
        integrity_check_log_error "Manifest file not found: $MANIFEST_FILE"
        echo "INTEGRITY ERROR: No manifest file found"
        return 2
    fi
    
    if [[ ! -r "$MANIFEST_FILE" ]]; then
        integrity_check_log_error "Manifest file not readable: $MANIFEST_FILE"
        echo "INTEGRITY ERROR: Manifest file not readable"
        return 2
    fi
    
    return 0
}

# Verify file integrity
verify_integrity() {
    integrity_check_log_info "Starting integrity verification..."
    
    # Check manifest exists and is readable
    if ! check_manifest_exists; then
        return 2
    fi
    
    # Count total files in manifest
    local total_files
    total_files="$(wc -l < "$MANIFEST_FILE")"
    
    integrity_check_log_info "Verifying $total_files files..."
    
    # Run sha256sum verification
    local verify_output
    local verify_result
    
    # Capture both stdout and stderr for comprehensive reporting
    if verify_output="$(sha256sum -c "$MANIFEST_FILE" 2>&1)"; then
        verify_result=$?
    else
        verify_result=$?
    fi
    
    # Parse results
    local failed_count=0
    local success_count=0
    
    # Process sha256sum -c output
    while IFS= read -r line; do
        if [[ "$line" =~ ^[A-Fa-f0-9]+:\ ([A-Z]+)$ ]]; then
            # This pattern doesn't match sha256sum -c output format
            continue
        elif [[ "$line" =~ ^(.+):\ ([A-Z]+)$ ]]; then
            local status="${BASH_REMATCH[2]}"
            case "$status" in
                "OK")
                    ((success_count++))
                    ;;
                "FAILED")
                    ((failed_count++))
                    local file_path
                    file_path="${BASH_REMATCH[1]}"
                    integrity_check_log_error "File integrity check failed: $file_path"
                    ;;
            esac
        fi
    done <<< "$verify_output"
    
    # Report results
    if [[ $verify_result -eq 0 ]]; then
        integrity_check_log_info "All $total_files files verified successfully"
        echo "INTEGRITY OK: All $total_files files verified"
        
        # Proceed to signature verification
        integrity_check_log_info "File integrity verified, proceeding to signature verification..."
        verify_signature_check
        local signature_result=$?
        
        if [[ $signature_result -eq 0 ]]; then
            integrity_check_log_info "Both integrity and signature verification passed"
            echo "INTEGRITY OK: All $total_files files verified and signature valid"
            return 0
        else
            integrity_check_log_error "Signature verification failed"
            echo "INTEGRITY ERROR: Signature verification failed"
            return 2
        fi
    else
        integrity_check_log_error "Integrity verification failed: $failed_count/$total_files files failed"
        echo "INTEGRITY ERROR: $failed_count/$total_files files failed verification"
        return 2
    fi
}

# Main integrity check function (plugin interface)
integrity_check_check() {
    # Check if sha256sum is available
    if ! command -v sha256sum >/dev/null 2>&1; then
        integrity_check_log_error "sha256sum command not found"
        echo "INTEGRITY ERROR: sha256sum command not available"
        return 2
    fi
    
    # Perform integrity verification
    verify_integrity
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    integrity_check_check
    rc=$?
    echo "Integrity check completed with status code: $rc"
    exit $rc
fi
