#!/bin/bash
# 網路監控腳本
# =================
# 功能：監控網路連線品質
# 回傳：0=OK, 1=WARN, 2=ERROR

set -u

# 全域變數
SCRIPT_NAME="Network Monitor"
SCRIPT_VERSION="1.0.0"

# 工具函數
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $SCRIPT_NAME: $1"
}

log_warn() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $SCRIPT_NAME: $1" >&2
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $SCRIPT_NAME: $1" >&2
}

# 網路品質讀取函數
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

# 網路錯誤類型判斷
network_error_type() {
    local latency loss warn_latency err_latency warn_loss err_loss
    
    warn_latency="${NETWORK_LATENCY_WARN_MS:-200}"
    err_latency="${NETWORK_LATENCY_ERROR_MS:-500}"
    warn_loss="${NETWORK_PACKET_LOSS_WARN_PCT:-10}"
    err_loss="${NETWORK_PACKET_LOSS_ERROR_PCT:-30}"
    
    latency="$(network_latency_ms)"
    loss="$(network_packet_loss_pct)"
    
    # 檢查連線失敗
    if [[ "$latency" == "0" && "$loss" == "0" ]]; then
        echo "connection_failed"
        return
    fi
    
    # 檢查延遲過高
    if (( $(echo "$latency >= $err_latency" | bc -l 2>/dev/null || echo "0") )); then
        echo "high_latency"
        return
    fi
    
    # 檢查封包遺失過高
    if (( $(echo "$loss >= $err_loss" | bc -l 2>/dev/null || echo "0") )); then
        echo "high_packet_loss"
        return
    fi
    
    echo "unknown"
}

# 網路檢查
network_check() {
    local latency loss warn_latency err_latency warn_loss err_loss
    
    warn_latency="${NETWORK_LATENCY_WARN_MS:-200}"
    err_latency="${NETWORK_LATENCY_ERROR_MS:-500}"
    warn_loss="${NETWORK_PACKET_LOSS_WARN_PCT:-10}"
    err_loss="${NETWORK_PACKET_LOSS_ERROR_PCT:-30}"
    
    latency="$(network_latency_ms)"
    loss="$(network_packet_loss_pct)"
    
    # 檢查連線失敗
    if [[ "$latency" == "0" && "$loss" == "0" ]]; then
        log_error "網路連線失敗: 無法連接到 $PING_TARGET"
        return 2
    fi
    
    # 檢查延遲過高
    if (( $(echo "$latency >= $err_latency" | bc -l 2>/dev/null || echo "0") )); then
        log_error "網路延遲過高: ${latency}ms (錯誤閾值: ${err_latency}ms)"
        return 2
    fi
    
    if (( $(echo "$latency >= $warn_latency" | bc -l 2>/dev/null || echo "0") )); then
        log_warn "網路延遲偏高: ${latency}ms (警告閾值: ${warn_latency}ms)"
        return 1
    fi
    
    # 檢查封包遺失過高
    if (( $(echo "$loss >= $err_loss" | bc -l 2>/dev/null || echo "0") )); then
        log_error "網路封包遺失過高: ${loss}% (錯誤閾值: ${err_loss}%)"
        return 2
    fi
    
    if (( $(echo "$loss >= $warn_loss" | bc -l 2>/dev/null || echo "0") )); then
        log_warn "網路封包遺失偏高: ${loss}% (警告閾值: ${warn_loss}%)"
        return 1
    fi
    
    log_info "網路品質正常: 延遲 ${latency}ms, 封包遺失 ${loss}%"
    return 0
}

# 主要執行邏輯
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    network_check
    rc=$?
    latency="$(network_latency_ms)"
    loss="$(network_packet_loss_pct)"
    error_type=$(network_error_type)
    echo "網路延遲: ${latency}ms, 封包遺失: ${loss}%, 狀態碼: $rc, 錯誤類型: ${error_type}"
    exit $rc
fi

