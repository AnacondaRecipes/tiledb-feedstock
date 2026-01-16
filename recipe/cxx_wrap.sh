#!/bin/bash

# Filter out -fexperimental-library and -Werror* flags
args=()
for arg in "$@"; do
    case "$arg" in
        -Werror*|-fexperimental-library)
            # Skip these arguments, they cause errors
            ;;
        *)
            args+=("$arg")
            ;;
    esac
done
$NN_CXX_ORIG "${args[@]}"
