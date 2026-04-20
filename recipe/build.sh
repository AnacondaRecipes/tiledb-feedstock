#!/bin/sh
set -exo pipefail

# Copy tiledb-patches to the source directory to indicate to vcpkg
# which packages have been installed locally
cp -r "${RECIPE_DIR}/tiledb-patches/." "${SRC_DIR}"

# Disable -Werror
export CFLAGS="${CFLAGS//-Werror/}"
export CXXFLAGS="${CXXFLAGS//-Werror/}"

# For some weird reason, ar is not picked up on linux-aarch64
if [ $(uname -s) = "Linux" ] && [ ! -f "${BUILD_PREFIX}/bin/ar" ]; then
    ln -s "${BUILD}-ar" "${BUILD_PREFIX}/bin/ar"
fi

if [[ $target_platform == linux-* ]]; then
  export LDFLAGS="${LDFLAGS} -lrt"
fi

# Set the vcpkg target triplet otherwise vcpkg can't find the
# compilers
if [[ $target_platform == osx-arm64  ]]; then
  CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
  export PATH="$PREFIX/include/fmt:$PATH"
  # Explicit library that holds proper libc++, build process can't figure it out for some reason
  export LDFLAGS="${LDFLAGS} $(${PREFIX}/bin/curl-config --libs) -L$BUILD_PREFIX/lib"
  export VCPKG_TARGET_TRIPLET="arm64-osx"
fi
if [[ $target_platform == linux-64  ]]; then
  export VCPKG_TARGET_TRIPLET="x64-linux"
fi
if [[ $target_platform == linux-aarch64  ]]; then
  export VCPKG_TARGET_TRIPLET="arm64-linux"
fi

# Regenerate the capnp serialization files with the version installed in Conda.
# This allows updating capnproto independently of upstream tiledb.
if ! $PREFIX/bin/capnp compile -I $PREFIX/include -oc++:$SRC_DIR/tiledb/sm/serialization $SRC_DIR/tiledb/sm/serialization/tiledb-rest.capnp --src-prefix=$SRC_DIR/tiledb/sm/serialization
then
  exit 1
fi

mkdir build && cd build
cmake -G Ninja ${CMAKE_ARGS} \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DTILEDB_WERROR=OFF \
  -DTILEDB_TESTS=OFF \
  -DTILEDB_INSTALL_LIBDIR=lib \
  -DTILEDB_HDFS=OFF \
  -DTILEDB_SANITIZER=OFF \
  -DCOMPILER_SUPPORTS_AVX2:BOOL=FALSE \
  -DTILEDB_S3=ON \
  -DTILEDB_AZURE=ON \
  -DTILEDB_SERIALIZATION=ON \
  -DTILEDB_WEBP=ON \
  -DTILEDB_DISABLE_AUTO_VCPKG=ON \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET} \
  -DVCPKG_TARGET_TRIPLET=${VCPKG_TARGET_TRIPLET} \
  ..
cmake --build . -j $(( ${CPU_COUNT} / 2 + 1 )) --target install
