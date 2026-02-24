#!/bin/bash
# tools/restore.sh
# System Recovery Script - Phase 2 Task 8
# Restores TrustMonitor system after attack demonstration

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Logging functions
log_info() {
    echo "[RESTORE] [INFO] $1"
}

log_warn() {
    echo "[RESTORE] [WARN] $1"
}

log_error() {
    echo "[RESTORE] [ERROR] $1" >&2
}

# Show usage
show_usage() {
    echo "TrustMonitor System Recovery Tool"
    echo "================================="
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --auto        Auto-detect and restore from latest backup"
    echo "  --backup DIR  Restore from specific backup directory"
    echo "  --clean       Clean attack artifacts and temporary files"
    echo "  --regen       Regenerate manifest and signature"
    echo "  --status      Show current system status"
    echo "  --list        List available backups"
    echo "  --help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --auto           # Auto-restore from latest backup"
    echo "  $0 --clean          # Clean attack artifacts only"
    echo "  $0 --regen          # Regenerate security files"
    echo "  $0 --backup /path   # Restore from specific backup"
}

# Clean attack artifacts
clean_attack_artifacts() {
    log_info "=== CLEANING ATTACK ARTIFACTS ==="
    
    # Remove attack proof file
    if [[ -f "/tmp/attack_proof.txt" ]]; then
        rm -f "/tmp/attack_proof.txt"
        log_info "✅ Removed attack proof file"
    fi
    
    # Remove any temporary attack files
    local temp_files=(
        "/tmp/attack_demo_*"
        "/tmp/backdoor_*"
        "/tmp/pwned_*"
    )
    
    for pattern in "${temp_files[@]}"; do
        if ls $pattern 1> /dev/null 2>&1; then
            rm -f $pattern
            log_info "✅ Removed temporary files: $pattern"
        fi
    done
    
    # Clean any corrupted signature files
    if [[ -f "$PROJECT_ROOT/manifest.sha256.sig" ]]; then
        # Check if signature is fake
        if grep -q "FAKE_SIGNATURE" "$PROJECT_ROOT/manifest.sha256.sig" 2>/dev/null; then
            rm -f "$PROJECT_ROOT/manifest.sha256.sig"
            log_info "✅ Removed fake signature file"
        fi
    fi
    
    log_info "✅ Attack artifacts cleaned"
}

# List available backups
list_backups() {
    log_info "=== AVAILABLE BACKUPS ==="
    
    local backup_dir="$PROJECT_ROOT/backup"
    if [[ ! -d "$backup_dir" ]]; then
        log_warn "No backup directory found"
        return 1
    fi
    
    local backups=($(ls -dt "$backup_dir"/attack_demo_* 2>/dev/null || true))
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        log_warn "No attack demo backups found"
        return 1
    fi
    
    for i in "${!backups[@]}"; do
        local backup_path="${backups[$i]}"
        local backup_name=$(basename "$backup_path")
        local backup_time=$(echo "$backup_name" | sed 's/attack_demo_//' | sed 's/_/ /g')
        
        echo "  $((i+1)). $backup_name"
        echo "     Time: $backup_time"
        echo "     Path: $backup_path"
        echo ""
    done
    
    log_info "Total backups found: ${#backups[@]}"
}

# Restore from specific backup
restore_from_backup() {
    local backup_dir="$1"
    
    if [[ ! -d "$backup_dir" ]]; then
        log_error "Backup directory not found: $backup_dir"
        return 1
    fi
    
    log_info "=== RESTORING FROM BACKUP ==="
    log_info "Backup source: $backup_dir"
    
    # Files to restore
    local restore_files=(
        "daemon/health_monitor.sh"
        "scripts/integrity_check.sh"
        "scripts/boot_sequence.sh"
        "scripts/cpu_monitor.sh"
        "manifest.sha256"
        "manifest.sha256.sig"
    )
    
    local restored_count=0
    
    for file in "${restore_files[@]}"; do
        local backup_file="$backup_dir/$(basename "$file")"
        local target_file="$PROJECT_ROOT/$file"
        
        if [[ -f "$backup_file" ]]; then
            cp "$backup_file" "$target_file"
            log_info "✅ Restored: $file"
            ((restored_count++))
        else
            log_warn "⚠️  Not in backup: $file"
        fi
    done
    
    log_info "✅ Restore completed: $restored_count files restored"
    
    # Set executable permissions for scripts
    local script_files=(
        "daemon/health_monitor.sh"
        "scripts/integrity_check.sh"
        "scripts/boot_sequence.sh"
        "scripts/cpu_monitor.sh"
    )
    
    for script in "${script_files[@]}"; do
        local target_file="$PROJECT_ROOT/$script"
        if [[ -f "$target_file" ]]; then
            chmod +x "$target_file"
            log_info "✅ Made executable: $script"
        fi
    done
}

# Auto-restore from latest backup
auto_restore() {
    log_info "=== AUTO-RESTORE MODE ==="
    
    local backup_dir="$PROJECT_ROOT/backup"
    local latest_backup=$(ls -dt "$backup_dir"/attack_demo_* 2>/dev/null | head -1 || true)
    
    if [[ -z "$latest_backup" ]]; then
        log_error "No backups found for auto-restore"
        log_info "Use --regen option to regenerate security files"
        return 1
    fi
    
    log_info "Latest backup found: $latest_backup"
    restore_from_backup "$latest_backup"
}

# Regenerate manifest and signature
regenerate_security_files() {
    log_info "=== REGENERATING SECURITY FILES ==="
    
    # Generate new hash manifest
    log_info "Generating new hash manifest..."
    if bash "$PROJECT_ROOT/tools/gen_hash.sh" generate; then
        log_info "✅ Hash manifest regenerated"
    else
        log_error "❌ Failed to generate hash manifest"
        return 1
    fi
    
    # Generate new key pair if needed
    if [[ ! -f "$PROJECT_ROOT/keys/private_key.pem" ]] || [[ ! -f "$PROJECT_ROOT/keys/public_key.pem" ]]; then
        log_info "Generating new RSA key pair..."
        if bash "$PROJECT_ROOT/tools/gen_keypair.sh" generate; then
            log_info "✅ RSA key pair generated"
        else
            log_error "❌ Failed to generate RSA key pair"
            return 1
        fi
    fi
    
    # Create new signature
    log_info "Creating new digital signature..."
    if bash "$PROJECT_ROOT/tools/sign_manifest.sh" sign; then
        log_info "✅ Digital signature created"
    else
        log_error "❌ Failed to create digital signature"
        return 1
    fi
    
    log_info "✅ Security files regeneration completed"
}

# Show current system status
show_system_status() {
    log_info "=== CURRENT SYSTEM STATUS ==="
    
    # Check service status
    if systemctl is-active --quiet health-monitor.service 2>/dev/null; then
        log_info "✅ Health monitor service: ACTIVE"
    else
        log_warn "⚠️  Health monitor service: INACTIVE"
    fi
    
    # Check integrity status
    if bash "$PROJECT_ROOT/scripts/integrity_check.sh" >/dev/null 2>&1; then
        log_info "✅ System integrity: VERIFIED"
    else
        log_error "❌ System integrity: COMPROMISED"
    fi
    
    # Check signature status
    if bash "$PROJECT_ROOT/scripts/verify_signature.sh" verify >/dev/null 2>&1; then
        log_info "✅ Digital signature: VALID"
    else
        log_error "❌ Digital signature: INVALID"
    fi
    
    # Check for attack proof
    if [[ -f "/tmp/attack_proof.txt" ]]; then
        log_warn "⚠️  Attack proof file found: /tmp/attack_proof.txt"
        log_warn "Content: $(cat /tmp/attack_proof.txt)"
    else
        log_info "✅ No attack artifacts found"
    fi
    
    # Check manifest status
    if [[ -f "$PROJECT_ROOT/manifest.sha256" ]]; then
        local file_count=$(wc -l < "$PROJECT_ROOT/manifest.sha256")
        log_info "✅ Manifest file: $file_count entries"
    else
        log_error "❌ Manifest file: MISSING"
    fi
    
    # Check signature file
    if [[ -f "$PROJECT_ROOT/manifest.sha256.sig" ]]; then
        if grep -q "FAKE_SIGNATURE" "$PROJECT_ROOT/manifest.sha256.sig" 2>/dev/null; then
            log_error "❌ Signature file: FAKE"
        else
            log_info "✅ Signature file: PRESENT"
        fi
    else
        log_error "❌ Signature file: MISSING"
    fi
}

# Full system recovery
full_recovery() {
    log_info "=== FULL SYSTEM RECOVERY ==="
    
    # Step 1: Clean attack artifacts
    clean_attack_artifacts
    
    # Step 2: Try auto-restore
    if auto_restore; then
        log_info "✅ System restored from backup"
    else
        log_warn "⚠️  No backup available, regenerating security files"
        regenerate_security_files
    fi
    
    # Step 3: Verify recovery
    log_info "Verifying system recovery..."
    if bash "$PROJECT_ROOT/scripts/integrity_check.sh" >/dev/null 2>&1; then
        log_info "✅ System recovery VERIFIED"
    else
        log_error "❌ System recovery FAILED"
        return 1
    fi
    
    # Step 4: Restart service if needed
    if systemctl is-active --quiet health-monitor.service 2>/dev/null; then
        log_info "Restarting health monitor service..."
        if sudo systemctl restart health-monitor.service; then
            log_info "✅ Service restarted successfully"
        else
            log_warn "⚠️  Service restart failed - manual restart may be needed"
        fi
    fi
    
    log_info "✅ Full system recovery completed"
}

# Main execution
main() {
    local option="${1:-help}"
    
    case "$option" in
        "--auto")
            full_recovery
            show_system_status
            ;;
        "--backup")
            if [[ -z "${2:-}" ]]; then
                log_error "Backup directory required"
                show_usage
                exit 1
            fi
            clean_attack_artifacts
            restore_from_backup "$2"
            show_system_status
            ;;
        "--clean")
            clean_attack_artifacts
            show_system_status
            ;;
        "--regen")
            regenerate_security_files
            show_system_status
            ;;
        "--status")
            show_system_status
            ;;
        "--list")
            list_backups
            ;;
        "--help"|"help"|"-h")
            show_usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $option"
            show_usage
            exit 1
            ;;
    esac
    
    log_info ""
    log_info "=== RECOVERY COMPLETED ==="
    log_info "System is now restored to a secure state"
    log_info "You can restart the health monitor service with:"
    log_info "  sudo systemctl restart health-monitor.service"
}

# Execute main function with all arguments
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
