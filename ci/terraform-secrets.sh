#!/bin/bash

set -eux

spruce merge --prune terraform_outputs \
  pdns-config/varsfiles/terraform.yml \
  terraform-yaml/state.yml \
  > terraform-secrets/terraform.yml

count=0
echo "nameservers: |" > terraform-secrets/ns.yml
for nameserver in $(bosh interpolate terraform-secrets/terraform.yml --path /master-ips | tr ";" "\n")
do
  count=$((count+1))
  echo "    ns${count} IN A ${nameserver}" >> terraform-secrets/ns.yml
done
