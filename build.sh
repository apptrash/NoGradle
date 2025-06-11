#!/bin/bash
set -e
set -x

export TARGET_SDK=35
export JVM_TARGET=21
export MIN_API=29
export BUILD_TOOLS_VERSION="35.0.1"

export ANDROID_SDK_PATH="${HOME}/Library/Android/sdk"
export ANDROID_JAR_PATH="${ANDROID_SDK_PATH}/platforms/android-${TARGET_SDK}/android.jar"

export PACKAGE="com.example.saferecorder"

PACKAGE_PATH="$(echo ${PACKAGE} | tr '.' '/')"
export PACKAGE_PATH

export SRC_PATH="sources/${PACKAGE_PATH}"
export OUTPUT_BUILD_PATH="build"

export BUILD_TOOLS_PATH="${ANDROID_SDK_PATH}/build-tools/${BUILD_TOOLS_VERSION}"

mkdir -p ${OUTPUT_BUILD_PATH}/assets

# Compile assets
"${BUILD_TOOLS_PATH}"/aapt2 compile --dir sources/res -o ${OUTPUT_BUILD_PATH}/assets/

mkdir -p ${OUTPUT_BUILD_PATH}/apk
mkdir -p ${OUTPUT_BUILD_PATH}/generated

# Generate AndroidManifest.xml with injected package attribute
xmlstarlet ed \
  --insert '/manifest' \
  -t attr \
  -n 'package' \
  -v ${PACKAGE} \
  sources/AndroidManifest.xml > ${OUTPUT_BUILD_PATH}/generated/AndroidManifest.xml

# Generate APK file
"${BUILD_TOOLS_PATH}"/aapt2 link \
    --min-sdk-version "${MIN_API}" \
    --target-sdk-version ${TARGET_SDK} \
    --compile-sdk-version-code ${TARGET_SDK} \
    --java ${OUTPUT_BUILD_PATH}/generated \
    -I "${ANDROID_JAR_PATH}" \
    -o "${OUTPUT_BUILD_PATH}/apk/output.apk" \
    --manifest ${OUTPUT_BUILD_PATH}/generated/AndroidManifest.xml \
    -v \
    ${OUTPUT_BUILD_PATH}/assets/*.flat

mkdir -p ${OUTPUT_BUILD_PATH}/sources

# Compile .kt to .class + add generated .java files
kotlinc -verbose \
 -Werror \
 -Wextra \
 -language-version 2.0 \
 -jvm-target ${JVM_TARGET} \
 -d "${OUTPUT_BUILD_PATH}/sources/" \
 -cp "${ANDROID_JAR_PATH}" \
 "${SRC_PATH}"/*.kt \
 "${SRC_PATH}"/**/*.kt \
 ${OUTPUT_BUILD_PATH}/generated/"${PACKAGE_PATH}"/*.java

mkdir -p ${OUTPUT_BUILD_PATH}/dex

# Compile .class to .dex
"${BUILD_TOOLS_PATH}"/d8 --debug \
 --min-api ${MIN_API} \
 --output ${OUTPUT_BUILD_PATH}/dex \
 --lib "${ANDROID_JAR_PATH}" \
 "${OUTPUT_BUILD_PATH}"/"${SRC_PATH}"/**/*.class \
 "${OUTPUT_BUILD_PATH}"/"${SRC_PATH}"/*.class

# Add classes.dex to APK
zip -uj ${OUTPUT_BUILD_PATH}/apk/output.apk ${OUTPUT_BUILD_PATH}/dex/classes.dex

# Align APK file
"${BUILD_TOOLS_PATH}"/zipalign \
  -P 16 \
  -f \
  -v 4 \
  ${OUTPUT_BUILD_PATH}/apk/output.apk \
  ${OUTPUT_BUILD_PATH}/apk/output-aligned.apk

# Sign APK with debug-key.keystore
"${BUILD_TOOLS_PATH}"/apksigner sign \
    --in ${OUTPUT_BUILD_PATH}/apk/output-aligned.apk \
    --out ${OUTPUT_BUILD_PATH}/apk/output-signed.apk \
    --min-sdk-version $((MIN_SDK)) \
    --ks debug-key.keystore \
    --ks-pass pass:no_gradle \
    --key-pass pass:no_gradle

# Print information about APK
for infoToDump in "badging" "permissions" "resources" "strings"
do
    "${BUILD_TOOLS_PATH}"/aapt2 dump $infoToDump ${OUTPUT_BUILD_PATH}/apk/output-signed.apk 
done
