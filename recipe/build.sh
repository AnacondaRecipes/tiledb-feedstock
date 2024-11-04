#!/bin/sh
set -exo pipefail

# Copy tiledb-patches to the source directory to indicate to vcpkg
# which packages have been installed locally
cp -r "${RECIPE_DIR}/tiledb-patches/." "${SRC_DIR}"

# Use CC/CXX wrappers to disable -Werror
export NN_CXX_ORIG=$CXX
export NN_CC_ORIG=$CC
export CXX="${RECIPE_DIR}/cxx_wrap.sh"
export CC="${RECIPE_DIR}/cc_wrap.sh"

# For some weird reason, ar is not picked up on linux-aarch64
if [ $(uname -s) = "Linux" ] && [ ! -f "${BUILD_PREFIX}/bin/ar" ]; then
    ln -s "${BUILD}-ar" "${BUILD_PREFIX}/bin/ar"
fi

export CMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET}

if [[ $target_platform =~ osx-arm64 ]]; then
  CURL_LIBS_APPEND=`$PREFIX/bin/curl-config --libs`
  export LDFLAGS="${LDFLAGS} ${CURL_LIBS_APPEND}"
fi

if [[ $target_platform  == linux-64 ]]; then
  export LDFLAGS="${LDFLAGS} -Wl,--no-as-needed"
fi

if [[ $target_platform == linux-* ]]; then
  export LDFLAGS="${LDFLAGS} -lrt"
fi

# Set the vcpkg target triplet otherwise vcpkg can't find the
# compilers
if [[ $target_platform == osx-arm64  ]]; then
  export VCPKG_TARGET_TRIPLET="arm64-osx"
fi
if [[ $target_platform == osx-64  ]]; then
  export VCPKG_TARGET_TRIPLET="x64-osx"
fi
if [[ $target_platform == linux-64  ]]; then
  export VCPKG_TARGET_TRIPLET="x64-linux"
fi
if [[ $target_platform == linux-ppc64le  ]]; then
  export VCPKG_TARGET_TRIPLET="ppc64le-linux"
fi
if [[ $target_platform == linux-aarch64  ]]; then
  export VCPKG_TARGET_TRIPLET="arm64-linux"
fi

# For snowflake build only, disabling all the ports:
# Azure, S3 (AWS) and WebP
# As they don't require them.
# TODO: Azure and AWS are supported currently on main in previous version.
# We should follow up on this package to update it properly and upload to defaults.

# Changes required to build with ports:
# - TILEDB_AZURE, TILEDB_S3, and optionally TILEDB_WEBP set to ON (WebP currently not supported, as it wasn't back then)
# - TILEDB_DISABLE_AUTO_VCPKG=ON to disable vcpkg download of dependencies
# I've been able to find following required packages:
# - azure-core-cpp
# - azure-identity-cpp
# - azure-storage-blobs-cpp
# - aws-sdk-cpp >=1.11.300 # or >=.2xx, when they introduced generated/src/aws-cpp-sdk-s3/include/aws/s3/model/StorageClass.h with SNOW and EXPRESS_ONEZONE StorageClass values, best to take the commit from vcpkg
# - capnproto 1.0.1 # hard pinned in cpp code
# - libmagic
# Then for azure-storage-blobs-cpp we need azure-storage-core-cpp
# and for aws-sdk-cpp a chain of aws-c-* dependencies

mkdir build && cd build
cmake ${CMAKE_ARGS} \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DTILEDB_WERROR=OFF \
  -DTILEDB_TESTS=OFF \
  -DTILEDB_INSTALL_LIBDIR=lib \
  -DTILEDB_HDFS=ON \
  -DTILEDB_SANITIZER=OFF \
  -DCOMPILER_SUPPORTS_AVX2:BOOL=FALSE \
  -DTILEDB_S3=OFF \
  -DTILEDB_AZURE=OFF \
  -DTILEDB_SERIALIZATION=ON \
  -DTILEDB_WEBP=OFF \
  -DTILEDB_DISABLE_AUTO_VCPKG=ON \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET} \
  ..
make -j $(( ${CPU_COUNT} / 2 + 1 ))
make -C tiledb install
