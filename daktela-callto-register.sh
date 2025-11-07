#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# daktela-callto-register.sh
# =============================================================================
# Register Daktela as the default handler for tel: and callto: URL schemes
# on macOS by manipulating Launch Services preferences.
#
# Usage:
#   Default:         ./daktela-callto-register.sh
#   Custom app name: APP_NAME="Daktela desktop" ./daktela-callto-register.sh
#   Custom bundle:   BUNDLE_ID=com.daktela.v6 ./daktela-callto-register.sh
#   Dry run:         DRY_RUN=1 ./daktela-callto-register.sh
#
# Requirements:
#   - macOS 10.10+ (tested on 10.15+)
#   - Daktela app must be installed on the system
#   - User scope only (no sudo required)
#   - Python 3 (comes with macOS 10.15+)
#
# Exit codes:
#   0 - Success
#   1 - General error
#   2 - Unable to resolve bundle ID
#   3 - Invalid bundle ID format
# =============================================================================

# --- Config (overridable) ---
SCHEMES=("tel" "callto")
: "${APP_NAME:=Daktela desktop}"
ALT_APP_NAMES=("Daktela" "Daktela Desktop" "Daktela.app" "Daktela desktop.app")
: "${DRY_RUN:=0}"

# --- Logging ---
info() { printf "[*] %s\n" "$*" >&2; }
ok()   { printf "[+] %s\n" "$*" >&2; }
err()  { printf "[!] %s\n" "$*" >&2; }

# --- Validation ---
validate_bundle_id() {
  local bid="$1"
  # Basic validation: must match pattern like com.company.app or reverse DNS
  if [[ "$bid" =~ ^[a-zA-Z0-9]+(\.[a-zA-Z0-9-]+){1,}$ ]]; then
    return 0
  else
    err "Invalid bundle ID format: $bid"
    return 1
  fi
}

# --- Bundle ID Resolution ---
resolve_bundle_id() {
  # Priority 1: explicit env override
  if [[ -n "${BUNDLE_ID:-}" ]]; then
    info "Using explicit BUNDLE_ID: $BUNDLE_ID"
    if ! validate_bundle_id "$BUNDLE_ID"; then
      return 3
    fi
    echo "$BUNDLE_ID"
    return 0
  fi

  # Priority 2: AppleScript by name(s)
  local try_names=("$APP_NAME" "${ALT_APP_NAMES[@]}")
  for name in "${try_names[@]}"; do
    if [[ -n "$name" ]]; then
      local bid
      bid="$(/usr/bin/osascript -e "try" -e "id of app \"${name}\"" -e "on error" -e "return \"\"" -e "end try" 2>/dev/null)" || true
      if [[ -n "$bid" ]]; then
        info "Found bundle ID via osascript for \"${name}\": ${bid}"
        if validate_bundle_id "$bid"; then
          echo "$bid"
          return 0
        fi
      fi
    fi
  done

  # Priority 3: Spotlight—search by bundle ID pattern (fixed query)
  # Note: Wildcard pattern matching in mdfind requires specific syntax
  local cand
  cand="$(/usr/bin/mdfind 'kMDItemCFBundleIdentifier == "com.daktela.*"c' 2>/dev/null | head -n1)" || true
  if [[ -z "$cand" ]]; then
    # Try alternative query format
    cand="$(/usr/bin/mdfind 'kMDItemCFBundleIdentifier LIKE "com.daktela.*"' 2>/dev/null | head -n1)" || true
  fi
  if [[ -n "$cand" ]]; then
    local bid
    bid="$(/usr/bin/mdls -name kMDItemCFBundleIdentifier -raw "$cand" 2>/dev/null)" || true
    if [[ -n "$bid" && "$bid" != "(null)" ]]; then
      info "Found bundle ID via Spotlight pattern: ${bid} (${cand})"
      if validate_bundle_id "$bid"; then
        echo "$bid"
        return 0
      fi
    fi
  fi

  # Priority 4: Spotlight—search Applications folder directly
  local apps_dir="/Applications"
  local user_apps_dir="$HOME/Applications"
  for app_dir in "$apps_dir" "$user_apps_dir"; do
    if [[ -d "$app_dir" ]]; then
      for app_name in "Daktela.app" "Daktela Desktop.app" "Daktela desktop.app"; do
        local app_path="$app_dir/$app_name"
        if [[ -d "$app_path" ]]; then
          local bid
          bid="$(/usr/bin/mdls -name kMDItemCFBundleIdentifier -raw "$app_path" 2>/dev/null)" || true
          if [[ -n "$bid" && "$bid" != "(null)" ]]; then
            info "Found bundle ID via direct app search: ${bid} (${app_path})"
            if validate_bundle_id "$bid"; then
              echo "$bid"
              return 0
            fi
          fi
        fi
      done
    fi
  done

  # Priority 5: Alternative Spotlight—filesystem name search with proper syntax
  cand="$(/usr/bin/mdfind 'kMDItemKind == "Application"' 2>/dev/null | /usr/bin/grep -i "Daktela" | head -n1)" || true
  if [[ -n "$cand" ]]; then
    local bid
    bid="$(/usr/bin/mdls -name kMDItemCFBundleIdentifier -raw "$cand" 2>/dev/null)" || true
    if [[ -n "$bid" && "$bid" != "(null)" ]]; then
      info "Found bundle ID via application search: ${bid} (${cand})"
      if validate_bundle_id "$bid"; then
        echo "$bid"
        return 0
      fi
    fi
  fi

  return 1
}

# --- Main Logic ---
main() {
  local bid
  if ! bid="$(resolve_bundle_id)"; then
    err "Unable to resolve Daktela bundle ID."
    err ""
    err "⚠️  PREREQUISITE: Daktela app must be installed on this system."
    err ""
    err "Solutions:"
    err "  1. Install Daktela desktop app from https://www.daktela.com/"
    err "  2. Launch the Daktela app at least once (registers with macOS)"
    err "  3. If already installed, set BUNDLE_ID=com.your.bundle ./$(basename "$0")"
    err "  4. Or set APP_NAME=\"Your App Name\" ./$(basename "$0")"
    err ""
    err "To find your bundle ID:"
    err "  osascript -e 'id of app \"Daktela\"'"
    exit 2
  fi
  BUNDLE_ID="$bid"

  if [[ "$DRY_RUN" == "1" ]]; then
    info "DRY RUN MODE - no changes will be made"
    ok "Would register: ${SCHEMES[*]} -> $BUNDLE_ID"
    return 0
  fi

  # Use duti if available (preferred method)
  if command -v duti >/dev/null 2>&1; then
    info "Using duti at $(command -v duti)"
    for s in "${SCHEMES[@]}"; do
      duti -s "$BUNDLE_ID" "$s"
      ok "Set $s -> $BUNDLE_ID (duti)"
    done
  else
    info "duti not found; using plist edit fallback (user scope)."
    
    # Convert bash array to comma-separated string for Python
    local schemes_str
    schemes_str=$(IFS=,; echo "${SCHEMES[*]}")
    
    # Export for Python
    export BUNDLE_ID
    export SCHEMES_STR="$schemes_str"
    
    /usr/bin/python3 <<'PYEOF'
import os, plistlib, subprocess, sys

try:
    bundle_id = os.environ["BUNDLE_ID"]
    schemes = os.environ["SCHEMES_STR"].split(",")
    home = os.path.expanduser("~")
    ls_dir = os.path.join(home, "Library", "Preferences", "com.apple.LaunchServices")
    secure = os.path.join(ls_dir, "com.apple.launchservices.secure.plist")
    legacy = os.path.join(ls_dir, "com.apple.launchservices.plist")
    
    def write_plist(path):
        """Write handler entries to plist file"""
        os.makedirs(os.path.dirname(path), exist_ok=True)
        data = {}
        
        # Load existing plist
        if os.path.exists(path):
            try:
                with open(path, "rb") as f:
                    data = plistlib.load(f)
            except Exception as e:
                print(f"Warning: Could not read {path}: {e}", file=sys.stderr)
                data = {}
        
        # Remove old entries for our schemes
        handlers = [
            h for h in data.get("LSHandlers", [])
            if h.get("LSHandlerURLScheme") not in schemes
        ]
        
        # Add new entries
        for scheme in schemes:
            handlers.append({
                "LSHandlerURLScheme": scheme,
                "LSHandlerRoleAll": bundle_id
            })
        
        data["LSHandlers"] = handlers
        
        # Write back
        with open(path, "wb") as f:
            plistlib.dump(data, f)
        
        return len(schemes)
    
    # Write to both plists
    count = write_plist(secure)
    if os.path.exists(legacy):
        write_plist(legacy)
    
    # Refresh preferences cache
    # Use USER env var instead of getlogin() for better compatibility
    user = os.environ.get("USER")
    if not user:
        try:
            user = os.getlogin()
        except OSError:
            # Fallback for SSH/cron environments
            import pwd
            user = pwd.getpwuid(os.getuid()).pw_name
    
    subprocess.call(["/usr/bin/killall", "-u", user, "cfprefsd"], 
                   stderr=subprocess.DEVNULL)
    
    print(f"Modified {count} scheme(s) in Launch Services preferences", file=sys.stderr)
    sys.exit(0)
    
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    import traceback
    traceback.print_exc(file=sys.stderr)
    sys.exit(1)
PYEOF

    local py_exit=$?
    if [[ $py_exit -ne 0 ]]; then
      err "Python plist modification failed with exit code $py_exit"
      exit 1
    fi
    
    # Seed Launch Services database (non-destructive)
    LSREG="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
    if [[ -x "$LSREG" ]]; then
      info "Seeding Launch Services database..."
      "$LSREG" -seed 2>/dev/null || true
    fi
    
    for s in "${SCHEMES[@]}"; do 
      ok "Set $s -> $BUNDLE_ID (plist)"
    done
  fi

  # Verify mappings
  info "Verifying current mappings…"
  
  local schemes_str
  schemes_str=$(IFS=,; echo "${SCHEMES[*]}")
  export SCHEMES_STR="$schemes_str"
  
  /usr/bin/python3 <<'PYEOF'
import os, plistlib, sys

try:
    schemes = os.environ["SCHEMES_STR"].split(",")
    home = os.path.expanduser("~")
    secure = os.path.join(home, "Library", "Preferences", "com.apple.LaunchServices",
                         "com.apple.launchservices.secure.plist")
    legacy = os.path.join(home, "Library", "Preferences", "com.apple.LaunchServices",
                         "com.apple.launchservices.plist")
    
    def check_plist(path, name):
        if not os.path.exists(path):
            print(f" - {name}: not found")
            return False
        
        try:
            with open(path, "rb") as f:
                data = plistlib.load(f)
            
            found = False
            for handler in data.get("LSHandlers", []):
                scheme = handler.get("LSHandlerURLScheme")
                if scheme in schemes:
                    print(f" - {scheme} -> {handler.get('LSHandlerRoleAll')} ({name})")
                    found = True
            
            if not found:
                print(f" - {name}: no handlers found for {schemes}")
            
            return found
        
        except Exception as e:
            print(f" - {name}: error reading: {e}", file=sys.stderr)
            return False
    
    found_secure = check_plist(secure, "secure")
    found_legacy = check_plist(legacy, "legacy")
    
    if not found_secure and not found_legacy:
        print("WARNING: No handlers found in any plist", file=sys.stderr)
        sys.exit(1)

except Exception as e:
    print(f"Verification error: {e}", file=sys.stderr)
    sys.exit(1)
PYEOF

  local verify_exit=$?
  if [[ $verify_exit -ne 0 ]]; then
    err "Warning: Verification showed issues, but changes were applied."
    err "You may need to log out and log back in for changes to take effect."
  fi

  ok "Done. Changes may require logging out/restarting for full effect."
  info "Test with: open tel:123456789 or open callto:123456789"
}

# --- Pre-flight Check ---
check_daktela_installation() {
  # Check common installation paths
  local common_paths=(
    "/Applications/Daktela.app"
    "/Applications/Daktela Desktop.app"
    "/Applications/Daktela desktop.app"
    "$HOME/Applications/Daktela.app"
    "$HOME/Applications/Daktela Desktop.app"
    "$HOME/Applications/Daktela desktop.app"
  )
  
  local found=0
  for app_path in "${common_paths[@]}"; do
    if [[ -d "$app_path" ]]; then
      info "Found Daktela at: $app_path"
      found=1
      break
    fi
  done
  
  if [[ $found -eq 0 && -z "${BUNDLE_ID:-}" ]]; then
    err "⚠️  WARNING: Daktela app not found in common locations."
    err ""
    err "This script requires Daktela to be installed."
    err "If it's already installed, you can specify the bundle ID explicitly:"
    err "  BUNDLE_ID=com.daktela.v6 ./$(basename "$0")"
    err ""
    info "Continuing to search via Spotlight..."
  fi
}

# --- Dependency Check ---
check_dependencies() {
  if ! command -v python3 >/dev/null 2>&1; then
    err "Error: python3 is required but not found."
    err "On macOS 10.15+, Python 3 should be pre-installed."
    exit 1
  fi
  
  if ! command -v duti >/dev/null 2>&1; then
    info "Note: duti not installed. Using plist fallback method."
    info "Install duti for cleaner operation: brew install duti"
  fi
}

# --- Entry Point ---
check_dependencies
check_daktela_installation
main "$@"

