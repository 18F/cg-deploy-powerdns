#!/bin/bash
set -eux

DNS_SERVERS=$(spruce json terraform-yaml/state.yml | jq -r ".terraform_outputs.${ENVIRONMENT}_dns_public_ips[]")

dig . DNSKEY @8.8.8.8 | grep -Ev '^($|;)' > root.keys
for ZONE in ${ZONES}; do
  dig +dnssec +sigchase +trusted-key=./root.keys "${ZONE}." A @8.8.8.8 | grep 'DNSSEC validation is ok: SUCCESS'
done
