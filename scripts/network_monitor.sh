#!/bin/bash
# Network Monitoring Script
# =================
# Purpose: Monitor network connectivity quality
# Returns: 0=OK, 1=WARN, 2=ERROR

set -u

# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load environment variables (if exists)
ENV_FILE="$BASE_DIR/config/health-monitor.env"
if [[ -f "$ENV_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$ENV_FILE"
fi

# Global variables
SCRIPT_NAME="Network Monitor"

# Utility functions
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $SCRIPT_NAME: $1"
}

log_warn() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $SCRIPT_NAME: $1" >&2
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $SCRIPT_NAME: $1" >&2
}

# Network quality reading functions
network_latency_ms() {
    local latency
    latency="$(ping -c 3 "$PING_TARGET" 2>/dev/null | tail -1 | awk -F'/' '{print $5}')"
    echo "${latency:-0}"
}

network_packet_loss_pct() {
    local loss
    loss="$(ping -c 3 "$PING_TARGET" 2>/dev/null | grep 'packet loss' | awk -F'%' '{print $1}' | awk '{print $NF}')"
    echo "${loss:-0}"
}

# Network error type determination
network_error_type() {
    local latency loss warn_latency err_latency warn_loss err_loss
    
    warn_latency="${NETWORK_LATENCY_WARN_MS:-200}"
    err_latency="${NETWORK_LATENCY_ERROR_MS:-500}"
    warn_loss="${NETWORK_PACKET_LOSS_WARN_PCT:-10}"
    err_loss="${NETWORK_PACKET_LOSS_ERROR_PCT:-30}"
    
    latency="$(network_latency_ms)"
    loss="$(network_packet_loss_pct)"
    
    # Check connection failure
    if [[ "$latency" == "0" && "$loss" == "0" ]]; then
        echo "connection_failed"
        return
    fi
    
    # Check high latency
    if (( $(echo "$latency >= $err_latency" | bc -l 2>/dev/null || echo "0") )); then
        echo "high_latency"
        return
    fi
    
    # Check high packet loss
    if (( $(echo "$loss >= $err_loss" | bc -l 2>/dev/null || echo "0") )); then
        echo "high_packet_loss"
        return
    fi
    
    echo "unknown"
}

# Network check
network_check() {
    local latency loss warn_latency err_latency warn_loss err_loss
    
    warn_latency="${NETWORK_LATENCY_WARN_MS:-200}"
    err_latency="${NETWORK_LATENCY_ERROR_MS:-500}"
    warn_loss="${NETWORK_PACKET_LOSS_WARN_PCT:-10}"
    err_loss="${NETWORK_PACKET_LOSS_ERROR_PCT:-30}"
    
    latency="$(network_latency_ms)"
    loss="$(network_packet_loss_pct)"
    
    # Check connection failure
    if [[ "$latency" == "0" && "$loss" == "0" ]]; then
        log_error "Network connection failed: Cannot connect to $PING_TARGET"
        return 2
    fi
    
    # Check high latency
    if (( $(echo "$latency >= $err_latency" | bc -l 2>/dev/null || echo "0") )); then
        log_error "Network latency too high: ${latency}ms (error threshold: ${err_latency}ms)"
        return 2
    fi
    
    if (( $(echo "$latency >= $warn_latency" | bc -l 2>/dev/null || echo "0") )); then
        log_warn "Network latency high: ${latency}ms (warning threshold: ${warn_latency}ms)"
        return 1
    fi
    
    # Check high packet loss
    if (( $(echo "$loss >= $err_loss" | bc -l 2>/dev/null || echo "0") )); then
        log_error "Network packet loss too high: ${loss}% (error threshold: ${err_loss}%)"
        return 2
    fi
    
    if (( $(echo "$loss >= $warn_loss" | bc -l 2>/dev/null || echo "0") )); then
        log_warn "Network packet loss high: ${loss}% (warning threshold: ${warn_loss}%)"
        return 1
    fi
    
    log_info "Network quality normal: latency=${latency}ms, loss=${loss}%"
    return 0
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    network_check
    rc=$?
    latency="$(network_latency_ms)"
    loss="$(network_packet_loss_pct)"
    error_type=$(network_error_type)
    echo "Network latency: ${latency}ms, packet loss: ${loss}%, status code: $rc, error type: ${error_type}"
    exit $rc
fi
