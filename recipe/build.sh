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
  -DTILEDB_S3=ON \
  -DTILEDB_AZURE=ON \
  -DTILEDB_SERIALIZATION=ON \
  -DTILEDB_WEBP=ON \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET} \
  ..
make -j $(( ${CPU_COUNT} / 2 + 1 ))
make -C tiledb install
