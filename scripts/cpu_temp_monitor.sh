#!/bin/bash
# CPU 溫度監控腳本
# ===================
# 功能：監控 CPU 溫度
# 回傳：0=OK, 1=WARN, 2=ERROR

set -u

# 全域變數
SCRIPT_NAME="CPU Temperature Monitor"
SCRIPT_VERSION="1.0.0"

# 載入設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# 載入環境變數 (如果存在)
ENV_FILE="$BASE_DIR/config/health-monitor.env"
if [[ -f "$ENV_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$ENV_FILE"
fi

# 預設溫度閾值
CPU_TEMP_WARN=${CPU_TEMP_WARN:-65}
CPU_TEMP_ERROR=${CPU_TEMP_ERROR:-75}

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

# CPU 溫度讀取
read_cpu_temp() {
    local temp_file="/sys/class/thermal/thermal_zone0/temp"
    if [[ -f "$temp_file" ]]; then
        local temp_raw
        temp_raw=$(cat "$temp_file")
        echo "$((temp_raw / 1000))"
    else
        echo "0"
    fi
}

# CPU 溫度檢查
cpu_temp_check() {
    local cpu_temp
    
    cpu_temp=$(read_cpu_temp)
    
    # 檢查溫度範圍
    if [[ $cpu_temp -ge $CPU_TEMP_ERROR ]]; then
        log_error "CPU 溫度過高: ${cpu_temp}°C (錯誤閾值: ${CPU_TEMP_ERROR}°C)"
        return 2
    elif [[ $cpu_temp -ge $CPU_TEMP_WARN ]]; then
        log_warn "CPU 溫度偏高: ${cpu_temp}°C (警告閾值: ${CPU_TEMP_WARN}°C)"
        return 1
    else
        log_info "CPU 溫度正常: ${cpu_temp}°C"
        return 0
    fi
}

# 提供溫度數值給其他腳本使用
cpu_temp_value() {
    read_cpu_temp
}

# 主要執行邏輯
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    cpu_temp_check
    rc=$?
    echo "CPU 溫度: $(cpu_temp_value)°C 狀態碼: $rc"
    exit $rc
fi
