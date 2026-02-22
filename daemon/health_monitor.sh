#!/bin/bash
# daemon/health_monitor.sh
# Main orchestrator: load modules, run checks, print results (journald will capture)

set -u

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Load environment file when running manually (development-friendly)
ENV_FILE="$BASE_DIR/config/health-monitor.env"
if [[ -z "${PING_TARGET:-}" && -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

# Add default fallback for all environment variables
: "${PING_TARGET:=8.8.8.8}"
: "${CHECK_INTERVAL:=30}"
: "${CPU_LOAD_WARN:=1.50}"
: "${CPU_LOAD_ERROR:=3.00}"
: "${MEM_AVAIL_WARN_PCT:=15}"
: "${MEM_AVAIL_ERROR_PCT:=5}"
: "${DISK_USED_WARN_PCT:=80}"
: "${DISK_USED_ERROR_PCT:=90}"
: "${CPU_TEMP_WARN:=65}"
: "${CPU_TEMP_ERROR:=75}"
: "${NETWORK_LATENCY_WARN_MS:=200}"
: "${NETWORK_LATENCY_ERROR_MS:=500}"
: "${NETWORK_PACKET_LOSS_WARN_PCT:=10}"
: "${NETWORK_PACKET_LOSS_ERROR_PCT:=30}"
: "${TEMP_WARNING:=40.0}"
: "${TEMP_ERROR:=45.0}"
: "${HUMIDITY_WARNING:=70.0}"
: "${HUMIDITY_ERROR:=80.0}"
: "${SENSOR_MAX_RETRIES:=3}"
: "${SENSOR_RETRY_DELAY:=1.0}"

# Dependency checking at startup
check_dependencies() {
    local missing_deps=()
    local warning_deps=()
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Checking system dependencies..."
    
    # Check system commands
    local system_commands=("bc" "python3" "pip3")
    for cmd in "${system_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    # Check Python packages
    local python_packages=("adafruit_dht" "RPi.GPIO")
    for package in "${python_packages[@]}"; do
        if ! python3 -c "import $package" &> /dev/null; then
            missing_deps+=("python3-$package")
        fi
    done
    
    # Check systemd availability
    if ! command -v systemctl &> /dev/null; then
        warning_deps+=("systemd (service management will be limited)")
    fi
    
    # Check hardware accessibility
    if [[ "$SENSOR_AVAILABLE" == "true" ]]; then
        if ! python3 -c "import adafruit_dht" &> /dev/null; then
            warning_deps+=("GPIO access (may need sudo or hardware not connected)")
        fi
    fi
    
    # Report results
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Missing required dependencies:"
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] FATAL: Cannot start without required dependencies"
        exit 1
    fi
    
    if [[ ${#warning_deps[@]} -gt 0 ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: Optional dependencies missing:"
        for dep in "${warning_deps[@]}"; do
            echo "  - $dep"
        done
    fi
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] All required dependencies available"
}

# Overall health aggregation
aggregate_health_status() {
    local network_status="$1"
    local cpu_status="$2"
    local memory_status="$3"
    local disk_status="$4"
    local temp_status="$5"
    local sensor_status="$6"
    
    local overall_status=0
    local components=()
    local warnings=()
    local errors=()
    
    # Aggregate component statuses
    components+=("network:$network_status")
    components+=("cpu:$cpu_status")
    components+=("memory:$memory_status")
    components+=("disk:$disk_status")
    components+=("cpu_temp:$temp_status")
    
    # Handle sensor status if available
    if [[ "$SENSOR_AVAILABLE" == "true" ]]; then
        components+=("sensor:$sensor_status")
    fi
    
    # Determine overall status (worst status wins)
    for component in "${components[@]}"; do
        local name="${component%:*}"
        local status="${component#*:}"
        
        case "$status" in
            0) ;;  # OK, no action needed
            1) 
                warnings+=("$name")
                if [[ $overall_status -lt 1 ]]; then
                    overall_status=1
                fi
                ;;
            2) 
                errors+=("$name")
                overall_status=2
                ;;
            *) 
                errors+=("$name")
                overall_status=2
                ;;
        esac
    done
    
    # Output overall health status
    case "$overall_status" in
        0) 
            log_info "OVERALL HEALTH: OK - All systems operational"
            ;;
        1) 
            log_warn "OVERALL HEALTH: WARNING - Issues detected in: ${warnings[*]}"
            ;;
        2) 
            log_error "OVERALL HEALTH: ERROR - Critical issues in: ${errors[*]}"
            ;;
    esac
    
    return $overall_status
}

# Load monitoring modules
source "$BASE_DIR/lib/logger.sh"
source "$BASE_DIR/scripts/network_monitor.sh"
source "$BASE_DIR/scripts/cpu_monitor.sh"
source "$BASE_DIR/scripts/memory_monitor.sh"
source "$BASE_DIR/scripts/disk_monitor.sh"
source "$BASE_DIR/scripts/cpu_temp_monitor.sh"

# Load hardware sensor modules (if available)
SENSOR_SCRIPT="$BASE_DIR/hardware/sensor_monitor.py"
if [[ -f "$SENSOR_SCRIPT" ]]; then
    SENSOR_AVAILABLE=true
else
    SENSOR_AVAILABLE=false
    log_warn "Hardware sensor monitoring script not found: $SENSOR_SCRIPT"
fi

# Required environment variables (provided by systemd EnvironmentFile)
: "${PING_TARGET:?PING_TARGET is required (env)}"
: "${CHECK_INTERVAL:?CHECK_INTERVAL is required (env)}"

cleanup() {
  log_info "Health monitor stopping"
  exit 0
}
trap cleanup SIGINT SIGTERM

# Check dependencies before starting
check_dependencies

log_info "Health monitor started"

while true; do
  # Crash simulation hook (for restart testing)
  if [[ "${FORCE_CRASH:-0}" == "1" ]]; then
    log_error "Simulating CRASH triggered by FORCE_CRASH env"
    exit 1
  fi

  # --- Network ---
  network_rc=0
  network_check || network_rc=$?
  latency=$(network_latency_ms)
  packet_loss=$(network_packet_loss_pct)

  case "$network_rc" in
    0) log_info  "Network OK (target=$PING_TARGET latency=${latency}ms loss=${packet_loss}%)" ;;
    1) log_warn  "Network WARN (target=$PING_TARGET latency=${latency}ms loss=${packet_loss}%)" ;;
    2) 
      # Use error type function provided by network_check
      error_type=$(network_error_type)
      case "$error_type" in
        "connection_failed")
          log_error "Network ERROR (target=$PING_TARGET connection failed)" ;;
        "high_latency")
          log_error "Network ERROR (target=$PING_TARGET high latency=${latency}ms)" ;;
        "high_packet_loss")
          log_error "Network ERROR (target=$PING_TARGET high packet loss=${packet_loss}%)" ;;
        *)
          log_error "Network ERROR (target=$PING_TARGET unknown error)" ;;
      esac
      ;;
    *) log_error "Network UNKNOWN (rc=$network_rc target=$PING_TARGET)" ;;
  esac

  # --- CPU ---
  cpu_rc=0
  cpu_check || cpu_rc=$?
  load1="$(cpu_load1)"

  case "$cpu_rc" in
    0) log_info  "CPU OK (load1=$load1)" ;;
    1) log_warn  "CPU WARN (load1=$load1 warn>=$CPU_LOAD_WARN)" ;;
    2) log_error "CPU ERROR (load1=$load1 error>=$CPU_LOAD_ERROR)" ;;
    *) log_error "CPU UNKNOWN (rc=$cpu_rc load1=$load1)" ;;
  esac

  # --- Memory ---
  mem_rc=0
  memory_check || mem_rc=$?
  avail_pct="$(mem_avail_pct)"

  case "$mem_rc" in
    0) log_info  "Memory OK (avail=${avail_pct}%)" ;;
    1) log_warn  "Memory WARN (avail=${avail_pct}% warn<=${MEM_AVAIL_WARN_PCT}%)" ;;
    2) log_error "Memory ERROR (avail=${avail_pct}% error<=${MEM_AVAIL_ERROR_PCT}%)" ;;
    *) log_error "Memory UNKNOWN (rc=$mem_rc avail=${avail_pct}%)" ;;
  esac

  # --- Disk ---
  disk_rc=0
  disk_check "/" || disk_rc=$?
  disk_used="$(disk_used_pct "/")"

  case "$disk_rc" in
    0) log_info  "Disk OK (used=${disk_used}%)" ;;
    1) log_warn  "Disk WARN (used=${disk_used}% warn>=${DISK_USED_WARN_PCT}%)" ;;
    2) log_error "Disk ERROR (used=${disk_used}% error>=${DISK_USED_ERROR_PCT}%)" ;;
    *) log_error "Disk UNKNOWN (rc=$disk_rc used=${disk_used}%)" ;;
  esac

  # --- CPU Temperature ---
  temp_rc=0
  cpu_temp_check || temp_rc=$?
  cpu_temp=$(cpu_temp_value)

  case "$temp_rc" in
    0) log_info  "CPU Temperature OK (temp=${cpu_temp}°C)" ;;
    1) log_warn  "CPU Temperature WARN (temp=${cpu_temp}°C warn>=${CPU_TEMP_WARN}°C)" ;;
    2) log_error "CPU Temperature ERROR (temp=${cpu_temp}°C error>=${CPU_TEMP_ERROR}°C)" ;;
    *) log_error "CPU Temperature UNKNOWN (rc=$temp_rc temp=${cpu_temp}°C)" ;;
  esac

  # --- Sensor Monitoring ---
  if [[ "$SENSOR_AVAILABLE" == "true" ]]; then
    sensor_rc=0
    # Execute sensor monitoring (test mode)
    python3 "$SENSOR_SCRIPT" --test >/dev/null 2>&1 || sensor_rc=$?
    
    case "$sensor_rc" in
      0) 
        # Parse sensor reading results
        sensor_output=$(python3 "$SENSOR_SCRIPT" --test 2>&1)
        if echo "$sensor_output" | grep -q "Sensor read successful"; then
          temp=$(echo "$sensor_output" | grep -E "Temperature: ([0-9.]+)°C" | sed -r 's/.*Temperature: ([0-9.]+)°C.*/\1/')
          humidity=$(echo "$sensor_output" | grep -E "Humidity: ([0-9.]+)%" | sed -r 's/.*Humidity: ([0-9.]+)%.*/\1/')
          status=$(echo "$sensor_output" | grep -E "Status: ([a-z]+)" | sed -r 's/.*Status: ([a-z]+).*/\1/')
          log_info "Sensor OK (temp=${temp}°C humidity=${humidity}% status=${status})"
        else
          log_warn "Sensor WARN (Read failed)"
        fi
        ;;
      *) 
        log_error "Sensor ERROR (Execution failed)" ;;
    esac
  else
    log_warn "Sensor UNAVAILABLE (Script not found)"
  fi

  # --- Overall Health Aggregation ---
  if [[ "$SENSOR_AVAILABLE" == "true" ]]; then
    aggregate_health_status "$network_rc" "$cpu_rc" "$mem_rc" "$disk_rc" "$temp_rc" "$sensor_rc"
  else
    aggregate_health_status "$network_rc" "$cpu_rc" "$mem_rc" "$disk_rc" "$temp_rc" "0"
  fi

  sleep "$CHECK_INTERVAL"
done
