#!/bin/bash
# tools/attack.sh
# Attack/Defense Demonstration Script - Phase 2 Task 8
# Simulates various attack scenarios to test ROT security mechanisms

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKUP_DIR="$PROJECT_ROOT/backup/attack_demo_$(date +%Y%m%d_%H%M%S)"

# Attack scenarios registry
declare -A ATTACK_SCENARIOS
ATTACK_SCENARIOS=(
    ["malicious_code"]="Inject malicious code into monitoring script"
    ["config_tamper"]="Tamper with system configuration"
    ["core_module"]="Corrupt core health monitor module"
    ["signature_forgery"]="Attempt signature forgery attack"
    ["multiple"]="Combined attack scenario"
)

# Logging functions
log_info() {
    echo "[ATTACK] [INFO] $1"
}

log_warn() {
    echo "[ATTACK] [WARN] $1"
}

log_error() {
    echo "[ATTACK] [ERROR] $1" >&2
}

# Show usage
show_usage() {
    echo "TrustMonitor Attack/Defense Demonstration"
    echo "======================================"
    echo ""
    echo "Usage: $0 [ATTACK_TYPE] [OPTIONS]"
    echo ""
    echo "Attack Types:"
    for scenario in "${!ATTACK_SCENARIOS[@]}"; do
        echo "  $scenario    - ${ATTACK_SCENARIOS[$scenario]}"
    done
    echo ""
    echo "Options:"
    echo "  --list        List all attack scenarios"
    echo "  --status      Show current system status"
    echo "  --verify      Verify system integrity before attack"
    echo "  --help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 malicious_code    # Inject malicious code"
    echo "  $0 multiple         # Launch combined attack"
    echo "  $0 --verify         # Check system integrity"
}

# Load backup manager
source "$SCRIPT_DIR/../../lib/backup_manager.sh"

# Create backup directory using unified backup system
create_backup() {
    log_info "Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    
    # Backup critical files
    local critical_files=(
        "daemon/health_monitor.sh"
        "scripts/integrity_check.sh"
        "scripts/boot_sequence.sh"
        "scripts/cpu_monitor.sh"
        "manifest.sha256"
        "manifest.sha256.sig"
    )
    
    for file in "${critical_files[@]}"; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            cp "$PROJECT_ROOT/$file" "$BACKUP_DIR/"
            log_info "Backed up: $file"
        fi
    done
    
    log_info "Backup completed: $BACKUP_DIR"
    
    # Also create security backup
    log_info "Creating additional security backup..."
    create_security_backup >/dev/null
}

# Attack Scenario 1: Malicious Code Injection
attack_malicious_code() {
    log_info "=== ATTACK SCENARIO 1: Malicious Code Injection ==="
    
    local target_file="$PROJECT_ROOT/scripts/cpu_monitor.sh"
    local malicious_code="# MALICIOUS CODE INJECTION - Backdoor\n# This code was injected by attacker\nif [[ \"\$(date +%M)\" == \"42\" ]]; then\n    log_error \"BACKDOOR ACTIVATED: Executing malicious command\"\n    echo \"PWNED by TrustMonitor Attack Demo\" > /tmp/attack_proof.txt\nfi"
    
    if [[ -f "$target_file" ]]; then
        log_info "Injecting malicious code into: $target_file"
        echo -e "$malicious_code" >> "$target_file"
        log_info "✅ Malicious code injected successfully"
        log_info "📍 Backdoor will activate at minute 42 of each hour"
    else
        log_error "Target file not found: $target_file"
        return 1
    fi
}

# Attack Scenario 2: Configuration Tampering
attack_config_tamper() {
    log_info "=== ATTACK SCENARIO 2: Configuration Tampering ==="
    
    local target_file="$PROJECT_ROOT/daemon/health_monitor.sh"
    local tampered_line='CPU_LOAD_ERROR=0.01  # TAMPERED: Lowered threshold to trigger false alarms'
    
    if [[ -f "$target_file" ]]; then
        log_info "Tampering with CPU error threshold in: $target_file"
        # Find and replace the CPU_LOAD_ERROR line
        sed -i 's/: "${CPU_LOAD_ERROR:=3.00}"/: "${CPU_LOAD_ERROR:=0.01}  # TAMPERED: Lowered threshold to trigger false alarms"/' "$target_file"
        log_info "✅ Configuration tampered successfully"
        log_info "📍 System will now report CPU errors under normal load"
    else
        log_error "Target file not found: $target_file"
        return 1
    fi
}

# Attack Scenario 3: Core Module Corruption
attack_core_module() {
    log_info "=== ATTACK SCENARIO 3: Core Module Corruption ==="
    
    local target_file="$PROJECT_ROOT/daemon/health_monitor.sh"
    local corrupted_line='log_info "Health monitor started"  # CORRUPTED: Modified startup message'
    
    if [[ -f "$target_file" ]]; then
        log_info "Corrupting core module: $target_file"
        # Corrupt the startup message
        sed -i 's/log_info "Health monitor started"/log_info "CORRUPTED: System compromised by attacker"/' "$target_file"
        log_info "✅ Core module corrupted successfully"
        log_info "📍 System will display compromised startup message"
    else
        log_error "Target file not found: $target_file"
        return 1
    fi
}

# Attack Scenario 4: Signature Forgery Attempt
attack_signature_forgery() {
    log_info "=== ATTACK SCENARIO 4: Signature Forgery Attempt ==="
    
    local manifest_file="$PROJECT_ROOT/manifest.sha256"
    local fake_signature="$PROJECT_ROOT/manifest.sha256.sig"
    
    if [[ -f "$manifest_file" ]]; then
        log_info "Attempting to create fake signature..."
        
        # Create a fake signature file (this will fail verification)
        echo "-----BEGIN FAKE SIGNATURE-----" > "$fake_signature"
        echo "FAKE_SIGNATURE_DATA_$(date +%s)_$(openssl rand -hex 16)" >> "$fake_signature"
        echo "-----END FAKE SIGNATURE-----" >> "$fake_signature"
        
        log_info "✅ Fake signature created (will fail verification)"
        log_info "📍 Signature verification will detect this forgery"
    else
        log_error "Manifest file not found: $manifest_file"
        return 1
    fi
}

# Attack Scenario 5: Combined Attack
attack_multiple() {
    log_info "=== ATTACK SCENARIO 5: Combined Attack ==="
    log_info "Launching multiple attack vectors..."
    
    attack_malicious_code
    attack_config_tamper
    attack_core_module
    
    log_info "✅ Combined attack completed"
    log_info "📍 Multiple security layers have been compromised"
}

# Verify system integrity before attack
verify_system_integrity() {
    log_info "Verifying system integrity before attack..."
    
    # Run integrity check
    if bash "$PROJECT_ROOT/scripts/integrity_check.sh" >/dev/null 2>&1; then
        log_info "✅ System integrity verified - Ready for attack demonstration"
        return 0
    else
        log_warn "⚠️  System integrity already compromised - Cannot proceed with attack demo"
        return 1
    fi
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
    fi
}

# List attack scenarios
list_attack_scenarios() {
    log_info "=== AVAILABLE ATTACK SCENARIOS ==="
    for scenario in "${!ATTACK_SCENARIOS[@]}"; do
        echo "  $scenario    - ${ATTACK_SCENARIOS[$scenario]}"
    done
}

# Main execution
main() {
    local attack_type="${1:-help}"
    
    case "$attack_type" in
        "malicious_code")
            verify_system_integrity || exit 1
            create_backup
            attack_malicious_code
            show_system_status
            ;;
        "config_tamper")
            verify_system_integrity || exit 1
            create_backup
            attack_config_tamper
            show_system_status
            ;;
        "core_module")
            verify_system_integrity || exit 1
            create_backup
            attack_core_module
            show_system_status
            ;;
        "signature_forgery")
            verify_system_integrity || exit 1
            create_backup
            attack_signature_forgery
            show_system_status
            ;;
        "multiple")
            verify_system_integrity || exit 1
            create_backup
            attack_multiple
            show_system_status
            ;;
        "--list")
            list_attack_scenarios
            ;;
        "--status")
            show_system_status
            ;;
        "--verify")
            verify_system_integrity
            ;;
        "--help"|"help"|"-h")
            show_usage
            exit 0
            ;;
        *)
            log_error "Unknown attack type: $attack_type"
            show_usage
            exit 1
            ;;
    esac
    
    log_info ""
    log_info "=== ATTACK COMPLETED ==="
    log_info "Next steps:"
    log_info "1. Restart health monitor service to see security response"
    log_info "   sudo systemctl restart health-monitor.service"
    log_info "2. Check service logs for security alerts"
    log_info "   sudo journalctl -u health-monitor.service -f"
    log_info "3. Use restore.sh to recover the system"
    log_info "   bash tools/restore.sh"
}

# Execute main function with all arguments
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
