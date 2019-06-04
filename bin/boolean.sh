#!/bin/bash
# -------------------------------------------------------------------------------
# command output w/ success | failure noted in (1) sms and (2) email subject line
#
# ------------+------------------------- #
# Carrier     | Domain Name              #
# ------------+------------------------- #
# At&T        | @txt.att.net             #
# Cricket     | @mms.mycricket.com       #
# Nextel      | @messaging.nextel.com    #
# Qwest       | @qwestmp.com             #
# Sprint      | @messaging.sprintpcs.com #
# T-Mobile    | @tmomail.net             #
# US Cellular | @email.uscc.net          #
# Verizon     | @vtext.com               #
# Virgin      | @vmobl.com               #
# ------------+------------------------- #
# -------------------------------------------------------------------------------
THIS=$( basename "${BASH_SOURCE[0]}" )	# the name of this script
if [[ $# -lt 2 ]] ; then echo "usage: $THIS 'test name' recipient [sms]" ; exit ; fi

OUT=$(mktemp) || { echo "Failed to create temp file; quitting." ; exit 1 ; }

cat > "$OUT"							# capture STDIN (cmd output) to tempfile

if grep "error" < "$OUT" 2>&1 > /dev/null ; then r="FAILURE" ; else r="SUCCESS" ; fi

# send email
cat "$OUT" | mailx -n -E -s "${r} -- ${1}" "${2}"

# send SMS on failures only if destination provided
if [ -n "$3" ] && [ "$r" = 'FAILURE' ] ; then mailx -n -s "${r} -- ${1}" "$3" < /dev/null ; fi