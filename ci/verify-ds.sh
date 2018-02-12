#!/bin/bash
set -eux

dig . DNSKEY @8.8.8.8 | grep -Ev '^($|;)' > root.keys
for ZONE in ${ZONES}; do
  dig +dnssec +sigchase +trusted-key=./root.keys "${ZONE}." A @8.8.8.8 | grep 'DNSSEC validation is ok: SUCCESS'
done
