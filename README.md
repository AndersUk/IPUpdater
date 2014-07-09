IPUpdater
=========

Small script that checks the current external IP address against a local cached copy. If different, it goes through each line in a second file using them as paramters for CURL. Hopefully this will update whatever online service you're using, such as OpenDNS, ClouDNS, etc etc

For example OpenDNS: 
` https://updates.opendns.com/nic/update?hostname=[networkName] --basic --user [email]:[password] `

Code for this has been lifted from various places on the web, so do feel free to use/change/whatever 

### Dependency ###
Script needs **curl** and **dig** to be installed on executing system.

## Usage ##
I run this script every five minutes, that way any change to external IP address is picked up very quickly.

    ./ipUpdater.sh    

**CRON Task** to run every 5 minutes:

    */5 * * * * /usr/local/src/IPUpdater/ipUpdater.sh > /dev/null 2>&1
