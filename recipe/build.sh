#!/bin/sh
set -exo pipefail

declare -a CMAKE_PLATFORM_FLAGS
if [[ ${target_platform} == osx-64 ]]; then
  CMAKE_PLATFORM_FLAGS+=(-DCMAKE_OSX_SYSROOT="${CONDA_BUILD_SYSROOT}")
  CMAKE_PLATFORM_FLAGS+=(-DCMAKE_OSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET}")
fi

if [[ $target_platform =~ osx-arm64 ]]; then
  CURL_LIBS_APPEND=`$PREFIX/bin/curl-config --libs`
  export LDFLAGS="${LDFLAGS} ${CURL_LIBS_APPEND}"
fi

export CFLAGS="${CFLAGS} -Wno-maybe-uninitialized"
export CXXFLAGS="${CXXFLAGS} -Wno-maybe-uninitialized"

mkdir build && cd build

if [[ $target_platform =~ linux-aarch64 ]]; then
  # For aarch64, skip the build for Azure (it fails).
  cmake ${CMAKE_ARGS} \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_PREFIX_PATH=${PREFIX} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_FLAGS="$CMAKE_CXX_FLAGS -Wno-error" \
    -DTILEDB_WERROR=OFF \
    -DTILEDB_TESTS=OFF \
    -DTILEDB_INSTALL_LIBDIR=lib \
    -DTILEDB_HDFS=ON \
    -DSANITIZER="OFF;-DCOMPILER_SUPPORTS_AVX2:BOOL=FALSE" \
    -DTILEDB_S3=ON \
    -DTILEDB_SERIALIZATION=ON \
    -DTILEDB_LOG_OUTPUT_ON_FAILURE=ON \
    "${CMAKE_PLATFORM_FLAGS[@]}" \
    ..
else
  cmake ${CMAKE_ARGS} \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_PREFIX_PATH=${PREFIX} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_FLAGS="$CMAKE_CXX_FLAGS -Wno-error" \
    -DTILEDB_WERROR=OFF \
    -DTILEDB_TESTS=OFF \
    -DTILEDB_INSTALL_LIBDIR=lib \
    -DTILEDB_HDFS=ON \
    -DSANITIZER="OFF;-DCOMPILER_SUPPORTS_AVX2:BOOL=FALSE" \
    -DTILEDB_S3=ON \
    -DTILEDB_SERIALIZATION=ON \
    -DTILEDB_LOG_OUTPUT_ON_FAILURE=ON \
    -DTILEDB_AZURE=ON \
    "${CMAKE_PLATFORM_FLAGS[@]}" \
    ..
fi

make -j ${CPU_COUNT}
make -C tiledb install
