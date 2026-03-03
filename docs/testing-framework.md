# TrustMonitor Testing Framework

## 🎯 測試框架概述

TrustMonitor 測試框架提供完整的系統測試覆蓋，確保系統各組件的功能和安全性。

## 📊 測試覆蓋範圍

### 當前狀況 (v3.1.6-testing-framework)
```bash
總體測試: 54 個測試
通過: 52 個 (96%)
失敗: 2 個 (4%)

各套件狀況:
✅ test_integrity_verification.sh: 15/15 (100%)
✅ test_attack_detection.sh: 17/17 (100%)
⚠ test_recovery.sh: 20/22 (90%)
```

## 🔧 測試類型

### 🟢 單元測試
測試單個組件的功能：
- 日誌系統 (`test_logger.sh`)
- 返回碼處理 (`test_return_codes.sh`)
- 配置驗證 (`test_config_validation.sh`)
- 備份管理器 (`test_backup_manager.sh`)
- 路徑管理器 (`test_path_manager.sh`)

### 🟡 整合測試
測試組件間的協作：
- 啟動序列 (`test_boot_sequence.sh`)
- 完整性檢查 (`test_integrity_check.sh`)
- 監控腳本 (`test_monitoring_scripts.sh`)
- 硬體整合 (`test_hardware_integration.sh`)

### 🔴 安全測試
測試安全功能：
- 攻擊檢測 (`test_attack_detection.sh`)
- 系統恢復 (`test_recovery.sh`)
- 完整性驗證 (`test_integrity_verification.sh`)

## 🚀 使用指南

### 運行測試
```bash
# 運行所有測試
bash tests/test_runner.sh

# 運行特定類型
bash tests/test_runner.sh unit
bash tests/test_runner.sh integration
bash tests/test_runner.sh security
```

### 查看結果
```bash
# 查看最新測試報告
cat tests/results/test_report_*.txt

# 查看 JSON 結果
cat tests/results/test_results_*.json
```

## 📈 穩定性分析

### 完全穩定 (100% 可靠)
- `test_integrity_verification.sh`: 完整性驗證功能
- `test_attack_detection.sh`: 攻擊檢測功能

### 基本穩定 (90% 可靠)
- `test_recovery.sh`: 系統恢復功能
  - 穩定部分: 工具檢查、功能檢查、備份系統
  - 不穩定部分: 手動恢復功能

### 需要手動干預
- 手動恢復測試 (2/22 失敗)
- 系統狀態相關測試

## 🔧 故障排除

### 常見問題

#### 測試失敗
```bash
# 檢查系統狀態
bash scripts/integrity_check.sh

# 恢復系統
bash tools/user/restore.sh --auto

# 重新運行測試
bash tests/test_runner.sh
```

#### 系統狀態問題
測試框架依賴系統完整性狀態。如果系統被攻擊測試破壞，後續測試可能失敗。

解決方案：
1. 在測試前恢復系統
2. 運行穩定測試套件
3. 手動管理系統狀態

## 📋 未來改進

### 測試分類策略
計劃實施測試分類：
- 自動化測試 (100% 穩定)
- 手動驗證測試 (有限手動干預)

### 系統狀態管理
改進測試隔離和狀態管理：
- 測試前狀態檢查
- 自動狀態恢復
- 測試隔離環境

---

**TrustMonitor Testing Framework v3.1.6** 🚀
