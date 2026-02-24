#!/bin/bash
# lib/backup_manager.sh
# Unified backup file management and cleanup system
# v2.2.4 - Centralized backup file handling

set -u

# Load logger
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/logger.sh"
source "$SCRIPT_DIR/return_codes.sh"

# Configuration
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKUP_ROOT_DIR="$BASE_DIR/backup"
SECURITY_BACKUP_DIR="$BACKUP_ROOT_DIR/security"
DEMO_BACKUP_DIR="$BACKUP_ROOT_DIR/attack_demo"

# Backup retention settings (days) - allow environment override
SECURITY_BACKUP_RETENTION=${SECURITY_BACKUP_RETENTION:-7}      # Keep security backups for 7 days
DEMO_BACKUP_RETENTION=${DEMO_BACKUP_RETENTION:-3}             # Keep demo backups for 3 days
MAX_SECURITY_BACKUPS=${MAX_SECURITY_BACKUPS:-10}              # Max 10 security backups
MAX_DEMO_BACKUPS=${MAX_DEMO_BACKUPS:-5}                       # Max 5 demo backups

# Logging functions
backup_log_info() {
    log_info "[BACKUP] $1"
}

backup_log_warn() {
    log_warn "[BACKUP] $1"
}

backup_log_error() {
    log_error "[BACKUP] $1"
}

# Initialize backup directories
init_backup_dirs() {
    backup_log_info "Initializing backup directories..."
    
    # Create main backup directories
    mkdir -p "$SECURITY_BACKUP_DIR"
    mkdir -p "$DEMO_BACKUP_DIR"
    
    # Ensure proper permissions
    chmod 755 "$BACKUP_ROOT_DIR"
    chmod 755 "$SECURITY_BACKUP_DIR"
    chmod 755 "$DEMO_BACKUP_DIR"
    
    backup_log_info "Backup directories initialized"
    return $RC_OK
}

# Move existing security files to unified backup directory
consolidate_security_backups() {
    backup_log_info "Consolidating existing security backup files..."
    
    local moved_count=0
    
    # Move signature backup files
    for backup_file in "$BASE_DIR"/manifest.sha256.sig.backup_*; do
        if [[ -f "$backup_file" ]]; then
            local filename
            filename=$(basename "$backup_file")
            mv "$backup_file" "$SECURITY_BACKUP_DIR/$filename"
            ((moved_count++))
            backup_log_info "Moved: $filename -> security/"
        fi
    done
    
    # Move current manifest and signature to security backup if they exist
    if [[ -f "$BASE_DIR/manifest.sha256" ]]; then
        local timestamp
        timestamp=$(date +%Y%m%d_%H%M%S)
        cp "$BASE_DIR/manifest.sha256" "$SECURITY_BACKUP_DIR/manifest.sha256.$timestamp"
        backup_log_info "Backed up: manifest.sha256.$timestamp"
        ((moved_count++))
    fi
    
    if [[ -f "$BASE_DIR/manifest.sha256.sig" ]]; then
        local timestamp
        timestamp=$(date +%Y%m%d_%H%M%S)
        cp "$BASE_DIR/manifest.sha256.sig" "$SECURITY_BACKUP_DIR/manifest.sha256.sig.$timestamp"
        backup_log_info "Backed up: manifest.sha256.sig.$timestamp"
        ((moved_count++))
    fi
    
    backup_log_info "Consolidation completed: $moved_count files moved"
    return $RC_OK
}

# Clean old security backups
cleanup_security_backups() {
    backup_log_info "Cleaning old security backups..."
    
    local removed_count=0
    
    # Remove old backup directories first
    find "$SECURITY_BACKUP_DIR" -maxdepth 1 -type d -name "20*" -mtime +$SECURITY_BACKUP_RETENTION -print0 2>/dev/null | while IFS= read -r -d '' dir; do
        if [[ "$dir" != "$SECURITY_BACKUP_DIR" ]]; then
            rm -rf "$dir"
            backup_log_info "Removed old security backup directory: $(basename "$dir")"
            ((removed_count++))
        fi
    done
    
    # Remove old backup files
    find "$SECURITY_BACKUP_DIR" -name "*.backup_*" -type f -mtime +$SECURITY_BACKUP_RETENTION -print0 2>/dev/null | while IFS= read -r -d '' file; do
        rm -f "$file"
        backup_log_info "Removed old security backup: $(basename "$file")"
        ((removed_count++))
    done
    
    # Keep only the most recent backup directories if we exceed the limit
    local total_dirs
    total_dirs=$(find "$SECURITY_BACKUP_DIR" -maxdepth 1 -type d -name "20*" | wc -l)
    
    if [[ $total_dirs -gt $MAX_SECURITY_BACKUPS ]]; then
        local dirs_to_remove=$((total_dirs - MAX_SECURITY_BACKUPS))
        find "$SECURITY_BACKUP_DIR" -maxdepth 1 -type d -name "20*" -printf '%T@ %p\n' | sort -n | head -n "$dirs_to_remove" | cut -d' ' -f2- | while read -r dir; do
            if [[ "$dir" != "$SECURITY_BACKUP_DIR" ]]; then
                rm -rf "$dir"
                backup_log_info "Removed excess security backup directory: $(basename "$dir")"
                ((removed_count++))
            fi
        done
    fi
    
    # Keep only the most recent backup files if we exceed the limit
    local total_files
    total_files=$(find "$SECURITY_BACKUP_DIR" -name "*.backup_*" -type f | wc -l)
    
    if [[ $total_files -gt $MAX_SECURITY_BACKUPS ]]; then
        local files_to_remove=$((total_files - MAX_SECURITY_BACKUPS))
        find "$SECURITY_BACKUP_DIR" -name "*.backup_*" -type f -printf '%T@ %p\n' | sort -n | head -n "$files_to_remove" | cut -d' ' -f2- | while read -r file; do
            rm -f "$file"
            backup_log_info "Removed excess security backup: $(basename "$file")"
            ((removed_count++))
        done
    fi
    
    backup_log_info "Security backup cleanup completed: $removed_count items removed"
    return $RC_OK
}

# Clean old demo backups
cleanup_demo_backups() {
    backup_log_info "Cleaning old demo backups..."
    
    local removed_count=0
    
    # Remove demo backup directories older than retention period
    find "$DEMO_BACKUP_DIR" -maxdepth 1 -type d -name "attack_demo_*" -mtime +$DEMO_BACKUP_RETENTION -print0 2>/dev/null | while IFS= read -r -d '' dir; do
        rm -rf "$dir"
        backup_log_info "Removed old demo backup: $(basename "$dir")"
        ((removed_count++))
    done
    
    # Keep only the most recent demo backups if we exceed the limit
    local total_dirs
    total_dirs=$(find "$DEMO_BACKUP_DIR" -maxdepth 1 -type d -name "attack_demo_*" | wc -l)
    
    if [[ $total_dirs -gt $MAX_DEMO_BACKUPS ]]; then
        local dirs_to_remove=$((total_dirs - MAX_DEMO_BACKUPS))
        find "$DEMO_BACKUP_DIR" -maxdepth 1 -type d -name "attack_demo_*" -printf '%T@ %p\n' | sort -n | head -n "$dirs_to_remove" | cut -d' ' -f2- | while read -r dir; do
            rm -rf "$dir"
            backup_log_info "Removed excess demo backup: $(basename "$dir")"
            ((removed_count++))
        done
    fi
    
    backup_log_info "Demo backup cleanup completed: $removed_count directories removed"
    return $RC_OK
}

# Create security backup with timestamp
create_security_backup() {
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    backup_log_info "Creating security backup: $timestamp"
    
    local backup_dir="$SECURITY_BACKUP_DIR/$timestamp"
    mkdir -p "$backup_dir"
    
    # Backup critical security files
    local security_files=(
        "manifest.sha256"
        "manifest.sha256.sig"
        "keys/"
    )
    
    for item in "${security_files[@]}"; do
        if [[ -e "$BASE_DIR/$item" ]]; then
            cp -r "$BASE_DIR/$item" "$backup_dir/"
            backup_log_info "Backed up: $item"
        fi
    done
    
    backup_log_info "Security backup created: $backup_dir"
    echo "$backup_dir"
    return $RC_OK
}

# Get backup statistics
get_backup_stats() {
    backup_log_info "Backup storage statistics:"
    
    echo "=== Backup Statistics ==="
    echo "Security backup directory: $SECURITY_BACKUP_DIR"
    echo "Demo backup directory: $DEMO_BACKUP_DIR"
    echo ""
    
    # Security backup stats
    local security_dirs
    local security_files
    local security_size
    security_dirs=$(find "$SECURITY_BACKUP_DIR" -maxdepth 1 -type d -name "20*" | wc -l)
    security_files=$(find "$SECURITY_BACKUP_DIR" -type f | wc -l)
    security_size=$(du -sh "$SECURITY_BACKUP_DIR" 2>/dev/null | cut -f1)
    echo "Security backups: $security_dirs directories, $security_files files, $security_size"
    
    # Demo backup stats
    local demo_dirs
    local demo_size
    demo_dirs=$(find "$DEMO_BACKUP_DIR" -maxdepth 1 -type d -name "attack_demo_*" | wc -l)
    demo_size=$(du -sh "$DEMO_BACKUP_DIR" 2>/dev/null | cut -f1)
    echo "Demo backups: $demo_dirs directories, $demo_size"
    
    echo ""
    echo "Retention settings:"
    echo "  Security files: Keep $SECURITY_BACKUP_RETENTION days, max $MAX_SECURITY_BACKUPS directories/files"
    echo "  Demo backups: Keep $DEMO_BACKUP_RETENTION days, max $MAX_DEMO_BACKUPS directories"
}

# Main cleanup function
cleanup_all_backups() {
    backup_log_info "Starting comprehensive backup cleanup..."
    
    init_backup_dirs
    cleanup_security_backups
    cleanup_demo_backups
    
    backup_log_info "Backup cleanup completed"
    get_backup_stats
    return $RC_OK
}

# Initialize and consolidate existing files
initialize_backup_system() {
    backup_log_info "Initializing unified backup system..."
    
    init_backup_dirs
    consolidate_security_backups
    cleanup_all_backups
    
    backup_log_info "Backup system initialization completed"
    return $RC_OK
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-cleanup}" in
        "init")
            initialize_backup_system
            ;;
        "cleanup")
            cleanup_all_backups
            ;;
        "stats")
            get_backup_stats
            ;;
        "create")
            create_security_backup
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [init|cleanup|stats|create|help]"
            echo "  init     - Initialize backup system and consolidate existing files"
            echo "  cleanup  - Clean old backup files"
            echo "  stats    - Show backup statistics"
            echo "  create   - Create new security backup"
            echo "  help     - Show this help"
            ;;
        *)
            backup_log_error "Unknown command: $1"
            echo "Use '$0 help' for usage information"
            exit $RC_ERROR
            ;;
    esac
fi
