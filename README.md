IPUpdater
=========

Small script that checks the current external IP address against a local cached copy. If different, it goes through each line in a second file using them as paramters for CURL. Hopefully this will update whatever online service you're using, such as OpenDNS, ClouDNS, etc etc

For example OpenDNS: 
` https://updates.opendns.com/nic/update?hostname=[networkName] --basic --user [email]:[password] `

Code for this has been lifted from various places on the web, so do feel free to use/change/whatever 

Don't forget to change the permissions on the UPDATELINES files so no one can snoop passwords, emails etc