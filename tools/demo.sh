#!/bin/bash
# tools/demo.sh
# Complete Attack/Defense Demonstration Script
# Phase 2 Task 8 - Full ROT Security Validation

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_info() {
    echo "ℹ️  $1"
}

# Show demo usage
show_usage() {
    echo "TrustMonitor Attack/Defense Demonstration"
    echo "===================================="
    echo ""
    echo "Usage: $0 [DEMO_TYPE]"
    echo ""
    echo "Demo Types:"
    echo "  quick      Quick demonstration (malicious code injection)"
    echo "  full       Full demonstration with all scenarios"
    echo "  service    Service integration demonstration"
    echo "  manual     Interactive manual demonstration"
    echo "  help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 quick     # 5-minute quick demo"
    echo "  $0 full      # 15-minute comprehensive demo"
    echo "  $0 service   # Test with systemd service"
}

# Quick demo - single attack scenario
demo_quick() {
    log_header "QUICK DEMONSTRATION"
    log_info "This demo shows malicious code injection and recovery"
    echo ""
    
    # Step 1: Show initial status
    log_header "Step 1: Initial System Status"
    bash "$SCRIPT_DIR/attack.sh" --status
    echo ""
    
    # Step 2: Launch attack
    log_header "Step 2: Launch Attack (Malicious Code Injection)"
    log_warning "Injecting backdoor into cpu_monitor.sh..."
    bash "$SCRIPT_DIR/attack.sh" malicious_code
    echo ""
    
    # Step 3: Verify detection
    log_header "Step 3: Security Detection"
    log_warning "Testing ROT security mechanisms..."
    if bash "$PROJECT_ROOT/scripts/integrity_check.sh" >/dev/null 2>&1; then
        log_error "UNEXPECTED: Security check passed - attack failed!"
        return 1
    else
        log_success "Security check FAILED as expected - attack detected!"
    fi
    echo ""
    
    # Step 4: System recovery
    log_header "Step 4: System Recovery"
    log_info "Restoring system from backup..."
    bash "$SCRIPT_DIR/restore.sh" --auto
    echo ""
    
    # Step 5: Final verification
    log_header "Step 5: Final Verification"
    if bash "$PROJECT_ROOT/scripts/integrity_check.sh" >/dev/null 2>&1; then
        log_success "System fully restored and secure!"
    else
        log_error "Recovery failed - system still compromised!"
        return 1
    fi
    
    log_success "Quick demonstration completed successfully!"
}

# Full demo - all scenarios
demo_full() {
    log_header "FULL DEMONSTRATION"
    log_info "This demo shows all attack scenarios and recovery mechanisms"
    echo ""
    
    local scenarios=(
        "malicious_code:Malicious Code Injection"
        "config_tamper:Configuration Tampering"
        "core_module:Core Module Corruption"
        "signature_forgery:Signature Forgery Attempt"
    )
    
    # Step 1: Initial status
    log_header "Step 1: Initial System Status"
    bash "$SCRIPT_DIR/attack.sh" --status
    echo ""
    
    # Step 2: Test each scenario
    for scenario_info in "${scenarios[@]}"; do
        IFS=':' read -r scenario_name scenario_desc <<< "$scenario_info"
        
        log_header "Step 2: $scenario_desc"
        log_warning "Testing $scenario_name scenario..."
        
        # Launch attack
        bash "$SCRIPT_DIR/attack.sh" "$scenario_name" >/dev/null 2>&1
        
        # Verify detection
        if bash "$PROJECT_ROOT/scripts/integrity_check.sh" >/dev/null 2>&1; then
            log_error "Security check passed - attack failed!"
        else
            log_success "Attack detected and blocked!"
        fi
        
        # Recovery
        log_info "Recovering system..."
        bash "$SCRIPT_DIR/restore.sh" --auto >/dev/null 2>&1
        
        # Verify recovery
        if bash "$PROJECT_ROOT/scripts/integrity_check.sh" >/dev/null 2>&1; then
            log_success "System recovered successfully!"
        else
            log_error "Recovery failed!"
            return 1
        fi
        
        echo ""
    done
    
    # Step 3: Combined attack
    log_header "Step 3: Combined Attack Scenario"
    log_warning "Testing multiple simultaneous attacks..."
    
    bash "$SCRIPT_DIR/attack.sh" multiple >/dev/null 2>&1
    
    if bash "$PROJECT_ROOT/scripts/integrity_check.sh" >/dev/null 2>&1; then
        log_error "Security check passed - combined attack failed!"
    else
        log_success "Combined attack detected and blocked!"
    fi
    
    # Recovery
    bash "$SCRIPT_DIR/restore.sh" --auto >/dev/null 2>&1
    
    if bash "$PROJECT_ROOT/scripts/integrity_check.sh" >/dev/null 2>&1; then
        log_success "System fully recovered from combined attack!"
    else
        log_error "Recovery from combined attack failed!"
        return 1
    fi
    
    log_success "Full demonstration completed successfully!"
}

# Service integration demo
demo_service() {
    log_header "SERVICE INTEGRATION DEMONSTRATION"
    log_info "This demo tests ROT security with systemd service integration"
    echo ""
    
    # Check if service exists
    if ! systemctl list-unit-files | grep -q "health-monitor.service"; then
        log_error "health-monitor.service not found"
        log_info "Install service first:"
        log_info "  sudo cp systemd/health-monitor.service.example /etc/systemd/system/health-monitor.service"
        log_info "  sudo systemctl daemon-reload"
        return 1
    fi
    
    # Step 1: Start service
    log_header "Step 1: Start Health Monitor Service"
    log_info "Starting health-monitor.service..."
    if sudo systemctl start health-monitor.service; then
        log_success "Service started successfully"
    else
        log_error "Failed to start service"
        return 1
    fi
    
    # Wait for service to initialize
    sleep 3
    
    # Check service status
    if systemctl is-active --quiet health-monitor.service; then
        log_success "Service is running"
    else
        log_error "Service failed to start"
        return 1
    fi
    echo ""
    
    # Step 2: Launch attack while service running
    log_header "Step 2: Attack Running Service"
    log_warning "Injecting malicious code while service is running..."
    bash "$SCRIPT_DIR/attack.sh" malicious_code >/dev/null 2>&1
    
    # Step 3: Check service response
    log_header "Step 3: Service Security Response"
    log_info "Checking service logs for security alerts..."
    
    # Show recent logs
    echo "Recent service logs:"
    sudo journalctl -u health-monitor.service --since "2 minutes ago" --no-pager | tail -10
    echo ""
    
    # Step 4: Restart service to test Secure Boot
    log_header "Step 4: Test Secure Boot Sequence"
    log_warning "Restarting service to test Secure Boot..."
    
    if sudo systemctl restart health-monitor.service; then
        sleep 3
        
        if systemctl is-active --quiet health-monitor.service; then
            log_warning "Service started (unexpected - should have failed)"
        else
            log_success "Service correctly refused to start due to integrity failure!"
        fi
    else
        log_success "Service correctly failed to start due to integrity failure!"
    fi
    echo ""
    
    # Step 5: Show service failure logs
    log_header "Step 5: Security Failure Logs"
    echo "Service failure logs:"
    sudo journalctl -u health-monitor.service --since "2 minutes ago" --no-pager | tail -10
    echo ""
    
    # Step 6: Recovery
    log_header "Step 6: System Recovery"
    log_info "Restoring system and restarting service..."
    
    bash "$SCRIPT_DIR/restore.sh" --auto >/dev/null 2>&1
    
    if sudo systemctl restart health-monitor.service; then
        sleep 3
        
        if systemctl is-active --quiet health-monitor.service; then
            log_success "Service recovered and running normally!"
        else
            log_error "Service failed to start after recovery"
            return 1
        fi
    else
        log_error "Failed to restart service after recovery"
        return 1
    fi
    
    log_success "Service integration demo completed successfully!"
}

# Manual interactive demo
demo_manual() {
    log_header "INTERACTIVE MANUAL DEMONSTRATION"
    log_info "This mode allows you to manually control the demonstration"
    echo ""
    
    while true; do
        echo "Available options:"
        echo "  1) Show system status"
        echo "  2) List attack scenarios"
        echo "  3) Launch attack"
        echo "  4) Test integrity check"
        echo "  5) Restore system"
        echo "  6) Show service logs"
        echo "  7) Exit"
        echo ""
        read -p "Choose option (1-7): " choice
        
        case "$choice" in
            1)
                bash "$SCRIPT_DIR/attack.sh" --status
                echo ""
                ;;
            2)
                bash "$SCRIPT_DIR/attack.sh" --list
                echo ""
                ;;
            3)
                echo "Available scenarios:"
                bash "$SCRIPT_DIR/attack.sh" --list
                read -p "Enter scenario name: " scenario
                if [[ -n "$scenario" ]]; then
                    bash "$SCRIPT_DIR/attack.sh" "$scenario"
                fi
                echo ""
                ;;
            4)
                bash "$PROJECT_ROOT/scripts/integrity_check.sh"
                echo ""
                ;;
            5)
                bash "$SCRIPT_DIR/restore.sh" --auto
                echo ""
                ;;
            6)
                if systemctl is-active --quiet health-monitor.service 2>/dev/null; then
                    echo "Recent service logs:"
                    sudo journalctl -u health-monitor.service --since "5 minutes ago" --no-pager | tail -10
                else
                    echo "Service is not running"
                fi
                echo ""
                ;;
            7)
                log_success "Exiting manual demonstration"
                break
                ;;
            *)
                log_error "Invalid option. Please choose 1-7."
                echo ""
                ;;
        esac
    done
}

# Main execution
main() {
    local demo_type="${1:-help}"
    
    case "$demo_type" in
        "quick")
            demo_quick
            ;;
        "full")
            demo_full
            ;;
        "service")
            demo_service
            ;;
        "manual")
            demo_manual
            ;;
        "help"|"-h"|"--help")
            show_usage
            exit 0
            ;;
        *)
            log_error "Unknown demo type: $demo_type"
            show_usage
            exit 1
            ;;
    esac
    
    log_success "Demonstration completed!"
    log_info "TrustMonitor ROT security is working correctly."
}

# Execute main function with all arguments
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
