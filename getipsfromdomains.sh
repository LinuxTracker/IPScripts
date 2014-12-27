# Script to read a list of domains (domains.txt) and resolve each domain against a list of DNS servers (in this case android ad servers)
# The resulting list of IPs is scrubbed of duplicates, invalid IPs and bogons
# The remiander is sorted in ascending order and outputted to adwareips.txt file
# Using a list of 47 DNS servers, lookups take ~10 sec per domain if DNS server has domain cached and ~25 seconds if not

# loads a regex string to scan for most bogons
bogons="(0|10|127|224|240)(\.[0-9]{1,3}){3}|(100\.64|169\.254|172\.16|192\.(0|168)|198\.(18|19))(\.[0-9]{0,3}){2}"

# loads an invalid IP regex into the invalidIP variable
invoct="25[6-9]|2[6-9][0-9]|[3-9][0-9][0-9]"
invalidIP="($invoct\\.){3}$invoct"

# declare variables
rfile=/home/user/ips/adware/rawdata 
wfile=/home/user/ips/adware/workdata
temp=/home/user/ips/adware/temp

workdir=/home/user/ips/adware

# zero out temp files
cat /dev/null > $rfile
cat /dev/null > $wfile
cat /dev/null > $temp
cat /dev/null > $workdir/baddomain.txt

while read u; do

      echo '1 nslookup -timeout=1' $u $d
      cat /dev/null > $temp

	  # perform initial lookup using google DNS	- load any NXDOMAIN lines into $temp = maybe add more dns checks here
      nslookup -timeout=1 $u 8.8.4.4 | grep NXDOMAIN > $temp

	  # If $temp is empty (good domain) perform DNS lookups - else skip and log the bad domain
	  if [ ! -s $temp ]; then
              while read d; do

                  # lookup the ip for domain=u from dns=d and write address line into rawdata
                  nslookup -timeout=1 $u $d | grep Address | grep -vE "$d" > $rfile

                  # extract IP address from rawdata into workfile
                  grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' $rfile >> $wfile
             done <$workdir/dnsdata.txt
         else 
              cat $temp >> $workdir/baddomain.txt
         fi
      
done <$workdir/android

# discard lines with bogons and invalid IPs
grep -vE "$bogons" $wfile | grep -vE "$invalidIP" > $rfile

# remove dupes - sort the remainder
cat $rfile | uniq | sort -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4 > $wfile

# write the output
cat $wfile > &workdir/androidadserverips.txt
