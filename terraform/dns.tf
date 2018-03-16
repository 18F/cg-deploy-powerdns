variable "powerdns_server_url" {}
variable "powerdns_api_key" {}

terraform {
  backend "s3" {}
}

provider "powerdns" {
  server_url = "${var.powerdns_server_url}"
  api_key = "${var.powerdns_api_key}"
}

resource "powerdns_zone" "sandbox_gov" {
  lifecycle {
    prevent_destroy = true
  }

  name = "sandbox.gov."
  kind = "Native"
  nameservers = [
    "ns1.sandbox.gov.",
    "ns2.sandbox.gov.",
    "ns3.sandbox.gov.",
    "ns4.sandbox.gov."
  ]
}

resource "powerdns_record" "dmarc" {
  zone = "${powerdns_zone.sandbox_gov.name}"
  name = "_dmarc.${powerdns_zone.sandbox_gov.name}"
  type = "TXT"
  ttl = 3600
  records = ["\"v=DMARC1; p=none; pct=10; fo=1; ri=86400; rua=mailto:dmarcreports@gsa.gov,mailto:reports@dmarc.cyber.dhs.gov; ruf=mailto:dmarcfailures@gsa.gov\""]
}
