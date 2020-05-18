#!/bin/bash

echo "Fetching mails"

[ -z "$IMAPCONF" ] && IMAPCONF="offlineimaprc"

offlineimap -l offlineimap.log -c $IMAPCONF

echo "Extracting attachments"
test -r my_ips && source my_ips
./extract.py
