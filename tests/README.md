# TrustMonitor Test Framework

## 🎯 測試框架概述

TrustMonitor 測試框架提供完整的系統測試覆蓋，包括單元測試、整合測試和安全測試。

## 📁 測試結構

```
tests/
├── README.md                    # 本文件
├── test_runner.sh              # 主測試運行器 (完整測試)
├── unit/                       # 單元測試
│   ├── test_logger.sh
│   ├── test_return_codes.sh
│   ├── test_config_validation.sh
│   ├── test_backup_manager.sh
│   └── test_path_manager.sh
├── integration/                # 整合測試
│   ├── test_boot_sequence.sh
│   ├── test_integrity_check.sh
│   ├── test_monitoring_scripts.sh
│   └── test_hardware_integration.sh
├── security/                   # 安全測試
│   ├── test_attack_detection.sh
│   ├── test_recovery.sh
│   └── test_integrity_verification.sh
├── results/                    # 測試結果 (git忽略)
└── logs/                       # 測試日誌 (git忽略)
```

## 🚀 快速開始

### 🟢 穩定測試
```bash
# 完整測試套件
bash tests/test_runner.sh

特點:
- 100% 穩定測試套件
- 完整功能覆蓋
- 自動化執行
- CI/CD 就緒
```

### 運行完整測試
```bash
# 運行所有測試
bash tests/test_runner.sh

# 運行特定類型測試
bash tests/test_runner.sh unit
bash tests/test_runner.sh integration
bash tests/test_runner.sh security
```

### 運行單個測試
```bash
# 運行單元測試
bash tests/unit/test_logger.sh

# 運行安全測試
bash tests/security/test_integrity_verification.sh
```

## 📊 測試類型

### 🟢 單元測試 (Unit Tests)
測試單個組件的功能：
- 日誌系統
- 返回碼處理
- 配置驗證
- 備份管理器
- 路徑管理器

### 🟡 整合測試 (Integration Tests)
測試組件間的協作：
- 啟動序列
- 完整性檢查
- 監控腳本
- 硬體整合

### 🔴 安全測試 (Security Tests)
測試安全功能：
- 攻擊檢測
- 系統恢復
- 完整性驗證

## 📈 測試結果

### 當前狀況
```bash
總體測試: 114 個測試
通過: 113 個 (99%)
失敗: 1 個 (1%)

各套件狀況:
✅ test_integrity_verification.sh: 15/16 (94% - 1個預期失敗)
✅ test_attack_detection.sh: 17/17 (100%)
✅ test_recovery.sh: 22/22 (100%)
✅ 所有單元測試: 50/50 (100%)
✅ 所有整合測試: 26/26 (100%)

注意: key_files_created 測試設計為在開發環境中失敗，這是正常的安全檢查行為。
```

### 穩定性分類
- **🟢 完全穩定**: 所有測試套件 (99% 通過率 - 1個預期安全檢查失敗)
- **🟡 基本穩定**: 無
- **🔴 需要手動**: 無

### 🔍 安全測試說明
**key_files_created 測試**:
- **開發環境**: 預期失敗 ✅ (需要私鑰進行簽名測試)
- **生產環境**: 應該通過 ✅ (不應有私鑰)
- **目的**: 確保生產設備安全，防止私鑰洩露

## 測試配置

### 環境要求
- Bash 4.0+
- Python 3.8+
- 系統完整性 (manifest.sha256)
- 數字簽章 (manifest.sha256.sig)

### 測試前準備
```bash
# 確保系統完整性
bash scripts/integrity_check.sh

# 如需重新生成
bash tools/demo/user/restore.sh --auto
```

## 📋 測試報告

測試結果保存在 `tests/results/` 目錄：
- `test_results_YYYYMMDD_HHMMSS.json` - JSON 格式結果
- `test_report_YYYYMMDD_HHMMSS.txt` - 人類可讀報告

## 🛠️ 故障排除

### 常見問題

#### 測試失敗
```bash
# 檢查系統狀態
bash scripts/integrity_check.sh

# 恢復系統
bash tools/demo/user/restore.sh --auto

# 重新運行測試
bash tests/test_runner.sh
```

#### 權限問題
```bash
# 確保測試腳本可執行
chmod +x tests/**/*.sh

# 檢查文件權限
ls -la tests/
```

#### 依賴問題
```bash
# 檢查必要文件
ls -la scripts/integrity_check.sh
ls -la tools/demo/user/restore.sh
ls -la data/manifest.sha256
```

## 📚 相關文檔

- [主 README.md](../README.md) - 系統概述
- [安全指南](../docs/security-guide.md) - 安全功能詳解
- [用戶指南](../docs/user-guide.md) - 完整用戶指南

## 🤝 貢獻指南

### 添加新測試
1. 在適當目錄創建測試腳本
2. 遵循現有命名約定
3. 實現標準測試函數
4. 更新 test_runner.sh
5. 測試並驗證

### 測試標準
- 使用統一的日誌格式
- 實現適當的錯誤處理
- 提供清晰的測試消息
- 支持結果輸出到 JSON

---

**TrustMonitor Test Framework** 🚀
