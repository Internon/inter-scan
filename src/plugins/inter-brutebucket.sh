#!/bin/bash
#This script is derived from Roberto Reigada script

RED='\033[0;31m'
WHITE='\033[0;37m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'
module=$(echo $0 | awk -F '/' '{print $NF}' | sed "s/\.[^\.]*$//g")
target=$1
SUB_MODULES_FOLDER=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../sub-modules
conf_folder=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../conf
resultsfolder=$2$(echo $target | sed 's/\//-/g')/$3/$module
mkdir $resultsfolder
companynamefile=$resultsfolder/../tmp/company_name.txt
DICT_FOLDER=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../dicts/
if [ $3 == "quick" ]; then
	echo "Checking buckets with company name"
elif [ $3 == "medium" ]; then
	echo "Checking buckets with company name and the target "$target
	if [[ $target =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
		echo "Target is an IP so we will pass this target"
	elif [[ $target =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\/[0-9]+$ ]]; then
		echo "Target is a network so we will pass this target"
	else
		echo "Target is a domain "
		echo $target >> $resultsfolder/bucketsFile.txt
	fi
elif [ $3 == "slow" ]; then
	echo "Checking buckets with company name and all the domains found for this target"
	cat $resultsfolder/../targets.txt >> $resultsfolder/bucketsFile.txt
else
	echo "Not correct speed chosen, exiting the module"
	exit 1
fi
cat $companynamefile | tr '[:upper:]' '[:lower:]'  >> $resultsfolder/bucketsFile.txt
bucketsFile=$resultsfolder/bucketsFile.txt
dictFile=$DICT_FOLDER"s3.txt"
services=$(echo S3,GS,Azure | sed 's/,/\n/g')

printf "${GREEN}Starting making the dictionary${NC}\n"
for i in $(cat $bucketsFile); do echo $i >> "$resultsfolder/customBucketsWordlist.txt"; done
for i in $(cat $dictFile); do sed -e "s/$/${i}/g" $bucketsFile >> "$resultsfolder/customBucketsWordlist.txt"; done
for i in $(cat $dictFile); do sed -e "s/$/.${i}/g" $bucketsFile >> "$resultsfolder/customBucketsWordlist.txt"; done
for i in $(cat $dictFile); do sed -e "s/$/-${i}/g" $bucketsFile >> "$resultsfolder/customBucketsWordlist.txt"; done
for i in $(cat $dictFile); do sed -e "s/^/${i}/" $bucketsFile >> "$resultsfolder/customBucketsWordlist.txt"; done
for i in $(cat $dictFile); do sed -e "s/^/${i}./" $bucketsFile >> "$resultsfolder/customBucketsWordlist.txt"; done
for i in $(cat $dictFile); do sed -e "s/^/${i}-/" $bucketsFile >> "$resultsfolder/customBucketsWordlist.txt"; done
printf "${GREEN}Starting making the test on the buckets created with our created dictionary${NC}\n"
for service in $services
do
	echo "Checking on service "$service
	$SUB_MODULES_FOLDER/aws-extender-cli/aws_extender_cli.py -f $resultsfolder/customBucketsWordlist.txt -s $service > $resultsfolder/bucket-results-$service.txt
done
printf "${GREEN}Finished the script, please check $resultsfolder/bucket-results-*.txt file${NC}\n"
