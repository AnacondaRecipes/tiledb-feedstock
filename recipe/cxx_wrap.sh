#!/bin/bash

args="${@##-Werror*}"
$NN_CXX_ORIG $args
