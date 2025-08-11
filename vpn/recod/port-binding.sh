#!/usr/bin/env bash
# this script binds TCP ports with SSH

DL=${1:-21}
GPU=${2:-0}
PORT=50$DL$GPU

ssh -L $PORT:localhost:$PORT -Nf dl-$DL
