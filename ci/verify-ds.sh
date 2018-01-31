#!/bin/bash
set -eu
DNS_SERVERS=$(spruce json terraform-yaml/state.yml  | jq -r ".terraform_outputs.${ENVIRONMENT}_dns_public_ips[]")

for DNS_SERVER in ${DNS_SERVERS}; do
  dig . DNSKEY @8.8.8.8| grep -Ev '^($|;)' > root.keys

  for ZONE in ${ZONES}; do
    dig +dnssec +sigchase +trusted-keys=./root.keys ${ZONE}. A @${DNS_SERVER} | tail -n 2 | grep 'DNSSEC validation is ok: SUCCESS'
  done
done
