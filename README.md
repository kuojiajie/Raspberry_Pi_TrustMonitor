# TrustMonitor BMC/ROT POC

A Raspberry Pi-based monitoring system that demonstrates Baseboard Management Controller (BMC) and Root of Trust (ROT) concepts through real hardware integration.

## 🎯 What TrustMonitor Does

TrustMonitor transforms a Raspberry Pi into a miniature BMC/ROT system that:

- **🖥️ System Health Monitoring**: CPU, memory, disk, network, and temperature tracking
- **🌡️ Hardware Integration**: DHT11 sensor and RGB LED for physical feedback
- **💡 Visual Status Indicators**: LED shows system health with temperature/humidity thresholds
- **🔒 Security Protection**: SHA256 integrity verification with RSA digital signatures
- **⚡ Service Management**: Automatic startup and background monitoring
- **🛡️ Attack Defense**: Security attack simulation and automatic recovery

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
└── DATA → GPIO 4 (Pin 7)

RGB LED (Common Anode):
├── Red   → GPIO 27 (Pin 13)
├── Green → GPIO 22 (Pin 15)
├── Blue  → GPIO 5 (Pin 29)
└── Common → 3.3V (Pin 1)
```

### LED Status Indicators
- **🔵 Blue**: System booting/integrity checking
- **🟢 Green**: System healthy
- **🟡 Yellow**: Warning conditions
- **🔴 Red**: Critical errors
- **⚪ Off**: System shutdown

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

### For Developers
- **[Documentation Index](docs/README.md)** - Complete technical documentation
- **[User Guide](docs/user-guide.md)** - Complete user guide and testing
- **[Security Guide](docs/security-guide.md)** - Security features and protection
- **[HAL System](docs/hal-system.md)** - Hardware abstraction layer overview
- **[Backup Management](docs/backup-management.md)** - Backup system and recovery

## 🛠️ Advanced Configuration

### Environment Variables
Key configuration options in `config/health-monitor.env`:

```bash
# Monitoring intervals
CHECK_INTERVAL=30                    # Health check frequency (seconds)
INTEGRITY_CHECK_INTERVAL=3600       # Integrity check frequency (seconds)

# Network monitoring
PING_TARGET=8.8.8.8                  # Ping target for network checks
NETWORK_TIMEOUT=5                    # Network timeout (seconds)

# Hardware settings
DHT11_PIN=4                          # DHT11 GPIO pin
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

## 🛠️ Quick Tools

### System Check
```bash
# Quick health check (recommended for users)
bash tools/dev/quick_test.sh

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

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📋 Version History

### v2.2.7 (Current) - Tools Reorganization & System Stabilization
- **� Tools Restructure**: Organized tools into `user/`, `dev/`, and `security/` directories
- **🛠️ Simplified Testing**: Removed complex test suite, kept essential `quick_test.sh`
- **� Enhanced Documentation**: Complete tools documentation with usage examples
- **🔧 Path Fixes**: Fixed `attack.sh` paths for security demonstrations
- **✅ System Stability**: All user-facing functions fully operational
- **�️ ROT Security**: Complete integrity verification and digital signature system
- **🎯 Phase 2 Complete**: Ready for Phase 3 development

### v2.2.6 - HAL (Hardware Abstraction Layer)
- **🏗️ HAL System**: Complete hardware abstraction layer with unified interfaces
- **🔌 Device Management**: Centralized device registration and lifecycle management
- **🔄 Backward Compatibility**: Seamless integration with existing hardware modules
- **🧪 Comprehensive Testing**: 15/15 HAL core tests, 23/23 hardware functionality tests

### v2.2.5 - Graceful Shutdown & Tools Reorganization
- **🛑 SIGTERM Handling**: Proper service shutdown with hardware cleanup
- **📂 Tools Restructure**: Organized tools into `user/`, `dev/`, and `security/` directories
- **💾 Backup Management**: Unified backup system with automatic cleanup

### v2.2.4 - Unified Backup Management
- **💾 Backup System**: Centralized backup with automatic rotation
- **🧹 Cleanup Automation**: Automatic old backup removal with retention policies
- **📊 Backup Statistics**: Backup monitoring and reporting

### v2.2.3 - Performance Optimization
- **⚡ Integrity Check Efficiency**: Optimized hash generation and verification
- **🚀 Faster Startup**: Reduced initialization time
- **📈 Performance Metrics**: Added performance monitoring

### v2.2.2 - Return Code Standardization
- **🔢 Unified Return Codes**: Standardized error handling across all scripts
- **📋 Code Constants**: Centralized return code definitions
- **🐛 Better Debugging**: Improved error reporting and troubleshooting

### v2.2.1 - Documentation Refactoring
- **📚 User-Focused Docs**: Restructured documentation for better user experience
- **🔖 Clear Navigation**: Improved document organization and cross-references
- **📖 Comprehensive Guides**: Enhanced setup and troubleshooting guides

### v2.2.0 - ROT Attack/Defense System
- **🛡️ Security Demo**: Complete attack/defense demonstration system
- **🎯 5 Attack Scenarios**: Comprehensive security testing scenarios
- **🔍 Forensic Analysis**: Attack detection and evidence collection

### v2.1.0 - RSA Digital Signature System
- **🔐 Digital Signatures**: RSA-based file integrity verification
- **🔑 Key Management**: Automated RSA key pair generation and management
- **📋 Signature Verification**: Complete signature validation system

### v2.0.0 - ROT Security Core
- **🚀 Secure Boot**: Root of Trust implementation with secure boot sequence
- **🔒 Integrity Protection**: SHA256-based file integrity verification
- **🛡️ Security Framework**: Comprehensive security architecture

### v1.1.5 - Plugin Auto-Load System
- **🔌 Plugin System**: Dynamic plugin loading and management
- **⚙️ Auto-Discovery**: Automatic plugin detection and initialization
- **🔧 Plugin Interface**: Standardized plugin development framework

### v1.1.4 - Dependency Cleanup
- **🧹 Code Cleanup**: Removed bc dependency and improved portability
- **📝 Documentation**: Updated README and improved formatting
- **🔧 Configuration**: Enhanced configuration management

### v1.1.3 - Health Aggregation
- **📊 Overall Health**: System-wide health status aggregation
- **🎯 Priority Alerts**: Critical system issue prioritization
- **📈 Health Metrics**: Comprehensive health monitoring dashboard

### v1.1.2 - Dependency Management
- **🔍 Dependency Checking**: Automatic dependency verification
- **📦 Package Management**: Enhanced package installation scripts
- **⚙️ Environment Setup**: Improved environment configuration

### v1.1.1 - Environment Fallback
- **🔄 Fallback System**: Enhanced environment variable fallback mechanisms
- **🛡️ Error Handling**: Improved error handling and recovery
- **🔧 Configuration Reliability**: More robust configuration management

### v1.1.0 - Phase 1 Complete
- **🎉 Production Ready**: Complete Phase 1 implementation
- **🚀 Stable Release**: Production-ready monitoring system
- **📚 Full Documentation**: Complete user and developer documentation

### v1.0.0 - Initial Release
- **🎯 Proof of Concept**: Initial BMC/ROT demonstration
- **🖥️ Basic Monitoring**: Core system health monitoring
- **🌡️ Hardware Integration**: DHT11 sensor and RGB LED support

---

**TrustMonitor: Your Raspberry Pi as a BMC/ROT System** 🚀

*For detailed technical documentation, see the [docs/](docs/) directory.*
