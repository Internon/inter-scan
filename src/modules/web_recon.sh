module=$(echo $0 | awk -F '/' '{print $NF}' | sed "s/\.[^\.]*$//g")
target=$1
INTERFUZZFILTER="not (c=BBB and l=BBB and w=BBB)"
if [ $3 == "quick" ]; then
	INTERDICT=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../dicts/web/OneListForAll/onelistforallmicro.txt
elif [ $3 == "medium" ]; then
	INTERDICT=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../dicts/web/OneListForAll/onelistforallmicro.txt
elif [ $3 == "slow" ]; then
	INTERDICT=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../dicts/web/OneListForAll/onelistforallshort.txt
else
	echo "Not correct speed chosen, exiting the module"
	exit 1
fi
resultsfolder=$2$(echo $target | sed 's/\//-/g')/$3/$module
mkdir -p $resultsfolder/
threads=$(cat $resultsfolder/../tmp/scan_threads.txt)
#Generating file with all the URLs to fuzz
echo -e "Executing httpx to retrieve http URLs from port scan for "$target
mkdir $resultsfolder/http-discover
mkdir $resultsfolder/fuzzing
mkdir $resultsfolder/aux
if [[ -f $resultsfolder/../tmp/full-nmap-parsed-tcp.txt ]]; then
	cat $resultsfolder/../tmp/full-nmap-parsed-tcp.txt | awk -F ',' '{print $1 ":" $2}' >> $resultsfolder/http-discover/httpx_aux.txt
	if [[ -f $resultsfolder/../tmp/tcp-tcpwrapped-service.txt ]]; then
		excludehosts="^$"
		for host in $(cat $resultsfolder/../tmp/tcp-tcpwrapped-service.txt | awk -F ',' '{ print $1}' | sort -u)
		do
			lines=$(cat $resultsfolder/../tmp/tcp-tcpwrapped-service.txt | grep "$host," | awk -F ',' '{ print $1}' | sort | uniq -c | awk -F ' ' '{print $1}')
			if [[ $lines -gt 250 ]]; then
				excludehosts=$(echo $host",\|"$exludehosts)
			fi
		done
		excludelist=$(echo $excludehosts | sed 's/,|$//g')
        	#For clients withouth telegraf on port 9126, remove this port on the following line or change the port
        	cat $resultsfolder/http-discover/httpx_aux.txt | grep -v $excludelist | grep -v ":5985$" | grep -v ":5986$" | grep -v ":47001$" | grep -v ":9126$" | tr '[:upper:]' '[:lower:]' | sort -u > $resultsfolder/http-discover/httpx_aux_cleaned.txt
		httpx -l $resultsfolder/http-discover/httpx_aux_cleaned.txt -silent -threads $threads -x ALL --retries 5 -status-code | grep -v '.400.' | awk -F' ' '{print $1}' | sort -u > $resultsfolder/full-initial-files.txt
	else
		cat $resultsfolder/http-discover/httpx_aux.txt | grep -v ":5985$" | grep -v ":5986$" | grep -v ":47001$" | grep -v ":9126$" | tr '[:upper:]' '[:lower:]' | sort -u > $resultsfolder/http-discover/httpx_aux_cleaned.txt
		httpx -l $resultsfolder/http-discover/httpx_aux_cleaned.txt -silent -threads $threads -x ALL --retries 5 -status-code | grep -v '.400.' | awk -F' ' '{print $1}' | sort -u > $resultsfolder/full-initial-files.txt
	fi
else
	echo $target > $resultsfolder/http-discover/httpx_aux_cleaned.txt
	if [[ "$target" =~ ":" ]]; then
		echo "Target contains port so we only do that port"
		httpx -l $resultsfolder/http-discover/httpx_aux_cleaned.txt -silent -threads $threads -x ALL --retries 5 -status-code | grep -v '.400.' | awk -F' ' '{print $1}' | sort -u > $resultsfolder/full-initial-files.txt
	else
		echo "Target doesn't contains port so we will do top ports"
		httpx -l $resultsfolder/http-discover/httpx_aux_cleaned.txt -silent -threads $threads -x ALL --retries 5 -status-code -p 66,80,81,443,445,457,1080,1100,1241,1352,1433,1434,1521,1944,2301,3000,3001,3128,3306,4000,4001,4002,4100,5000,5001,5432,5800,5801,5802,6346,6347,7001,7002,7080,7081,8080,8443,8888,30821 | grep -v '.400.' | awk -F' ' '{print $1}' | sort -u > $resultsfolder/full-initial-files.txt
	fi

fi
#Executing fuzzing scan
echo "Executing fuzzing on URLs found for "$target
cp $resultsfolder/full-initial-files.txt $resultsfolder/aux/full-initial-files.txt
for url in $(cat $resultsfolder/aux/full-initial-files.txt)
do
	ip=$(echo $url | sed 's/^[^\/]*\/\///g' | sed 's/\/.*//g')
	cat $resultsfolder/../tmp/ips-with-domains.txt | grep $ip | sed 's/,/\n/g' | sort -ur | ffuf -w $INTERDICT:FUZZ -w -:VHOST -t $threads -noninteractive -p 0.1-0.5 -acc notherexxxxasdf -ac -mc all -u $url/FUZZ -H "Host: VHOST" -se -of all -o $resultsfolder/fuzzing/$(echo $url | sed 's/\/\//-/g'| sed 's/\//-/g' | sed 's/:/-/g') >> $resultsfolder/fuzzing/debug.file 2> $resultsfolder/fuzzing/$(echo $url | sed 's/\//-/g' | sed 's/:/-/g').error
	#It seems that the error file is being created always but without any error but we can see if there was an error by seeing the total and the current file of the dict
	finalfuzz=$(cat $resultsfolder/fuzzing/$(echo $url | sed 's/\//-/g' | sed 's/:/-/g').error | grep Progress | sed 's/.*Progress://g' | awk '{print $1}' | tr -d '\[' | tr -d '\]' | awk -F '/' '{print $1}')
	totalfuzz=$(cat $resultsfolder/fuzzing/$(echo $url | sed 's/\//-/g' | sed 's/:/-/g').error | grep Progress | sed 's/.*Progress://g' | awk '{print $1}' | tr -d '\[' | tr -d '\]' | awk -F '/' '{print $2}')
	if [ "$finalfuzz" != "$totalfuzz" ]; then
		echo "[INFO] - Skipping $url because found an error take into account the vhosts of this url"
	        echo $url >> $resultsfolder/aux/fuzz-skipped-urls.txt
	fi
	sed -i "/$(echo $url| sed 's/https*:\/\///g' | sed 's/\/$//g')/d" $resultsfolder/aux/full-initial-files.txt
done
echo "Skipped URLs in $resultsfolder/aux/fuzz-skipped-urls.txt"
#URLs status parsing
echo "On path $resultsfolder/fuzzing/ you have the html files that have a good look and feel to review differences between paths"
echo -e "Generating URL status files for URLs found for "$target
cat $resultsfolder/fuzzing/*.json | jq ".results[] | [.url, .host] | @csv" | tr -d '\\"' | tr -d '"' | sed 's/\(^[^\/]*\/\/\)[^\/]*\([^,]*\),\(.*$\)/\1\3\2/g' | sort -u > $resultsfolder/all-urls-fuzzing-results.txt
allstatus=$(cat $resultsfolder/fuzzing/*.json | jq .results[].status | sort -u)
mkdir $resultsfolder/status_files
for status in $allstatus
do
	cat $resultsfolder/fuzzing/*.json | jq ".results[] | select(.status==$status) | [.url, .host] | @csv" | tr -d '\\"' | tr -d '"' | sed 's/\(^[^\/]*\/\/\)[^\/]*\([^,]*\),\(.*$\)/\1\3\2/g' | sort -u > $resultsfolder/status_files/urls-status-$status.txt 
	if [[ $(cat $resultsfolder/status_files/urls-status-$status.txt | wc -l) -lt 50 ]]; then 
		cat $resultsfolder/status_files/urls-status-$status.txt >> $resultsfolder/urls-status-screenshot.txt
	fi
done
#URLS screenshot aquatone
echo "Making screenshots for URLs found for "$target
#Adding virtual hosts in /etc/hosts for aquatone
sudo bash -c "cat $resultsfolder/../tmp/ips-with-domains.txt | sed 's/,/\t/g' >> /etc/hosts"
cat $resultsfolder/urls-status-screenshot.txt | aquatone -screenshot-timeout 120000 -threads $threads -http-timeout 120000 --scan-timeout 120000 -out $resultsfolder/screenshots -silent
cp $resultsfolder/all-urls-fuzzing-results.txt $resultsfolder/../tmp/
cp $resultsfolder/full-initial-files.txt $resultsfolder/../tmp/
if [[ -f $resultsfolder/status_files/urls-status-200.txt ]] ; then
	cp $resultsfolder/status_files/urls-status-200.txt $resultsfolder/../tmp/
else
	echo '' > $resultsfolder/../tmp/urls-status-200.txt
fi
if [[ $(cat $resultsfolder/../tmp/urls-status-200.txt | wc -l) -lt 100 ]]; then
	cat $resultsfolder/../tmp/urls-status-200.txt $resultsfolder/../tmp/full-initial-files.txt | sort -u > $resultsfolder/../tmp/full-urls.txt
else
	cat $resultsfolder/../tmp/full-initial-files.txt > $resultsfolder/../tmp/full-urls.txt
fi
#Cleaning /etc/hosts
cp /etc/hosts $resultsfolder/../tmp/aux-etc-hosts.txt
numlines=$(cat $resultsfolder/../tmp/ips-with-domains.txt | wc -l)
sudo bash -c "head -n -$numlines $resultsfolder/../tmp/aux-etc-hosts.txt > /etc/hosts"
echo "There could be some error in aquatone screenshots if there is various IPs with the same domain"
