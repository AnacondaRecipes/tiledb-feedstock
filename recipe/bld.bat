setlocal EnableDelayedExpansion

REM Copy tiledb-patches to the source directory
xcopy /Y /S /I "%RECIPE_DIR%\tiledb-patches" "%SRC_DIR%"

REM Regenerate the capnp serialization files with the version installed in Conda.
REM This allows updating capnproto independently of upstream tiledb.
%PREFIX%\Library\bin\capnp compile -I %PREFIX%\Library\include -oc++:%SRC_DIR%\tiledb\sm\serialization %SRC_DIR%\tiledb\sm\serialization\tiledb-rest.capnp --src-prefix=%SRC_DIR%\tiledb\sm\serialization
if %ERRORLEVEL% neq 0 (
    echo "capnp compile FAILED with errorlevel %ERRORLEVEL%"
    exit /b %ERRORLEVEL%
)

mkdir "%SRC_DIR%"\build
pushd "%SRC_DIR%"\build

echo "===== [lz4-diag] searching source tree for lz4 handling ====="
findstr /s /i /m "lz4" "%SRC_DIR%\cmake\*.cmake" "%SRC_DIR%\cmake\Modules\*.cmake" "%SRC_DIR%\cmake\helpers\*.cmake" 2>nul
echo "===== [lz4-diag] printing tiledb/CMakeLists.txt around line 725 ====="
powershell -Command "Get-Content '%SRC_DIR%\tiledb\CMakeLists.txt' | Select-Object -Skip 700 -First 50"
echo "===== [lz4-diag] printing cmake/helpers/CheckDependentLibraries.cmake if present ====="
findstr /i "lz4" "%SRC_DIR%\cmake\helpers\CheckDependentLibraries.cmake" 2>nul
echo "===== [lz4-diag] done ====="

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

echo "cmake configure exited with errorlevel %ERRORLEVEL%"
if %ERRORLEVEL% neq 0 (
    echo "cmake configure FAILED - see above for CMake output"
    popd
    exit /b %ERRORLEVEL%
)

echo "Building with CPU_COUNT=%CPU_COUNT%"
cmake --build . -v -j %CPU_COUNT% --target install
echo "cmake --build exited with errorlevel %ERRORLEVEL%"
if %ERRORLEVEL% neq 0 (
    popd
    exit /b %ERRORLEVEL%
)
popd