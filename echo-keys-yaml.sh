#!/bin/bash

set -eu

DOMAIN=$1

ZSK_FILE="$DOMAIN.zsk.private"
KSK_FILE="$DOMAIN.ksk.private"

IFS=$'\n'
echo "  - type: zsk"
echo "    active: active"
echo "    key: |"
for line in `cat $ZSK_FILE`; do
  echo "      ${line}"
done
echo ""
IFS=$' '

IFS=$'\n'
echo "  - type: ksk"
echo "    active: active"
echo "    key: |"
for line in `cat $KSK_FILE`; do
  echo "      ${line}"
done
echo ""
IFS=$' '
