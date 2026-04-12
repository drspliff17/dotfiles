#!/usr/bin/env bash
cmus-remote -C status | while read -r key property; do
  case $key in
  tag | set)
    read -r subkey subValue <<<"$property"
    key="$subkey"
    property="$subValue"
    ;;
  esac

  echo "$key $property"

done
