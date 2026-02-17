#!/bin/bash
# 記憶體監控腳本
# ===================
# 功能：監控系統記憶體使用量
# 回傳：0=OK, 1=WARN, 2=ERROR

set -u

# 全域變數
SCRIPT_NAME="Memory Monitor"
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

# 記憶體讀取函數
mem_total_kb() {
    awk '/^MemTotal:/ {print $2}' /proc/meminfo
}

mem_avail_kb() {
    awk '/^MemAvailable:/ {print $2}' /proc/meminfo
}

mem_avail_pct() {
    local total avail
    
    total="$(mem_total_kb)"
    avail="$(mem_avail_kb)"
    
    # 防呆檢查
    if [[ -z "$total" || "$total" -le 0 || -z "$avail" ]]; then
        echo "0"
        return
    fi
    
    echo $(( avail * 100 / total ))
}

# 記憶體檢查
memory_check() {
    local warn_pct err_pct avail_pct
    
    warn_pct="${MEM_AVAIL_WARN_PCT:-15}"
    err_pct="${MEM_AVAIL_ERROR_PCT:-5}"
    avail_pct="$(mem_avail_pct)"
    
    # 檢查記憶體可用量
    if (( avail_pct <= err_pct )); then
        log_error "記憶體可用量過低: ${avail_pct}% (錯誤閾值: ${err_pct}%)"
        return 2
    fi
    
    if (( avail_pct <= warn_pct )); then
        log_warn "記憶體可用量偏低: ${avail_pct}% (警告閾值: ${warn_pct}%)"
        return 1
    fi
    
    log_info "記憶體可用量正常: ${avail_pct}%"
    return 0
}

# 主要執行邏輯
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    memory_check
    rc=$?
    echo "記憶體可用量: $(mem_avail_pct)% 狀態碼: $rc"
    exit $rc
fi

