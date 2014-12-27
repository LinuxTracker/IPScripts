# Script to read a list of domains (domains.txt) and resolve each domain against a list of DNS servers (in this case android ad servers)
# The resulting list of IPs is scrubbed of duplicates, invalid IPs and bogons
# The remiander is sorted in ascending order and outputted to adwareips.txt file

# loads a regex string to scan for most bogons
bogons="(0|10|127|224|240)(\.[0-9]{1,3}){3}|(100\.64|169\.254|172\.16|192\.(0|168)|198\.(18|19))(\.[0-9]{0,3}){2}"

# loads an invalid IP regex into the invalidIP variable
invoct="25[6-9]|2[6-9][0-9]|[3-9][0-9][0-9]"
invalidIP="($invoct\\.){3}$invoct"

# declare variables
rfile=/home/user/ips/adware/rawdata 
wfile=/home/user/ips/adware/workdata
workdir=/home/user/ips/adware

# zero out temp files
cat /dev/null > $rfile
cat /dev/null > $wfile

while read u; do
   while read d; do

      # lookup the ip for url=u from dns=d into rawfile
      echo 'nslookup -timeout=1' $u $d
      nslookup -timeout=1 $u $d > $rfile

      # extract IP address from rawdata minus lines with dns server
      grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' $rfile | grep -vE "$d" >> $wfile
      
   done <$workdir/dnsdata.txt

done <$workdir/domains.txt

# discard lines with bogons and invalid IPs
grep -vE "$bogons" $wfile | grep -vE "$invalidIP" > $rfile

# remove dupes - sort the remainder
cat $rfile | uniq | sort -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4 > $wfile

# write the output
cat $wfile > &workdir/adwareips.txt