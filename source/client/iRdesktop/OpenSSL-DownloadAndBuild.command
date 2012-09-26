#!/bin/sh

# Copyright (c) 2011 Thinstuff s.r.o
# License: GPL Version 2
# This script will download and build openssl for iPhone (armv6) and i386

OPENSSLVERSION="1.0.0d"
MD5SUM="40b6ea380cc8a5bf9734c2f8bf7e701e"
SDKVERSION="4.3"

BDIR=`dirname "$0"`
cd "$BDIR"

CS=`md5 -q "openssl-$OPENSSLVERSION.tar.gz" 2>/dev/null`
if [ ! "$CS" = "$MD5SUM" ]; then
    echo "Downloading OpenSSL Version $OPENSSLVERSION ..."
    rm -f "openssl-$OPENSSLVERSION.tar.gz"
    curl -o "openssl-$OPENSSLVERSION.tar.gz" http://www.openssl.org/source/openssl-$OPENSSLVERSION.tar.gz

    CS=`md5 -q "openssl-$OPENSSLVERSION.tar.gz" 2>/dev/null`
    if [ ! "$CS" = "$MD5SUM" ]; then
	echo "Download failed or invalid checksum. Have a nice day."
	exit 1
    fi
fi

rm -rf openssltmp
mkdir openssltmp
cd openssltmp

echo "Unpacking OpenSSL ..."
tar xfz "../openssl-$OPENSSLVERSION.tar.gz"
if [ ! $? = 0 ]; then
    echo "Unpacking failed."
    exit 1
fi
echo

cd "openssl-$OPENSSLVERSION"
mkdir -p ../../openssl
rm -f ../../openssl/*.h

echo "Copying header files ..."
cp include/openssl/*.h ../../openssl/
echo

echo "Configuring openssl. Please wait ..."
./config no-shared no-asm no-krb5 no-gost zlib >BuildLog-config.txt 2>&1
if [ ! $? = 0 ]; then
    echo "config failed."
    exit 1
fi
echo

echo "Building i386 version (for simulator). Please wait ..."
CC="/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/bin/gcc"
CFLAGS="-D_DARWIN_C_SOURCE -UOPENSSL_BN_ASM_PART_WORDS -arch i386 -isysroot /Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator${SDKVERSION}.sdk/"
LDFLAGS="-arch i386 -dynamiclib"
make CC="${CC}" CFLAG="${CFLAGS}" SHARED_LDFLAGS="${LDFLAGS}" >BuildLog-i386.txt 2>&1
echo "Done. Build log saved in BuildLog-i386.txt"
cp libcrypto.a ../../openssl/libcrypto_i386.a
cp libssl.a ../../openssl/libssl_i386.a
make clean >/dev/null 2>&1
echo

echo "Building armv6 version (for iPhone). Please wait ..."
CC="/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/gcc"
CFLAGS="-D_DARWIN_C_SOURCE -UOPENSSL_BN_ASM_PART_WORDS -arch armv6 -isysroot /Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS${SDKVERSION}.sdk/"
LDFLAGS="-arch armv6 -dynamiclib"
make CC="${CC}" CFLAG="${CFLAGS}" SHARED_LDFLAGS="${LDFLAGS}" >BuildLog-armv6.txt 2>&1
echo "Done. Build log saved in BuildLog-armv6.txt"
cp libcrypto.a ../../openssl/libcrypto_armv6.a
cp libssl.a ../../openssl/libssl_armv6.a
make clean >/dev/null 2>&1
echo

echo "Building armv7 version (for iPhone). Please wait ..."
CC="/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/gcc"
CFLAGS="-D_DARWIN_C_SOURCE -UOPENSSL_BN_ASM_PART_WORDS -arch armv7 -isysroot /Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS${SDKVERSION}.sdk/"
LDFLAGS="-arch armv7 -dynamiclib"
make CC="${CC}" CFLAG="${CFLAGS}" SHARED_LDFLAGS="${LDFLAGS}" >BuildLog-armv7.txt 2>&1
echo "Done. Build log saved in BuildLog-armv6.txt"
cp libcrypto.a ../../openssl/libcrypto_armv7.a
cp libssl.a ../../openssl/libssl_armv7.a
make clean >/dev/null 2>&1
echo

echo "Finished. Please verify the contens of the openssl folder in your main project folder"

