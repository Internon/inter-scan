#!/bin/bash
RED='\033[0;31m'
WHITE='\e[37m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'
DICT_FOLDER=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../dicts/dns
SUB_MODULES_FOLDER=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../sub-modules
RESOLVERS_FOLDER=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../resolvers
export CENSYS_API_ID=''
export CENSYS_API_SECRET=''
target=$1

if [ $# -lt 2 ];
then
        printf "${RED}USAGE params: <domains_file> <folder_to_save_the_results>${NC}\n"
        exit 0
fi
module=$(echo $0 | awk -F '/' '{print $NF}' | sed "s/\.[^\.]*$//g")

if [ ! -f $domainsFile ]; then
        echo "${RED}File $domainsFile not found${NC}\n"
        exit 0
fi

printf "Subdomain enumeration script\n"
printf "Author: Roberto Reigada - roberto.reigada@a2secure.com\n"
printf "Modified by: Internon\n"
printf "\n"
	resultsfolder=$2$(echo $target | sed 's/\//-/g')/$3/$module
	mkdir -p $resultsfolder
	if [[ $target =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  		echo "Target is an IP"
		amass intel -addr $target > $resultsfolder/amass.tmp
		echo $target > $resultsfolder/../targets.txt
	elif [[ $target =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\/[0-9]+$ ]]; then
		echo "Target is a network"
		amass intel -cidr $target > $resultsfolder/amass.tmp
		echo $target > $resultsfolder/../targets.txt
	else
		echo "Target is a domain "
		amass intel -whois -d $target -include WhoisXMLAPI > $resultsfolder/amass.tmp
        	echo $target >> $resultsfolder/amass.tmp
	fi
	cat $resultsfolder/amass.tmp | sort -u > $resultsfolder/../tmp/targets_aux.txt
	mkdir $resultsfolder/passive
	for i in $(cat $resultsfolder/../tmp/targets_aux.txt)
	do
		assetfinder -subs-only $i > "$resultsfolder/passive/assetfinder.tmp"
        	cat "$resultsfolder/passive/assetfinder.tmp" | grep -v "*\|@\|#" | sort -u > "$resultsfolder/passive/tmp.txt"
		if [ -f $resultsfolder/passive/tmp.txt ]
                then
        		mv "$resultsfolder/passive/tmp.txt" "$resultsfolder/passive/assetfinder.tmp"
		fi
        	echo $i | subfinder -silent > "$resultsfolder/passive/subfinder.tmp"
        	cat "$resultsfolder/passive/subfinder.tmp" | grep -v "*\|@\|#" | sort -u > "$resultsfolder/passive/tmp.txt"
		if [ -f $resultsfolder/passive/tmp.txt ]
		then
			mv "$resultsfolder/passive/tmp.txt" "$resultsfolder/passive/subfinder.tmp"
		fi
        	curl -s https://crt.sh/\?q=\%.$i\&output\=json | jq -r '.[].name_value' | sed 's/\*\.//g' | grep -v "*\|@\|#\|---" | sort -u >> $resultsfolder/passive/crt.tmp
        	curl -s https://www.threatcrowd.org/searchApi/v2/domain/report/?domain=$i | jq -r '.subdomains | .[]' | sort -u >> $resultsfolder/passive/threatcrowd.tmp
        	curl -s https://api.hackertarget.com/hostsearch/?q=$i | cut -d',' -f1 | sort -u >> $resultsfolder/passive/hackertarget.tmp
        	timeout 1m python3 $SUB_MODULES_FOLDER/dnscan/dnscan.py -d $i -o "$resultsfolder/passive/dnscan.tmp" > /dev/null 2>&1
        	sed '1,/A records/d' "$resultsfolder/passive/dnscan.tmp" | tr -d ' ' > "$resultsfolder/passive/.tmp"
        	sed 's/^[^-]*-//g' "$resultsfolder/passive/.tmp" | sort -u > "$resultsfolder/passive/dnscan.tmp"
        	rm -rf "$resultsfolder/passive/.tmp"
		exec >/dev/null 2>&1; python3 $SUB_MODULES_FOLDER/censys-subdomain-finder/censys_subdomain_finder.py $i -o "$resultsfolder/passive/censys.tmp"; exec >/dev/tty; exec 2>/dev/tty
		if test -f "$resultsfolder/passive/censys.tmp"; then
			cat "$resultsfolder/passive/censys.tmp" | grep -v "*\|@\|#" | sort -u > "$resultsfolder/passive/tmp.txt"
			mv "$resultsfolder/passive/tmp.txt" "$resultsfolder/passive/censys.tmp"
		fi
		sed -e "s/$/.$i/" $DICT_FOLDER/fast.txt > "$resultsfolder/brutewordlist.tmp"
		exec >/dev/null 2>&1; timeout 15m shuffledns -d $i -list "$resultsfolder/brutewordlist.tmp" -r $RESOLVERS_FOLDER/trusted_resolvers.txt >> "$resultsfolder/passive/shuffledns.tmp"; exec >/dev/tty; exec 2>/dev/tty
		cat "$resultsfolder/passive/shuffledns.tmp" | grep -v "*\|@\|#" | sort -u > "$resultsfolder/passive/tmp.txt"
		mv "$resultsfolder/passive/tmp.txt" "$resultsfolder/passive/shuffledns.tmp"
		rm -rf "$resultsfolder/brutewordlist.tmp"
		cat $resultsfolder/passive/*.tmp | sort -u > "$resultsfolder/passivesubdomains.tmp"
        	if test -f "$resultsfolder/passivesubdomains.tmp"; then
                	var_passive=$(wc -l "$resultsfolder/passivesubdomains.tmp" | awk '{print $1}')
        	else
                	var_passive=0
        	fi
        	if [ $var_passive -lt 600 ]
        	then
                	cat "$resultsfolder/passivesubdomains.tmp" | dnsgen -w $DICT_FOLDER/alterationwords.txt - > "$resultsfolder/dnsgenwordlist.tmp"
                	exec >/dev/null 2>&1; cat "$resultsfolder/dnsgenwordlist.tmp" | $SUB_MODULES_FOLDER/massdns/bin/massdns -r $RESOLVERS_FOLDER/resolvers.txt -t A -o S --root > "$resultsfolder/temp.tmp"; exec >/dev/tty ; exec 2>/dev/tty
                	cat "$resultsfolder/temp.tmp" | awk '{print $1}' | sed 's/.$//' | sed -e 's/^*.//' | sort -u > "$resultsfolder/temp2.tmp"
                	exec >/dev/null 2>&1; $SUB_MODULES_FOLDER/massdns/bin/massdns -r $RESOLVERS_FOLDER/trusted_resolvers.txt -t A "$resultsfolder/temp2.tmp" -o S --root > "$resultsfolder/temp3.tmp"; exec >/dev/tty ; exec 2>/dev/tty
                	cat "$resultsfolder/temp3.tmp" | awk '{print $1}' | sed 's/.$//' | sed -e 's/^*.//' | sort -u >> $resultsfolder/massdnsBrute.tmp
                	rm -rf "$resultsfolder/dnsgenwordlist.tmp"
                	rm -rf "$resultsfolder/temp.tmp"
                	rm -rf "$resultsfolder/temp2.tmp"
                	rm -rf "$resultsfolder/temp3.tmp"
        	fi

        	if test -f "$resultsfolder/passive/assetfinder.tmp"; then
                	var_assetfinder=$(wc -l "$resultsfolder/passive/assetfinder.tmp" | awk '{print $1}')
        	else
                	var_assetfinder=0
        	fi
        	if test -f "$resultsfolder/passive/subfinder.tmp"; then
                	var_subfinder=$(wc -l "$resultsfolder/passive/subfinder.tmp" | awk '{print $1}')
        	else
                	var_subfinder=0
        	fi
        	if test -f "$resultsfolder/passive/crt.tmp"; then
                	var_crt=$(wc -l "$resultsfolder/passive/crt.tmp" | awk '{print $1}')
        	else
                	var_crt=0
        	fi
        	if test -f "$resultsfolder/passive/threatcrowd.tmp"; then
                	var_threatcrowd=$(wc -l "$resultsfolder/passive/threatcrowd.tmp" | awk '{print $1}')
        	else
                	var_threatcrowd=0
        	fi
        	if test -f "$resultsfolder/passive/hackertarget.tmp"; then
                	var_hackertarget=$(wc -l "$resultsfolder/passive/hackertarget.tmp" | awk '{print $1}')
        	else
                	var_hackertarget=0
        	fi
        	if test -f "$resultsfolder/passive/dnscan.tmp"; then
                	var_dnscan=$(wc -l "$resultsfolder/passive/dnscan.tmp" | awk '{print $1}')
        	else
                	var_dnscan=0
        	fi
        	if test -f "$resultsfolder/passive/censys.tmp"; then
                	var_censys=$(wc -l "$resultsfolder/passive/censys.tmp" | awk '{print $1}')
        	else
                	var_censys=0
        	fi
        	if test -f "$resultsfolder/passive/shuffledns.tmp"; then
                	var_shuffle=$(wc -l "$resultsfolder/passive/shuffledns.tmp" | awk '{print $1}')
        	else
                	var_shuffle=0
        	fi
        	if test -f "$resultsfolder/passivesubdomains.tmp"; then
                	var_passive=$(wc -l "$resultsfolder/passivesubdomains.tmp" | awk '{print $1}')
        	else
                	var_passive=0
        	fi
        	if test -f "$resultsfolder/massdnsBrute.tmp"; then
                	var_massdns=$(wc -l "$resultsfolder/massdnsBrute.tmp" | awk '{print $1}')
        	else
                	var_massdns=0
                	touch "$resultsfolder/massdnsBrute.tmp"
        	fi
        	printf "${RED}Domain: ${i}${NC}\n"
        	printf "Assetfinder ........... ${var_assetfinder}\n"
        	printf "Subfinder ............. ${var_subfinder}\n"
        	printf "crt.sh ................ ${var_crt}\n"
       		printf "Threatcrowd ........... ${var_threatcrowd}\n"
        	printf "Hackertarget .......... ${var_hackertarget}\n"
        	printf "Dnscan ................ ${var_dnscan}\n"
        	printf "Censys ................ ${var_censys}\n"
        	printf "ShuffleDNS ............ ${var_shuffle}\n"
        	if [ $var_massdns -lt 500 ]
        	then
                	printf "Massdns ............... ${var_massdns}\n"
                	cat "$resultsfolder/massdnsBrute.tmp" "$resultsfolder/passivesubdomains.tmp" | sort -u >> "$resultsfolder/target.txt"
                	if test -f "$resultsfolder/target.txt"; then
                        	var_target=$(wc -l "$resultsfolder/target.txt" | awk '{print $1}')
                	else
                        	var_target=0
                	fi
                	printf "TOTAL (inc. Massdns)... ${var_target}\n"
        	else
                	printf "Massdns ......... ${var_massdns}${RED}     CHECK FOR WILDCARDS!! ${WHITE}\n"
                	cat "$resultsfolder/passivesubdomains.tmp" "$resultsfolder/target.txt" | sort -u >> "$resultsfolder/target.txt"
                	printf "TOTAL (w/o Massdns).... ${var_passive}\n"
        	fi
        	cat "$resultsfolder/target.txt" | grep -P '^(?:[a-z0-9]+\.){2}[^.]*$' | sort -u > "$resultsfolder/thirdlevelsubs.txt"
        	if test -f "$resultsfolder/thirdlevelsubs.txt"; then
                	var_third=$(wc -l "$resultsfolder/thirdlevelsubs.txt" | awk '{print $1}')
        	else
                	var_third=0
        	fi
        	if [ $var_third -lt 600 ] && [ $var_third != 0 ]
        	then
                	for j in $(cat "$resultsfolder/thirdlevelsubs.txt")
                	do
                        	curl -s https://crt.sh/\?q=\%.$j\&output\=json | jq -r '.[].name_value' | sed 's/\*\.//g' | grep -v "*\|@\|#\|---" | sort -u >> $resultsfolder/thirdlevelsubs_crt.tmp
                	done
                	cat "$resultsfolder/thirdlevelsubs_crt.tmp" "$resultsfolder/target.txt" | sort -u > "$resultsfolder/temp.tmp"
	        	mv "$resultsfolder/temp.tmp" "$resultsfolder/target.txt"
        	fi
	done
	cat $resultsfolder/target.txt | sort -u >> $resultsfolder/../targets_aux.txt
	cat $resultsfolder/../targets_aux.txt | sort -u >> $resultsfolder/../targets.txt
	rm $resultsfolder/../targets_aux.txt
	rm $resultsfolder/../tmp/targets_aux.txt
