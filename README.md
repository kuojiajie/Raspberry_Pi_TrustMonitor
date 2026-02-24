# TrustMonitor BMC/ROT POC

A Raspberry Pi-based monitoring system that demonstrates Baseboard Management Controller (BMC) and Root of Trust (ROT) concepts through real hardware integration.

## 🎯 What This Project Does

TrustMonitor transforms a Raspberry Pi into a miniature BMC/ROT system that:
- **Monitors System Health**: Tracks CPU, memory, disk, network, and temperature
- **Integrates Hardware**: Uses DHT11 sensor and RGB LED for physical feedback
- **Provides Visual Status**: LED indicators show system health at a glance
- **Runs as Service**: Automatic startup and monitoring in the background

## 🎯 Phase 1 Achievements (COMPLETED)

### 1. Project Environment Setup
- **systemd Service**: Configured automatic startup and monitoring
- **Git Workflow**: Proper version control with feature branches
- **Service Management**: Professional service lifecycle management

### 2. Hardware Integration
- **DHT11 Sensor**: Temperature and humidity monitoring with retry logic
- **RGB LED**: Visual status indicators (Green=Normal, Blue=Warning, Red=Error)
- **GPIO Control**: Professional PWM-based LED control
- **Error Handling**: Graceful handling of hardware failures

### 3. System Monitoring
- **CPU Load**: Real-time CPU load monitoring with thresholds
- **Memory Usage**: Available memory percentage tracking
- **Disk Usage**: Filesystem space monitoring
- **Network Connectivity**: Ping-based network health checks
- **CPU Temperature**: Thermal monitoring via /sys filesystem

### 4. Professional Architecture
- **Modular Design**: Clear separation of hardware and system monitoring
- **Hardware Abstraction**: Isolated hardware modules for easy testing
- **Service Integration**: Native systemd integration with journald logging
- **Configuration Management**: Environment-based configuration system
- **Plugin Auto-Load**: Dynamic plugin discovery and loading system
- **Standardized Interface**: Unified plugin interface with check and description functions

### 5. Internationalization & Professional Code
- **English Documentation**: All code comments, logs, and documentation in English
- **Professional Comments**: Clear, maintainable, and consistent code comments
- **Standardized Logging**: Uniform logging format across all modules
- **Clean Code Practices**: Removed unused variables and optimized code structure

### 6. Testing & Validation
- **Hardware Testing**: All hardware components tested and working
- **Service Testing**: Automatic service startup and monitoring verified
- **Integration Testing**: Complete system integration validated
- **Performance Testing**: CPU and memory usage optimized

### 7. Hardware Setup
- **DHT11 Sensor**: Connect to GPIO 17 for temperature/humidity monitoring
- **RGB LED**: Connect to GPIO 27 (Red), GPIO 22 (Green), GPIO 5 (Blue)
- **Power**: Ensure stable power supply for reliable sensor readings

## 📁 Project Structure

```
Raspberry_Pi_TrustMonitor/
├── config
│   └── health-monitor.env.example    # Configuration template
├── daemon
│   └── health_monitor.sh              # Main service orchestrator
├── hardware
│   ├── __init__.py                    # Hardware module initialization
│   ├── led_controller.py             # RGB LED control
│   ├── sensor_monitor.py             # Integrated sensor monitoring
│   └── sensor_reader.py              # DHT11 sensor interface
├── lib
│   ├── logger.sh                      # Logging utilities
│   └── plugin_loader.sh               # Plugin auto-loading system
├── logs                               # Log directory (currently uses journald)
├── scripts
│   ├── cpu_monitor.sh                 # CPU load monitoring plugin
│   ├── cpu_temp_monitor.sh           # CPU temperature monitoring plugin
│   ├── disk_monitor.sh                # Disk usage monitoring plugin
│   ├── memory_monitor.sh              # Memory usage monitoring plugin
│   ├── network_monitor.sh             # Network connectivity monitoring plugin
│   ├── integrity_check.sh            # ROT Security: File integrity verification plugin
│   ├── verify_signature.sh            # ROT Security: Digital signature verification plugin
│   └── boot_sequence.sh              # ROT Security: Secure Boot sequence controller
├── systemd
│   └── health-monitor.service.example  # Service configuration template
└── tools
    ├── gen_hash.sh                    # ROT Security: Hash fingerprint generator
    ├── gen_keypair.sh                # ROT Security: RSA key pair generator
    ├── sign_manifest.sh               # ROT Security: Digital signature generator
    └── crash_test.sh                  # Service testing utility
```

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
# Note: bc dependency removed - using awk for floating point comparisons
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
✅ **All Hardware Components**: Fully tested and operational
✅ **System Monitoring**: CPU, memory, disk, network, and temperature monitoring active
✅ **Service Integration**: Automatic startup and systemd integration verified
✅ **Environment Fallback**: Built-in default values ensure system works without config files
✅ **Dependency Checking**: Startup validation ensures all required dependencies are available
✅ **Health Aggregation**: Unified system status reporting for comprehensive monitoring
✅ **BC Dependency Removal**: Successfully removed bc dependency using awk for floating point comparisons
✅ **Temperature Precision**: Unified decimal point precision across all monitoring components
✅ **Plugin Auto-Load System**: Dynamic plugin discovery and loading with standardized interface
✅ **Plugin Testing**: All 8 monitoring plugins successfully converted and tested
✅ **Logging System**: Unified logging with plugin-specific context and conflict resolution
✅ **Production Ready**: Stable 46-second monitoring cycles with automatic recovery
✅ **ROT Security Core**: Secure Boot sequence with integrity verification fully implemented
✅ **Hash Fingerprint Mechanism**: SHA256-based file integrity checking with automatic detection
✅ **Digital Signature System**: RSA-sha256 cryptographic verification with dual validation
✅ **LED Status Feedback**: Blue (booting) → Green (normal) / Red (failed) visual indicators

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

### Environment Variables
The system uses **environment variables with built-in fallback values** for maximum reliability:

#### 🛡️ Fallback Mechanism
- **Primary**: Values from `config/health-monitor.env` (if exists)
- **Fallback**: Built-in default values (always available)
- **Result**: System works even without configuration file

#### 📊 Plugin Auto-Load System
The system features a **modern plugin auto-loading architecture** for enhanced modularity:
- **Dynamic Discovery**: Automatically discovers and loads all `.sh` scripts in the `scripts/` directory
- **Standardized Interface**: All plugins implement `*_check()` and `*_description()` functions
- **Unified Logging**: Plugin-specific logging functions with clear context attribution
- **Return Codes**: Standardized return codes (0=OK, 1=WARN, 2=ERROR) for consistent status reporting
- **Extensibility**: New monitoring scripts can be added without modifying the main daemon
- **Isolation**: Each plugin operates independently with proper error handling

#### 📊 Health Aggregation
The system provides **unified health status reporting** that aggregates all monitoring components:
- **Overall Status**: Single health indicator based on worst component status
- **Status Levels**: OK (all normal), WARNING (issues detected), ERROR (critical problems)
- **Component Coverage**: Network, CPU, Memory, Disk, CPU Temperature, Hardware Sensor
- **Reporting**: Clear identification of problematic components in warning/error states

#### 📊 BC Dependency Removal
The system has been **optimized to remove external bc dependency**:
- **Replacement Technology**: Using awk for floating point comparisons instead of bc
- **Benefits**: Reduced external dependencies, improved system reliability
- **Implementation**: All floating point comparisons now use `awk "BEGIN {print ($var >= $threshold)}"`
- **Compatibility**: awk is a standard utility available on all systems
- **Performance**: Faster execution with built-in tools
- **Maintenance**: Reduced system complexity and dependency management

#### 📝 Configuration Options
Edit `config/health-monitor.env` to customize monitoring behavior:

```bash
# Monitoring intervals (seconds)
CHECK_INTERVAL=30                    # System monitoring frequency
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
- **🟢 Green**: All systems operating normally (temp < 40°C, humidity < 70%)
- **🔵 Blue**: Warning conditions detected (temp 40-45°C or humidity 70-80%)
- **🔴 Red**: Error conditions detected (temp > 45°C or humidity > 80% or sensor failure)
- **⚫ Off**: System startup, shutdown, or hardware failure

> **Note**: LED indicators are triggered briefly during system checks (every 46 seconds) and may be difficult to observe due to the short display duration. This is a known limitation and will be addressed in a future branch.

## 🔄 Status Logic
```bash
# Green: All checks pass
# Blue: Any warning threshold exceeded
# Red: Any error threshold exceeded or hardware failure
```

## 🔄 What's Next

### 🟡 Phase 2: ROT Security Core (COMPLETED)
- ✅ **Firmware Integrity**: Hash-based verification of system files with SHA256
- ✅ **Secure Boot Simulation**: Boot-time integrity checking with LED status feedback
- ✅ **Digital Signatures**: RSA-sha256 cryptographic verification of critical files (Task 7)
- ⏳ **Attack/Defense Scripts**: Demonstration scenarios (Task 8)

### 🔴 Phase 3: Advanced Features (Planned)
- **Watchdog Mechanism**: Hardware watchdog for system recovery
- **Event Logging**: System Event Log (SEL) for audit trails
- **Performance Optimization**: Resource usage optimization
- **Documentation**: Technical documentation and presentation

---

## 🎯 Why This Project Matters

TrustMonitor demonstrates key BMC/ROT concepts in an accessible way:
- **Hardware Integration**: Real sensor data drives system decisions
- **Visual Feedback**: Physical indicators make system status tangible
- **Service Architecture**: Professional service management and logging
- **Modular Design**: Clean separation of concerns for maintainability
- **Educational Value**: Hands-on learning of system monitoring concepts
- **Security Focus**: Real-world ROT security implementation with integrity verification

---

## 🛡️ Phase 2 ROT Security Features

### Secure Boot Sequence
The system now implements a comprehensive Secure Boot sequence that verifies system integrity before entering monitoring mode:

**Boot Flow**:
1. **System Startup** → LED Blue (Booting)
2. **Integrity Check** → Verify all critical files against SHA256 hashes
3. **Digital Signature Verification** → RSA-sha256 signature validation
4. **Result Processing**:
   - ✅ **PASS** → LED Green → Enter normal monitoring mode
   - ❌ **FAIL** → LED Red Blinking → System halt (refuses service)

### Hash Fingerprint Mechanism
- **tools/gen_hash.sh**: Generates SHA256 hashes for all .sh and .py files
- **scripts/integrity_check.sh**: Verifies file integrity using manifest.sha256
- **Automatic Detection**: Any file modification triggers security halt

### Digital Signature System
- **tools/gen_keypair.sh**: Generates RSA-2048 key pairs for cryptographic signing
- **tools/sign_manifest.sh**: Creates RSA-sha256 digital signatures for manifest files
- **scripts/verify_signature.sh**: Verifies RSA digital signatures using public keys
- **Dual Verification**: Combines integrity checking with signature validation

### Usage Examples
```bash
# Generate hash manifest
bash tools/gen_hash.sh generate

# Generate RSA key pair
bash tools/gen_keypair.sh generate

# Create digital signature
bash tools/sign_manifest.sh sign

# Verify integrity manually
bash scripts/integrity_check.sh

# Test Secure Boot sequence
bash daemon/health_monitor.sh

# Simulate attack (modify file)
echo "# malicious code" >> scripts/cpu_monitor.sh
# System will halt on next restart with red LED blinking

# Verify signature manually
bash scripts/verify_signature.sh verify
```

---

## 📋 Version Information

**Current Version**: v2.2.0 (Phase 2 Task 8 Complete - ROT Attack/Defense Demo)

### Version History
- **v2.2.0**: Phase 2 Task 8 Complete - ROT Attack/Defense Demo with full hardware integration and security validation
- **v2.1.0**: Phase 2 Complete - ROT Security Core with RSA-sha256 digital signatures and dual verification system
- **v2.0.0**: Phase 2 Foundation - ROT Security Core with Secure Boot sequence and integrity verification
- **v1.1.5**: Phase 1 Refactoring - Plugin Auto-Load System with dynamic plugin discovery and loading
- **v1.1.4**: Phase 1 Refactoring - Remove bc dependency using awk for floating point comparisons
- **v1.1.3**: Phase 1 Refactoring - Overall health aggregation system
- **v1.1.2**: Phase 1 Refactoring - Environment fallback and dependency checking
- **v1.1.1**: Enhanced reliability with environment variable fallback mechanism
- **v1.1.0**: Phase 1 Complete - Hardware integration and system monitoring with full test validation
- **v1.0.0**: Initial release with basic monitoring capabilities


### Known Limitations
- ⚠️ **LED Visibility**: LED indicators display briefly during checks and may be difficult to observe (confirmed working in v2.2.0 testing)
- ⚠️ **PWM Control**: LED hardware response requires further investigation (basic functionality verified, advanced PWM needs optimization)
- ⚠️ **Sensor Accuracy**: DHT11 sensor may occasionally experience checksum errors (handled by retry mechanism, verified working)
- ⚠️ **Hash Regeneration**: manifest.sha256 must be regenerated after any legitimate code changes (automated in attack/defense demo)
- ⚠️ **Key Management**: RSA keys must be securely stored and backed up manually

### Future Improvements
- 🔧 **LED Enhancement**: Branch development for improved LED visibility and hardware response
- 🔧 **Sensor Optimization**: Enhanced sensor reading algorithms and error handling
- 🔧 **Visual Feedback**: Alternative status indication methods
- 🔧 **Key Rotation**: Automated RSA key rotation and management system
- ✅ **Attack Scenarios**: Comprehensive attack/defense demonstration scripts (COMPLETED in v2.2.0)

---

**Phase 2 Complete** - ROT Security Core implemented with Secure Boot sequence, integrity verification, RSA-sha256 digital signatures, and comprehensive attack/defense demonstration (v2.2.0)