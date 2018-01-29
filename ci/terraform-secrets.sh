#!/bin/bash

set -eux

spruce merge --prune terraform_outputs \
  pdns-config/varsfiles/terraform.yml \
  terraform-yaml/state.yml \
  > terraform-secrets/terraform.yml
