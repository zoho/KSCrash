# Merge Script

# 1
# Set bash script to exit immediately if any commands fail.
set -e
# If GENERATE_FAT_FRAMEWORK is set to "NO" script will generate xcframework
# If GENERATE_FAT_FRAMEWORK is set to "YES" script will FAT framework
GENERATE_FAT_FRAMEWORK="NO"
# 2
# Setup some constants for use later on.
PROJECT_NAME="KSCrash-Mac"
FRAMEWORK_NAME="KSCrash"
SCHEME="KSCrash"


# 3
# If remnants from a previous build exist, delete them.

if [ -d "${SRCROOT}/build" ]; then
rm -rf "${SRCROOT}/build"
fi

if [ "$GENERATE_FAT_FRAMEWORK" == "YES" ]; then


echo "==========================="
echo " "
echo "Starting Build of FAT Framework"
echo " "
echo "==========================="


UNIVERSAL_OUTPUTFOLDER=${SRCROOT}/build/${CONFIGURATION}-universal
OUTPUT_DIR=${SRCROOT}/build


# make sure the output directory exists
mkdir -p "${OUTPUT_DIR}"


# If remains from a previous build exist,delete them.
if [ -d "${OUTPUT_DIR}" ]; then
rm -rf "${OUTPUT_DIR}"
fi

# Build the framework for device and for simulator.
echo "Building for device"
xcodebuild -project "${PROJECT_NAME}.xcodeproj" -scheme "${SCHEME}" -configuration Release -arch arm64 -arch armv7 -arch armv7s only_active_arch=no defines_module=yes -sdk "iphoneos" -derivedDataPath "${OUTPUT_DIR}"
echo "Building for Simulator"
xcodebuild -project "${PROJECT_NAME}.xcodeproj" -scheme "${SCHEME}" -configuration Release -arch x86_64 -arch i386 only_active_arch=no defines_module=yes -sdk "iphonesimulator" -derivedDataPath "${OUTPUT_DIR}"
# Remove .framework file if exists from previous run.
if [ -d "${OUTPUT_DIR}/${FRAMEWORK_NAME}.framework" ]; then
rm -rf "${OUTPUT_DIR}/${FRAMEWORK_NAME}.framework"
fi
# Copy the device version of framework.
cp -r "${OUTPUT_DIR}/Build/Products/Release-iphoneos/${FRAMEWORK_NAME}.framework" "${OUTPUT_DIR}/${FRAMEWORK_NAME}.framework"
# Merging the device and simulator frameworks' executables with 
# lipo.
lipo -create -output "${OUTPUT_DIR}/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}" "${OUTPUT_DIR}/Build/Products/Release-iphoneos/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}" "${OUTPUT_DIR}/Build/Products/Release-iphonesimulator/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}"
# Copy Swift module mappings for simulator into the framework. 
cp -r "${OUTPUT_DIR}/Build/Products/Release-iphonesimulator/${FRAMEWORK_NAME}.framework/Modules/${FRAMEWORK_NAME}.swiftmodule/" "${OUTPUT_DIR}/${FRAMEWORK_NAME}.framework/Modules/${FRAMEWORK_NAME}.swiftmodule"
cp -r "${OUTPUT_DIR}/Build/Products/Release-iphoneos/${FRAMEWORK_NAME}.framework/Modules/${FRAMEWORK_NAME}.swiftmodule/" "${OUTPUT_DIR}/${FRAMEWORK_NAME}.framework/Modules/${FRAMEWORK_NAME}.swiftmodule"

# Create new combined simulator and device swift header file.
COMBINED_PATH="${BUILD_DIR}/iOS + iOS Simulator/${PROJECT_NAME}-Swift.h"
mkdir -p "${BUILD_DIR}/iOS + iOS Simulator/"
touch "${COMBINED_PATH}"
echo "#ifndef TARGET_OS_SIMULATOR\n#include <TargetConditionals.h>\n#endif\n#if TARGET_OS_SIMULATOR" >> "${COMBINED_PATH}"
cat "${OUTPUT_DIR}/Build/Products/Release-iphonesimulator/${FRAMEWORK_NAME}.framework/Headers/${FRAMEWORK_NAME}-Swift.h" >> "${COMBINED_PATH}"
echo "#else" >> "${COMBINED_PATH}"
echo "//Start of iphoneos" >> "${COMBINED_PATH}"
cat "${OUTPUT_DIR}/Build/Products/Release-iphoneos/${FRAMEWORK_NAME}.framework/Headers/${FRAMEWORK_NAME}-Swift.h" >> "${COMBINED_PATH}"
echo "#endif" >> "${COMBINED_PATH}"
# Overwrite generated -Swift.h file with combined -Swift.h file 
cat "$COMBINED_PATH" > "${OUTPUT_DIR}/${FRAMEWORK_NAME}.framework/Headers/${FRAMEWORK_NAME}-Swift.h"
#Optional Step to copy the framework to root folder
#cp -r "${OUTPUT_DIR}/${FRAMEWORK_NAME}.framework" "${SRCROOT}"


fi 


#  XCFramework Build Script
#  Created by Rishabh Raghunath on 28/04/20.
#  Copyright © 2019 Rishabh Raghunath. All rights reserved.


if [ "$GENERATE_FAT_FRAMEWORK" == "NO" ]; then

echo "==========================="
echo " "
echo "Starting Build of XCframework"
echo " "
echo "==========================="

if [ -d "archive" ]; then
rm -rf "archive"
fi

if [ -d "output" ]; then
rm -rf "output"
fi

# xcodebuild -project "${PROJECT_NAME}.xcodeproj" -scheme "${SCHEME}" -configuration Release -sdk macosx CONFIGURATION_BUILD_DIR=. clean build

xcodebuild -project "${PROJECT_NAME}.xcodeproj" archive -scheme "${SCHEME}" -destination="platform=macOS" -archivePath archive/osx.xcarchive -sdk macosx SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES

xcodebuild -create-xcframework -framework "Archive/osx.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" -output  "../output/${FRAMEWORK_NAME}.xcframework"

# Append Mobilisten-Swift.h contents generated for i368, x86_64 architecture to end of Mobilisten-Swift file generated for simulator
#cat output/Mobilisten.xcframework/ios-x86_64_i386-simulator/Mobilisten.framework/Headers/Mobilisten-Swift.h >> output/Mobilisten.xcframework/ios-armv7_arm64/Mobilisten.framework/Headers/Mobilisten-Swift.h

fi

