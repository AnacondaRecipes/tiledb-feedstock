#!/bin/bash

args="${@##-Werror*}"
$NN_CC_ORIG $args
