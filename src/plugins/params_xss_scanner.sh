#!/bin/bash

# Roberto Reigada
# 01/2021

# REQUIREMENTS
# -----------------------------------
# Arjun 1.6 (Only this version) - https://github.com/s0md3v/Arjun/releases/tag/1.6
# GAU - https://github.com/lc/gau
# Waybackurls - https://github.com/tomnomnom/waybackurls
# GoSpider - https://github.com/jaeles-project/gospider
# Qsreplace - https://github.com/tomnomnom/qsreplace
# httpx - https://github.com/projectdiscovery/httpx
# -----------------------------------
module=$(echo $0 | awk -F '/' '{print $NF}' | sed "s/\.[^\.]*$//g")
SUB_MODULES_FOLDER=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../sub-modules
target=$1
RED='\033[0;31m'
WHITE='\e[37m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'
resultsfolder=$2$(echo $target | sed 's/\//-/g')/$3/$(echo $module | sed 's/^[0-9]*_//g')
mkdir -p $resultsfolder
urlsFile=$2$(echo $target | sed 's/\//-/g')/$3/tmp/full-urls.txt
c=0

for i in $(cat $urlsFile)
do
	greppedURL=$(echo $i |sed 's/https\?:\/\///')
	c=$((c+1))
	exec >/dev/null 2>&1; timeout 15m arjun -u $i -o "$resultsfolder/$c"; exec >/dev/tty; exec 2>/dev/tty
	if test -f "$resultsfolder/$c"; then
		cat "$resultsfolder/$c" | jq -r '.[].params[]' | tr -d \"\|,\|[\|] | awk NF > tmp.txt; mv tmp.txt "$resultsfolder/$c"
	fi
	if test -f "$resultsfolder/$c"; then
		var_params=$(wc -l "$resultsfolder/$c" | awk '{print $1}')
	else
		var_params=0
	fi
	# Sometimes arjun find 500+ parameters. To avoid this issue we use the -lt 20
	if [ $var_params -gt 0 ] && [ $var_params -lt 20 ];
	then
		cat "$resultsfolder/$c" &> /dev/null
	else
		rm -rf "$resultsfolder/$c"
	fi
	# Individual parameter
	if test -f "$resultsfolder/$c"; then
		for param in $(cat "$resultsfolder/$c")
		do
			if [ $param != "{}" ]
			then
				echo "&$param=FUZZ" >> "$resultsfolder/${c}_parameters.txt"
			fi
		done
		# Multiple parameters
		var=""
		for param in $(cat "$resultsfolder/$c")
		do
			if [ $param != "{}" ]
			then
				var=$var"&$param=FUZZ"
			fi
		done
		echo $var >> "$resultsfolder/${c}_parameters.txt"
		cat "$resultsfolder/${c}_parameters.txt" | sort -u > "$resultsfolder/${c}_temp.txt"; mv "$resultsfolder/${c}_temp.txt" "$resultsfolder/${c}_parameters.txt"
		rm -rf "$resultsfolder/$c"
	fi
	# GAU + Waybackurls + GoSpider
	exec >/dev/null 2>&1; timeout 5m gau -o "$resultsfolder/${c}_crawl_results.txt" $i; exec >/dev/tty; exec 2>/dev/tty
	exec >/dev/null 2>&1; timeout 5m echo "$i" | waybackurls >> "$resultsfolder/${c}_crawl_results.txt"; exec >/dev/tty; exec 2>/dev/tty
	exec >/dev/null 2>&1; timeout 5m gospider -q -s $i -d 2 --user-agent web | tr " " "\n" | grep "http://\|https://" >> "$resultsfolder/${c}_crawl_results.txt"; exec >/dev/tty; exec 2>/dev/tty
	# With the grep -i we remove all the out of scope crawled URLs
	cat "$resultsfolder/${c}_crawl_results.txt" | grep -i "$greppedURL" | sort -u > "$resultsfolder/${c}_tmp.txt"
	mv "$resultsfolder/${c}_tmp.txt" "$resultsfolder/${c}_crawl_results.txt"
	if test -f "$resultsfolder/${c}_crawl_results.txt"; then
		var_urls=$(wc -l "$resultsfolder/${c}_crawl_results.txt" | awk '{print $1}')
	else
		var_urls=0
	fi
	# For each URL adding the ones bruteforced individually and all together
	for url in $(cat "$resultsfolder/${c}_crawl_results.txt")
	do
		echo $url >> "$resultsfolder/${c}_urls_checked.txt"
		if test -f "$resultsfolder/${c}_parameters.txt"; then
			for paramline in $(cat "$resultsfolder/${c}_parameters.txt")
			do
				# If url contains parameters already we add &...
				if grep -q "=" <<<"$url"; then
					echo $url$paramline >> "$resultsfolder/${c}_urls_checked.txt"
				else
					# If the url does not contain any parameter we need to start the parameter with ? instead of &
					paramline="${paramline:1}"
					echo "$url?$paramline" >> "$resultsfolder/${c}_urls_checked.txt"
				fi
			done
		fi
	done
	exec >/dev/null 2>&1; cat "$resultsfolder/${c}_urls_checked.txt" | grep -i "=" | qsreplace "\"';<>bugbb" | httpx -silent -match-regex "[\"';<>].?.?.?.?bugbb" -threads 50 >> "$resultsfolder/${c}_reflection_results.txt"; exec >/dev/tty; exec 2>/dev/tty
	if test -f "$resultsfolder/${c}_reflection_results.txt"; then
		var_reflection=$(wc -l "$resultsfolder/${c}_reflection_results.txt" | awk '{print $1}')
	else
		var_reflection=0
	fi
	if [ $var_reflection -gt 0 ]
	then
		for reflection in $(cat "$resultsfolder/${c}_reflection_results.txt")
		do
			echo $reflection | httpx -silent -match-regex "\"';<>bugbb" > "$resultsfolder/${c}_temp.txt"
			if test -f "$resultsfolder/${c}_temp.txt"; then
				var_fullmatch=$(wc -l "$resultsfolder/${c}_temp.txt" | awk '{print $1}')
			else
				var_fullmatch=0
			fi
			if [ $var_fullmatch -gt 0 ]
			then
				echo $reflection >> "$resultsfolder/${c}_full_reflection_results.txt"
				rm -rf "$resultsfolder/${c}_temp.txt"
			else
				echo $reflection >> "$resultsfolder/${c}_partial_reflection_results.txt"
				rm -rf "$resultsfolder/${c}_temp.txt"
			fi
		done
		if test -f "$resultsfolder/${c}_full_reflection_results.txt"; then
			cat "$resultsfolder/${c}_full_reflection_results.txt" >> "$resultsfolder/full_reflection_results.txt"
		fi
		if test -f "$resultsfolder/${c}_partial_reflection_results.txt"; then
			cat "$resultsfolder/${c}_partial_reflection_results.txt" >> "$resultsfolder/partial_reflection_results.txt"
		fi
	else
		rm -rf "$resultsfolder/${c}_full_reflection_results.txt"
		rm -rf "$resultsfolder/${c}_partial_reflection_results.txt"
	fi
	rm -rf "$resultsfolder/${c}_reflection_results.txt"
done
# Ordering the results
if test -f "$resultsfolder/full_reflection_results.txt"; then
	cat "$resultsfolder/full_reflection_results.txt" | sort -u > "$resultsfolder/t.txt"; mv "$resultsfolder/t.txt" "$resultsfolder/full_reflection_results.txt"; rm -rf "$resultsfolder/t.txt"
fi
if test -f "$resultsfolder/partial_reflection_results.txt"; then
	cat "$resultsfolder/partial_reflection_results.txt" | sort -u > "$resultsfolder/t.txt"; mv "$resultsfolder/t.txt" "$resultsfolder/partial_reflection_results.txt"; rm -rf "$resultsfolder/t.txt"
fi
cat $resultsfolder/*urls_checked.txt $resultsfolder/*crawl_results.txt | sort -u > $resultsfolder/../tmp/full_urls_with_params.txt
