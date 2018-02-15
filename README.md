## cloud.gov Bosh PowerDNS Deployment Manifests and Concourse pipeline

This repo contains the source for the Bosh deployment manifest and deployment pipeline for the cloud.gov PowerDNS deployment.

### Rationale
cloud.gov requires DNSSEC to be implemented on the root zone.  This requires using the [18F/pdns-release](https://github.com/18F/pdns-release) which has been modified to build with SQLite and enable DNSSEC.

### Architecture
This pipeline will deploy:
* Staging
  * 2 Primary private DNS servers
  * 2 Secondary public DNS servers
* Production
  * 2 Primary private DNS servers
  * 4 Secondary public DNS servers

The private servers are only able to be accessed by the secondary servers, and are firewalled off from other communications.  The primary instances additionally do not speak DNSSEC, this role is performed by the secondaries.

### Deployment
The pipeline under `ci/pipeline.yml` deploys to staging, generates a non-redacted diff against production configuration, and will manually allow a production push.  It will run smoke tests against production every 10 minutes, and send the notifications to Slack.

To customize this release for a deployment, [BOSH Operations Files](https://bosh.io/docs/cli-ops-files.html) are used to change the YAML to match the deployment.  These files replace variables given via [Bosh Variables](https://bosh.io/docs/cli-int.html) and `terraform-secrets.sh`.  To change the example record to the record of your choice:

* Generate DNSSEC keys using `generate-keys.sh DOMAIN`
* BOSH Lite Steps
  * Initialize bosh-lite `cloud-config` with `bosh-lite-cloud-config.yml`
  * Edit `opsfiles/bosh-lite.yml`
    * Replace `/instance_groups/name=pdns_private/jobs/name=pdns/properties/named_conf` with your domain name
    * Replace `/instance_groups/name=pdns_private/jobs/name=pdns/properties/pipe_conf` with your domain records
    * Replace `/instance_groups/name=pdns_public/jobs/name=pdns/properties/named_conf` with your domain name
  * Edit `varsfiles/bosh-lite.yml`
    * Replace `dnssec_zones` with the output of `echo-keys-yaml.sh DOMAIN`
  * Deploy to bosh lite: `bosh -e vbox -d pdns deploy ./deployment.yml -l ./varsfiles/bosh-lite.yml -o ./opsfiles/bosh-lite.yml`
* Staging / Production Steps
  * Edit `opsfiles/staging.yml` or `opsfiles/production.yml`
    * Replace `/instance_groups/name=pdns_private/jobs/name=pdns/properties/named_conf` with your domain name
    * Replace `/instance_groups/name=pdns_private/jobs/name=pdns/properties/pipe_conf` with your domain records
    * Replace `/instance_groups/name=pdns_public/jobs/name=pdns/properties/named_conf` with your domain name
  * Create a vars file for the environment
    * Replace `dnssec_zones` with the output of `echo-keys-yaml.sh DOMAIN`.  These keys should be kept *private* and not stored in Github.  This pipeline retrieves these from a encrypted store
  * Commit and Concourse CI will automatically deploy to staging

### Limitations
This pipeline and the forked powerdns bosh release currently only support a single domain with the following properties:
* `private_named_conf` - Specifies that the zone is a master and to retrieve zone records from `/var/vcap/jobs/pdns/etc/pipe.conf`
* `private_pipe_conf` - A list of zone records such as `subdomain IN A 10.0.0.1`
* `public_named_conf` - Used by secondary servers which specifies the zone as a slave, and to contact the primary servers for the source of truth

### Utility Commands
* `generate-keys.sh DOMAIN` - Generate KSK and ZSK public and private keys for use in DNSSEC
* `echo-keys-yaml.sh DOMAIN` - Echo keys in yaml format to paste in s3 zone configuration file

### Testing Records
Verification is done automatically via the Concourse pipeline.  To test DNSSEC locally:
* Retrieve root keys: `dig . DNSKEY @8.8.8.8 | grep -Ev '^($|;)' > root.keys`
* Check RRset: `dig +sigchase +dnssec +trusted-key=./root.keys example.com. A @YOUR_PUBLIC_DNS_IP | grep -P "^;; VERIFYING A RRset for example.com. with DNSKEY:\d+: success$"`
* Check DS: `dig +sigchase +dnssec +trusted-key=./root.keys example.com. A @8.8.8.8 | grep 'DNSSEC validation is ok: SUCCESS'`
