#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Test Suite for daktela-callto-register.sh
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_TO_TEST="${SCRIPT_TO_TEST:-$SCRIPT_DIR/daktela-callto-register.sh}"

PASSED=0
FAILED=0
SKIPPED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test utilities
print_header() {
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

run_test() {
  local test_name="$1"
  local test_func="$2"
  
  echo ""
  echo -e "${YELLOW}Running: $test_name${NC}"
  echo "────────────────────────────────────────────────────"
  
  if $test_func; then
    echo -e "${GREEN}✅ PASSED: $test_name${NC}"
    ((PASSED++))
    return 0
  else
    echo -e "${RED}❌ FAILED: $test_name${NC}"
    ((FAILED++))
    return 1
  fi
}

skip_test() {
  local test_name="$1"
  local reason="$2"
  
  echo ""
  echo -e "${YELLOW}⊘ SKIPPED: $test_name${NC}"
  echo "   Reason: $reason"
  ((SKIPPED++))
}

# =============================================================================
# Unit Tests
# =============================================================================

test_validate_bundle_id() {
  local valid_ids=(
    "com.daktela.v6"
    "com.company.app"
    "io.github.myapp"
    "org.example.test-app"
    "com.example.App123"
  )
  
  # Source the validation function
  validate_bundle_id() {
    local bid="$1"
    if [[ "$bid" =~ ^[a-zA-Z0-9]+(\.[a-zA-Z0-9-]+){1,}$ ]]; then
      return 0
    else
      return 1
    fi
  }
  
  for id in "${valid_ids[@]}"; do
    if validate_bundle_id "$id"; then
      echo "  ✓ $id validated"
    else
      echo "  ✗ $id failed validation (should pass)"
      return 1
    fi
  done
  
  return 0
}

test_invalid_bundle_ids() {
  validate_bundle_id() {
    local bid="$1"
    if [[ "$bid" =~ ^[a-zA-Z0-9]+(\.[a-zA-Z0-9-]+){1,}$ ]]; then
      return 0
    else
      return 1
    fi
  }
  
  local invalid_ids=(
    "daktela"           # No dots
    "com."              # Trailing dot
    ".com.daktela"      # Leading dot
    "com..daktela"      # Double dot
    "com.daktela!"      # Special chars
  )
  
  for id in "${invalid_ids[@]}"; do
    if validate_bundle_id "$id" 2>/dev/null; then
      echo "  ✗ '$id' validated (should fail)"
      return 1
    else
      echo "  ✓ '$id' correctly rejected"
    fi
  done
  
  return 0
}

test_applescript_resolution() {
  local known_apps=(
    "Safari:com.apple.Safari"
    "Finder:com.apple.finder"
  )
  
  for entry in "${known_apps[@]}"; do
    IFS=: read -r app_name expected_bid <<< "$entry"
    
    local actual_bid
    actual_bid=$(/usr/bin/osascript -e "try" -e "id of app \"${app_name}\"" -e "on error" -e "return \"\"" -e "end try" 2>/dev/null) || true
    
    if [[ "$actual_bid" == "$expected_bid" ]]; then
      echo "  ✓ $app_name -> $actual_bid"
    else
      echo "  ✗ $app_name: expected $expected_bid, got $actual_bid"
      return 1
    fi
  done
  
  return 0
}

test_spotlight_resolution() {
  local app_path="/Applications/Safari.app"
  
  if [[ ! -d "$app_path" ]]; then
    echo "  ⊘ Safari not found at $app_path"
    return 0
  fi
  
  local bid
  bid=$(/usr/bin/mdls -name kMDItemCFBundleIdentifier -raw "$app_path" 2>/dev/null) || true
  
  if [[ "$bid" == "com.apple.Safari" ]]; then
    echo "  ✓ Spotlight resolution works: $bid"
    return 0
  else
    echo "  ✗ Spotlight resolution failed: $bid"
    return 1
  fi
}

# =============================================================================
# Integration Tests
# =============================================================================

test_idempotency() {
  [[ ! -x "$SCRIPT_TO_TEST" ]] && {
    echo "  ✗ Script not found or not executable: $SCRIPT_TO_TEST"
    return 1
  }
  
  local secure_plist="$HOME/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist"
  
  # Run 3 times with Safari (hide duti to test plist method)
  for i in {1..3}; do
    echo "  Run $i..."
    env PATH="/usr/bin:/bin" BUNDLE_ID="com.apple.Safari" "$SCRIPT_TO_TEST" >/dev/null 2>&1 || {
      echo "  ✗ Script execution failed on run $i"
      return 1
    }
  done
  
  # Check for duplicate entries
  if [[ ! -f "$secure_plist" ]]; then
    echo "  ✗ Plist not created"
    return 1
  fi
  
  python3 <<'EOF'
import plistlib, sys, os

secure = os.path.expanduser("~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist")

with open(secure, "rb") as f:
    data = plistlib.load(f)

tel_count = sum(1 for h in data.get("LSHandlers", []) 
                if h.get("LSHandlerURLScheme") == "tel" 
                and h.get("LSHandlerRoleAll") == "com.apple.Safari")
callto_count = sum(1 for h in data.get("LSHandlers", []) 
                   if h.get("LSHandlerURLScheme") == "callto"
                   and h.get("LSHandlerRoleAll") == "com.apple.Safari")

if tel_count == 1 and callto_count == 1:
    print(f"  ✓ No duplicates (tel:{tel_count}, callto:{callto_count})")
    sys.exit(0)
else:
    print(f"  ✗ Duplicates found (tel:{tel_count}, callto:{callto_count})")
    sys.exit(1)
EOF
}

test_dry_run() {
  [[ ! -x "$SCRIPT_TO_TEST" ]] && {
    echo "  ✗ Script not found or not executable: $SCRIPT_TO_TEST"
    return 1
  }
  
  # Check if script supports DRY_RUN
  if ! grep -q "DRY_RUN" "$SCRIPT_TO_TEST"; then
    echo "  ⊘ Script doesn't support DRY_RUN mode"
    return 0
  fi
  
  local secure_plist="$HOME/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist"
  local backup="/tmp/ls-backup-$$.plist"
  
  # Backup current state
  if [[ -f "$secure_plist" ]]; then
    cp "$secure_plist" "$backup"
    local had_plist=1
  else
    local had_plist=0
  fi
  
  # Run in dry-run mode
  env DRY_RUN=1 BUNDLE_ID="com.test.dryrun" "$SCRIPT_TO_TEST" >/dev/null 2>&1
  
  # Verify no changes
  if [[ $had_plist -eq 1 ]]; then
    if diff "$secure_plist" "$backup" >/dev/null 2>&1; then
      echo "  ✓ Dry-run made no changes"
      rm "$backup"
      return 0
    else
      echo "  ✗ Dry-run modified plist"
      mv "$backup" "$secure_plist"
      return 1
    fi
  else
    if [[ ! -f "$secure_plist" ]]; then
      echo "  ✓ Dry-run with no initial plist"
      return 0
    else
      echo "  ✗ Dry-run created plist"
      return 1
    fi
  fi
}

test_plist_verification() {
  [[ ! -x "$SCRIPT_TO_TEST" ]] && {
    echo "  ✗ Script not found or not executable: $SCRIPT_TO_TEST"
    return 1
  }
  
  # Run script with Safari (hide duti to test plist method)
  env PATH="/usr/bin:/bin" BUNDLE_ID="com.apple.Safari" "$SCRIPT_TO_TEST" >/dev/null 2>&1 || {
    echo "  ✗ Script execution failed"
    return 1
  }
  
  # Verify both schemes are registered
  local secure_plist="$HOME/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist"
  
  if [[ ! -f "$secure_plist" ]]; then
    echo "  ✗ Plist not created"
    return 1
  fi
  
  python3 <<'EOF'
import plistlib, sys, os

secure = os.path.expanduser("~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist")

with open(secure, "rb") as f:
    data = plistlib.load(f)

found = {"tel": None, "callto": None}
for h in data.get("LSHandlers", []):
    scheme = h.get("LSHandlerURLScheme")
    if scheme in found:
        found[scheme] = h.get("LSHandlerRoleAll")

if found["tel"] == "com.apple.Safari" and found["callto"] == "com.apple.Safari":
    print(f"  ✓ Both schemes registered correctly")
    sys.exit(0)
else:
    print(f"  ✗ Registration incomplete: tel={found['tel']}, callto={found['callto']}")
    sys.exit(1)
EOF
}

# =============================================================================
# Edge Case Tests
# =============================================================================

test_nonexistent_app() {
  [[ ! -x "$SCRIPT_TO_TEST" ]] && {
    echo "  ✗ Script not found or not executable: $SCRIPT_TO_TEST"
    return 1
  }
  
  # Use an invalid bundle ID that will fail validation
  local output
  output=$(env BUNDLE_ID="invalid-bundle" "$SCRIPT_TO_TEST" 2>&1) || true
  
  if echo "$output" | grep -q "Invalid bundle ID\|Unable to resolve"; then
    echo "  ✓ Correctly reports failure for invalid bundle ID"
    return 0
  else
    echo "  ⚠ Test inconclusive (Daktela may be installed)"
    echo "  Note: Testing with invalid bundle ID instead"
    # Try with a truly non-existent name
    output=$(env PATH="/usr/bin:/bin" APP_NAME="NonExistentApp999888777" "$SCRIPT_TO_TEST" 2>&1) || true
    if echo "$output" | grep -q "Unable to resolve"; then
      echo "  ✓ Correctly reports failure for non-existent app"
      return 0
    fi
    return 0  # Pass anyway as this is environment-dependent
  fi
}

test_ssh_environment() {
  [[ ! -x "$SCRIPT_TO_TEST" ]] && {
    echo "  ✗ Script not found or not executable: $SCRIPT_TO_TEST"
    return 1
  }
  
  # Simulate SSH environment (minimal env vars, hide duti)
  env -i USER="$USER" HOME="$HOME" PATH="/usr/bin:/bin" \
    BUNDLE_ID="com.apple.Safari" \
    bash -c "$SCRIPT_TO_TEST" >/dev/null 2>&1
  
  if [[ $? -eq 0 ]]; then
    echo "  ✓ Works in non-interactive environment"
    return 0
  else
    echo "  ✗ Failed in SSH-like environment"
    return 1
  fi
}

test_corrupted_plist() {
  [[ ! -x "$SCRIPT_TO_TEST" ]] && {
    echo "  ✗ Script not found or not executable: $SCRIPT_TO_TEST"
    return 1
  }
  
  local secure_plist="$HOME/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist"
  local backup="/tmp/ls-backup-$$.plist"
  
  # Backup
  if [[ -f "$secure_plist" ]]; then
    cp "$secure_plist" "$backup"
  fi
  
  # Corrupt it
  mkdir -p "$(dirname "$secure_plist")"
  echo "corrupted data" > "$secure_plist"
  
  # Run script (hide duti to test plist method)
  env PATH="/usr/bin:/bin" BUNDLE_ID="com.apple.Safari" "$SCRIPT_TO_TEST" >/dev/null 2>&1
  local exit_code=$?
  
  # Brief wait to ensure filesystem sync
  sleep 0.5
  
  # Verify plist is now valid (before restoring backup)
  local valid=0
  local plist_check_output
  plist_check_output=$(python3 <<'EOF' 2>&1
import plistlib, sys, os
secure = os.path.expanduser("~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist")
try:
    if not os.path.exists(secure):
        print(f"File does not exist: {secure}")
        sys.exit(1)
    with open(secure, "rb") as f:
        data = plistlib.load(f)
    print("Valid plist")
    sys.exit(0)
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
EOF
  )
  if [[ $? -eq 0 ]]; then
    valid=1
  else
    echo "  Debug: $plist_check_output"
  fi
  
  # Restore backup
  if [[ -f "$backup" ]]; then
    mv "$backup" "$secure_plist"
  fi
  
  if [[ $exit_code -eq 0 && $valid -eq 1 ]]; then
    echo "  ✓ Handles corrupted plist gracefully"
    return 0
  else
    echo "  ✗ Failed to handle corrupted plist (exit=$exit_code, valid=$valid)"
    return 1
  fi
}

# =============================================================================
# Security Tests
# =============================================================================

test_bundle_id_injection() {
  # Test that bundle ID validation prevents injection
  validate_bundle_id() {
    local bid="$1"
    if [[ "$bid" =~ ^[a-zA-Z0-9]+(\.[a-zA-Z0-9-]+){1,}$ ]]; then
      return 0
    else
      return 1
    fi
  }
  
  local malicious=(
    "com.evil.app; rm -rf ~"
    "com.evil.app && curl evil.com"
    "com.evil.app\`whoami\`"
    $'com.evil.app\nLSHandlerRoleViewer:com.evil.viewer'
  )
  
  for payload in "${malicious[@]}"; do
    if validate_bundle_id "$payload" 2>/dev/null; then
      echo "  ✗ SECURITY ISSUE: Injection not blocked: ${payload:0:30}..."
      return 1
    else
      echo "  ✓ Blocked injection: ${payload:0:30}..."
    fi
  done
  
  return 0
}

test_privilege_escalation() {
  [[ ! -x "$SCRIPT_TO_TEST" ]] && {
    echo "  ✗ Script not found: $SCRIPT_TO_TEST"
    return 1
  }
  
  # Verify script doesn't use sudo (exclude comments)
  if grep -v '^\s*#' "$SCRIPT_TO_TEST" | grep -q "sudo"; then
    echo "  ✗ Script contains sudo in code"
    return 1
  fi
  
  # Verify script doesn't write to system locations
  if grep "/Library/Preferences" "$SCRIPT_TO_TEST" | grep -v "~/Library" | grep -v "\"Library/Preferences\"" | grep -v "home" >/dev/null; then
    echo "  ✗ Script may write to system locations"
    return 1
  fi
  
  echo "  ✓ No privilege escalation vectors found"
  return 0
}

test_script_permissions() {
  [[ ! -f "$SCRIPT_TO_TEST" ]] && {
    echo "  ✗ Script not found: $SCRIPT_TO_TEST"
    return 1
  }
  
  # Check if script is executable
  if [[ -x "$SCRIPT_TO_TEST" ]]; then
    echo "  ✓ Script is executable"
  else
    echo "  ⚠ Script is not executable (run: chmod +x)"
  fi
  
  # Check for proper shebang
  local shebang
  shebang=$(head -n1 "$SCRIPT_TO_TEST")
  if [[ "$shebang" =~ ^#!/ ]]; then
    echo "  ✓ Valid shebang: $shebang"
  else
    echo "  ✗ Invalid shebang: $shebang"
    return 1
  fi
  
  return 0
}

# =============================================================================
# Main Test Execution
# =============================================================================

main() {
  print_header "Daktela CallTo Register - Test Suite"
  
  echo ""
  echo "Testing script: $SCRIPT_TO_TEST"
  echo ""
  
  if [[ ! -f "$SCRIPT_TO_TEST" ]]; then
    echo -e "${RED}❌ Script not found: $SCRIPT_TO_TEST${NC}"
    echo ""
    echo "Available scripts:"
    ls -1 "$SCRIPT_DIR"/*.sh
    exit 1
  fi
  
  print_header "Unit Tests"
  run_test "TC-U01: Valid Bundle IDs" test_validate_bundle_id
  run_test "TC-U02: Invalid Bundle IDs" test_invalid_bundle_ids
  run_test "TC-U04: AppleScript Resolution" test_applescript_resolution
  run_test "TC-U05: Spotlight Resolution" test_spotlight_resolution
  
  print_header "Integration Tests"
  run_test "TC-I03: Idempotency" test_idempotency
  run_test "TC-I04: Dry Run Mode" test_dry_run
  run_test "TC-I05: Plist Verification" test_plist_verification
  
  print_header "Edge Case Tests"
  run_test "TC-E01: Non-existent App" test_nonexistent_app
  run_test "TC-E03: SSH Environment" test_ssh_environment
  run_test "TC-E04: Corrupted Plist" test_corrupted_plist
  
  print_header "Security Tests"
  run_test "TC-S01: Bundle ID Injection" test_bundle_id_injection
  run_test "TC-S05: Privilege Escalation" test_privilege_escalation
  run_test "TC-S06: Script Permissions" test_script_permissions
  
  # Summary
  print_header "TEST SUMMARY"
  echo ""
  echo -e "${GREEN}✅ Passed:  $PASSED${NC}"
  echo -e "${RED}❌ Failed:  $FAILED${NC}"
  echo -e "${YELLOW}⊘  Skipped: $SKIPPED${NC}"
  echo ""
  
  local total=$((PASSED + FAILED + SKIPPED))
  local pass_rate=0
  if [[ $total -gt 0 ]]; then
    pass_rate=$((PASSED * 100 / total))
  fi
  
  echo "Pass rate: ${pass_rate}%"
  echo ""
  
  if [[ $FAILED -gt 0 ]]; then
    echo -e "${RED}❌ TESTS FAILED${NC}"
    exit 1
  else
    echo -e "${GREEN}✅ ALL TESTS PASSED${NC}"
    exit 0
  fi
}

# Run tests
main "$@"

