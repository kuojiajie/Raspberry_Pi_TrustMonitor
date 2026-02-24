#!/bin/bash
# lib/plugin_loader.sh
# Plugin auto-loading system for monitoring modules

set -u

# Load logger first to ensure it's available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/logger.sh"
source "$SCRIPT_DIR/return_codes.sh"

# Plugin registry
declare -A PLUGINS
declare -A PLUGIN_DESCRIPTIONS

# Plugin-specific logging functions
plugin_log_info() {
    local plugin_name="$1"
    local message="$2"
    log_info "[$plugin_name] $message"
}

plugin_log_warn() {
    local plugin_name="$1"
    local message="$2"
    log_warn "[$plugin_name] $message"
}

plugin_log_error() {
    local plugin_name="$1"
    local message="$2"
    log_error "[$plugin_name] $message"
}

# Load a single plugin
load_plugin() {
    local plugin_file="$1"
    local plugin_name
    plugin_name="$(basename "$plugin_file" .sh)"
    
    # Check if plugin file exists and is readable
    if [[ ! -f "$plugin_file" || ! -r "$plugin_file" ]]; then
        echo "Warning: Plugin file $plugin_file not accessible" >&2
        return 1
    fi
    
    # Source the plugin
    # shellcheck disable=SC1090
    source "$plugin_file"
    
    # Register plugin if it has required functions
    if declare -f "${plugin_name}_check" >/dev/null; then
        PLUGINS["$plugin_name"]="$plugin_file"
        
        # Get plugin description if available
        if declare -f "${plugin_name}_description" >/dev/null; then
            PLUGIN_DESCRIPTIONS["$plugin_name"]="$("${plugin_name}_description")"
        else
            PLUGIN_DESCRIPTIONS["$plugin_name"]="No description available"
        fi
        
        # Set up plugin-specific logging functions
        eval "${plugin_name}_log_info() { log_info \"[$plugin_name] \$1\"; }"
        eval "${plugin_name}_log_warn() { log_warn \"[$plugin_name] \$1\"; }"
        eval "${plugin_name}_log_error() { log_error \"[$plugin_name] \$1\"; }"
        
        echo "Loaded plugin: $plugin_name"
        return 0
    else
        echo "Warning: Plugin $plugin_name does not have required ${plugin_name}_check function" >&2
        return 1
    fi
}

# Auto-load all plugins from a directory
load_plugins_from_dir() {
    local plugin_dir="$1"
    local loaded_count=0
    
    if [[ ! -d "$plugin_dir" ]]; then
        echo "Error: Plugin directory $plugin_dir does not exist" >&2
        return 1
    fi
    
    # Find all .sh files in the directory
    while IFS= read -r -d '' plugin_file; do
        if load_plugin "$plugin_file"; then
            ((loaded_count++))
        fi
    done < <(find "$plugin_dir" -name "*.sh" -type f -print0 | sort -z)
    
    echo "Loaded $loaded_count plugins from $plugin_dir"
    return 0
}

# Get list of loaded plugins
get_loaded_plugins() {
    printf '%s\n' "${!PLUGINS[@]}" | sort
}

# Get plugin description
get_plugin_description() {
    local plugin_name="$1"
    echo "${PLUGIN_DESCRIPTIONS[$plugin_name]:-No description available}"
}

# Check if plugin is loaded
is_plugin_loaded() {
    local plugin_name="$1"
    [[ -n "${PLUGINS[$plugin_name]:-}" ]]
}

# Execute plugin check function
execute_plugin_check() {
    local plugin_name="$1"
    local check_function="${plugin_name}_check"
    
    if ! is_plugin_loaded "$plugin_name"; then
        echo "Error: Plugin $plugin_name is not loaded" >&2
        return $RC_PLUGIN_ERROR
    fi
    
    if ! declare -f "$check_function" >/dev/null; then
        echo "Error: Plugin $plugin_name does not have $check_function function" >&2
        return $RC_PLUGIN_ERROR
    fi
    
    # Execute the check function and capture its return code
    "$check_function"
    local exit_code=$?
    
    return $exit_code
}

# List all plugins with descriptions
list_plugins() {
    echo "Available plugins:"
    for plugin_name in $(get_loaded_plugins); do
        echo "  $plugin_name: $(get_plugin_description "$plugin_name")"
    done
}

# Plugin system information
plugin_system_info() {
    echo "Plugin System Information:"
    echo "  Total plugins loaded: ${#PLUGINS[@]}"
    echo "  Plugin directory: ${PLUGIN_DIR:-Not set}"
    echo ""
    list_plugins
}
