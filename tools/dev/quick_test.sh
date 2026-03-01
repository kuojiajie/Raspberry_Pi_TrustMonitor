#!/bin/bash

# TrustMonitor Quick Test - Basic System Health Check
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=== TrustMonitor Quick Health Check ==="
echo "Project root: $PROJECT_ROOT"
echo ""

# Test 1: Basic dependencies
echo "🔍 Checking basic dependencies..."
if command -v python3 >/dev/null 2>&1 && command -v systemctl >/dev/null 2>&1; then
    echo "✅ Basic dependencies available"
else
    echo "❌ Missing basic dependencies"
    exit 1
fi

# Test 2: Configuration file
echo "🔍 Checking configuration..."
if [[ -f "$PROJECT_ROOT/config/health-monitor.env" ]]; then
    echo "✅ Configuration file exists"
    source "$PROJECT_ROOT/config/health-monitor.env"
    echo "   - LED pins: RED=$LED_RED_PIN, GREEN=$LED_GREEN_PIN, BLUE=$LED_BLUE_PIN"
    echo "   - DHT11 pin: $DHT11_PIN"
else
    echo "❌ Configuration file missing"
    exit 1
fi

# Test 3: Security files
echo "🔍 Checking security files..."
if [[ -f "$PROJECT_ROOT/data/manifest.sha256" && -f "$PROJECT_ROOT/data/manifest.sha256.sig" ]]; then
    echo "✅ Security files present"
else
    echo "❌ Security files missing"
    exit 1
fi

# Test 4: Service status
echo "🔍 Checking service status..."
if systemctl is-active --quiet health-monitor.service 2>/dev/null; then
    echo "✅ Health monitor service running"
else
    echo "⚠️  Health monitor service not running"
fi

# Test 5: Basic monitoring scripts
echo "🔍 Checking monitoring scripts..."
cd "$PROJECT_ROOT"
if bash scripts/cpu_monitor.sh >/dev/null 2>&1; then
    echo "✅ CPU monitoring works"
else
    echo "❌ CPU monitoring failed"
fi

echo ""
echo "=== Quick Test Completed ==="
echo "For detailed testing, run: bash tools/user/demo.sh"
