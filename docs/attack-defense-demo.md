# Attack/Defense Demonstration

## 🎯 Overview

Demonstrate TrustMonitor's security mechanisms through realistic attack scenarios and recovery procedures.

## 🛡️ Security Features Tested

### 1. **File Integrity Verification**
- SHA256 hash monitoring of all system files
- Immediate detection of unauthorized modifications
- Automatic system halt on compromise

### 2. **Digital Signature Verification**
- RSA cryptographic verification of manifest files
- Protection against man-in-the-middle attacks
- Dual-layer security (integrity + authenticity)

### 3. **Secure Boot Sequence**
- Pre-startup integrity verification
- LED status indicators (Blue→Green/Red)
- System refusal to start when compromised

## 🎭 Attack Scenarios

### Scenario 1: Malicious Code Injection
**Attack**: Backdoor insertion in monitoring script
```bash
bash tools/security/attack.sh malicious_code
```
**What happens**: Injects backdoor code, activates at minute 42, creates evidence file
**Detection**: SHA256 hash mismatch detected immediately
**Impact**: System refuses to start, LED shows red error

### Scenario 2: Configuration Tampering
**Attack**: Alter system thresholds to cause false alarms
```bash
bash tools/security/attack.sh config_tamper
```
**What happens**: Lowers CPU error threshold, causes false alarms
**Detection**: File modification detected by integrity check
**Impact**: System halts with configuration corruption alert

### Scenario 3: Core Module Corruption
**Attack**: Modify main health monitor behavior
```bash
bash tools/security/attack.sh core_module
```
**What happens**: Corrupts startup message, shows "System compromised"
**Detection**: Immediate integrity verification failure
**Impact**: System refuses to enter monitoring mode

### Scenario 4: Signature Forgery
**Attack**: Attempt to create fake digital signature
```bash
bash tools/security/attack.sh signature_forgery
```
**What happens**: Creates fake signature file, attempts to bypass verification
**Detection**: RSA signature verification fails
**Impact**: System detects cryptographic attack

### Scenario 5: Combined Attack
**Attack**: Multiple simultaneous attack vectors
```bash
bash tools/security/attack.sh multiple
```
**What happens**: Combines scenarios 1, 2, and 3
**Detection**: Multiple integrity failures detected
**Impact**: Comprehensive security alert with detailed failure report

## 🔄 Recovery Procedures

### Automatic Recovery
```bash
bash tools/user/restore.sh --auto
```
**What happens**: Cleans attack artifacts, restores from backup, verifies integrity

### Manual Recovery
```bash
# List available backups
bash tools/user/restore.sh --list

# Restore from specific backup
bash tools/user/restore.sh --backup [backup_id]

# Regenerate security files only
bash tools/user/restore.sh --regen
```

## 📊 Complete Demo Flow

```bash
# 1. Check initial status
bash tools/security/attack.sh --status

# 2. Launch attack
bash tools/security/attack.sh malicious_code

# 3. Verify detection
bash scripts/integrity_check.sh

# 4. Recover system
bash tools/user/restore.sh --auto

# 5. Verify recovery
bash scripts/integrity_check.sh
```

## 📈 LED Status Indicators

| Status | LED Color | Meaning |
|--------|-----------|---------|
| 🔵 Blue | Booting | System starting, verifying integrity |
| 🟢 Green | Normal | All security checks passed |
| 🔴 Red | Error | Security compromise detected |
| ⚫ Off | Halted | System refuses to operate |

## � Troubleshooting

### Service Won't Start After Attack
```bash
sudo systemctl status health-monitor.service
sudo journalctl -u health-monitor.service --since "5 minutes ago"
bash tools/user/restore.sh --auto
```

### Permission Errors
```bash
chmod +x daemon/health_monitor.sh
chmod +x scripts/*.sh
chmod +x tools/user/*.sh
chmod +x tools/security/*.sh
```

## 📚 Additional Information

For detailed backup management, see [Backup Management](backup-management.md).
For complete security features, see [Security Guide](security-guide.md).

---

*Attack/Defense demonstration shows TrustMonitor's comprehensive security protection.*
