#!/bin/bash
# tools/gen_hash.sh
# Hash fingerprint generator for integrity verification
# Generates SHA256 hashes for all .sh and .py files in the project

set -euo pipefail

# Load TrustMonitor initialization system
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/trustmon_init.sh"

# Initialize this script
init_trustmon_script "gen_hash.sh"

# Configuration (using unified path manager)
MANIFEST_FILE="$MANIFEST_FILE"  # From path_manager.sh

# Logging function
log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

# Generate hash manifest
generate_manifest() {
    log_info "Generating hash manifest..."
    
    # Create temporary file
    local temp_manifest
    temp_manifest="$(mktemp)"
    
    # Find all .sh and .py files, excluding specific directories
    find "$PROJECT_ROOT" -name "*.sh" -o -name "*.py" 2>/dev/null | \
        grep -v -E "(__pycache__|\.git|backup|logs)" | \
        while read -r file; do
        # Get relative path from project root
        local rel_path
        rel_path="${file#$PROJECT_ROOT/}"
        
        # Calculate SHA256 hash
        local hash
        hash="$(sha256sum "$file" | cut -d' ' -f1)"
        
        # Add to manifest
        echo "$hash  $rel_path" >> "$temp_manifest"
        
    done
    
    # Move temporary file to final location
    mv "$temp_manifest" "$MANIFEST_FILE"
    
    log_info "Hash manifest generated: $MANIFEST_FILE"
    log_info "Total files: $(wc -l < "$MANIFEST_FILE")"
}

# Verify existing manifest (if exists)
verify_existing() {
    if [[ -f "$MANIFEST_FILE" ]]; then
        log_info "Verifying existing manifest..."
        if sha256sum -c "$MANIFEST_FILE" >/dev/null 2>&1; then
            log_info "Existing manifest is valid"
            return 0
        else
            log_error "Existing manifest verification failed"
            return 1
        fi
    else
        log_info "No existing manifest found"
        return 0
    fi
}

# Main execution
main() {
    case "${1:-generate}" in
        "generate")
            generate_manifest
            ;;
        "verify")
            verify_existing
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [generate|verify|help]"
            echo "  generate - Generate hash manifest (default)"
            echo "  verify   - Verify existing manifest"
            echo "  help     - Show this help"
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"
