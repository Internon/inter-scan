module=$(echo $0 | awk -F '/' '{print $NF}' | sed "s/\.[^\.]*$//g")
target=$1
resultsfolder=$2$(echo $target | sed 's/\//-/g')/$3/$module
mkdir -p $resultsfolder/
#Generating file with all the URLs to fuzz
echo -e "Executing subjack for URLs found for "$target
if test -f "$resultsfolder/../targets.txt"; then
	var_target=$(wc -l "$resultsfolder/../targets.txt" | awk '{print $1}')
else
	var_target=0
fi
printf "Subjack results\n"
if [ $var_target -lt 8000 ]
then
	subjack -w "$resultsfolder/../targets.txt" -t 100 -timeout 30 -o "$resultsfolder/subjack_ssl.txt" -ssl
	subjack -w "$resultsfolder/../targets.txt" -t 100 -timeout 30 -o "$resultsfolder/subjack.txt"
	if [ ! -f "$resultsfolder/subjack.txt" ]
	then
		printf "${GREEN}No subdomain takeovers found\n"
	fi
else
	printf "${GREEN}Subjack scan skipped!\n"
fi
