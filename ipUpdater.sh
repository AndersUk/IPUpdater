#!/bin/bash

CONFIGDIR="."
DB="$CONFIGDIR/checkip.db"
CURLLINES="$CONFIGDIR/curllines.txt"

command -v dig >/dev/null 2>&1 || {
echo -e "I require dig but it's not installed. Aborting." >&2
exit 1; }

command -v curl >/dev/null 2>&1 || {
echo -e "I require curl but it's not installed. Aborting." >&2
exit 1; }


run() {
	NOW=$(date "+%m-%d-%Y %H:%M:%S")


	if [[ ! -f "$CURLLINES" ]]; then
		echo -e " No CURL file found: $CURLLINES - nothing to do then..."
		exit 1
	fi
	
	if [[ ! -f "$DB" ]]; then
		echo -e " No old IP on record so writing dummy values to database."
		echo '1.1.1.1.' > "$DB"
	fi
	
	OLDIP=$(cat "$DB")
		
	# Get the IP address
	# Script tries initially from a DNS server using dig
	CURRENTIP=$(dig +short myip.opendns.com @resolver1.opendns.com)

	# If that fails, it defaults back to using websites
	# that provide the IP trying all three of these:
	# 1. http://www.whatsmyip.us
	# 2. http://icanhazip.com
	# 3. http://ifconfig.me
	if [[ -z "$CURRENTIP" ]]; then
		CURRENTIP=$(curl -s http://www.whatsmyip.us/ | grep "</textarea>"| sed 's/[</].*$//')
	fi

	if [[ -z "$CURRENTIP" ]]; then
		CURRENTIP=$(curl -s http://icanhazip.com/)
	fi

	if [[ -z "$CURRENTIP" ]]; then
		CURRENTIP=$(curl -s http://ifconfig.me/)
	fi

	if [[ -z "$CURRENTIP" ]]; then
		# net up or down
		echo -e " WAN or websites are down, no action taken."
		exit 1
	fi 

	if [[ "$CURRENTIP" != "$OLDIP" ]]; then
		# IP changed
		echo -e " Current IP differs from IP in database so notifying and updating database."
		triggerUpdate
	else
		# no change
		echo -e " IP matches IP on record so taking no action."
	fi
}

triggerUpdate() {
	echo "$CURRENTIP" > "$DB"	
	
	grep -v '^#' $CURLLINES | while read -r file ; do
	    if [ -n "$file" ]; then
			echo -e "$file"
	    	curl -s $file
			echo -e "\n"
		fi
	done
}

run

exit 0
