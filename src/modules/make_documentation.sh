module=$(echo $0 | awk -F '/' '{print $NF}' | sed "s/\.[^\.]*$//g")
target=$1
echo "Generating documentation for working on targets found for "$target
resultsfolder=$2$(echo $target | sed 's/\//-/g')/$3/documentation
mkdir -p $resultsfolder
hosts=$(cat $resultsfolder/../tmp/nmap-*-target.gnmap | grep Ports: | awk -F' ' '{print $2}' | sort -u)
conf_folder=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../conf
dateexecution=$(date "+%d-%m-%Y_%H-%M")
httpregex=".*http.*|.*ssl.*"
porthttpregex="^66$|^80$|^81$|^443$|^445$|^457$|^1080$|^1100$|^1241$|^1352$|^1433$|^1434$|^1521$|^1944$|^2301$|^3000$|^3128$|^3306$|^4000$|^4001$|^4002$|^4100$|^5000$|^5432$|^5800$|^5801$|^5802$|^6346$|^6347$|^7001$|^7002$|^8080$|^8443$|^8888$|^30821$"
for host in $hosts; do
	mkdir -p $resultsfolder/$host
	cp $conf_folder/internon-logo.png $resultsfolder/$host/internon-logo.png
	for virtualhost in $(cat $resultsfolder/../tmp/ips-with-domains.txt | grep "$host,\|$host$" | sed 's/,/\n/g' | sort -u); do
		nameoutput=$(echo $virtualhost"_"$dateexecution".md")
		if [[ ! -d $resultsfolder/$host/evidences/$virtualhost ]]; then
			mkdir -p $resultsfolder/$host/evidences/$virtualhost
		fi
		echo -e '# '$virtualhost'\n' >> $resultsfolder/$host/$nameoutput
		echo -e 'This note is for attacking '$virtualhost' with IP' $host'  ' >> $resultsfolder/$host/$nameoutput
		echo -e 'Before testing remember to review the IP resolution of the domain to match the IP and if it doesn'"'"'t match, add it on /etc/hosts and re-execute the web-scan process  ' >> $resultsfolder/$host/$nameoutput
		echo -e 'Remember to fill all the checklists on all the ports and mark with "~~" the checklists that doesn'"'"' fit in your escenario  \n' >> $resultsfolder/$host/$nameoutput
		echo -e '![Internon Logo](internon-logo.png)\n' >> $resultsfolder/$host/$nameoutput
		echo -e '| Risk        | Vulnerability number           |
| ------------- |:-------------:|
| <span style="color:red">**Critical**</span>      | 0 |
| <span style="color:orange">**High**</span>      | 0      |
| <span style="color:#FFBF00">**Medium**</span> | 0      |
| <span style="color:green">**Low**</span> | 0      |
| <span style="color:blue">**Info**</span> | 0      |\n' >> $resultsfolder/$host/$nameoutput
		echo -e '## Information Gathering\n' >> $resultsfolder/$host/$nameoutput
		echo -e '### Virtual servers or domains related' >> $resultsfolder/$host/$nameoutput
		if [[ -f $resultsfolder/../tmp/ips-with-domains.txt ]]; then
			cat $resultsfolder/../tmp/ips-with-domains.txt | grep "$host,\|$host$" | sed 's/$/  \n/g' | sed 's/,/  \n/g' | sort -u >> $resultsfolder/$host/$nameoutput
			echo -e '' >> $resultsfolder/$host/$nameoutput
		else
			echo -e 'No domains found for this IP  \n' >> $resultsfolder/$host/$nameoutput
		fi
		echo -e '### Credentials\n
N/A\n
### Open ports\n' >> $resultsfolder/$host/$nameoutput
		if [[ -f $resultsfolder/../tmp/full-nmap-parsed-tcp.txt ]]; then
			echo -e '#### TCP\n' >> $resultsfolder/$host/$nameoutput
			cat $resultsfolder/../tmp/full-nmap-parsed-tcp.txt | grep "$host," | sed 's/^/- /g' | sed 's/$/  /g' >> $resultsfolder/$host/$nameoutput
			echo -e '' >> $resultsfolder/$host/$nameoutput
		fi
		if [[ -f $resultsfolder/../tmp/full-nmap-parsed-udp.txt ]]; then
			echo -e '#### UDP\n' >> $resultsfolder/$host/$nameoutput
			cat $resultsfolder/../tmp/full-nmap-parsed-udp.txt | grep "$host," | sed 's/^/- /g' | sed 's/$/  /g' >> $resultsfolder/$host/$nameoutput
			echo -e '' >> $resultsfolder/$host/$nameoutput
		fi
		echo -e '## Exploitation\n
### Before start

- [ ] Review previous reports to check if vulnerabilities are closed
- [ ] Execute some OSINT process for the company

### Infrastructure

- [ ] Execute and review vulnerabilities from vulnerability scan
- [ ] Review services and versions of opened ports (If found any service like active directory notify the Manager first if it is not in the scope)
- [ ] Extra checks depending on the services\n' >> $resultsfolder/$host/$nameoutput
		for service in $(cat $resultsfolder/../tmp/*-service.txt | grep "$host," | awk -F ',' '{print $3 }' | sort -u)
		do
			echo -e "#### $service service"'\n' >> $resultsfolder/$host/$nameoutput
			for port in $(cat $resultsfolder/../tmp/*-service.txt | grep "$host," | grep ",$service," | awk -F ',' '{print $2}' | sort -u)
			do
				echo -e '##### Port '$port'\n' >> $resultsfolder/$host/$nameoutput
				if [[ $service =~ $httpregex ]] || [[ $port =~ $porthttpregex ]]
				then
					cat $conf_folder/web-checklist.md >> $resultsfolder/$host/$nameoutput
					echo -e '> Status 2XX  ' >> $resultsfolder/$host/$nameoutput
					echo -e 'N/A  ' >> $resultsfolder/$host/$nameoutput
					echo -e '> Status 3XX  ' >> $resultsfolder/$host/$nameoutput
					echo -e 'N/A  ' >> $resultsfolder/$host/$nameoutput
					echo -e '> Status 5XX  ' >> $resultsfolder/$host/$nameoutput
					echo -e 'N/A  \n' >> $resultsfolder/$host/$nameoutput
				elif [[ $port == "88" ]]
				then
					cat $conf_folder/ad-checklist.md >> $resultsfolder/$host/$nameoutput
				else
					echo -e '###### Credentials

- [ ] Execute the BruteForce attack or the password spray attack with default accounts credentials (Be careful with blocking policies)
- [ ] Execute the BruteForce attack or the password spray attack with found accounts credentials (Be careful with blocking policies)
- [ ] Execute the BruteForce attack or the password spray attack with own dictionaries generated (Be careful with blocking policies)\n' >> $resultsfolder/$host/$nameoutput
				fi
				echo -e '###### Port '$port' vulnerabilities\n
N/A\n' >> $resultsfolder/$host/$nameoutput
				echo -e '---\n' >> $resultsfolder/$host/$nameoutput
			done
		done
		echo -e '## Post-Exploitation

- [ ] After gaining access, notify the Manager (And maybe the client) if they give you permission, follow with the points
- [ ] Gain persistence
- [ ] Check user privileges
- [ ] Check for privilege escalation and gain persistence with new account
- [ ] Retrieve local hashes
- [ ] Check users folder
- [ ] Check open local ports
- [ ] Check other Network interfaces
- [ ] Find useful information in files (SSH keys, plaintext passwords, Browser information or other interesting information)
- [ ] Move laterally to other server
- [ ] Repeat processes from [`Infrastructure`](#infrastructure) with internal scope (Check scope in ARP table, routes, guessing, etc)\n' >> $resultsfolder/$host/$nameoutput
	done
done
