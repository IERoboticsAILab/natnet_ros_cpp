#!/bin/bash

SDKFile="NatNetSDK.tar"

# Check if sdk was already downloaded
#if [  -d "deps/NatNetSDK" ] 
if [[ -d "deps/NatNetSDK/lib" ]] && [[ -d "deps/NatNetSDK/include" ]]; then
        echo "SDK already installed."
        exit 1
fi

# NatNet SDK 4.0 segfaults inside libNatNet.so on frames streamed by Motive 3.x
# (ClientCore::UnpackMarkerSetData / UnpackForcePlateData), so use 4.4.
# 4.2 and 4.3 need glibc 2.38 and do not load on Ubuntu 20.04; 4.4 does.
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
        echo "System architecture is AMD64."
        SDK_URL="https://s3.amazonaws.com/naturalpoint/software/NatNetSDKLinux/ubuntu/NatNet_SDK_4.4_ubuntu.tar"
elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm"* ]]; then
        echo "System architecture is ARM."
        SDK_URL="https://s3.amazonaws.com/naturalpoint/software/NatNetSDKLinux/ubuntu_arm/NatNet_SDK_4.4_ubuntu_ARM.tar"
else
        echo "Unsupported architecture: $ARCH"
        exit 1
fi

# Download sources.
wget ${SDK_URL} -O ${SDKFile}

# Uncompressing
tar xf ${SDKFile} -C deps/NatNetSDK/ && rm -rf ${SDKFile}
