#!/bin/bash
set -eu

for DNS_SERVER in "${DNS_SERVERS}"; do
  dig . DNSKEY @{$DNS_SERVER}| grep -Ev '^($|;)' > root.keys

  for ZONE in "${ZONES}"; do
    dig +sigchase +dnssec +trusted-key=./root.keys ${ZONE}. A @${DNS_SERVER} | grep -P '^;; VERIFYING A RRset for example.com. with DNSKEY:\d+: success$'
    # valid=$(dig +dnssec +sigchase +trusted-keys=./root.keys ${ZONE}. A @${DNS_SERVER} | tail -n 2 | grep 'DNSSEC validation is ok: SUCCESS')
  done
done