#!/usr/bin/env bash

_validateOrientation() {
  case "$1" in
  left | right | top | bottom)
    return 0
    ;;
  *)
    return 1
    ;;
  esac
}
