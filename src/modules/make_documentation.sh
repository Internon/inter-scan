module=$(echo $0 | awk -F '/' '{print $NF}' | sed "s/\.[^\.]*$//g")
target=$1
	echo "Generating documentation for working on targets found for "$target
	resultsfolder=$2$(echo $target | sed 's/\//-/g')/$3/documentation
	mkdir -p $resultsfolder
	hosts=$(cat $resultsfolder/../tmp/nmap-*-target.gnmap | grep Ports: | awk -F' ' '{print $2}' | sort -u)
	dateexecution=$(date "+%d-%m-%Y_%H-%M")
        for host in $hosts; do
		mkdir $resultsfolder/$host
		for virtualhost in $(cat $resultsfolder/../tmp/ips-with-domains.txt | grep "$host,\|$host$" | sed 's/,/\n/g' | sort -u); do
                	nameoutput=$(echo $virtualhost"_"$dateexecution".md")
                	if [[ ! -d $resultsfolder/$host/evidences/$virtualhost ]]; then
                        	mkdir -p $resultsfolder/$host/evidences/$virtualhost
                        fi
                	echo -e '### '$virtualhost'\n' >> $resultsfolder/$host/$nameoutput
                	echo -e '## Virtual Servers - Domains related\n' >> $resultsfolder/$host/$nameoutput
                	if [[ -f $resultsfolder/../tmp/ips-with-domains.txt ]]; then
                        	cat $resultsfolder/../tmp/ips-with-domains.txt | grep "$host,\|$host$" | sed 's/,/\n/g' | sort -u >> $resultsfolder/$host/$nameoutput
                        	echo -e '\n' >> $resultsfolder/$host/$nameoutput
                	else
                        	echo -e 'No domains found for this IP\n' >> $resultsfolder/$host/$nameoutput
                	fi
                	echo -e '## Credentials\n
## Ports open\n
> TCP\n' >> $resultsfolder/$host/$nameoutput
                	if [[ -f $resultsfolder/../tmp/full-nmap-parsed-tcp.txt ]]; then
  				cat $resultsfolder/../tmp/full-nmap-parsed-tcp.txt | grep "$host," >> $resultsfolder/$host/$nameoutput
			fi
                	echo -e '\n
> UDP\n' >> $resultsfolder/$host/$nameoutput
			if [[ -f $resultsfolder/../tmp/full-nmap-parsed-udp.txt ]]; then
				cat $resultsfolder/../tmp/full-nmap-parsed-udp.txt | grep "$host," >> $resultsfolder/$host/$nameoutput
			fi
			echo -e '\n
## Gaining access\n' >> $resultsfolder/$host/$nameoutput
                	cat $resultsfolder/../tmp/*-service.txt | grep "$host," | awk -F ',' '{print "> " $3 " service" }' | sort -u >> $resultsfolder/$host/$nameoutput
                	echo -e '\n
## Privesc\n
## Postexplotation\n
> Local Hashes\ncat /etc/shadow or cat /etc/passwd\nSAM dump + lsa\n
> Users folder\nls -lahR /home\n
> Netstat\nnetstat -anopl\nnetstat -anobl\n
> Network interfaces\nifconfig\nipconfig\n
> SSH keys\nfind / | grep "\.ssh/"\n
> Database information\n
> Browser information if GUI\n
> Credentials on files/proofs.txt\n
' >> $resultsfolder/$host/$nameoutput
		done
	done
