#!/bin/bash
# 磁碟監控腳本
# =================
# 功能：監控磁碟使用量
# 回傳：0=OK, 1=WARN, 2=ERROR

set -u

# 全域變數
SCRIPT_NAME="Disk Monitor"
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

# 磁碟使用量讀取
disk_used_pct() {
    local mount_point="${1:-/}"
    df -P "$mount_point" | awk 'NR==2 {gsub(/%/,"",$5); print $5}'
}

# 磁碟檢查
disk_check() {
    local mount_point warn err used
    
    mount_point="${1:-/}"
    warn="${DISK_USED_WARN_PCT:-80}"
    err="${DISK_USED_ERROR_PCT:-90}"
    used="$(disk_used_pct "$mount_point")"
    
    # 防呆檢查
    if [[ -z "$used" ]]; then
        log_error "無法讀取磁碟使用量: $mount_point"
        return 2
    fi
    
    # 檢查磁碟使用量
    if (( used >= err )); then
        log_error "磁碟使用量過高: ${used}% (錯誤閾值: ${err}%)"
        return 2
    fi
    
    if (( used >= warn )); then
        log_warn "磁碟使用量偏高: ${used}% (警告閾值: ${warn}%)"
        return 1
    fi
    
    log_info "磁碟使用量正常: ${used}%"
    return 0
}

# 主要執行邏輯
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    disk_check "/"
    rc=$?
    echo "磁碟使用量: $(disk_used_pct "/")% 狀態碼: $rc"
    exit $rc
fi

