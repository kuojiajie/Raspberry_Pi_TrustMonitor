# TrustMonitor Attack/Defense Demonstration Guide
# Phase 2 Task 8 - ROT Security Validation

## 🎯 Objective

Demonstrate the effectiveness of TrustMonitor's ROT (Root of Trust) security mechanisms through realistic attack scenarios and recovery procedures.

## 🆕 v2.2.4 Backup System Update

The attack demo now uses the unified backup management system introduced in v2.2.4:

- **Automatic Backup Creation**: All attacks automatically create backups in `backup/attack_demo/YYYYMMDD_HHMMSS/`
- **Dual Backup Strategy**: Creates both demo backup and security backup for maximum protection
- **Organized Storage**: Backups are properly categorized and managed with retention policies
- **Easy Recovery**: Use `tools/user/restore.sh --auto` for automatic recovery from the latest backup

For detailed backup management information, see [Backup Management Documentation](../backup-management.md).

## 🛡️ Security Features Tested

### 1. **SHA256 File Integrity Verification**
- Monitors hash values of all critical system files
- Detects any unauthorized modifications
- Provides immediate failure notification

### 2. **RSA Digital Signature Verification**
- Cryptographic verification of manifest authenticity
- Prevents man-in-the-middle attacks on hash files
- Dual-layer security (integrity + authenticity)

### 3. **Secure Boot Sequence**
- Pre-startup integrity verification
- LED status indicators (Blue→Green/Red)
- System halt on security failures

## 🎭 Attack Scenarios

### Scenario 1: Malicious Code Injection
**Attack Type**: Backdoor insertion in monitoring script
```bash
# Execute attack
bash tools/security/attack.sh malicious_code

# What happens:
# - Injects backdoor code into cpu_monitor.sh
# - Backdoor activates at minute 42 of each hour
# - Creates /tmp/attack_proof.txt as evidence
```

**Detection**: SHA256 hash mismatch detected immediately
**Impact**: System refuses to start, LED shows red error

### Scenario 2: Configuration Tampering
**Attack Type**: Alter system thresholds to cause false alarms
```bash
# Execute attack
bash tools/security/attack.sh config_tamper

# What happens:
# - Lowers CPU error threshold from 3.00 to 0.01
# - Causes false CPU error reports under normal load
# - Undermines system reliability
```

**Detection**: File modification detected by integrity check
**Impact**: System halts with configuration corruption alert

### Scenario 3: Core Module Corruption
**Attack Type**: Modify main health monitor behavior
```bash
# Execute attack
bash tools/security/attack.sh core_module

# What happens:
# - Corrupts startup message in health_monitor.sh
# - Changes "Health monitor started" to "System compromised"
# - Demonstrates core system compromise
```

**Detection**: Immediate integrity verification failure
**Impact**: System refuses to enter monitoring mode

### Scenario 4: Signature Forgery Attempt
**Attack Type**: Attempt to create fake digital signature
```bash
# Execute attack
bash tools/security/attack.sh signature_forgery

# What happens:
# - Creates fake signature file
# - Attempts to bypass RSA verification
# - Demonstrates cryptographic security
```

**Detection**: RSA signature verification fails
**Impact**: System detects cryptographic attack

### Scenario 5: Combined Attack
**Attack Type**: Multiple simultaneous attack vectors
```bash
# Execute attack
bash tools/security/attack.sh multiple

# What happens:
# - Combines scenarios 1, 2, and 3
# - Tests comprehensive security response
# - Demonstrates multi-layer protection
```

**Detection**: Multiple integrity failures detected
**Impact**: Comprehensive security alert with detailed failure report

## 🔄 Recovery Procedures

### Automatic Recovery
```bash
# Full automatic recovery
bash tools/user/restore.sh --auto

# What happens:
# - Cleans attack artifacts
# - Restores from latest backup
# - Verifies system integrity
# - Restarts services if needed
```

### Manual Recovery
```bash
# List available backups
bash tools/user/restore.sh --list

# Restore from specific backup
bash tools/user/restore.sh --backup /path/to/backup

# Clean attack artifacts only
bash tools/user/restore.sh --clean

# Regenerate security files
bash tools/user/restore.sh --regen
```

### Status Monitoring
```bash
# Check current system status
bash tools/restore.sh --status

# Verify system integrity
bash scripts/integrity_check.sh

# Verify digital signature
bash scripts/verify_signature.sh verify
```

## 📊 Demonstration Flow

### Complete Attack/Defense Cycle
```bash
# 1. Initial Status Check
bash tools/security/attack.sh --status
# Expected: System integrity VERIFIED, signature VALID

# 2. Launch Attack
bash tools/security/attack.sh malicious_code
# Expected: System integrity COMPROMISED, backup created

# 3. Verify Detection
bash scripts/integrity_check.sh
# Expected: Integrity check FAILED, exit code 2

# 4. System Recovery
bash tools/user/restore.sh --auto
# Expected: System restored, integrity VERIFIED

# 5. Final Verification
bash scripts/integrity_check.sh
# Expected: All checks PASSED, exit code 0
```

## 🔍 Security Validation Points

### 1. **Detection Accuracy**
- ✅ Detects single-byte file modifications
- ✅ Identifies unauthorized code injections
- ✅ Recognizes configuration tampering
- ✅ Validates cryptographic signatures

### 2. **Response Effectiveness**
- ✅ Immediate system halt on compromise
- ✅ Clear error reporting and logging
- ✅ LED visual indicators (Red = Error)
- ✅ Detailed failure information

### 3. **Recovery Reliability**
- ✅ Complete file restoration from backup
- ✅ Attack artifact cleanup
- ✅ Service recovery and verification
- ✅ Multiple recovery options

## 📈 LED Status Indicators

| Status | LED Color | Meaning |
|--------|-----------|---------|
| 🔵 Blue | Booting | System starting, verifying integrity |
| 🟢 Green | Normal | All security checks passed |
| 🔴 Red | Error | Security compromise detected |
| ⚫ Off | Halted | System refuses to operate |

## 🛠️ Advanced Testing

### Service Integration Test
```bash
# Start health monitor service
sudo systemctl start health-monitor.service

# Monitor logs in real-time
sudo journalctl -u health-monitor.service -f

# Launch attack while service running
bash tools/security/attack.sh malicious_code

# Observe service response
# Expected: Service detects compromise, enters error state
```

### Boot Sequence Test
```bash
# Attack the system
bash tools/security/attack.sh core_module

# Restart service to test Secure Boot
sudo systemctl restart health-monitor.service

# Check service status
sudo systemctl status health-monitor.service
# Expected: Service fails to start due to integrity check
```

## 📋 Testing Checklist

### Pre-Demonstration
- [ ] Verify system integrity is clean
- [ ] Confirm service is running properly
- [ ] Check LED indicators are functional
- [ ] Validate backup directory exists

### During Demonstration
- [ ] Show initial clean status
- [ ] Execute chosen attack scenario
- [ ] Demonstrate detection mechanism
- [ ] Display error indicators and logs
- [ ] Perform system recovery
- [ ] Verify restored functionality

### Post-Demonstration
- [ ] Clean up temporary files
- [ ] Document any issues encountered
- [ ] Verify system is in secure state
- [ ] Update documentation if needed

## 🔧 Troubleshooting

### Common Issues

**Service won't start after attack**
```bash
# Check service status
sudo systemctl status health-monitor.service

# View error logs
sudo journalctl -u health-monitor.service --since "5 minutes ago"

# Restore system
bash tools/user/restore.sh --auto
```

**Backup restoration fails**
```bash
# List available backups
bash tools/restore.sh --list

# Regenerate security files
bash tools/user/restore.sh --regen

# Manual file restoration
cp backup/attack_demo_*/files/* ./
```

**Permission errors**
```bash
# Fix script permissions
chmod +x daemon/health_monitor.sh
chmod +x scripts/*.sh
chmod +x tools/user/*.sh
chmod +x tools/dev/*.sh
chmod +x tools/security/*.sh

# Fix key permissions
chmod 600 keys/private_key.pem
chmod 644 keys/public_key.pem
```

## 📚 Learning Objectives

### Security Concepts Demonstrated
1. **File Integrity Monitoring** - SHA256 hash verification
2. **Cryptographic Authentication** - RSA digital signatures
3. **Secure Boot Process** - Pre-execution verification
4. **Incident Response** - Automated recovery procedures
5. **Defense in Depth** - Multiple security layers

### Practical Skills
1. **Attack Simulation** - Realistic threat modeling
2. **Security Testing** - Verification of controls
3. **System Recovery** - Backup and restore procedures
4. **Log Analysis** - Security event investigation
5. **Service Management** - Systemd service handling

## 🎯 Success Criteria

### Demonstration Success Metrics
- ✅ All attacks are detected immediately
- ✅ System refuses to operate when compromised
- ✅ Recovery procedures restore full functionality
- ✅ LED indicators provide clear visual feedback
- ✅ Logs contain detailed security information
- ✅ No false positives in normal operation

### Educational Outcomes
- ✅ Clear understanding of ROT security principles
- ✅ Hands-on experience with attack/defense scenarios
- ✅ Practical knowledge of system recovery
- ✅ Familiarity with security monitoring tools
- ✅ Ability to troubleshoot security issues

---

**Phase 2 Task 8 Complete** - ROT Security Demonstration System
**Status**: ✅ Operational and Tested
**Security Level**: 🛡️ Enterprise-Grade Protection
