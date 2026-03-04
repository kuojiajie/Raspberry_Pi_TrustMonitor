# Developer Guide

## 🛠 開發者指南

本文檔提供開發者需要的技術細節和工具使用說明。

## 🔧 工具概覽

TrustMonitor 提供完整的工具集，分為三個主要類別：

### `tools/user/` - 用戶工具
基本系統管理和安全工具：
- **`gen_hash.sh`** - 生成 SHA256 雜湊清單用於完整性驗證
- **`gen_keypair.sh`** - 生成 RSA 密鑰對用於數位簽章
- **`sign_manifest.sh`** - 使用私鑰簽署雜湊清單
- **`restore.sh`** - 在安全事件後從備份恢復系統
- **`demo.sh`** - 完整系統演示和測試

### `tools/demo/security/` - 安全工具
- **`attack.sh`** - 攻擊/防禦演示腳本，用於測試安全機制
- **攻擊類型**: malicious_code, config_tamper, core_module, signature_forgery
- **使用方式**: `bash tools/demo/security/attack.sh --list` 查看可用攻擊

### `tools/dev/` - 開發工具
- **`quick_test.sh`** - 基本系統健康檢查，用於快速驗證

## 🔧 配置驗證系統

TrustMonitor 包含完整的配置驗證系統。

### 使用方法
```bash
# 驗證默認配置文件
bash tools/config/validate_config.sh

# 驗證特定配置文件
bash tools/config/validate_config.sh /path/to/custom.env

# 驗證特定部分
bash tools/config/validate_config.sh --system-only
bash tools/config/validate_config.sh --paths-only
bash tools/config/validate_config.sh --logging-only
```

### 驗證選項
- `--dht11-only` - 僅驗證 DHT11 針腳配置
- `--temp-only` - 僅驗證溫度閾值
- `--led-only` - 僅驗證 LED 針腳配置
- `--network-only` - 僅驗證網絡配置
- `--security-only` - 僅驗證安全配置
- `--system-only` - 僅驗證系統閾值
- `--paths-only` - 僅驗證路徑配置
- `--logging-only` - 僅驗證日誌配置
- `--watchdog-only` - 僅驗證看門狗配置
- `--sel-only` - 僅驗證 SEL 配置

## 🧪 測試框架

TrustMonitor 提供完整的測試覆蓋，確保系統可靠性。

### 運行測試
```bash
# 運行完整測試套件
bash tests/test_runner.sh

# 運行特定測試類型
bash tests/test_runner.sh unit
bash tests/test_runner.sh integration
bash tests/test_runner.sh security
```

### 測試覆蓋範圍
- **單元測試**: 組件功能測試
- **整合測試**: 組件協作測試
- **安全測試**: 安全功能測試
- **硬體測試**: 硬體整合測試

### 故障排除
```bash
# 檢查系統完整性
bash scripts/integrity_check.sh

# 如果 integrity check 失敗，更新 manifest
bash tools/user/gen_hash.sh generate
bash tools/user/sign_manifest.sh sign

# 重新運行測試
bash tests/test_runner.sh
```

## 📊 返回碼系統

使用標準化返回碼：
```bash
RC_OK=0              # 操作成功
RC_WARN=1            # 警告條件
RC_ERROR=2           # 錯誤條件
RC_INTEGRITY_FAILED=4    # 完整性驗證失敗
RC_SIGNATURE_FAILED=5    # 簽章驗證失敗
```

## 🔌 HAL 系統

硬體抽象層提供統一的硬體訪問介面。

### 關鍵檔案
- `hardware/hal_core.py` - 核心 HAL 系統
- `hardware/hal_interface.py` - 主要硬體介面
- `hardware/hal_sensors.py` - 感測器管理
- `hardware/hal_indicators.py` - LED 控制

### 配置
```bash
USE_HAL=true                         # 啟用 HAL (默認)
DHT11_PIN=17                         # 感測器針腳 (GPIO 17)
LED_RED_PIN=27                        # LED 針腳
LED_GREEN_PIN=22
LED_BLUE_PIN=5
```

## 🚀 快速工具參考

### 用戶工具
```bash
# 快速系統健康檢查
bash tools/dev/quick_test.sh

# 完整系統演示
bash tools/user/demo.sh

# 運行完整測試套件
bash tests/test_runner.sh

# 安全演示
bash tools/demo/security/attack.sh --list
bash tools/demo/security/attack.sh malicious_code

# 系統恢復
bash tools/demo/user/restore.sh --auto
```

### 開發者工具
```bash
# 配置驗證
bash tools/config/validate_config.sh

# 生成安全密鑰
bash tools/user/gen_keypair.sh generate

# 更新系統完整性
bash tools/user/gen_hash.sh generate
bash tools/user/sign_manifest.sh sign

# 驗證系統完整性
bash scripts/integrity_check.sh
```

---

*此文檔適合開發者參考，用戶請參閱用戶指南和安全指南。*
