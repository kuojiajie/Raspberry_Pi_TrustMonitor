#!/bin/bash

# Simple test runner
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=== TrustMonitor Quick Test Runner ==="
echo "Project root: $PROJECT_ROOT"

# Test scripts
declare -a TESTS=(
    "test_hal_core.sh"
    "test_hal_refactor.sh"
    "test_system_integration.sh"
)

TOTAL=0
PASSED=0
FAILED=0

for test_script in "${TESTS[@]}"; do
    echo "Running: $test_script"
    ((TOTAL++))
    
    # GPIO cleanup before each test
    if [[ -f "$PROJECT_ROOT/tools/dev/cleanup_gpio.sh" ]]; then
        echo "  Cleaning up GPIO..."
        "$PROJECT_ROOT/tools/dev/cleanup_gpio.sh" >/dev/null 2>&1
    fi
    
    if timeout 60 "$SCRIPT_DIR/$test_script" > /dev/null 2>&1; then
        echo "✅ PASS: $test_script"
        ((PASSED++))
    else
        echo "❌ FAIL: $test_script"
        ((FAILED++))
    fi
    echo
done

echo "=== Results ==="
echo "Total: $TOTAL"
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if [[ $FAILED -eq 0 ]]; then
    echo "🎉 All tests passed!"
    exit 0
else
    echo "❌ Some tests failed!"
    exit 1
fi
