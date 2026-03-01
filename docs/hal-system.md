# HAL System Overview

## 🏗️ Hardware Abstraction Layer (HAL)

TrustMonitor uses a Hardware Abstraction Layer (HAL) to provide unified access to hardware components like sensors and LEDs.

## 🔌 What HAL Does

- **Unified Interface**: Single way to access all hardware
- **Automatic Detection**: Finds and configures hardware automatically  
- **Error Handling**: Graceful fallback if hardware fails
- **Backward Compatibility**: Works with existing hardware controllers

## 🎯 For Users

You don't need to know HAL details - it works automatically:

```bash
# System automatically uses HAL when available
bash tools/dev/quick_test.sh

# Hardware just works
bash tools/user/demo.sh
```

## 📁 Key Files

- `hardware/hal_core.py` - Core HAL system
- `hardware/hal_interface.py` - Main hardware interface
- `hardware/hal_sensors.py` - Sensor management
- `hardware/hal_indicators.py` - LED control

## 🔧 Configuration

HAL uses settings from `config/health-monitor.env`:

```bash
USE_HAL=true                         # Enable HAL (default)
DHT11_PIN=4                          # Sensor pin
LED_RED_PIN=27                        # LED pins
LED_GREEN_PIN=22
LED_BLUE_PIN=5
```

## 🚨 Troubleshooting

If hardware doesn't work:

1. Check GPIO permissions: `groups $USER` (should include gpio)
2. Verify wiring connections
3. Run quick test: `bash tools/dev/quick_test.sh`

HAL automatically falls back to legacy controllers if needed.

---

*HAL is designed to work transparently - most users don't need to configure it.*
