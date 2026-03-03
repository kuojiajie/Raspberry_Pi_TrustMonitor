#!/bin/bash
# tools/dev/quick_test_with_integrity.sh
# Quick test with automatic integrity rebuilding
# v1.0.0 - Quick testing with integrity check

set -u

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

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
    echo "  -t, --type     Test type (unit|integration|security|all)"
    echo "  -v, --verbose  Verbose output"
    echo "  -q, --quiet    Quiet mode"
    echo ""
    echo "This script runs tests with automatic integrity rebuilding:"
    echo "  1. Rebuild integrity (hash + signature)"
    echo "  2. Run specified tests"
    echo ""
    echo "Examples:"
    echo "  $0                    # Run all tests with integrity"
    echo "  $0 -t unit            # Run unit tests with integrity"
    echo "  $0 -t security        # Run security tests with integrity"
    echo "  $0 -v                  # Verbose mode"
    echo "  $0 -q                  # Quiet mode"
}

# Function to log messages
log() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} [QUICK_TEST] $1"
    elif [[ "$QUIET" != "true" ]]; then
        echo -e "[QUICK_TEST] $1"
    fi
}

# Function to rebuild integrity
rebuild_integrity() {
    log "Rebuilding integrity before testing..."
    
    # Check if rebuild script exists
    if [[ ! -f "$BASE_DIR/tools/dev/rebuild_integrity.sh" ]]; then
        echo -e "${RED}Error: rebuild_integrity.sh not found${NC}" >&2
        return 1
    fi
    
    # Run integrity rebuild
    if "$BASE_DIR/tools/dev/rebuild_integrity.sh" -q; then
        log "✓ Integrity rebuilt successfully"
        return 0
    else
        echo -e "${RED}✗ Integrity rebuild failed${NC}" >&2
        return 1
    fi
}

# Function to run tests
run_tests() {
    local test_type="$1"
    log "Running $test_type tests..."
    
    # Check if test runner exists
    if [[ ! -f "$BASE_DIR/tests/test_runner.sh" ]]; then
        echo -e "${RED}Error: test_runner.sh not found${NC}" >&2
        return 1
    fi
    
    # Run tests
    case "$test_type" in
        unit)
            "$BASE_DIR/tests/test_runner.sh" unit
            ;;
        integration)
            "$BASE_DIR/tests/test_runner.sh" integration
            ;;
        security)
            "$BASE_DIR/tests/test_runner.sh" security
            ;;
        all)
            "$BASE_DIR/tests/test_runner.sh"
            ;;
        *)
            echo -e "${RED}Error: Invalid test type: $test_type${NC}" >&2
            return 1
            ;;
    esac
}

# Main function
main() {
    local test_type="all"
    local verbose=false
    local quiet=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -t|--type)
                test_type="$2"
                shift 2
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -q|--quiet)
                quiet=true
                shift
                ;;
            *)
                echo -e "${RED}Error: Unknown option: $1${NC}" >&2
                usage
                exit 1
                ;;
        esac
    done
    
    # Set global variables
    VERBOSE="$verbose"
    QUIET="$quiet"
    
    # Validate test type
    case "$test_type" in
        unit|integration|security|all)
            ;;
        *)
            echo -e "${RED}Error: Invalid test type: $test_type${NC}" >&2
            echo "Valid types: unit, integration, security, all" >&2
            exit 1
            ;;
    esac
    
    # Rebuild integrity
    if ! rebuild_integrity; then
        echo -e "${RED}Failed to rebuild integrity, aborting tests${NC}" >&2
        exit 1
    fi
    
    # Run tests
    if ! run_tests "$test_type"; then
        echo -e "${RED}Tests failed${NC}" >&2
        exit 1
    fi
    
    echo -e "${GREEN}✓ Quick test with integrity completed successfully${NC}"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
