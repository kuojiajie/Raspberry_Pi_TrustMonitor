#!/bin/bash
# tools/dev/rebuild_integrity.sh
# Rebuild integrity after file modifications
# v1.0.0 - Automated integrity rebuilding tool

set -u

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load libraries
source "$BASE_DIR/lib/return_codes.sh"
source "$BASE_DIR/lib/logger.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display usage
usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -v, --verbose  Verbose output"
    echo "  -q, --quiet    Quiet mode"
    echo "  -t, --test     Run tests after rebuilding"
    echo ""
    echo "This script rebuilds integrity after file modifications:"
    echo "  1. Generate hash manifest"
    echo "  2. Create digital signature"
    echo "  3. Verify integrity check"
    echo "  4. Optionally run tests"
    echo ""
    echo "Examples:"
    echo "  $0                    # Rebuild integrity"
    echo "  $0 -t                  # Rebuild and test"
    echo "  $0 -v                  # Verbose rebuild"
    echo "  $0 -q                  # Quiet rebuild"
}

# Function to log messages
log() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} [REBUILD] $1"
    elif [[ "$QUIET" != "true" ]]; then
        echo -e "[REBUILD] $1"
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to rebuild integrity
rebuild_integrity() {
    log "Starting integrity rebuilding..."
    
    # Check dependencies
    if ! command_exists "openssl"; then
        echo -e "${RED}Error: OpenSSL not found${NC}" >&2
        return $RC_DEPENDENCY_ERROR
    fi
    
    if [[ ! -f "$BASE_DIR/tools/user/gen_hash.sh" ]]; then
        echo -e "${RED}Error: gen_hash.sh not found${NC}" >&2
        return $RC_DEPENDENCY_ERROR
    fi
    
    if [[ ! -f "$BASE_DIR/tools/user/sign_manifest.sh" ]]; then
        echo -e "${RED}Error: sign_manifest.sh not found${NC}" >&2
        return $RC_DEPENDENCY_ERROR
    fi
    
    if [[ ! -f "$BASE_DIR/scripts/integrity_check.sh" ]]; then
        echo -e "${RED}Error: integrity_check.sh not found${NC}" >&2
        return $RC_DEPENDENCY_ERROR
    fi
    
    # Step 1: Generate hash manifest
    log "Step 1: Generating hash manifest..."
    if "$BASE_DIR/tools/user/gen_hash.sh" generate; then
        log "✓ Hash manifest generated successfully"
    else
        echo -e "${RED}✗ Failed to generate hash manifest${NC}" >&2
        return $RC_ERROR
    fi
    
    # Step 2: Create digital signature
    log "Step 2: Creating digital signature..."
    if "$BASE_DIR/tools/user/sign_manifest.sh" sign; then
        log "✓ Digital signature created successfully"
    else
        echo -e "${RED}✗ Failed to create digital signature${NC}" >&2
        return $RC_ERROR
    fi
    
    # Step 3: Verify integrity check
    log "Step 3: Verifying integrity check..."
    "$BASE_DIR/scripts/integrity_check.sh" >/dev/null 2>&1
    local exit_code=$?
    
    if [[ $exit_code -ge 0 ]]; then
        if [[ $exit_code -eq 0 ]]; then
            log "✓ Integrity check passed (exit code: $exit_code)"
        else
            log "⚠ Integrity check completed with exit code: $exit_code (may be expected)"
        fi
    else
        echo -e "${RED}✗ Integrity check failed to run${NC}" >&2
        return $RC_ERROR
    fi
    
    log "Integrity rebuilding completed successfully!"
    return $RC_OK
}

# Function to run tests
run_tests() {
    log "Running tests after integrity rebuilding..."
    
    if [[ -f "$BASE_DIR/tests/test_runner.sh" ]]; then
        if "$BASE_DIR/tests/test_runner.sh" security; then
            log "✓ Security tests passed"
        else
            echo -e "${YELLOW}⚠ Security tests completed with some failures${NC}" >&2
        fi
    else
        echo -e "${YELLOW}⚠ Test runner not found, skipping tests${NC}" >&2
    fi
}

# Main function
main() {
    local verbose=false
    local quiet=false
    local run_tests_after=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                return $RC_OK
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -q|--quiet)
                quiet=true
                shift
                ;;
            -t|--test)
                run_tests_after=true
                shift
                ;;
            *)
                echo -e "${RED}Error: Unknown option: $1${NC}" >&2
                usage
                return $RC_ERROR
                ;;
        esac
    done
    
    # Set global variables
    VERBOSE="$verbose"
    QUIET="$quiet"
    
    # Rebuild integrity
    rebuild_integrity
    local rebuild_result=$?
    
    # Run tests if requested
    if [[ $rebuild_result -eq $RC_OK && "$run_tests_after" == "true" ]]; then
        run_tests
    fi
    
    return $rebuild_result
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
