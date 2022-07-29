module=$(echo $0 | awk -F '/' '{print $NF}' | sed "s/\.[^\.]*$//g")
target=$1
SUB_MODULES_FOLDER=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../sub-modules
conf_folder=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../conf
resultsfolder=$2$(echo $target | sed 's/\//-/g')/$3/$module
companynamefile=$resultsfolder/../tmp/company_name.txt
mkdir $resultsfolder
$SUB_MODULES_FOLDER/GitDorker/GitDorker.py -tf $conf_folder/GitTokens/TOKENSFILE -o $resultsfolder/GitDorker-company-name.txt -p -q $(cat $companynamefile) -d $SUB_MODULES_FOLDER/GitDorker/Dorks/alldorksv3
if [ $3 == "quick" ]; then
	echo "Executing GitDorker only with company name"
	$SUB_MODULES_FOLDER/GitDorker/GitDorker.py -tf $conf_folder/GitTokens/TOKENSFILE -o $resultsfolder/GitDorker-company-name.txt -p -q $(cat $companynamefile) -d $SUB_MODULES_FOLDER/GitDorker/Dorks/alldorksv3
elif [ $3 == "medium" ]; then
	echo "Executing GitDorker with company name and the target "$target
	$SUB_MODULES_FOLDER/GitDorker/GitDorker.py -tf $conf_folder/GitTokens/TOKENSFILE -o $resultsfolder/GitDorker-company-name.txt -p -q $(cat $companynamefile) -d $SUB_MODULES_FOLDER/GitDorker/Dorks/alldorksv3
	if [[ $target =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                echo "Target is an IP so we will pass this target"
        elif [[ $target =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\/[0-9]+$ ]]; then
                echo "Target is a network so we will pass this target"
        else
                echo "Target is a domain "
		$SUB_MODULES_FOLDER/GitDorker/GitDorker.py -tf $conf_folder/GitTokens/TOKENSFILE -o $resultsfolder/GitDorker-target.txt -p -q $target -d $SUB_MODULES_FOLDER/GitDorker/Dorks/alldorksv3
        fi
elif [ $3 == "slow" ]; then
	echo "Executing GitDorker with company name and all the domains found during domain recon"
	$SUB_MODULES_FOLDER/GitDorker/GitDorker.py -tf $conf_folder/GitTokens/TOKENSFILE -o $resultsfolder/GitDorker-company-name.txt -p -q $(cat $companynamefile) -d $SUB_MODULES_FOLDER/GitDorker/Dorks/alldorksv3
	for domain in $(cat $resultsfolder/../targets.txt)
	do
		$SUB_MODULES_FOLDER/GitDorker/GitDorker.py -tf $conf_folder/GitTokens/TOKENSFILE -o $resultsfolder/GitDorker-$domain.txt -p -q $domain -d $SUB_MODULES_FOLDER/GitDorker/Dorks/alldorksv3
	done
else
	echo "Not correct speed chosen, exiting the module"
	exit 1
fi
