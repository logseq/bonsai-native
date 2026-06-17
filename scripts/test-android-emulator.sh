#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
android_home=${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}
adb="$android_home/platform-tools/adb"
emulator="$android_home/emulator/emulator"
avd_name=${BONSAI_ANDROID_AVD:-Medium_Phone_API_36.1}
apk="$repo_root/android/app/build/outputs/apk/debug/app-debug.apk"
screenshot=${BONSAI_ANDROID_SCREENSHOT:-/tmp/bonsai-native-counter.png}
before_xml=${BONSAI_ANDROID_BEFORE_XML:-/tmp/bonsai-native-counter-before.xml}
after_xml=${BONSAI_ANDROID_AFTER_XML:-/tmp/bonsai-native-counter-after.xml}

if [[ ! -x "$adb" ]]; then
  echo "Missing adb at $adb" >&2
  exit 1
fi

if [[ ! -x "$emulator" ]]; then
  echo "Missing emulator at $emulator" >&2
  exit 1
fi

if [[ ! -f "$apk" ]]; then
  echo "Missing APK at $apk. Run: cd android && ./gradlew :app:assembleDebug" >&2
  exit 1
fi

booted_device=$("$adb" devices | awk '$2 == "device" { print $1; exit }')
if [[ -z "$booted_device" ]]; then
  log_file=${BONSAI_ANDROID_EMULATOR_LOG:-/tmp/bonsai-native-emulator.log}
  "$emulator" "@$avd_name" -no-snapshot -wipe-data -gpu swiftshader_indirect -no-audio -no-boot-anim -no-window \
    > "$log_file" 2>&1 &
  emulator_pid=$!
  trap 'kill "$emulator_pid" 2>/dev/null || true' EXIT

  for _ in {1..60}; do
    booted_device=$("$adb" devices | awk '$2 == "device" { print $1; exit }')
    boot_completed=$("$adb" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)
    if [[ -n "$booted_device" && "$boot_completed" == "1" ]]; then
      break
    fi
    sleep 5
  done
else
  boot_completed=$("$adb" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)
fi

if [[ -z "$booted_device" || "$boot_completed" != "1" ]]; then
  echo "No booted emulator detected for $avd_name" >&2
  exit 1
fi

"$adb" install -r "$apk"
"$adb" shell am force-stop com.logseq.bonsaiandroid
"$adb" shell am start -W -n com.logseq.bonsaiandroid/.MainActivity >/dev/null
sleep 2
"$adb" shell uiautomator dump /sdcard/bonsai-native-before.xml >/dev/null
"$adb" pull /sdcard/bonsai-native-before.xml "$before_xml" >/dev/null
if ! grep -q 'text="Count: 0"' "$before_xml"; then
  echo "Counter did not render initial Count: 0 state" >&2
  exit 1
fi

"$adb" shell input tap 167 180
sleep 1
"$adb" shell uiautomator dump /sdcard/bonsai-native-after.xml >/dev/null
"$adb" pull /sdcard/bonsai-native-after.xml "$after_xml" >/dev/null
if ! grep -q 'text="Count: 1"' "$after_xml"; then
  echo "Counter did not update to Count: 1 after tapping Increment" >&2
  exit 1
fi

"$adb" exec-out screencap -p > "$screenshot"

echo "Installed $apk on $booted_device"
echo "Verified native Bonsai click dispatch: Count: 0 -> Count: 1"
echo "Captured $screenshot"
