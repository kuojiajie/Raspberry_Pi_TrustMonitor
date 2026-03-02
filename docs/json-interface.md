# JSON Interface Standardization v3.1.2

## 📝 JSON Output Standardization

TrustMonitor v3.1.2 introduces standardized JSON output for all watchdog status reporting, enabling machine-readable interfaces and automated tool integration.

## 🎯 Standardization Goals

1. **Machine Readable**: JSON format for automated parsing
2. **Consistent Output**: Unified format across all watchdog scripts
3. **Tool Integration**: Enable monitoring and analysis tools
4. **Future Ready**: Prepare for REST API and CI/CD integration
5. **Backward Compatible**: Maintain existing functionality

## 📊 JSON Format Standard

### Structure
```json
{
  "status": "healthy|issues_detected|service_restart_failed|...",
  "last_check": "2026-03-02T13:52:16+08:00",
  "last_action": "Human-readable description"
}
```

### Status Values
- `"healthy"`: All systems normal
- `"issues_detected"`: Problems found during checks
- `"service_restart_failed"`: Service restart failed
- `"system_critical"`: Critical system issues
- `"cpu_temp_critical"`: CPU temperature too high
- `"cpu_temp_high"`: CPU temperature elevated
- `"hung_processes"`: Uninterruptible processes detected

### Timestamp Format
- **ISO 8601**: `YYYY-MM-DDTHH:MM:SS+TZ:ZZ`
- **UTC Local**: Uses system timezone
- **Consistent**: All timestamps use same format

## 🔧 Implementation Details

### Scripts Modified
1. **scripts/watchdog.sh**: Main watchdog with full monitoring
2. **scripts/watchdog_standalone.sh**: Lightweight standalone version

### Code Changes
```bash
# Before (key=value format)
{
    echo "status=$status"
    echo "last_check=$timestamp"
    echo "last_action=$details"
} > "$WATCHDOG_STATUS_FILE"

# After (JSON format)
printf '{"status": "%s", "last_check": "%s", "last_action": "%s"}\n' \
    "$status" "$timestamp" "$details" > "$WATCHDOG_STATUS_FILE"
```

## 🧪 Testing and Validation

### Automated Testing
```bash
# JSON format validation
cat data/runtime/watchdog/status | python3 -m json.tool

# Content verification
cat data/runtime/watchdog/status | jq .

# Consistency check
bash scripts/watchdog.sh check
bash scripts/watchdog_standalone.sh check
diff <(bash scripts/watchdog.sh status | tail -1) \
     <(bash scripts/watchdog_standalone.sh status)
```

### Test Results
- ✅ **JSON Valid**: Passes Python json.tool validation
- ✅ **Format Consistent**: Both scripts output identical format
- ✅ **Timestamp Correct**: ISO 8601 format with timezone
- ✅ **Status Values**: Proper status enumeration
- ✅ **Service Integration**: Works with systemd service

## 🚀 Benefits

### For Users
- **Better Monitoring**: JSON format easier to parse
- **Tool Integration**: Works with monitoring tools
- **Consistent Output**: Predictable format across scripts

### For Developers
- **API Ready**: JSON format for future REST API
- **CI/CD Ready**: Machine-readable for automation
- **Debugging**: Structured data easier to analyze

### For System Administrators
- **Log Analysis**: JSON easier to process with tools
- **Monitoring**: Integration with monitoring systems
- **Alerting**: Easier to create alerting rules

## 📁 File Locations

### Status Files
- `data/runtime/watchdog/status` - Main watchdog status
- Generated automatically during watchdog checks
- Updated on each monitoring cycle

### Configuration
- Uses existing watchdog configuration
- No additional configuration required
- Backward compatible with existing setups

## 🔍 Usage Examples

### Reading Status
```bash
# Direct read
cat data/runtime/watchdog/status

# Parsed with jq
cat data/runtime/watchdog/status | jq '.status'

# Parsed with Python
python3 -c "
import json
with open('data/runtime/watchdog/status') as f:
    data = json.load(f)
    print(f\"Status: {data['status']}\")
    print(f\"Last Check: {data['last_check']}\")
"
```

### Integration Examples
```bash
# Monitoring script
while true; do
    status=$(cat data/runtime/watchdog/status | jq -r '.status')
    if [[ "$status" != "healthy" ]]; then
        echo "Alert: System status is $status"
        # Send alert, log, etc.
    fi
    sleep 60
done

# CI/CD integration
if [[ "$(cat data/runtime/watchdog/status | jq -r '.status')" == "healthy" ]]; then
    echo "✅ System healthy - proceeding with deployment"
else
    echo "❌ System issues detected - aborting deployment"
    exit 1
fi
```

## 📋 Migration Notes

### From Old Format
```bash
# Old key=value parsing
while IFS='=' read -r key value; do
    case "$key" in
        "status") status="$value" ;;
        "last_check") timestamp="$value" ;;
        "last_action") action="$value" ;;
    esac
done < status_file

# New JSON parsing
status=$(jq -r '.status' status_file)
timestamp=$(jq -r '.last_check' status_file)
action=$(jq -r '.last_action' status_file)
```

### Backward Compatibility
- Old scripts continue to work
- Status file format changed but readable
- No breaking changes to existing functionality
- Gradual migration path available

---

*JSON Interface Standardization prepares TrustMonitor for modern monitoring and automation workflows.*
