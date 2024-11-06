setlocal EnableDelayedExpansion

REM Copy tiledb-patches to the source directory
xcopy /Y /S /I "%RECIPE_DIR%\tiledb-patches" "%SRC_DIR%"

mkdir "%SRC_DIR%"\build
pushd "%SRC_DIR%"\build

REM Ideally, we'd disable vcpkg as it's done in build.sh
REM but tiledb is using libmagic (aka darwin file command) on windows, with some patches that make it possible...

cmake -G Ninja %CMAKE_ARGS% ^
      -DCMAKE_INSTALL_PREFIX="%LIBRARY_PREFIX%" ^
      -DCMAKE_BUILD_TYPE=Release ^
      -DTILEDB_WERROR=OFF ^
      -DTILEDB_TESTS=OFF ^
      -DTILEDB_S3=OFF ^
      -DTILEDB_AZURE=OFF ^
      -DTILEDB_WEBP=OFF ^
      -DTILEDB_HDFS=OFF ^
      -DCOMPILER_SUPPORTS_AVX2=OFF ^
      -DTILEDB_SKIP_S3AWSSDK_DIR_LENGTH_CHECK=ON ^
      -DTILEDB_SERIALIZATION=ON ^
      -DCMAKE_PREFIX_PATH="%LIBRARY_PREFIX%" ^
      -DVCPKG_TARGET_TRIPLET=x64-windows ^
      -DVCPKG_CMAKE_CONFIGURE_OPTIONS=-DCMAKE_FIND_DEBUG_MODE=TRUE ^
      ..
if errorlevel 1 exit 1

cmake --build . -j %CPU_COUNT% --target install
if errorlevel 1 exit 1
popd
