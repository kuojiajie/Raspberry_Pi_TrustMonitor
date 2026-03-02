#!/bin/bash
# lib/trustmon_init.sh
# TrustMonitor Initialization Library
# Standardizes script initialization across the project

set -u

# Load path manager first
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/path_manager.sh"

# Load core libraries
source "$LIB_DIR/logger.sh"
source "$LIB_DIR/return_codes.sh"

# Standard script initialization
init_trustmon_script() {
    local script_name="${1:-$(basename "${BASH_SOURCE[1]}")}"
    
    # Validate paths
    if ! validate_paths; then
        log_error "Path validation failed for $script_name"
        exit $RC_ERROR
    fi
    
    # Initialize data structure
    init_data_structure
    
    # Create compatibility symlinks
    create_compatibility_symlinks
    
    log_info "TrustMonitor script initialized: $script_name"
    log_info "Project root: $PROJECT_ROOT"
}

# Get script-specific configuration directory
get_script_config_dir() {
    local script_name="${1:-$(basename "${BASH_SOURCE[1]}")}"
    echo "$CONFIG_DIR/${script_name%.*}"
}

# Load script-specific configuration
load_script_config() {
    local script_name="${1:-$(basename "${BASH_SOURCE[1]}")}"
    local config_file="$CONFIG_DIR/health-monitor.env"
    local script_config_file="$(get_script_config_dir "$script_name")/config.env"
    
    # Load global config
    if [[ -f "$config_file" ]]; then
        source "$config_file"
    fi
    
    # Load script-specific config
    if [[ -f "$script_config_file" ]]; then
        source "$script_config_file"
    fi
}

# Standard cleanup function
cleanup_trustmon_script() {
    local script_name="${1:-$(basename "${BASH_SOURCE[1]}")}"
    local exit_code="${2:-0}"
    
    log_info "Cleaning up TrustMonitor script: $script_name (exit code: $exit_code)"
    
    # Add any common cleanup logic here
    # Individual scripts can override this function
    
    exit "$exit_code"
}

# Export functions
export -f init_trustmon_script
export -f get_script_config_dir
export -f load_script_config
export -f cleanup_trustmon_script
