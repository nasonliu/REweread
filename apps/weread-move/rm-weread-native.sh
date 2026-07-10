#!/bin/sh
set -eu

APP_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
KO_DIR="${KO_DIR:-/home/root/xovi/exthome/appload/koreader}"
LOG_DIR="${APP_DIR}/logs"
mkdir -p "${LOG_DIR}"

export LD_PRELOAD="${LD_PRELOAD:-/home/root/shims/qtfb-shim.so}"
export QTFB_SHIM_MODEL="${QTFB_SHIM_MODEL:-false}"
export QTFB_SHIM_INPUT_MODE="${QTFB_SHIM_INPUT_MODE:-NATIVE}"
export QTFB_SHIM_MODE="${QTFB_SHIM_MODE:-N_RGB565}"
export KO_DONT_GRAB_INPUT="${KO_DONT_GRAB_INPUT:-1}"
export KO_DONT_SET_DEPTH="${KO_DONT_SET_DEPTH:-1}"
export RM_WEREAD_APP_DIR="${APP_DIR}"

cd "${KO_DIR}"
exec ./luajit "${APP_DIR}/native_app.lua" >>"${LOG_DIR}/rm-weread-native.log" 2>&1
