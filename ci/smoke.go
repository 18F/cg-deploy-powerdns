package main

import (
	"fmt"
	"log"
	"net"
	"os"
	"strings"

	"github.com/miekg/dns"
)

func getARecords(name, addr string) (zskID uint16, addrs []net.IP, err error) {
	client := new(dns.Client)

	msg := new(dns.Msg)
	msg.SetQuestion(name, dns.TypeA)
	msg.SetEdns0(4096, true)

	var r *dns.Msg
	r, _, err = client.Exchange(msg, addr)
	if err != nil {
		return
	}

	for _, rr := range r.Answer {
		switch rr.(type) {
		case *dns.A:
			addrs = append(addrs, rr.(*dns.A).A)
		case *dns.RRSIG:
			zskID = rr.(*dns.RRSIG).KeyTag
		default:
		}
	}

	return
}

func getDNSKEYRecords(name, addr string) (kskID uint16, dnskeyIDs map[uint16]bool, err error) {
	client := new(dns.Client)

	msg := new(dns.Msg)
	msg.SetQuestion(name, dns.TypeDNSKEY)
	msg.SetEdns0(4096, true)

	var r *dns.Msg
	r, _, err = client.Exchange(msg, addr)
	if err != nil {
		return
	}

	dnskeyIDs = map[uint16]bool{}
	for _, rr := range r.Answer {
		switch rr.(type) {
		case *dns.DNSKEY:
			dnskeyIDs[rr.(*dns.DNSKEY).KeyTag()] = true
		case *dns.RRSIG:
			kskID = rr.(*dns.RRSIG).KeyTag
		default:
		}
	}

	return
}

func main() {
	domain := os.Getenv("DOMAIN_NAME")
	servers := strings.Split(os.Getenv("DNS_SERVERS"), ",")

	var realZskID, realKskID uint16

	for idx, server := range servers {
		target := fmt.Sprintf("%s:53", server)
		zskID, _, err := getARecords(domain, target)
		if err != nil {
			log.Fatalf("error: %s", err)
		}

		kskID, dnskeyIDs, err := getDNSKEYRecords(domain, target)
		if err != nil {
			log.Fatalf("error: %s", err)
		}

		var ok bool
		_, ok = dnskeyIDs[zskID]
		if !ok {
			log.Fatalf("could not find zskID %s in dnskey records", zskID)
		}
		_, ok = dnskeyIDs[kskID]
		if !ok {
			log.Fatalf("could not find kskID %s in dnskey records", kskID)
		}

		if idx == 0 {
			realZskID = zskID
			realKskID = kskID
		} else {
			if zskID != realZskID {
				log.Fatalf("zskID mismatch: %d, %d, %s", zskID, realZskID, target)
			}
			if kskID != realKskID {
				log.Fatalf("kskID mismatch: %d, %d, %s", kskID, realKskID, target)
			}
		}
	}
}
