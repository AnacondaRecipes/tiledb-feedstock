setlocal EnableDelayedExpansion

REM Copy tiledb-patches to the source directory
xcopy /Y /S /I "%RECIPE_DIR%\tiledb-patches" "%SRC_DIR%"

REM Regenerate the capnp serialization files with the version installed in Conda.
REM This allows updating capnproto independently of upstream tiledb.
%PREFIX%\Library\bin\capnp compile -I %PREFIX%\Library\include -oc++:%SRC_DIR%\tiledb\sm\serialization %SRC_DIR%\tiledb\sm\serialization\tiledb-rest.capnp --src-prefix=%SRC_DIR%\tiledb\sm\serialization
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

mkdir "%SRC_DIR%"\build
pushd "%SRC_DIR%"\build

cmake -G Ninja %CMAKE_ARGS% ^
      -DCMAKE_INSTALL_PREFIX="%LIBRARY_PREFIX%" ^
      -DCMAKE_PREFIX_PATH="%LIBRARY_PREFIX%" ^
      -DCMAKE_BUILD_TYPE=Release ^
      -DTILEDB_CMAKE_IDE=ON ^
      -DTILEDB_WERROR=OFF ^
      -DTILEDB_TESTS=OFF ^
      -DTILEDB_S3=ON ^
      -DTILEDB_AZURE=ON ^
      -DTILEDB_WEBP=ON ^
      -DTILEDB_HDFS=OFF ^
      -DCOMPILER_SUPPORTS_AVX2=OFF ^
      -DTILEDB_SKIP_S3AWSSDK_DIR_LENGTH_CHECK=ON ^
      -DTILEDB_SERIALIZATION=ON ^
      -DTILEDB_DISABLE_AUTO_VCPKG=ON ^
      -DVCPKG_TARGET_TRIPLET=x64-windows ^
      -DVCPKG_CMAKE_CONFIGURE_OPTIONS=-DCMAKE_FIND_DEBUG_MODE=TRUE ^
      ..
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

cmake --build . -j %CPU_COUNT% --target install
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%
popd
