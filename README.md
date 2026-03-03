# TrustMonitor BMC/ROT POC

A Raspberry Pi-based monitoring system that demonstrates Baseboard Management Controller (BMC) and Root of Trust (ROT) concepts through real hardware integration.

## 🎯 What TrustMonitor Does

TrustMonitor transforms a Raspberry Pi into a miniature BMC/ROT system that:

- **🖥 System Health Monitoring**: CPU, memory, disk, network, and temperature tracking
- **🌡 Hardware Integration**: DHT11 sensor and RGB LED for physical feedback
- **💡 Visual Status Indicators**: LED shows system health with temperature/humidity thresholds
- **🔒 Security Protection**: SHA256 integrity verification with RSA digital signatures
- **⚡ Service Management**: Automatic startup and background monitoring
- **🛡 Attack Defense**: Security attack simulation and automatic recovery
- **🔐 Systemd Hardening**: v3.1.1+ includes security-hardened systemd service

## 🚀 Quick Start (5 Minutes)

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

### Step 4: Verify Installation
```bash
# Check service status
sudo systemctl status health-monitor.service

# View live logs
sudo journalctl -u health-monitor.service -f

# Quick manual test
bash daemon/health_monitor.sh
```

## 💡 Usage Guide

### Daily Operations
```bash
# Check system status
sudo systemctl status health-monitor.service

# View recent logs
sudo journalctl -u health-monitor.service --since "1 hour ago"

# Restart service
sudo systemctl restart health-monitor.service
```

### Security Management
```bash
# Generate security keys (first time only)
bash tools/user/gen_keypair.sh generate

# Update system integrity after changes
bash tools/user/gen_hash.sh generate
bash tools/user/sign_manifest.sh sign

# Verify system integrity
bash scripts/integrity_check.sh
```

### System Testing
```bash
# Run complete test suite
bash tests/test_runner.sh

# Run specific test types
bash tests/test_runner.sh unit
bash tests/test_runner.sh integration
bash tests/test_runner.sh security

# View test results
ls -la tests/results/
cat tests/results/test_report_*.txt
```

### System Recovery
```bash
# Automatic recovery from backup
bash tools/user/restore.sh --auto

# Manual recovery
bash tools/user/restore.sh --list
bash tools/user/restore.sh --restore [backup_id]
```

## 🔧 Hardware Setup

### Wiring Diagram
```
DHT11 Sensor:
├── VCC  → 3.3V (Pin 1)
├── GND  → Ground (Pin 6)
└── DATA → GPIO 17 (Pin 11)

RGB LED (Common Anode):
├── Red   → GPIO 27 (Pin 13)
├── Green → GPIO 22 (Pin 15)
├── Blue  → GPIO 5 (Pin 29)
└── Common → 3.3V (Pin 1)
```

### LED Status Indicators
- **🔵 Blue**: System booting/integrity checking
- **🟢 Green**: System healthy
- **🟡 Yellow**: Warning conditions (Red + Green)
- **🔴 Red**: Critical errors
- **⚪ White**: System shutdown

*Note: RGB LED supports color mixing for additional states (Yellow, Cyan, Magenta, White)*

## 📊 Monitoring Features

### System Metrics
- **CPU Load**: 1-minute average with warning/error thresholds
- **Memory**: Available memory percentage monitoring
- **Disk Usage**: Mount point usage tracking
- **Network**: Ping latency and packet loss monitoring
- **Temperature**: CPU and DHT11 sensor temperature
- **Humidity**: DHT11 sensor humidity monitoring

### Alert Thresholds
All thresholds are configurable in `config/health-monitor.env`:

```bash
# Example thresholds
CPU_LOAD_WARN=1.50
CPU_LOAD_ERROR=3.00
MEM_AVAIL_WARN_PCT=15
MEM_AVAIL_ERROR_PCT=5
DISK_USED_WARN_PCT=80
DISK_USED_ERROR_PCT=90
CPU_TEMP_WARN=60.0
CPU_TEMP_ERROR=70.0
```

## 🔒 Security Features

### Integrity Verification
TrustMonitor uses SHA256 hash verification to ensure system files haven't been tampered with:

```bash
# Verify all system files
bash scripts/integrity_check.sh

# Expected output: INTEGRITY OK: All XX files verified and signature valid
```

### Digital Signatures
RSA digital signatures ensure authenticity of the integrity manifest:

```bash
# Verify digital signature
bash scripts/verify_signature.sh verify

# Expected output: SIGNATURE STATUS: VERIFIED
```

### Security Demo
Experience TrustMonitor's security capabilities:

```bash
# Run complete security demonstration
bash tools/user/demo.sh quick

# View available attack scenarios
bash tools/security/attack.sh --list

# Run specific attack simulation
bash tools/security/attack.sh malicious_code
```

## 📚 Documentation

### For Users
- **[Attack/Defense Demo Guide](docs/attack-defense-demo.md)** - Complete security demonstration
- **[Backup Management](docs/backup-management.md)** - System backup and recovery
- **[Configuration Validation](docs/configuration-validation.md)** - v3.1.5+ configuration validation guide

### For Developers
- **[Documentation Index](docs/README.md)** - Complete technical documentation
- **[User Guide](docs/user-guide.md)** - Complete user guide and testing
- **[Security Guide](docs/security-guide.md)** - Security features and protection
- **[HAL System](docs/hal-system.md)** - Hardware abstraction layer overview
- **[Backup Management](docs/backup-management.md)** - Backup system and recovery

## 🛠 Advanced Configuration

### Environment Variables
Key configuration options in `config/health-monitor.env`:

**Note**: Copy `config/health-monitor.env.example` to `config/health-monitor.env` and modify as needed.

```bash
# Monitoring intervals
CHECK_INTERVAL=30                    # Health check frequency (seconds)
INTEGRITY_CHECK_INTERVAL=3600       # Integrity check frequency (seconds)

# Network monitoring
PING_TARGET=8.8.8.8                  # Ping target for network checks
NETWORK_TIMEOUT=5                    # Network timeout (seconds)

# Hardware settings
DHT11_PIN=17                         # DHT11 GPIO pin (GPIO 17)
USE_HAL=true                         # Use Hardware Abstraction Layer
```

### Service Management
```bash
# Service control commands
sudo systemctl start health-monitor.service
sudo systemctl stop health-monitor.service
sudo systemctl restart health-monitor.service
sudo systemctl enable health-monitor.service
sudo systemctl disable health-monitor.service

# Log management
sudo journalctl -u health-monitor.service --since today
sudo journalctl -u health-monitor.service -f
sudo journalctl -u health-monitor.service --vacuum-time=7d
```

## 🛠 Quick Tools

### System Check
```bash
# Quick health check (recommended for users)
bash tools/dev/quick_test.sh

# Configuration validation (v3.1.5+)
bash tools/config/validate_config.sh

# Validate specific configuration sections
bash tools/config/validate_config.sh --system-only
bash tools/config/validate_config.sh --paths-only
bash tools/config/validate_config.sh --logging-only

# Complete system demonstration
bash tools/user/demo.sh
```

### Security Testing
```bash
# View available attack scenarios
bash tools/security/attack.sh --list

# Run specific attack simulation
bash tools/security/attack.sh malicious_code

# Restore after attack
bash tools/user/restore.sh --auto
```

### System Maintenance
```bash
# Update system integrity after changes
bash tools/user/gen_hash.sh generate
bash tools/user/sign_manifest.sh sign

# Verify system integrity
bash scripts/integrity_check.sh

# Validate configuration (v3.1.5+)
bash tools/config/validate_config.sh

# Validate specific configuration sections
bash tools/config/validate_config.sh --system-only
bash tools/config/validate_config.sh --paths-only
bash tools/config/validate_config.sh --logging-only
```

## 🔧 Troubleshooting

### Common Issues

#### Service Won't Start
```bash
# Check service status
sudo systemctl status health-monitor.service

# Check for missing dependencies
bash daemon/health_monitor.sh

# Verify permissions
ls -la daemon/health_monitor.sh
```

#### Hardware Not Working
```bash
# Quick hardware check
bash tools/dev/quick_test.sh

# Check GPIO permissions
ls -la /dev/gpiomem
groups $USER  # Should include gpio group

# Test LED directly
python3 -c "
import sys
sys.path.append('hardware')
from hal_indicators import RGBLEDIndicator, LEDColor
led = RGBLEDIndicator('rgb_led')
config = {'pins': {'red': 27, 'green': 22, 'blue': 5}, 'brightness': 100}
if led.initialize(config):
    led.set_color(LEDColor.GREEN)
    print('LED test successful')
    led.clear()
"
```

#### Integrity Check Fails
```bash
# Regenerate hashes after legitimate changes
bash tools/user/gen_hash.sh generate
bash tools/user/sign_manifest.sh sign

# Or use restore tool
bash tools/user/restore.sh --regen
```

### Log Analysis
```bash
# Filter logs by level
sudo journalctl -u health-monitor.service | grep ERROR
sudo journalctl -u health-monitor.service | grep WARN

# Monitor specific metrics
sudo journalctl -u health-monitor.service | grep "CPU"
sudo journalctl -u health-monitor.service | grep "Memory"
```

## 📈 System Requirements

### Minimum Requirements
- **Hardware**: Raspberry Pi 3B+ or later
- **Storage**: 1GB free space
- **Memory**: 512MB RAM
- **OS**: Raspberry Pi OS (Bullseye or later)

### Recommended Requirements
- **Hardware**: Raspberry Pi 4B (2GB+)
- **Storage**: 8GB SD card (Class 10)
- **Memory**: 2GB+ RAM
- **Network**: Ethernet or WiFi connection

## 🤝 Contributing

TrustMonitor is a proof-of-concept system designed for educational and demonstration purposes. For development contributions:

1. Follow the existing code style and structure
2. Test changes with the provided test suite
3. Update documentation as needed
4. Ensure security features remain intact

---

**TrustMonitor: Your Raspberry Pi as a BMC/ROT System** 🚀

*For detailed technical documentation, see the [docs/](docs/) directory.*
