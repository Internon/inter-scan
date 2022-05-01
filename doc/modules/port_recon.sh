#Delete unused variables
module=$(echo $0 | awk -F '/' '{print $NF}' | sed "s/\.[^\.]*$//g")
target=$1
SUB_MODULES_FOLDER=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../sub-modules
conf_folder=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../conf
resultsfolder=$2$(echo $target | sed 's/\//-/g')/$3/$module
companynamefile=$resultsfolder/../tmp/company_name.txt
mkdir $resultsfolder
#	{INSERT CODE HERE}
