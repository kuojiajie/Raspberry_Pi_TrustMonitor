#!/bin/bash
# lib/path_manager.sh
# Unified Path Management for TrustMonitor Project
# Provides consistent path resolution across all scripts

set -u

# Project Root Detection
get_project_root() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
    
    # Navigate up until we find project markers
    while [[ "$script_dir" != "/" ]]; do
        if [[ -f "$script_dir/README.md" ]] && 
           [[ -d "$script_dir/lib" ]] && 
           [[ -d "$script_dir/hardware" ]]; then
            echo "$script_dir"
            return 0
        fi
        script_dir="$(dirname "$script_dir")"
    done
    
    # Fallback: use current working directory
    echo "$(pwd)"
}

# Global Path Variables
PROJECT_ROOT="$(get_project_root)"
DATA_DIR="$PROJECT_ROOT/data"
CONFIG_DIR="$PROJECT_ROOT/config"
LIB_DIR="$PROJECT_ROOT/lib"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"
HARDWARE_DIR="$PROJECT_ROOT/hardware"
TOOLS_DIR="$PROJECT_ROOT/tools"
DAEMON_DIR="$PROJECT_ROOT/daemon"
BACKUP_DIR="$PROJECT_ROOT/backup"
LOGS_DIR="$PROJECT_ROOT/logs"
SYSTEMD_DIR="$PROJECT_ROOT/systemd"

# Data Subdirectories
KEYS_DIR="$DATA_DIR/keys"
RUNTIME_DIR="$DATA_DIR/runtime"
INTEGRITY_DIR="$DATA_DIR/integrity"

# Security Files (new secure structure)
MANIFEST_FILE="$INTEGRITY_DIR/manifest.sha256"
SIGNATURE_FILE="$INTEGRITY_DIR/manifest.sha256.sig"
PUBLIC_KEY_FILE="$INTEGRITY_DIR/public_key.pem"
LAST_INTEGRITY_CHECK_FILE="$RUNTIME_DIR/.last_integrity_check"

# Tool Subdirectories
USER_TOOLS_DIR="$TOOLS_DIR/user"
DEV_TOOLS_DIR="$TOOLS_DIR/dev"
SECURITY_TOOLS_DIR="$TOOLS_DIR/security"

# Initialize Data Directory Structure
init_data_structure() {
    local dirs=(
        "$DATA_DIR"
        "$KEYS_DIR" 
        "$RUNTIME_DIR"
        "$BACKUP_DIR"
        "$LOGS_DIR"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            echo "Created directory: $dir"
        fi
    done
}

# Create Backward Compatibility Symlinks
create_compatibility_symlinks() {
    local symlinks=(
        "$DATA_DIR/keys:$PROJECT_ROOT/keys"
        "$DATA_DIR/manifest.sha256:$PROJECT_ROOT/manifest.sha256"
        "$DATA_DIR/manifest.sha256.sig:$PROJECT_ROOT/manifest.sha256.sig"
        "$RUNTIME_DIR/.last_integrity_check:$PROJECT_ROOT/.last_integrity_check"
    )
    
    for symlink in "${symlinks[@]}"; do
        local target="${symlink%:*}"
        local source="${symlink#*:}"
        
        if [[ ! -L "$source" ]] && [[ ! -e "$source" ]]; then
            ln -sf "$target" "$source"
            echo "Created symlink: $source -> $target"
        fi
    done
}

# Path Validation Functions
validate_paths() {
    local errors=0
    
    if [[ ! -d "$PROJECT_ROOT" ]]; then
        echo "ERROR: Project root not found: $PROJECT_ROOT" >&2
        ((errors++))
    fi
    
    if [[ ! -d "$LIB_DIR" ]]; then
        echo "ERROR: Library directory not found: $LIB_DIR" >&2
        ((errors++))
    fi
    
    if [[ ! -d "$HARDWARE_DIR" ]]; then
        echo "ERROR: Hardware directory not found: $HARDWARE_DIR" >&2
        ((errors++))
    fi
    
    return $errors
}

# Show Path Information
show_paths() {
    echo "TrustMonitor Path Configuration:"
    echo "================================"
    echo "Project Root: $PROJECT_ROOT"
    echo "Data Dir: $DATA_DIR"
    echo "Config Dir: $CONFIG_DIR"
    echo "Library Dir: $LIB_DIR"
    echo "Scripts Dir: $SCRIPTS_DIR"
    echo "Hardware Dir: $HARDWARE_DIR"
    echo "Tools Dir: $TOOLS_DIR"
    echo "Daemon Dir: $DAEMON_DIR"
    echo "Backup Dir: $BACKUP_DIR"
    echo "Logs Dir: $LOGS_DIR"
    echo "Systemd Dir: $SYSTEMD_DIR"
    echo ""
    echo "Data Subdirectories:"
    echo "  Keys Dir: $KEYS_DIR"
    echo "  Runtime Dir: $RUNTIME_DIR"
    echo ""
    echo "Security Files:"
    echo "  Manifest: $MANIFEST_FILE"
    echo "  Signature: $SIGNATURE_FILE"
    echo "  Last Check: $LAST_INTEGRITY_CHECK_FILE"
}

# Export all path variables
export PROJECT_ROOT DATA_DIR CONFIG_DIR LIB_DIR SCRIPTS_DIR HARDWARE_DIR
export TOOLS_DIR DAEMON_DIR BACKUP_DIR LOGS_DIR SYSTEMD_DIR
export KEYS_DIR RUNTIME_DIR MANIFEST_FILE SIGNATURE_FILE LAST_INTEGRITY_CHECK_FILE
export USER_TOOLS_DIR DEV_TOOLS_DIR SECURITY_TOOLS_DIR

# Auto-initialize when sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    init_data_structure
    create_compatibility_symlinks
fi
