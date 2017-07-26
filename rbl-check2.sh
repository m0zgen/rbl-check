#!/bin/bash

# IPs or hostnames to check if none provided as arguments to the script
hosts='
122.114.190.101
122.114.190.102
'

# Locally maintained list of DNSBLs to check
LocalList='
b.barracudacentral.org
truncate.gbudb.net
dnsbl.proxybl.org
dnsbl.sorbs.net
safe.dnsbl.sorbs.net
http.dnsbl.sorbs.net
socks.dnsbl.sorbs.net
misc.dnsbl.sorbs.net
smtp.dnsbl.sorbs.net
web.dnsbl.sorbs.net
new.spam.dnsbl.sorbs.net
recent.spam.dnsbl.sorbs.net
old.spam.dnsbl.sorbs.net
spam.dnsbl.sorbs.net
escalations.dnsbl.sorbs.net
block.dnsbl.sorbs.net
zombie.dnsbl.sorbs.net
dul.dnsbl.sorbs.net
rhsbl.sorbs.net
badconf.rhsbl.sorbs.net
nomail.rhsbl.sorbs.net
sbl.spamhaus.org
xbl.spamhaus.org
pbl.spamhaus.org
zen.spamhaus.org
rbl.orbitrbl.com
intercept.datapacket.net
db.wpbl.info
bl.spamcop.net
noptr.spamrats.com
dyna.spamrats.com
spam.spamrats.com
bl.spamcannibal.org
any.dnsl.ipquery.org
dnsbl.njabl.org
bhnc.njabl.org
spamtrap.drbl.drand.net
dnsbl.ahbl.org
rhsbl.ahbl.org
ircbl.ahbl.org
tor.ahbl.org
dnsbl.dronebl.org
rbl.atlbl.net
hbl.atlbl.net
access.atlbl.net
ix.dnsbl.manitu.net
dnsbl.inps.de
bl.blocklist.de
'

# pipe delimited exclude list for remote lists
Exclude='^dnsbl.mailer.mobi$|^foo.bar$|^bar.baz$'

# Remotely maintained list of DNSBLs to check
WPurl="http://en.wikipedia.org/wiki/Comparison_of_DNS_blacklists"
WPlst=$(curl -s $WPurl | egrep "([a-z]+\.){1,7}[a-z]+" | sed -r 's|||g;/$Exclude/d')


# ---------------------------------------------------------------------

HostToIP()
{
 if ( echo "$host" | egrep -q "[a-zA-Z]" ); then
   IP=$(host "$host" | awk '/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ {print$NF}')
 else
   IP="$host"
 fi
}

Repeat()
{
 printf "%${2}s\n" | sed "s/ /${1}/g"
}

Reverse()
{
 echo $1 | awk -F. '{print$4"."$3"."$2"."$1}'
}

Check()
{
 result=$(dig +short $rIP.$BL)
 if [ -n "$result" ]; then
   echo -e "MAY BE LISTED \t $BL (answer = $result)"
 else
   echo -e "NOT LISTED \t $BL"
 fi
}

if [ -n "$1" ]; then
  hosts=$@
fi

if [ -z "$hosts" ]; then
  hosts=$(netstat -tn | awk '$4 ~ /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ && $4 !~ /127.0.0/ {gsub(/:[0-9]+/,"",$4);} END{print$4}')
fi

for host in $hosts; do
  HostToIP
  rIP=$(Reverse $IP)
  # remote list
  echo; Repeat - 100
  echo " checking $IP against BLs from $WPurl"
  Repeat - 100
  for BL in $WPlst; do
    Check
  done
  # local list
  echo; Repeat - 100
  echo " checking $IP against BLs from a local list"
  Repeat - 100
  for BL in $LocalList; do
    Check
  done
done
