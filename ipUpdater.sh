#!/bin/bash

### ipUpdater.sh 
###
### Small script that checks the current external IP address against a local 
### cached copy. If different, it goes through each line in a second file
### using them as paramters for CURL. Hopefully this will update whatever
### online service you're using, such as OpenDNS, ClouDNS, etc etc
###
### For example OpenDNS: 
### https://updates.opendns.com/nic/update?hostname=[networkName] --basic --user [email]:[password] 
###
### Code for this has been lifted from various places on the web, so do
### do feel free to use/change/whatever 
### 
### Don't forget to change the permissions on the UPDATELINES files so 
### no one can snoop passwords, emails etc
###


### Script Settings ----------------------------------------------------------- 
CONFIGDIR="."
DB="$CONFIGDIR/lastIP.db"
UPDATELINES="$CONFIGDIR/ipUpdaterLines.txt"
LOGFILE="$CONFIGDIR/ipUpdater.log"
LASTRUN="$CONFIGDIR/ipUpdaterLastRun.log"

### Preflight Checks ----------------------------------------------------------
command -v dig >/dev/null 2>&1 || {
echo -e "I require dig but it's not installed. Aborting." >&2
exit 1; }

command -v curl >/dev/null 2>&1 || {
echo -e "I require curl but it's not installed. Aborting." >&2
exit 1; }


### Main code -----------------------------------------------------------------
log() {
	echo -e "$1" >> $LOGFILE
}

lastLog() {
	echo -e "$1" >> $LASTRUN
}

run() {
	NOW=$(date "+%d-%m-%Y %H:%M:%S")
	
	# Reset the last run log file
	echo $NOW > $LASTRUN

	if [[ ! -s "$UPDATELINES" ]]; then
		lastLog "No CURL lines found: $UPDATELINES - nothing to do then..."
		exit 1
	fi
	
	if [[ ! -s "$DB" ]]; then
		lastLog "No old IP on record so writing dummy values to database."
		echo '1.1.1.1.' > "$DB"
	fi
	
	# Get the last stored IP adddress
	OLDIP=$(cat "$DB")
		
	# Get the IP address from the internet
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
		lastLog "WAN or websites are down, no action taken."
		exit 1
	fi 

	if [[ "$CURRENTIP" != "$OLDIP" ]]; then
		# IP changed
		lastLog "Current IP differs from IP in database so notifying and updating database."
		triggerUpdate
	else
		# no change
		lastLog "IP matches IP on record so taking no action."
	fi
}

triggerUpdate() {
	# Update the local cache
	echo "$CURRENTIP" > "$DB"	
	
	# Reset the log file
	echo $NOW > $LOGFILE
			
	# Only allow the user to view log file as it could have key details in it
	chmod u=rw,go= $LOGFILE 
	
	# Do the same for the 
	chmod u=rw,go= $UPDATELINES 
	
	# Go through secondary file, excluding comments
	grep -v '^#' $UPDATELINES | while read -r lline ; do
	    if [[ -n "$lline" ]]; then
			log $lline
	    	result=$(curl -s $lline)
			log $result
			log ""
		fi
	done
}

run

exit 0
