#!/bin/bash
set -eux

DNS_SERVERS=$(spruce json terraform-yaml/state.yml | jq -r ".terraform_outputs.${ENVIRONMENT}_dns_public_ips[]")

dig . DNSKEY @8.8.8.8 | grep -Ev '^($|;)' > root.keys
for DNS_SERVER in ${DNS_SERVERS}; do
  for ZONE in ${ZONES}; do
    dig +dnssec +sigchase +trusted-key=./root.keys "${ZONE}." A "@${DNS_SERVER}" \
      | grep 'DNSSEC validation is ok: SUCCESS'
  done
done
