#!/bin/bash

# for what in 45.90.28.39 45.90.30.39 1.1.1.1 1.0.0.1; do
for what in 80.69.96.12 45.90.28.39 45.90.30.39 1.1.1.1 1.0.0.1 8.8.8.8 8.8.4.4 208.67.222.222 208.67.220.220 84.200.69.80 84.200.70.40 9.9.9.11 149.112.112.11 localhost; do
  cp -af index_192.168.0.13.html index_$what.html
  sed -i "s/192.168.0.13/$what/g" index_$what.html
  sed -i "s/src=ping_/src=dnsping_/g" index_$what.html
done

