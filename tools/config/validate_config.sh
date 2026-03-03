#!/bin/bash
# tools/config/validate_config.sh
# Configuration validation tool for TrustMonitor
# Validates configuration files and provides detailed error messages

set -u

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load libraries
source "$BASE_DIR/lib/return_codes.sh"
source "$BASE_DIR/lib/logger.sh"

# Configuration file path
CONFIG_FILE="${BASE_DIR}/config/health-monitor.env"

# Validation results
VALIDATION_ERRORS=()
VALIDATION_WARNINGS=()

# ==============================================================================
# Validation Functions
# ==============================================================================

validate_dht11_pin() {
    log_info "Validating DHT11 pin configuration..."
    
    if [[ -z "${DHT11_PIN:-}" ]]; then
        VALIDATION_ERRORS+=("DHT11_PIN not defined in configuration")
        return $RC_ERROR
    fi
    
    # Check if DHT11_PIN is a valid GPIO pin number
    if ! [[ "$DHT11_PIN" =~ ^[0-9]+$ ]]; then
        VALIDATION_ERRORS+=("DHT11_PIN must be a numeric GPIO pin number, got: $DHT11_PIN")
        return $RC_ERROR
    fi
    
    # Check valid GPIO pin range for Raspberry Pi (0-27 for Pi 4)
    if [[ "$DHT11_PIN" -lt 0 ]] || [[ "$DHT11_PIN" -gt 27 ]]; then
        VALIDATION_ERRORS+=("DHT11_PIN must be between 0-27 for Raspberry Pi, got: $DHT11_PIN")
        return $RC_ERROR
    fi
    
    # Check for common valid DHT11 pins
    local valid_dht11_pins=(4 17 18 22 23 24 25 27)
    local pin_valid=false
    
    for valid_pin in "${valid_dht11_pins[@]}"; do
        if [[ "$DHT11_PIN" -eq "$valid_pin" ]]; then
            pin_valid=true
            break
        fi
    done
    
    if [[ "$pin_valid" == "false" ]]; then
        VALIDATION_WARNINGS+=("DHT11_PIN=$DHT11_PIN may not be optimal. Recommended pins: ${valid_dht11_pins[*]}")
    fi
    
    log_info "DHT11 pin validation passed: GPIO $DHT11_PIN"
    return $RC_OK
}

validate_temperature_thresholds() {
    log_info "Validating temperature thresholds..."
    
    # Check CPU temperature thresholds
    if [[ -z "${CPU_TEMP_WARN:-}" ]]; then
        VALIDATION_ERRORS+=("CPU_TEMP_WARN not defined in configuration")
        return $RC_ERROR
    fi
    
    if [[ -z "${CPU_TEMP_ERROR:-}" ]]; then
        VALIDATION_ERRORS+=("CPU_TEMP_ERROR not defined in configuration")
        return $RC_ERROR
    fi
    
    # Validate numeric format
    if ! [[ "$CPU_TEMP_WARN" =~ ^[0-9]+\.?[0-9]*$ ]]; then
        VALIDATION_ERRORS+=("CPU_TEMP_WARN must be a numeric value, got: $CPU_TEMP_WARN")
        return $RC_ERROR
    fi
    
    if ! [[ "$CPU_TEMP_ERROR" =~ ^[0-9]+\.?[0-9]*$ ]]; then
        VALIDATION_ERRORS+=("CPU_TEMP_ERROR must be a numeric value, got: $CPU_TEMP_ERROR")
        return $RC_ERROR
    fi
    
    # Check logical relationship (warning < error)
    if (( $(awk "BEGIN {print ($CPU_TEMP_WARN >= $CPU_TEMP_ERROR)}") )); then
        VALIDATION_ERRORS+=("CPU_TEMP_WARN ($CPU_TEMP_WARN) must be less than CPU_TEMP_ERROR ($CPU_TEMP_ERROR)")
        return $RC_ERROR
    fi
    
    # Check safe temperature ranges for Raspberry Pi
    if (( $(awk "BEGIN {print ($CPU_TEMP_WARN > 80)}") )); then
        VALIDATION_WARNINGS+=("CPU_TEMP_WARN ($CPU_TEMP_WARN) is above safe operating range for Raspberry Pi (max 85°C)")
    fi
    
    if (( $(awk "BEGIN {print ($CPU_TEMP_ERROR > 85)}") )); then
        VALIDATION_ERRORS+=("CPU_TEMP_ERROR ($CPU_TEMP_ERROR) exceeds maximum safe temperature for Raspberry Pi (85°C)")
        return $RC_ERROR
    fi
    
    # Check sensor temperature thresholds if defined
    if [[ -n "${TEMP_WARNING:-}" ]]; then
        if ! [[ "$TEMP_WARNING" =~ ^[0-9]+\.?[0-9]*$ ]]; then
            VALIDATION_ERRORS+=("TEMP_WARNING must be a numeric value, got: $TEMP_WARNING")
            return $RC_ERROR
        fi
    fi
    
    if [[ -n "${TEMP_ERROR:-}" ]]; then
        if ! [[ "$TEMP_ERROR" =~ ^[0-9]+\.?[0-9]*$ ]]; then
            VALIDATION_ERRORS+=("TEMP_ERROR must be a numeric value, got: $TEMP_ERROR")
            return $RC_ERROR
        fi
    fi
    
    if [[ -n "${TEMP_WARNING:-}" && -n "${TEMP_ERROR:-}" ]]; then
        if (( $(awk "BEGIN {print ($TEMP_WARNING >= $TEMP_ERROR)}") )); then
            VALIDATION_ERRORS+=("TEMP_WARNING ($TEMP_WARNING) must be less than TEMP_ERROR ($TEMP_ERROR)")
            return $RC_ERROR
        fi
    fi
    
    log_info "Temperature thresholds validation passed"
    return $RC_OK
}

validate_led_pins() {
    log_info "Validating LED pin configuration..."
    
    # Check LED pin definitions
    local led_pins=("LED_RED_PIN" "LED_GREEN_PIN" "LED_BLUE_PIN")
    local required_pins=3
    
    for pin_var in "${led_pins[@]}"; do
        if [[ -z "${!pin_var:-}" ]]; then
            VALIDATION_ERRORS+=("$pin_var not defined in configuration")
            return $RC_ERROR
        fi
        
        local pin_value="${!pin_var}"
        
        # Check if pin is numeric
        if ! [[ "$pin_value" =~ ^[0-9]+$ ]]; then
            VALIDATION_ERRORS+=("$pin_var must be a numeric GPIO pin number, got: $pin_value")
            return $RC_ERROR
        fi
        
        # Check valid GPIO pin range
        if [[ "$pin_value" -lt 0 ]] || [[ "$pin_value" -gt 27 ]]; then
            VALIDATION_ERRORS+=("$pin_var must be between 0-27 for Raspberry Pi, got: $pin_value")
            return $RC_ERROR
        fi
    done
    
    # Check for pin conflicts
    local pin_values=("${LED_RED_PIN}" "${LED_GREEN_PIN}" "${LED_BLUE_PIN}")
    local unique_pins=($(printf "%s\n" "${pin_values[@]}" | sort -u))
    
    if [[ ${#unique_pins[@]} -ne ${#pin_values[@]} ]]; then
        VALIDATION_ERRORS+=("LED pins must be unique. Found duplicate pins: ${pin_values[*]}")
        return $RC_ERROR
    fi
    
    # Check for common valid LED pins
    local valid_led_pins=(5 6 12 13 16 17 18 19 20 21 22 23 24 25 26 27)
    local all_pins_valid=true
    
    for pin_value in "${pin_values[@]}"; do
        local pin_valid=false
        for valid_pin in "${valid_led_pins[@]}"; do
            if [[ "$pin_value" -eq "$valid_pin" ]]; then
                pin_valid=true
                break
            fi
        done
        
        if [[ "$pin_valid" == "false" ]]; then
            VALIDATION_WARNINGS+=("LED pin $pin_value may not be optimal. Recommended pins: ${valid_led_pins[*]}")
        fi
    done
    
    log_info "LED pin validation passed: RED=${LED_RED_PIN}, GREEN=${LED_GREEN_PIN}, BLUE=${LED_BLUE_PIN}"
    return $RC_OK
}

validate_network_config() {
    log_info "Validating network configuration..."
    
    # Check PING_TARGET
    if [[ -z "${PING_TARGET:-}" ]]; then
        VALIDATION_ERRORS+=("PING_TARGET not defined in configuration")
        return $RC_ERROR
    fi
    
    # Validate IP address or hostname format
    if [[ "$PING_TARGET" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        # IP address validation
        IFS='.' read -ra ADDR <<< "$PING_TARGET"
        local ip_valid=true
        
        for octet in "${ADDR[@]}"; do
            if [[ "$octet" -lt 0 ]] || [[ "$octet" -gt 255 ]]; then
                ip_valid=false
                break
            fi
        done
        
        if [[ "$ip_valid" == "false" ]]; then
            VALIDATION_ERRORS+=("PING_TARGET is not a valid IP address: $PING_TARGET")
            return $RC_ERROR
        fi
    else
        # Hostname validation (basic)
        if [[ ! "$PING_TARGET" =~ ^[a-zA-Z0-9.-]+$ ]]; then
            VALIDATION_ERRORS+=("PING_TARGET is not a valid hostname: $PING_TARGET")
            return $RC_ERROR
        fi
    fi
    
    # Check NETWORK_TIMEOUT
    if [[ -z "${NETWORK_TIMEOUT:-}" ]]; then
        VALIDATION_ERRORS+=("NETWORK_TIMEOUT not defined in configuration")
        return $RC_ERROR
    fi
    
    if ! [[ "$NETWORK_TIMEOUT" =~ ^[0-9]+$ ]]; then
        VALIDATION_ERRORS+=("NETWORK_TIMEOUT must be a numeric value, got: $NETWORK_TIMEOUT")
        return $RC_ERROR
    fi
    
    if [[ "$NETWORK_TIMEOUT" -lt 1 ]] || [[ "$NETWORK_TIMEOUT" -gt 30 ]]; then
        VALIDATION_WARNINGS+=("NETWORK_TIMEOUT ($NETWORK_TIMEOUT) should be between 1-30 seconds")
    fi
    
    # Check network quality thresholds if defined
    if [[ -n "${NETWORK_LATENCY_WARN_MS:-}" ]]; then
        if ! [[ "$NETWORK_LATENCY_WARN_MS" =~ ^[0-9]+$ ]]; then
            VALIDATION_ERRORS+=("NETWORK_LATENCY_WARN_MS must be numeric, got: $NETWORK_LATENCY_WARN_MS")
            return $RC_ERROR
        fi
    fi
    
    if [[ -n "${NETWORK_LATENCY_ERROR_MS:-}" ]]; then
        if ! [[ "$NETWORK_LATENCY_ERROR_MS" =~ ^[0-9]+$ ]]; then
            VALIDATION_ERRORS+=("NETWORK_LATENCY_ERROR_MS must be numeric, got: $NETWORK_LATENCY_ERROR_MS")
            return $RC_ERROR
        fi
    fi
    
    if [[ -n "${NETWORK_PACKET_LOSS_WARN_PCT:-}" ]]; then
        if ! [[ "$NETWORK_PACKET_LOSS_WARN_PCT" =~ ^[0-9]+$ ]]; then
            VALIDATION_ERRORS+=("NETWORK_PACKET_LOSS_WARN_PCT must be numeric, got: $NETWORK_PACKET_LOSS_WARN_PCT")
            return $RC_ERROR
        fi
        
        if [[ "$NETWORK_PACKET_LOSS_WARN_PCT" -gt 100 ]]; then
            VALIDATION_ERRORS+=("NETWORK_PACKET_LOSS_WARN_PCT cannot exceed 100%, got: $NETWORK_PACKET_LOSS_WARN_PCT")
            return $RC_ERROR
        fi
    fi
    
    log_info "Network configuration validation passed: PING_TARGET=$PING_TARGET, NETWORK_TIMEOUT=${NETWORK_TIMEOUT}s"
    return $RC_OK
}

validate_system_thresholds() {
    log_info "Validating system thresholds..."
    
    # Check CPU load thresholds
    if [[ -z "${CPU_LOAD_WARN:-}" ]]; then
        VALIDATION_ERRORS+=("CPU_LOAD_WARN not defined in configuration")
        return $RC_ERROR
    fi
    
    if [[ -z "${CPU_LOAD_ERROR:-}" ]]; then
        VALIDATION_ERRORS+=("CPU_LOAD_ERROR not defined in configuration")
        return $RC_ERROR
    fi
    
    # Validate CPU load format
    if ! [[ "$CPU_LOAD_WARN" =~ ^[0-9]+\.?[0-9]*$ ]]; then
        VALIDATION_ERRORS+=("CPU_LOAD_WARN must be a numeric value, got: $CPU_LOAD_WARN")
        return $RC_ERROR
    fi
    
    if ! [[ "$CPU_LOAD_ERROR" =~ ^[0-9]+\.?[0-9]*$ ]]; then
        VALIDATION_ERRORS+=("CPU_LOAD_ERROR must be a numeric value, got: $CPU_LOAD_ERROR")
        return $RC_ERROR
    fi
    
    # Check CPU load logical relationship
    if (( $(awk "BEGIN {print ($CPU_LOAD_WARN >= $CPU_LOAD_ERROR)}") )); then
        VALIDATION_ERRORS+=("CPU_LOAD_WARN ($CPU_LOAD_WARN) must be less than CPU_LOAD_ERROR ($CPU_LOAD_ERROR)")
        return $RC_ERROR
    fi
    
    # Check CPU load reasonable ranges
    if (( $(awk "BEGIN {print ($CPU_LOAD_WARN > 10)}") )); then
        VALIDATION_WARNINGS+=("CPU_LOAD_WARN ($CPU_LOAD_WARN) is very high. Consider values between 1.0-3.0")
    fi
    
    if (( $(awk "BEGIN {print ($CPU_LOAD_ERROR > 20)}") )); then
        VALIDATION_WARNINGS+=("CPU_LOAD_ERROR ($CPU_LOAD_ERROR) is extremely high. Consider values between 2.0-5.0")
    fi
    
    # Check memory thresholds
    if [[ -z "${MEM_AVAIL_WARN_PCT:-}" ]]; then
        VALIDATION_ERRORS+=("MEM_AVAIL_WARN_PCT not defined in configuration")
        return $RC_ERROR
    fi
    
    if [[ -z "${MEM_AVAIL_ERROR_PCT:-}" ]]; then
        VALIDATION_ERRORS+=("MEM_AVAIL_ERROR_PCT not defined in configuration")
        return $RC_ERROR
    fi
    
    # Validate memory threshold format
    if ! [[ "$MEM_AVAIL_WARN_PCT" =~ ^[0-9]+$ ]]; then
        VALIDATION_ERRORS+=("MEM_AVAIL_WARN_PCT must be a numeric percentage, got: $MEM_AVAIL_WARN_PCT")
        return $RC_ERROR
    fi
    
    if ! [[ "$MEM_AVAIL_ERROR_PCT" =~ ^[0-9]+$ ]]; then
        VALIDATION_ERRORS+=("MEM_AVAIL_ERROR_PCT must be a numeric percentage, got: $MEM_AVAIL_ERROR_PCT")
        return $RC_ERROR
    fi
    
    # Check memory threshold ranges
    if [[ "$MEM_AVAIL_WARN_PCT" -lt 1 ]] || [[ "$MEM_AVAIL_WARN_PCT" -gt 100 ]]; then
        VALIDATION_ERRORS+=("MEM_AVAIL_WARN_PCT must be between 1-100%, got: $MEM_AVAIL_WARN_PCT")
        return $RC_ERROR
    fi
    
    if [[ "$MEM_AVAIL_ERROR_PCT" -lt 1 ]] || [[ "$MEM_AVAIL_ERROR_PCT" -gt 100 ]]; then
        VALIDATION_ERRORS+=("MEM_AVAIL_ERROR_PCT must be between 1-100%, got: $MEM_AVAIL_ERROR_PCT")
        return $RC_ERROR
    fi
    
    # Check memory logical relationship (error < warning for availability)
    if [[ "$MEM_AVAIL_WARN_PCT" -le "$MEM_AVAIL_ERROR_PCT" ]]; then
        VALIDATION_ERRORS+=("MEM_AVAIL_WARN_PCT ($MEM_AVAIL_WARN_PCT) must be greater than MEM_AVAIL_ERROR_PCT ($MEM_AVAIL_ERROR_PCT) for availability thresholds")
        return $RC_ERROR
    fi
    
    # Check memory reasonable ranges
    if [[ "$MEM_AVAIL_WARN_PCT" -gt 50 ]]; then
        VALIDATION_WARNINGS+=("MEM_AVAIL_WARN_PCT ($MEM_AVAIL_WARN_PCT) is very high. Consider values between 10-20%")
    fi
    
    if [[ "$MEM_AVAIL_ERROR_PCT" -gt 20 ]]; then
        VALIDATION_WARNINGS+=("MEM_AVAIL_ERROR_PCT ($MEM_AVAIL_ERROR_PCT) is very high. Consider values between 5-10%")
    fi
    
    # Check disk thresholds
    if [[ -z "${DISK_USED_WARN_PCT:-}" ]]; then
        VALIDATION_ERRORS+=("DISK_USED_WARN_PCT not defined in configuration")
        return $RC_ERROR
    fi
    
    if [[ -z "${DISK_USED_ERROR_PCT:-}" ]]; then
        VALIDATION_ERRORS+=("DISK_USED_ERROR_PCT not defined in configuration")
        return $RC_ERROR
    fi
    
    # Validate disk threshold format
    if ! [[ "$DISK_USED_WARN_PCT" =~ ^[0-9]+$ ]]; then
        VALIDATION_ERRORS+=("DISK_USED_WARN_PCT must be a numeric percentage, got: $DISK_USED_WARN_PCT")
        return $RC_ERROR
    fi
    
    if ! [[ "$DISK_USED_ERROR_PCT" =~ ^[0-9]+$ ]]; then
        VALIDATION_ERRORS+=("DISK_USED_ERROR_PCT must be a numeric percentage, got: $DISK_USED_ERROR_PCT")
        return $RC_ERROR
    fi
    
    # Check disk threshold ranges
    if [[ "$DISK_USED_WARN_PCT" -lt 1 ]] || [[ "$DISK_USED_WARN_PCT" -gt 100 ]]; then
        VALIDATION_ERRORS+=("DISK_USED_WARN_PCT must be between 1-100%, got: $DISK_USED_WARN_PCT")
        return $RC_ERROR
    fi
    
    if [[ "$DISK_USED_ERROR_PCT" -lt 1 ]] || [[ "$DISK_USED_ERROR_PCT" -gt 100 ]]; then
        VALIDATION_ERRORS+=("DISK_USED_ERROR_PCT must be between 1-100%, got: $DISK_USED_ERROR_PCT")
        return $RC_ERROR
    fi
    
    # Check disk logical relationship (warning < error for usage)
    if [[ "$DISK_USED_WARN_PCT" -ge "$DISK_USED_ERROR_PCT" ]]; then
        VALIDATION_ERRORS+=("DISK_USED_WARN_PCT ($DISK_USED_WARN_PCT) must be less than DISK_USED_ERROR_PCT ($DISK_USED_ERROR_PCT) for usage thresholds")
        return $RC_ERROR
    fi
    
    # Check disk reasonable ranges
    if [[ "$DISK_USED_WARN_PCT" -lt 70 ]]; then
        VALIDATION_WARNINGS+=("DISK_USED_WARN_PCT ($DISK_USED_WARN_PCT) is very low. Consider values between 75-85%")
    fi
    
    if [[ "$DISK_USED_ERROR_PCT" -gt 98 ]]; then
        VALIDATION_WARNINGS+=("DISK_USED_ERROR_PCT ($DISK_USED_ERROR_PCT) is very high. Consider values between 90-95%")
    fi
    
    log_info "System thresholds validation passed: CPU(${CPU_LOAD_WARN}/${CPU_LOAD_WARN}), MEM(${MEM_AVAIL_WARN_PCT}%/${MEM_AVAIL_ERROR_PCT}%), DISK(${DISK_USED_WARN_PCT}%/${DISK_USED_ERROR_PCT}%)"
    return $RC_OK
}

validate_paths() {
    log_info "Validating path configuration..."
    
    # Check PROJECT_ROOT
    if [[ -z "${PROJECT_ROOT:-}" ]]; then
        VALIDATION_ERRORS+=("PROJECT_ROOT not defined in configuration")
        return $RC_ERROR
    fi
    
    # Check if PROJECT_ROOT is absolute path
    if [[ ! "$PROJECT_ROOT" =~ ^/ ]]; then
        VALIDATION_ERRORS+=("PROJECT_ROOT must be an absolute path, got: $PROJECT_ROOT")
        return $RC_ERROR
    fi
    
    # Check if PROJECT_ROOT exists
    if [[ ! -d "$PROJECT_ROOT" ]]; then
        VALIDATION_ERRORS+=("PROJECT_ROOT directory does not exist: $PROJECT_ROOT")
        return $RC_ERROR
    fi
    
    # Check PROJECT_ROOT permissions
    if [[ ! -r "$PROJECT_ROOT" ]]; then
        VALIDATION_ERRORS+=("PROJECT_ROOT is not readable: $PROJECT_ROOT")
        return $RC_ERROR
    fi
    
    # Check DATA_DIR
    if [[ -z "${DATA_DIR:-}" ]]; then
        VALIDATION_ERRORS+=("DATA_DIR not defined in configuration")
        return $RC_ERROR
    fi
    
    # Check if DATA_DIR is absolute path
    if [[ ! "$DATA_DIR" =~ ^/ ]]; then
        VALIDATION_ERRORS+=("DATA_DIR must be an absolute path, got: $DATA_DIR")
        return $RC_ERROR
    fi
    
    # Check if DATA_DIR exists or can be created
    if [[ ! -d "$DATA_DIR" ]]; then
        # Try to create DATA_DIR
        if ! mkdir -p "$DATA_DIR" 2>/dev/null; then
            VALIDATION_ERRORS+=("DATA_DIR does not exist and cannot be created: $DATA_DIR")
            return $RC_ERROR
        fi
        VALIDATION_WARNINGS+=("DATA_DIR was created automatically: $DATA_DIR")
    fi
    
    # Check DATA_DIR permissions
    if [[ ! -w "$DATA_DIR" ]]; then
        VALIDATION_ERRORS+=("DATA_DIR is not writable: $DATA_DIR")
        return $RC_ERROR
    fi
    
    # Check KEYS_DIR
    if [[ -z "${KEYS_DIR:-}" ]]; then
        VALIDATION_ERRORS+=("KEYS_DIR not defined in configuration")
        return $RC_ERROR
    fi
    
    # Check if KEYS_DIR is absolute path
    if [[ ! "$KEYS_DIR" =~ ^/ ]]; then
        VALIDATION_ERRORS+=("KEYS_DIR must be an absolute path, got: $KEYS_DIR")
        return $RC_ERROR
    fi
    
    # Check if KEYS_DIR exists or can be created
    if [[ ! -d "$KEYS_DIR" ]]; then
        # Try to create KEYS_DIR
        if ! mkdir -p "$KEYS_DIR" 2>/dev/null; then
            VALIDATION_ERRORS+=("KEYS_DIR does not exist and cannot be created: $KEYS_DIR")
            return $RC_ERROR
        fi
        VALIDATION_WARNINGS+=("KEYS_DIR was created automatically: $KEYS_DIR")
    fi
    
    # Check KEYS_DIR permissions (should be secure)
    if [[ ! -w "$KEYS_DIR" ]]; then
        VALIDATION_ERRORS+=("KEYS_DIR is not writable: $KEYS_DIR")
        return $RC_ERROR
    fi
    
    # Check KEYS_DIR security (should not be world-readable)
    if [[ -r "$KEYS_DIR" && $(stat -c %a "$KEYS_DIR" 2>/dev/null) =~ [0-9]*[0-9][0-9] ]]; then
        local perms=$(stat -c %a "$KEYS_DIR" 2>/dev/null)
        if [[ "${perms: -1}" -ge 4 ]]; then
            VALIDATION_WARNINGS+=("KEYS_DIR is world-readable (${perms}). Consider securing with chmod 700")
        fi
    fi
    
    # Check path relationships
    if [[ ! "$DATA_DIR" =~ ^"$PROJECT_ROOT" ]]; then
        VALIDATION_WARNINGS+=("DATA_DIR ($DATA_DIR) is not within PROJECT_ROOT ($PROJECT_ROOT)")
    fi
    
    if [[ ! "$KEYS_DIR" =~ ^"$PROJECT_ROOT" ]]; then
        VALIDATION_WARNINGS+=("KEYS_DIR ($KEYS_DIR) is not within PROJECT_ROOT ($PROJECT_ROOT)")
    fi
    
    log_info "Path configuration validation passed: PROJECT_ROOT=$PROJECT_ROOT, DATA_DIR=$DATA_DIR, KEYS_DIR=$KEYS_DIR"
    return $RC_OK
}

validate_logging_config() {
    log_info "Validating logging configuration..."
    
    # Check LOG_LEVEL
    if [[ -n "${LOG_LEVEL:-}" ]]; then
        local valid_levels=("DEBUG" "INFO" "WARN" "ERROR")
        local level_valid=false
        
        for valid_level in "${valid_levels[@]}"; do
            if [[ "$LOG_LEVEL" == "$valid_level" ]]; then
                level_valid=true
                break
            fi
        done
        
        if [[ "$level_valid" == "false" ]]; then
            VALIDATION_ERRORS+=("LOG_LEVEL ($LOG_LEVEL) is not valid. Valid levels: ${valid_levels[*]}")
            return $RC_ERROR
        fi
    fi
    
    # Check LOG_FORMAT
    if [[ -n "${LOG_FORMAT:-}" ]]; then
        # Check for required placeholders
        local required_placeholders=("%LEVEL%" "%MESSAGE%")
        local optional_placeholders=("%COMPONENT%" "%TIMESTAMP%")
        
        for placeholder in "${required_placeholders[@]}"; do
            if [[ ! "$LOG_FORMAT" =~ $placeholder ]]; then
                VALIDATION_ERRORS+=("LOG_FORMAT missing required placeholder: $placeholder")
                return $RC_ERROR
            fi
        done
        
        # Check for common format issues
        if [[ ! "$LOG_FORMAT" =~ \[.*\] ]]; then
            VALIDATION_WARNINGS+=("LOG_FORMAT should include brackets for better readability")
        fi
        
        # Check format length
        if [[ ${#LOG_FORMAT} -gt 200 ]]; then
            VALIDATION_WARNINGS+=("LOG_FORMAT is very long (${#LOG_FORMAT} chars). Consider simplifying")
        fi
    fi
    
    log_info "Logging configuration validation passed: LOG_LEVEL=${LOG_LEVEL:-INFO}, LOG_FORMAT configured"
    return $RC_OK
}

validate_watchdog_config() {
    log_info "Validating watchdog configuration..."
    
    # Check WATCHDOG_INTERVAL
    if [[ -n "${WATCHDOG_INTERVAL:-}" ]]; then
        if ! [[ "$WATCHDOG_INTERVAL" =~ ^[0-9]+$ ]]; then
            VALIDATION_ERRORS+=("WATCHDOG_INTERVAL must be numeric, got: $WATCHDOG_INTERVAL")
            return $RC_ERROR
        fi
        
        if [[ "$WATCHDOG_INTERVAL" -lt 60 ]]; then
            VALIDATION_WARNINGS+=("WATCHDOG_INTERVAL (${WATCHDOG_INTERVAL}s) is very frequent. Consider values >= 60s")
        fi
        
        if [[ "$WATCHDOG_INTERVAL" -gt 3600 ]]; then
            VALIDATION_WARNINGS+=("WATCHDOG_INTERVAL (${WATCHDOG_INTERVAL}s) is very infrequent. Consider values <= 3600s")
        fi
    fi
    
    # Check WATCHDOG_TIMEOUT
    if [[ -n "${WATCHDOG_TIMEOUT:-}" ]]; then
        if ! [[ "$WATCHDOG_TIMEOUT" =~ ^[0-9]+$ ]]; then
            VALIDATION_ERRORS+=("WATCHDOG_TIMEOUT must be numeric, got: $WATCHDOG_TIMEOUT")
            return $RC_ERROR
        fi
        
        if [[ "$WATCHDOG_TIMEOUT" -lt 120 ]]; then
            VALIDATION_WARNINGS+=("WATCHDOG_TIMEOUT (${WATCHDOG_TIMEOUT}s) is very short. Consider values >= 120s")
        fi
    fi
    
    # Check logical relationship (timeout > interval)
    if [[ -n "${WATCHDOG_INTERVAL:-}" && -n "${WATCHDOG_TIMEOUT:-}" ]]; then
        if [[ "$WATCHDOG_TIMEOUT" -le "$WATCHDOG_INTERVAL" ]]; then
            VALIDATION_ERRORS+=("WATCHDOG_TIMEOUT ($WATCHDOG_TIMEOUT) must be greater than WATCHDOG_INTERVAL ($WATCHDOG_INTERVAL)")
            return $RC_ERROR
        fi
        
        # Check reasonable ratio
        local ratio=$((WATCHDOG_TIMEOUT / WATCHDOG_INTERVAL))
        if [[ $ratio -lt 2 ]]; then
            VALIDATION_WARNINGS+=("WATCHDOG_TIMEOUT should be at least 2x WATCHDOG_INTERVAL")
        fi
    fi
    
    # Check WATCHDOG_MAX_RETRIES
    if [[ -n "${WATCHDOG_MAX_RETRIES:-}" ]]; then
        if ! [[ "$WATCHDOG_MAX_RETRIES" =~ ^[0-9]+$ ]]; then
            VALIDATION_ERRORS+=("WATCHDOG_MAX_RETRIES must be numeric, got: $WATCHDOG_MAX_RETRIES")
            return $RC_ERROR
        fi
        
        if [[ "$WATCHDOG_MAX_RETRIES" -lt 1 ]]; then
            VALIDATION_ERRORS+=("WATCHDOG_MAX_RETRIES must be at least 1, got: $WATCHDOG_MAX_RETRIES")
            return $RC_ERROR
        fi
        
        if [[ "$WATCHDOG_MAX_RETRIES" -gt 10 ]]; then
            VALIDATION_WARNINGS+=("WATCHDOG_MAX_RETRIES ($WATCHDOG_MAX_RETRIES) is high. Consider values between 1-5")
        fi
    fi
    
    # Check WATCHDOG_RECOVERY_DELAY
    if [[ -n "${WATCHDOG_RECOVERY_DELAY:-}" ]]; then
        if ! [[ "$WATCHDOG_RECOVERY_DELAY" =~ ^[0-9]+$ ]]; then
            VALIDATION_ERRORS+=("WATCHDOG_RECOVERY_DELAY must be numeric, got: $WATCHDOG_RECOVERY_DELAY")
            return $RC_ERROR
        fi
        
        if [[ "$WATCHDOG_RECOVERY_DELAY" -lt 5 ]]; then
            VALIDATION_WARNINGS+=("WATCHDOG_RECOVERY_DELAY (${WATCHDOG_RECOVERY_DELAY}s) is very short. Consider values >= 5s")
        fi
        
        if [[ "$WATCHDOG_RECOVERY_DELAY" -gt 300 ]]; then
            VALIDATION_WARNINGS+=("WATCHDOG_RECOVERY_DELAY (${WATCHDOG_RECOVERY_DELAY}s) is very long. Consider values <= 300s")
        fi
    fi
    
    # Check WATCHDOG_SERVICES
    if [[ -n "${WATCHDOG_SERVICES:-}" ]]; then
        # Check service name format
        if [[ ! "$WATCHDOG_SERVICES" =~ \.service$ ]]; then
            VALIDATION_WARNINGS+=("WATCHDOG_SERVICES should end with .service, got: $WATCHDOG_SERVICES")
        fi
        
        # Check for multiple services (comma-separated)
        if [[ "$WATCHDOG_SERVICES" =~ , ]]; then
            local service_count=$(echo "$WATCHDOG_SERVICES" | tr ',' '\n' | wc -l)
            VALIDATION_WARNINGS+=("Multiple watchdog services configured ($service_count). Ensure all services exist")
        fi
    fi
    
    # Check watchdog system thresholds
    if [[ -n "${WATCHDOG_CPU_THRESHOLD:-}" ]]; then
        if ! [[ "$WATCHDOG_CPU_THRESHOLD" =~ ^[0-9]+\.?[0-9]*$ ]]; then
            VALIDATION_ERRORS+=("WATCHDOG_CPU_THRESHOLD must be numeric, got: $WATCHDOG_CPU_THRESHOLD")
            return $RC_ERROR
        fi
    fi
    
    if [[ -n "${WATCHDOG_MEM_THRESHOLD:-}" ]]; then
        if ! [[ "$WATCHDOG_MEM_THRESHOLD" =~ ^[0-9]+\.?[0-9]*$ ]]; then
            VALIDATION_ERRORS+=("WATCHDOG_MEM_THRESHOLD must be numeric, got: $WATCHDOG_MEM_THRESHOLD")
            return $RC_ERROR
        fi
        
        if (( $(awk "BEGIN {print ($WATCHDOG_MEM_THRESHOLD > 8)}") )); then
            VALIDATION_WARNINGS+=("WATCHDOG_MEM_THRESHOLD (${WATCHDOG_MEM_THRESHOLD}GB) is high for Raspberry Pi. Consider values <= 4GB")
        fi
    fi
    
    if [[ -n "${WATCHDOG_DISK_THRESHOLD:-}" ]]; then
        if ! [[ "$WATCHDOG_DISK_THRESHOLD" =~ ^[0-9]+$ ]]; then
            VALIDATION_ERRORS+=("WATCHDOG_DISK_THRESHOLD must be numeric, got: $WATCHDOG_DISK_THRESHOLD")
            return $RC_ERROR
        fi
        
        if [[ "$WATCHDOG_DISK_THRESHOLD" -gt 100 ]]; then
            VALIDATION_ERRORS+=("WATCHDOG_DISK_THRESHOLD cannot exceed 100%, got: $WATCHDOG_DISK_THRESHOLD")
            return $RC_ERROR
        fi
    fi
    
    log_info "Watchdog configuration validation passed"
    return $RC_OK
}

validate_sel_config() {
    log_info "Validating SEL configuration..."
    
    # Check SEL_MAX_ENTRIES
    if [[ -n "${SEL_MAX_ENTRIES:-}" ]]; then
        if ! [[ "$SEL_MAX_ENTRIES" =~ ^[0-9]+$ ]]; then
            VALIDATION_ERRORS+=("SEL_MAX_ENTRIES must be numeric, got: $SEL_MAX_ENTRIES")
            return $RC_ERROR
        fi
        
        if [[ "$SEL_MAX_ENTRIES" -lt 100 ]]; then
            VALIDATION_WARNINGS+=("SEL_MAX_ENTRIES ($SEL_MAX_ENTRIES) is very low. Consider values >= 1000")
        fi
        
        if [[ "$SEL_MAX_ENTRIES" -gt 100000 ]]; then
            VALIDATION_WARNINGS+=("SEL_MAX_ENTRIES ($SEL_MAX_ENTRIES) is very high. Consider values <= 10000")
        fi
    fi
    
    # Check SEL_RETENTION_DAYS
    if [[ -n "${SEL_RETENTION_DAYS:-}" ]]; then
        if ! [[ "$SEL_RETENTION_DAYS" =~ ^[0-9]+$ ]]; then
            VALIDATION_ERRORS+=("SEL_RETENTION_DAYS must be numeric, got: $SEL_RETENTION_DAYS")
            return $RC_ERROR
        fi
        
        if [[ "$SEL_RETENTION_DAYS" -lt 7 ]]; then
            VALIDATION_WARNINGS+=("SEL_RETENTION_DAYS ($SEL_RETENTION_DAYS) is very short. Consider values >= 7 days")
        fi
        
        if [[ "$SEL_RETENTION_DAYS" -gt 365 ]]; then
            VALIDATION_WARNINGS+=("SEL_RETENTION_DAYS ($SEL_RETENTION_DAYS) is very long. Consider values <= 365 days")
        fi
    fi
    
    # Check SEL boolean configurations
    local sel_bool_vars=("SEL_LOG_CRITICAL_EVENTS" "SEL_LOG_SECURITY_EVENTS" "SEL_LOG_WATCHDOG_EVENTS")
    
    for var in "${sel_bool_vars[@]}"; do
        if [[ -n "${!var:-}" ]]; then
            local value="${!var}"
            # Convert to lowercase for comparison
            value=$(echo "$value" | tr '[:upper:]' '[:lower:]')
            
            if [[ "$value" != "true" && "$value" != "false" ]]; then
                VALIDATION_ERRORS+=("$var must be 'true' or 'false', got: ${!var}")
                return $RC_ERROR
            fi
        fi
    done
    
    # Check logical relationships
    if [[ -n "${SEL_MAX_ENTRIES:-}" && -n "${SEL_RETENTION_DAYS:-}" ]]; then
        # Estimate daily entries based on max entries and retention
        local estimated_daily=$((SEL_MAX_ENTRIES / SEL_RETENTION_DAYS))
        
        if [[ $estimated_daily -gt 1000 ]]; then
            VALIDATION_WARNINGS+=("Estimated daily SEL entries ($estimated_daily) is high. Consider adjusting SEL_MAX_ENTRIES or SEL_RETENTION_DAYS")
        fi
    fi
    
    log_info "SEL configuration validation passed: MAX_ENTRIES=${SEL_MAX_ENTRIES:-1000}, RETENTION_DAYS=${SEL_RETENTION_DAYS:-30}"
    return $RC_OK
}

validate_security_config() {
    log_info "Validating security configuration..."
    
    # Check RSA key size
    if [[ -n "${RSA_KEY_SIZE:-}" ]]; then
        if ! [[ "$RSA_KEY_SIZE" =~ ^[0-9]+$ ]]; then
            VALIDATION_ERRORS+=("RSA_KEY_SIZE must be numeric, got: $RSA_KEY_SIZE")
            return $RC_ERROR
        fi
        
        if [[ "$RSA_KEY_SIZE" -lt 1024 ]]; then
            VALIDATION_ERRORS+=("RSA_KEY_SIZE ($RSA_KEY_SIZE) is too small. Minimum recommended: 2048")
            return $RC_ERROR
        fi
        
        if [[ "$RSA_KEY_SIZE" -gt 8192 ]]; then
            VALIDATION_WARNINGS+=("RSA_KEY_SIZE ($RSA_KEY_SIZE) is very large and may impact performance")
        fi
        
        # Check for common key sizes
        local valid_key_sizes=(1024 2048 3072 4096)
        local size_valid=false
        
        for valid_size in "${valid_key_sizes[@]}"; do
            if [[ "$RSA_KEY_SIZE" -eq "$valid_size" ]]; then
                size_valid=true
                break
            fi
        done
        
        if [[ "$size_valid" == "false" ]]; then
            VALIDATION_WARNINGS+=("RSA_KEY_SIZE ($RSA_KEY_SIZE) is not a standard size. Recommended: ${valid_key_sizes[*]}")
        fi
    fi
    
    # Check hash algorithm
    if [[ -n "${HASH_ALGORITHM:-}" ]]; then
        local valid_algorithms=("sha256" "sha384" "sha512" "sha1")
        local algo_valid=false
        
        for valid_algo in "${valid_algorithms[@]}"; do
            if [[ "$HASH_ALGORITHM" == "$valid_algo" ]]; then
                algo_valid=true
                break
            fi
        done
        
        if [[ "$algo_valid" == "false" ]]; then
            VALIDATION_ERRORS+=("HASH_ALGORITHM ($HASH_ALGORITHM) is not supported. Valid: ${valid_algorithms[*]}")
            return $RC_ERROR
        fi
        
        if [[ "$HASH_ALGORITHM" == "sha1" ]]; then
            VALIDATION_WARNINGS+=("SHA1 is deprecated for security applications. Consider using SHA256 or stronger")
        fi
    fi
    
    # Check monitoring intervals
    if [[ -n "${INTEGRITY_CHECK_INTERVAL:-}" ]]; then
        if ! [[ "$INTEGRITY_CHECK_INTERVAL" =~ ^[0-9]+$ ]]; then
            VALIDATION_ERRORS+=("INTEGRITY_CHECK_INTERVAL must be numeric, got: $INTEGRITY_CHECK_INTERVAL")
            return $RC_ERROR
        fi
        
        if [[ "$INTEGRITY_CHECK_INTERVAL" -lt 300 ]]; then
            VALIDATION_WARNINGS+=("INTEGRITY_CHECK_INTERVAL (${INTEGRITY_CHECK_INTERVAL}s) is very frequent and may impact performance")
        fi
        
        if [[ "$INTEGRITY_CHECK_INTERVAL" -gt 86400 ]]; then
            VALIDATION_WARNINGS+=("INTEGRITY_CHECK_INTERVAL (${INTEGRITY_CHECK_INTERVAL}s) is too infrequent for security")
        fi
    fi
    
    log_info "Security configuration validation passed"
    return $RC_OK
}

# ==============================================================================
# Main Validation Functions
# ==============================================================================

load_config() {
    local config_file="$1"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        return $RC_ERROR
    fi
    
    log_info "Loading configuration from: $config_file"
    
    # Source the configuration file
    set -a
    source "$config_file"
    set +a
    
    return $RC_OK
}

print_validation_results() {
    local total_errors=${#VALIDATION_ERRORS[@]}
    local total_warnings=${#VALIDATION_WARNINGS[@]}
    
    echo
    echo "=== Configuration Validation Results ==="
    echo "Configuration file: $CONFIG_FILE"
    echo "Validation time: $(date -Iseconds)"
    echo
    
    if [[ $total_errors -eq 0 ]] && [[ $total_warnings -eq 0 ]]; then
        echo "✅ Configuration validation PASSED"
        echo "🎉 All configuration parameters are valid and properly formatted"
        return $RC_OK
    fi
    
    # Print errors
    if [[ $total_errors -gt 0 ]]; then
        echo "❌ Configuration validation FAILED"
        echo "Errors found: $total_errors"
        echo
        for i in "${!VALIDATION_ERRORS[@]}"; do
            echo "  ERROR $((i+1)): ${VALIDATION_ERRORS[i]}"
        done
        echo
    fi
    
    # Print warnings
    if [[ $total_warnings -gt 0 ]]; then
        echo "⚠️  Configuration warnings found: $total_warnings"
        echo
        for i in "${!VALIDATION_WARNINGS[@]}"; do
            echo "  WARNING $((i+1)): ${VALIDATION_WARNINGS[i]}"
        done
        echo
    fi
    
    # Print summary
    if [[ $total_errors -gt 0 ]]; then
        echo "💡 Please fix the errors before using this configuration"
        return $RC_ERROR
    else
        echo "💡 Configuration is valid but has warnings that should be reviewed"
        return $RC_WARN
    fi
}

validate_all() {
    log_info "Starting comprehensive configuration validation..."
    
    local validation_functions=(
        "validate_dht11_pin"
        "validate_temperature_thresholds"
        "validate_led_pins"
        "validate_network_config"
        "validate_security_config"
        "validate_system_thresholds"
        "validate_paths"
        "validate_logging_config"
        "validate_watchdog_config"
        "validate_sel_config"
    )
    
    local total_validations=${#validation_functions[@]}
    local passed_validations=0
    
    for validation_func in "${validation_functions[@]}"; do
        if $validation_func; then
            ((passed_validations++))
        fi
    done
    
    log_info "Validation completed: $passed_validations/$total_validations checks passed"
    
    return $((total_validations - passed_validations > 0 ? RC_ERROR : RC_OK))
}

# ==============================================================================
# Help and Usage
# ==============================================================================

show_help() {
    cat << EOF
TrustMonitor Configuration Validation Tool

USAGE:
    $0 [OPTIONS] [CONFIG_FILE]

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -q, --quiet         Suppress non-error output
    --dht11-only        Validate only DHT11 pin configuration
    --temp-only          Validate only temperature thresholds
    --led-only           Validate only LED pin configuration
    --network-only       Validate only network configuration
    --security-only      Validate only security configuration
    --system-only        Validate only system thresholds
    --paths-only         Validate only path configuration
    --logging-only       Validate only logging configuration
    --watchdog-only      Validate only watchdog configuration
    --sel-only          Validate only SEL configuration

EXAMPLES:
    # Validate default configuration file
    $0

    # Validate specific configuration file
    $0 /path/to/custom.env

    # Validate only DHT11 configuration
    $0 --dht11-only

    # Validate only system thresholds
    $0 --system-only

    # Validate with verbose output
    $0 -v

CONFIG FILE:
    Default: $BASE_DIR/config/health-monitor.env
    The configuration file should contain environment variable assignments
    in the format: VARIABLE=value

VALIDATION CHECKS:
    • DHT11 pin format and range validation
    • Temperature threshold format and logic validation
    • LED pin format and uniqueness validation
    • Network configuration validation
    • Security configuration validation
    • System thresholds validation (CPU, memory, disk)
    • Path configuration validation (PROJECT_ROOT, DATA_DIR, KEYS_DIR)
    • Logging configuration validation (LOG_LEVEL, LOG_FORMAT)
    • Watchdog configuration validation (intervals, retries, services)
    • SEL configuration validation (entries, retention, events)

EXIT CODES:
    0  - Validation passed
    1  - Validation failed (errors found)
    2  - Validation passed with warnings
    3  - Configuration file not found
    4  - Invalid arguments

EOF
}

# ==============================================================================
# Main Execution
# ==============================================================================

main() {
    local config_file="$CONFIG_FILE"
    local verbose=false
    local quiet=false
    local specific_validation=""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
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
            --dht11-only)
                specific_validation="validate_dht11_pin"
                shift
                ;;
            --temp-only)
                specific_validation="validate_temperature_thresholds"
                shift
                ;;
            --led-only)
                specific_validation="validate_led_pins"
                shift
                ;;
            --network-only)
                specific_validation="validate_network_config"
                shift
                ;;
            --security-only)
                specific_validation="validate_security_config"
                shift
                ;;
            --system-only)
                specific_validation="validate_system_thresholds"
                shift
                ;;
            --paths-only)
                specific_validation="validate_paths"
                shift
                ;;
            --logging-only)
                specific_validation="validate_logging_config"
                shift
                ;;
            --watchdog-only)
                specific_validation="validate_watchdog_config"
                shift
                ;;
            --sel-only)
                specific_validation="validate_sel_config"
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                show_help
                return $RC_ERROR
                ;;
            *)
                # Last argument that's not an option is the config file
                if [[ -f "$1" ]]; then
                    config_file="$1"
                else
                    log_error "Configuration file not found: $1"
                    return $RC_ERROR
                fi
                shift
                ;;
        esac
    done
    
    # Update global config file path
    CONFIG_FILE="$config_file"
    
    # Load configuration
    if ! load_config "$CONFIG_FILE"; then
        return $RC_ERROR
    fi
    
    # Run validation
    if [[ -n "$specific_validation" ]]; then
        log_info "Running specific validation: $specific_validation"
        $specific_validation
    else
        validate_all
    fi
    
    local validation_result=$?
    
    # Print results
    if [[ "$quiet" != "true" ]]; then
        print_validation_results
    fi
    
    return $validation_result
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
