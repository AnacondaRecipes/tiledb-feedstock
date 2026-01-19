#!/bin/bash
args=()
for arg in "$@"; do
    case "$arg" in
        -Werror*|-fexperimental-library)
            # These arguments provoke errors
            ;;
        *)
            args+=("$arg")
            ;;
    esac
done
$NN_CC_ORIG "${args[@]}"