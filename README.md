# TrustMonitor BMC/ROT POC

A Raspberry Pi-based monitoring system that demonstrates Baseboard Management Controller (BMC) and Root of Trust (ROT) concepts through real hardware integration.

## 🎯 Core Features

TrustMonitor transforms a Raspberry Pi into a miniature BMC/ROT system that:

- **System Health Monitoring**: CPU, memory, disk, network, and temperature tracking
- **Hardware Integration**: DHT11 sensor and RGB LED for physical feedback
- **Visual Status Indicators**: LED shows system health with temperature/humidity thresholds
- **Security Protection**: SHA256 integrity verification with RSA digital signatures
- **Service Management**: Automatic startup and background monitoring

## 🛠️ Installation & Setup

### Prerequisites
- Raspberry Pi (3B+ or later recommended)
- Python 3.8+ with pip
- DHT11 temperature/humidity sensor
- RGB LED (common anode)
- Jumper wires and breadboard

### Step 1: Install Dependencies
```bash
# Install Python dependencies
pip3 install adafruit-circuitpython-dht

# Install system dependencies (if needed)
sudo apt update
```

### Step 2: Configure System
```bash
# Option 1: Use configuration template (recommended)
cp config/health-monitor.env.example config/health-monitor.env
vim config/health-monitor.env

# Option 2: Use built-in defaults (quick start)
# System works immediately with default values - no config needed!
```

### Step 3: Install Service
```bash
# Copy service template
sudo cp systemd/health-monitor.service.example /etc/systemd/system/health-monitor.service

# Edit service file for your user paths
sudo vim /etc/systemd/system/health-monitor.service

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable health-monitor.service
sudo systemctl start health-monitor.service
```

## 📊 Usage & Monitoring

### Check System Status
```bash
# Check service status
sudo systemctl status health-monitor.service

# View real-time logs
sudo journalctl -u health-monitor.service -f

# View recent logs
sudo journalctl -u health-monitor.service --since "1 hour ago"
```

### Manual Testing
```bash
# Test hardware components
python3 hardware/sensor_monitor.py --test

# Test individual monitoring scripts
bash scripts/cpu_monitor.sh
bash scripts/memory_monitor.sh
bash scripts/disk_monitor.sh
bash scripts/network_monitor.sh
bash scripts/cpu_temp_monitor.sh

# Test ROT Security features
bash scripts/integrity_check.sh          # Verify file integrity and signature
bash scripts/verify_signature.sh verify  # Verify digital signature only
bash scripts/boot_sequence.sh            # Test Secure Boot sequence
bash tools/gen_hash.sh generate          # Generate hash manifest
bash tools/gen_keypair.sh generate       # Generate RSA key pair
bash tools/sign_manifest.sh sign         # Create digital signature

# Test LED control
python3 hardware/led_controller.py --color green
python3 hardware/led_controller.py --blink blue
```

### Test Results Summary
✅ **Hardware Components**: DHT11 sensor and RGB LED fully operational  
✅ **System Monitoring**: CPU, memory, disk, network, and temperature monitoring active  
✅ **Service Integration**: Automatic startup and systemd integration verified  
✅ **Security Features**: File integrity verification with digital signatures implemented  
✅ **Plugin System**: Dynamic plugin discovery and loading operational

### Service Management
```bash
# Restart service
sudo systemctl restart health-monitor.service

# Stop service
sudo systemctl stop health-monitor.service

# Test service crash recovery
sudo systemctl kill -SIGABRT health-monitor.service
```

## 🔧 Configuration

### Quick Start
The system works immediately with built-in defaults - no configuration required!

### Customization (Optional)
For custom monitoring thresholds, copy and edit the configuration file:
```bash
cp config/health-monitor.env.example config/health-monitor.env
```

### Key Settings
```bash
# Monitoring intervals (seconds)
CHECK_INTERVAL=30                    # System monitoring frequency
INTEGRITY_CHECK_INTERVAL=3600        # Integrity check frequency (1 hour, separate from monitoring)
SENSOR_MONITOR_INTERVAL=60           # Hardware monitoring frequency

# System thresholds
CPU_LOAD_WARN=1.50                   # CPU load warning threshold
CPU_LOAD_ERROR=3.00                  # CPU load error threshold
MEM_AVAIL_WARN_PCT=15                # Memory warning (% available)
MEM_AVAIL_ERROR_PCT=5                 # Memory error (% available)
DISK_USED_WARN_PCT=80                # Disk usage warning (%)
DISK_USED_ERROR_PCT=90                # Disk usage error (%)
CPU_TEMP_WARN=65.0                    # CPU temperature warning (°C)
CPU_TEMP_ERROR=75.0                   # CPU temperature error (°C)

# Hardware thresholds
TEMP_WARNING=40.0                    # Temperature warning (°C)
TEMP_ERROR=45.0                      # Temperature error (°C)
HUMIDITY_WARNING=70.0                # Humidity warning (%)
HUMIDITY_ERROR=80.0                  # Humidity error (%)
SENSOR_MAX_RETRIES=3                 # Sensor retry attempts
SENSOR_RETRY_DELAY=1.0               # Delay between retries (seconds)

# Network monitoring
PING_TARGET=8.8.8.8                  # Ping target for network checks
NETWORK_LATENCY_WARN_MS=200          # Network latency warning (ms)
NETWORK_LATENCY_ERROR_MS=500         # Network latency error (ms)
NETWORK_PACKET_LOSS_WARN_PCT=10      # Packet loss warning (%)
NETWORK_PACKET_LOSS_ERROR_PCT=30     # Packet loss error (%)
```

## 📈 LED Status Indicators
The RGB LED provides visual feedback about system health:
- **🟢 Green**: All systems normal (temp < 40°C, humidity < 70%)
- **🔵 Blue**: Warning conditions (temp 40-45°C or humidity 70-80%)  
- **🔴 Red**: Error conditions (temp > 45°C, humidity > 80%, or sensor failure)
- **⚫ Off**: System startup or shutdown

## 🛡️ Security Protection

TrustMonitor provides comprehensive security for your monitoring system:

- **File Integrity**: SHA256 hash verification detects unauthorized file modifications
- **Digital Signatures**: RSA-2048 cryptographic signatures protect critical system files  
- **Secure Boot**: Pre-execution integrity verification before monitoring mode
- **Attack Detection**: Automatic detection of tampering and malicious code injection
- **System Recovery**: Automatic backup and restoration with secure rollback

## 🎭 Security Demonstration

### Quick Demo
```bash
# 5-Minute Quick Demo
bash tools/demo.sh quick

# Full Demo with All Scenarios
bash tools/demo.sh full

# Manual Testing
bash tools/attack.sh --list          # View attack scenarios
bash tools/attack.sh malicious_code   # Simulate attack
bash tools/restore.sh --auto         # Restore system
```

### What It Demonstrates
1. **Attack Simulation** - Shows how system detects malicious modifications
2. **Security Response** - System halts when integrity is compromised
3. **Recovery Process** - Automatic restoration from secure backups

## 📚 Documentation

For detailed technical documentation, see the `docs/` directory:

- **[Attack/Defense Demo](docs/security/attack-defense-demo.md)** - Complete security demonstration with 5 attack scenarios

*See [docs/README.md](docs/README.md) for available documentation.*

---

## 📋 Version Information

**Current Version**: v2.2.4 - Backup File Automatic Cleanup System

### Recent Releases
- **v2.2.4**: Unified backup management with automatic cleanup and retention policies
- **v2.2.3**: Separated integrity check frequency from monitoring cycle for improved performance
- **v2.2.2**: Unified return code constants across all components
- **v2.2.1**: README simplification and documentation restructure
- **v2.2.0**: ROT Attack/Defense Demo with full security validation
- **v2.1.0**: RSA-sha256 Digital Signature System
- **v2.0.0**: ROT Security Core with Secure Boot sequence

### v2.2.4 Changes
- **Unified Backup System**: All backup files consolidated to `backup/` directory with organized structure
- **Automatic Cleanup**: Time-based and count-based retention policies prevent disk space issues
- **Backup Categories**: Separation of security backups (`backup/security/`) and demo backups (`backup/attack_demo/`)
- **Retention Policies**: Configurable retention settings (7 days for security, 3 days for demos)
- **Cleanup Plugin**: New `scripts/backup_cleanup.sh` plugin for automatic maintenance
- **Enhanced Tools**: Updated `sign_manifest.sh` and `attack.sh` to use unified backup system
- **Storage Statistics**: Built-in backup usage reporting and monitoring

*For complete version history, see git tags and commit log*