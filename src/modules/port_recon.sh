module=$(echo $0 | awk -F '/' '{print $NF}' | sed "s/\.[^\.]*$//g")
target=$1
	resultsfolder=$2$(echo $target | sed 's/\//-/g')/$3/$module
	mkdir $resultsfolder
	echo -e "Executing port scan to targets found for "$target
	if [ $3 == "quick" ]; then
		echo "Executing top ports scan and host discovery with ping and few ports"
		sudo nmap -sSV -T4 --defeat-rst-ratelimit --max-retries 3 --min-parallelism 100 --min-hostgroup 256 -PS1025,1028,1029,10443,111,135,139,1521,161,1917,21,22,23,25,2869,3306,3389,443,445,49000,497,5000,515,53,548,5985,5986,6000,79,80,8080,8081,8090,9001,9002,9100,993,995 -oX $resultsfolder/nmap-tcp-target.xml -oG $resultsfolder/nmap-tcp-target.gnmap --open -iL $resultsfolder/../targets.txt &> /dev/null
                sudo nmap -sUV -F --defeat-rst-ratelimit --min-parallelism 100 --host-timeout 5m --version-intensity 0 -oX $resultsfolder/nmap-udp-target.xml -oG $resultsfolder/nmap-udp-target.gnmap --open -iL $resultsfolder/../targets.txt &> /dev/null
	elif [ $3 == "medium" ]; then
		echo "Executing full ports scan with host discovery with ping and few ports"
		sudo nmap -sSV -T4 --defeat-rst-ratelimit --max-retries 3 --min-parallelism 100 --min-hostgroup 256 -PS1025,1028,1029,10443,111,135,139,1521,161,1917,21,22,23,25,2869,3306,3389,443,445,49000,497,5000,515,53,548,5985,5986,6000,79,80,8080,8081,8090,9001,9002,9100,993,995 -oX $resultsfolder/nmap-tcp-target.xml -oG $resultsfolder/nmap-tcp-target.gnmap --open -p- -iL $resultsfolder/../targets.txt &> /dev/null
		sudo nmap -sUV -F --defeat-rst-ratelimit --min-parallelism 100 --host-timeout 5m --version-intensity 0 -oX $resultsfolder/nmap-udp-target.xml -oG $resultsfolder/nmap-udp-target.gnmap --open -iL $resultsfolder/../targets.txt &> /dev/null
	elif [ $3 == "slow" ]; then
		echo "Executing full ports without host discovery"
		sudo nmap -sSV -T4 --defeat-rst-ratelimit --max-retries 3 --min-parallelism 100 --min-hostgroup 256 -Pn -oX $resultsfolder/nmap-tcp-target.xml -oG $resultsfolder/nmap-tcp-target.gnmap --open -Pn -p- -iL $resultsfolder/../targets.txt &> /dev/null
                sudo nmap -sUV --defeat-rst-ratelimit --min-parallelism 100 --host-timeout 5m --version-intensity 0 -oX $resultsfolder/nmap-udp-target.xml -oG $resultsfolder/nmap-udp-target.gnmap --open -iL $resultsfolder/../targets.txt &> /dev/null
	else
        	echo "Not correct speed chosen, exiting the module"
        	exit 1
	fi
	cp $resultsfolder/* $resultsfolder/../tmp/
