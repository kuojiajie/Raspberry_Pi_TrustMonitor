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

### Hardware Setup
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
│   └── logger.sh                      # Logging utilities
├── logs                               # Log directory (currently uses journald)
├── scripts
│   ├── cpu_monitor.sh                 # CPU load monitoring
│   ├── cpu_temp_monitor.sh           # CPU temperature monitoring
│   ├── disk_monitor.sh                # Disk usage monitoring
│   ├── memory_monitor.sh              # Memory usage monitoring
│   └── network_monitor.sh             # Network connectivity monitoring
├── systemd
│   └── health-monitor.service.example  # Service configuration template
└── tools
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
sudo apt install bc  # For floating point comparisons in shell scripts
```

### Step 2: Configure System
```bash
# Copy configuration template
cp config/health-monitor.env.example config/health-monitor.env

# Edit configuration with your preferred thresholds
vim config/health-monitor.env
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

# Test LED control
python3 hardware/led_controller.py
```

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
Edit `config/health-monitor.env` to customize monitoring behavior:

```bash
# Monitoring intervals (seconds)
CHECK_INTERVAL=30                    # System monitoring frequency
SENSOR_MONITOR_INTERVAL=60           # Hardware monitoring frequency

# System thresholds
CPU_LOAD_WARN=2.00                   # CPU load warning threshold
CPU_LOAD_ERROR=3.00                  # CPU load error threshold
MEMORY_WARN=20                       # Memory warning (% available)
MEMORY_ERROR=10                      # Memory error (% available)
DISK_WARN=80                         # Disk usage warning (%)
DISK_ERROR=90                        # Disk usage error (%)
CPU_TEMP_WARN=70                     # CPU temperature warning (°C)
CPU_TEMP_ERROR=80                    # CPU temperature error (°C)

# Hardware thresholds
TEMP_WARNING=30.0                    # Temperature warning (°C)
TEMP_ERROR=35.0                      # Temperature error (°C)
HUMIDITY_WARNING=70.0                # Humidity warning (%)
HUMIDITY_ERROR=80.0                  # Humidity error (%)

# Network monitoring
PING_TARGET=8.8.8.8                  # Ping target for network checks
```

### Import Strategy
Control hardware module import behavior:

```bash
# Use absolute import (recommended)
USE_RELATIVE_IMPORT=false

# Use relative import (legacy)
USE_RELATIVE_IMPORT=true
```

## 📈 LED Status Indicators

The RGB LED provides visual feedback about system health:

- **🟢 Green**: All systems operating normally
- **🔵 Blue**: Warning conditions detected (elevated resource usage)
- **🔴 Red**: Error conditions detected (critical issues)
- **⚫ Off**: System startup, shutdown, or hardware failure

### Status Logic
```bash
# Green: All checks pass
# Blue: Any warning threshold exceeded
# Red: Any error threshold exceeded or hardware failure
```

## 🔄 What's Next

### Phase 2: ROT Security Core (Planned)
- **Firmware Integrity**: Hash-based verification of system files
- **Secure Boot Simulation**: Boot-time integrity checking
- **Digital Signatures**: Cryptographic verification of critical files
- **Failure Modes**: Secure handling of integrity violations

### Phase 3: Advanced Features (Planned)
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

**Phase 1 Complete** - Ready for Phase 2 development