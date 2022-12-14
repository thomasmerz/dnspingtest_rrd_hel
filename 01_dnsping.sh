#!/bin/bash

# different dirs on different hosts:
case $(hostname) in
  merz-nimbus)
    cd /home/thomas/Documents/Administration/dnspingtest_rrd."$(hostname)"/ || exit 1
    ;;
  ubuntu-cx11-02|ubuntu-cx11-03)
    cd ~/dev/dnspingtest_rrd."$(hostname)"/ || exit 1
    ;;
  *)
    exit 1
    ;;
esac

PING=/usr/bin/dnsping
COUNT=4
DEADLINE=10

dnsping_host() {
    output="$($PING -q -c $COUNT -w $DEADLINE -s "$1" nextwurz.mooo.com 2>&1)"
    # notice $output is quoted to preserve newlines
    temp=$(echo "$output"| awk '
        BEGIN           {pl=100; rtt=0.1}
        /requests transmitted/   {
            match($0, /([0-9]+)% lost/, matchstr)
            pl=matchstr[1]
        }
        /^min/          {
            # looking for something like "min=14.553 ms, avg=16.015 ms, max=17.675 ms, stddev=1.571 ms"
            match($3, /avg=(.*)/, a)
            rtt=a[1]
        }
        /Name or service not known/  {
            # no output at all means network is probably down
            pl=100
            rtt=0.1
        }
        END         {print pl ":" rtt}
        '|cut -d"=" -f2)
    RETURN_VALUE="$temp"
}

# dnsping some hosts for some dns resolvers:
# dns1.nextdns.io 45.90.28.39
# dns2.nextdns.io 45.90.30.39
# Google (ECS, DNSSEC);8.8.8.8;8.8.4.4;2001:4860:4860:0:0:0:0:8888;2001:4860:4860:0:0:0:0:8844
# OpenDNS (ECS, DNSSEC);208.67.222.222;208.67.220.220;2620:119:35::35;2620:119:53::53
# DNS.WATCH (DNSSEC);84.200.69.80;84.200.70.40;2001:1608:10:25:0:0:1c04:b12f;2001:1608:10:25:0:0:9249:d69b
# Quad9 (filtered, ECS, DNSSEC);9.9.9.11;149.112.112.11;2620:fe::11;2620:fe::fe:11
# --
# https://www.privacy-handbuch.de/handbuch_93d.htm
# "Die DNS-Server vom CCC (213.73.91.35) und Digitalcourage e.V. (85.214.20.141) empfehle ich nicht, da diese Server kein DNSSEC zur Validierung nutzen."
# Der CCC listet "seinen" eigenen/o.g. DNS-Server selber nicht mehr auf seiner Seite: https://www.ccc.de/censorship/dns-howto/ -- Offline/Down/ABN?!
# 46.182.19.48 (Digitalcourage)
# 194.150.168.168 (AS250.net)  -- doesn't work at hetznerc/cloud/non-enduser-provider
# --
# 5.1.66.255 Freifunk M??nchen zensurfrei, DNSSEC
# 185.150.99.255 Freifunk M??nchen zensurfrei, DNSSEC
# 80.241.218.68 dismail.de
# 159.69.114.157 dismail.de
# 176.9.93.198 dnsforge.de
# 176.9.1.117 dnsforge.de
# 94.140.14.14 AdGuard MIT Werbe- und Trackingfilter
# 94.140.15.15 AdGuard MIT Werbe- und Trackingfilter
# 94.140.14.140 AdGuard OHNE Werbe- und Trackingfilter
# 94.140.14.141 AdGuard OHNE Werbe- und Trackingfilter
# 95.215.19.53 Njalla  unzensiert (Njalla ist ein privacy-fokusierter, schwedischer Domain-, Hosting- und VPN-Provider)
# --
for resolvers in 45.90.28.39 45.90.30.39 1.1.1.1 1.0.0.1 8.8.8.8 8.8.4.4 208.67.222.222 208.67.220.220 84.200.69.80 84.200.70.40 9.9.9.11 149.112.112.11 localhost 46.182.19.48 5.1.66.255 185.150.99.255 80.241.218.68 159.69.114.157 176.9.93.198 176.9.1.117 94.140.14.14 94.140.15.15 94.140.14.140 94.140.14.141 95.215.19.53; do
  dnsping_host $resolvers
  /usr/bin/rrdtool update \
      data/dnsping_$resolvers.rrd \
      --template \
      pl:rtt \
      N:"$RETURN_VALUE"
  # https://forum.syncthing.net/t/why-are-rrd-files-transferred-by-time-and-not-immediately/16391
  touch data/dnsping_$resolvers.rrd
done

