#!/bin/bash
set -e
set -x

adb install build/apk/output-signed.apk
adb shell "am start -n 'io.github.apptrash/.ui.MainActivity'"
