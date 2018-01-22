#!/bin/bash

set -eu

DOMAIN=$1

##  Must have either:
#     Linux - apt-get install dnssec-tools haveged
#     OSX   - brew install jdnssec-tools

ZSK_KEYGEN_CMD="dnssec-keygen"
KSK_KEYGEN_CMD="dnssec-keygen -f KSK"
if hash jdnssec-keygen 2>/dev/null; then
  ZSK_KEYGEN_CMD="jdnssec-keygen"
  KSK_KEYGEN_CMD="jdnssec-keygen -k"
fi

# Generate ZSK
ZSK_NAME=$($ZSK_KEYGEN_CMD -a NSEC3RSASHA1 -b 2048 -n ZONE "$DOMAIN")
mv "$ZSK_NAME.key" "$DOMAIN.zsk.public"
mv "$ZSK_NAME.private" "$DOMAIN.zsk.private"

# Generate KSK
KSK_NAME=$($KSK_KEYGEN_CMD -a NSEC3RSASHA1 -b 4096 -n ZONE "$DOMAIN")
mv "$KSK_NAME.key" "$DOMAIN.ksk.public"
mv "$KSK_NAME.private" "$DOMAIN.ksk.private"


