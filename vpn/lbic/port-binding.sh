#!/usr/bin/env bash
# this script binds TCP ports with SSH

PORT=${1:-8888}

ssh -L $PORT:localhost:$PORT -Nf lbic
