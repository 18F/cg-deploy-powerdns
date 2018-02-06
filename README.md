## cloud.gov Bosh PowerDNS Deployment Manifests and Concourse pipeline

This repo contains the source for the Bosh deployment manifest and deployment pipeline for the cloud.gov PowerDNS deployment.

### Utilities
* `generate-keys.sh DOMAIN` - Generate KSK and ZSK public and private keys for use in DNSSEC
* `echo-keys-yaml.sh DOMAIN` - Echo keys in yaml format to paste in s3 zone configuration file
