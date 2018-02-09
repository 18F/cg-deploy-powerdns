#!/bin/bash

set -eux

sed -i "s/ENVIRONMENT/${ENVIRONMENT}/g" pdns-config/varsfiles/terraform.yml

spruce merge --prune terraform_outputs \
  pdns-config/varsfiles/${ENVIRONMENT}.yml \
  terraform-yaml/state.yml \
  > terraform-secrets/terraform.yml

count=0
echo "nameservers: |" > terraform-secrets/ns.yml
for nameserver in $(spruce json terraform-yaml/state.yml | jq -r ".terraform_outputs.${ENVIRONMENT}_dns_public_ips[]")
do
  count=$((count+1))
  echo "    ns${count} IN A ${nameserver}" >> terraform-secrets/ns.yml
done
