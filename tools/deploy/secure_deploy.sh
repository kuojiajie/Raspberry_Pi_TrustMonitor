#!/bin/bash
# tools/deploy/secure_deploy.sh
# Secure deployment script for production systems
# Implements proper key separation and system hardening

set -u

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Logging functions
log_info() {
    echo -e "${BLUE}[SECURE_DEPLOY] $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}[SECURE_DEPLOY] $1${NC}"
}

log_error() {
    echo -e "${RED}[SECURE_DEPLOY] $1${NC}"
}

# Security check: ensure private key is not present
check_private_key_absence() {
    log_info "Checking for private key absence..."
    
    local private_keys_found=0
    
    # Check common locations
    local key_locations=(
        "$BASE_DIR/data/keys/private_key.pem"
        "$BASE_DIR/keys/private_key.pem"
        "$BASE_DIR/private_key.pem"
    )
    
    for key_file in "${key_locations[@]}"; do
        if [[ -f "$key_file" ]]; then
            log_error "SECURITY VIOLATION: Private key found at $key_file"
            ((private_keys_found++))
        fi
    done
    
    if [[ $private_keys_found -gt 0 ]]; then
        log_error "Found $private_keys_found private key(s) - remove before deployment!"
        return 1
    else
        log_info "✓ No private keys found - OK for deployment"
        return 0
    fi
}

# Verify integrity files exist
check_integrity_files() {
    log_info "Checking integrity files..."
    
    local required_files=(
        "$BASE_DIR/data/integrity/manifest.sha256"
        "$BASE_DIR/data/integrity/manifest.sha256.sig"
        "$BASE_DIR/data/integrity/public_key.pem"
    )
    
    local missing_files=0
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            log_error "Missing required file: $file"
            ((missing_files++))
        fi
    done
    
    if [[ $missing_files -gt 0 ]]; then
        log_error "Missing $missing_files required integrity files"
        return 1
    else
        log_info "✓ All integrity files present"
        return 0
    fi
}

# Set immutable protection on critical scripts
harden_critical_scripts() {
    log_info "Applying immutable protection to critical scripts..."
    
    local critical_scripts=(
        "$BASE_DIR/scripts/integrity_check.sh"
        "$BASE_DIR/scripts/boot_sequence.sh"
        "$BASE_DIR/scripts/verify_signature.sh"
    )
    
    for script in "${critical_scripts[@]}"; do
        if [[ -f "$script" ]]; then
            # Make executable and immutable
            chmod 755 "$script"
            if command -v chattr >/dev/null 2>&1; then
                chattr +i "$script"
                log_info "✓ Made immutable: $script"
            else
                log_warn "chattr not available - script not immutable: $script"
            fi
        fi
    done
}

# Set secure permissions
set_secure_permissions() {
    log_info "Setting secure permissions..."
    
    # Integrity directory - readable by all, writable only by root
    chmod 755 "$BASE_DIR/data/integrity"
    chmod 644 "$BASE_DIR/data/integrity/manifest.sha256"
    chmod 644 "$BASE_DIR/data/integrity/manifest.sha256.sig"
    chmod 644 "$BASE_DIR/data/integrity/public_key.pem"
    
    # Scripts directory
    chmod 755 "$BASE_DIR/scripts"
    find "$BASE_DIR/scripts" -name "*.sh" -exec chmod 755 {} \;
    
    log_info "✓ Secure permissions applied"
}

# Remove symlinks for security
remove_symlinks() {
    log_info "Removing symbolic links for security..."
    
    local symlinks=(
        "$BASE_DIR/keys"
        "$BASE_DIR/manifest.sha256"
        "$BASE_DIR/manifest.sha256.sig"
    )
    
    for symlink in "${symlinks[@]}"; do
        if [[ -L "$symlink" ]]; then
            rm "$symlink"
            log_info "✓ Removed symlink: $symlink"
        fi
    done
}

# Create systemd service with sandbox
create_secure_systemd_service() {
    log_info "Creating secure systemd service..."
    
    local service_content="[Unit]
Description=TrustMonitor Security Daemon
After=network.target

[Service]
Type=simple
ExecStart=$BASE_DIR/daemon/health_monitor.sh
Restart=always
RestartSec=10

# Security sandboxing
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$BASE_DIR/data/runtime $BASE_DIR/logs
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictRealtime=true
RestrictSUIDSGID=true
RemoveIPC=true

# User permissions
User=root
Group=root

[Install]
WantedBy=multi-user.target
"
    
    echo "$service_content" > "$BASE_DIR/systemd/trustmonitor-secure.service"
    log_info "✓ Created secure systemd service: trustmonitor-secure.service"
}

# Setup log rotation
setup_log_rotation() {
    log_info "Setting up log rotation..."
    
    local logrotate_config="# TrustMonitor log rotation
$BASE_DIR/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 root root
    maxsize 5M
}

$BASE_DIR/data/runtime/sel.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 root root
    maxsize 5M
}
"
    
    echo "$logrotate_config" > "$BASE_DIR/config/trustmonitor.logrotate"
    log_info "✓ Created logrotate configuration"
}

# Main deployment function
deploy_secure_system() {
    log_info "Starting secure deployment..."
    
    # Security checks
    check_private_key_absence || exit 1
    check_integrity_files || exit 1
    
    # System hardening
    remove_symlinks
    set_secure_permissions
    harden_critical_scripts
    
    # Service configuration
    create_secure_systemd_service
    setup_log_rotation
    
    log_info "✓ Secure deployment completed successfully!"
    log_info ""
    log_info "Next steps:"
    log_info "1. Copy trustmonitor-secure.service to /etc/systemd/system/"
    log_info "2. Copy trustmonitor.logrotate to /etc/logrotate.d/"
    log_info "3. Run: systemctl daemon-reload"
    log_info "4. Run: systemctl enable trustmonitor-secure.service"
    log_info "5. Run: systemctl start trustmonitor-secure.service"
}

# Show help
show_help() {
    cat << EOF
TrustMonitor Secure Deployment Tool

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help     Show this help message
    --check-only    Only run security checks, don't deploy

DESCRIPTION:
    This script prepares TrustMonitor for secure production deployment by:
    - Ensuring no private keys are present
    - Setting proper file permissions
    - Making critical scripts immutable
    - Creating sandboxed systemd service
    - Setting up log rotation

SECURITY NOTES:
    - Private keys should NEVER be on production systems
    - Only public keys are needed for verification
    - Critical scripts are made immutable with chattr +i
    - Systemd service runs in strict sandbox mode

EOF
}

# Main execution
main() {
    local check_only=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            --check-only)
                check_only=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    if [[ "$check_only" == "true" ]]; then
        log_info "Running security checks only..."
        check_private_key_absence || exit 1
        check_integrity_files || exit 1
        log_info "✓ All security checks passed"
    else
        deploy_secure_system
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
