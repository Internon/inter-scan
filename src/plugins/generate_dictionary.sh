module=$(echo $0 | awk -F '/' '{print $NF}' | sed "s/\.[^\.]*$//g")
target=$1
SPEED=$3
SUB_MODULES_FOLDER=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../sub-modules
resultsfolder=$2$target/$SPEED/$module
companynamefile=$resultsfolder/../tmp/company_name.txt
dictfolder=$resultsfolder/dict
echo "Generating dictionary"
mkdir -p $resultsfolder/dict
if [ -f $companynamefile ]; then
	python $SUB_MODULES_FOLDER/CrossLinked/crosslinked.py "$(cat $companynamefile)" -j 1 -t 60 -f "{first} {last}" -o $resultsfolder/companyusers_first_space_last.txt &> /dev/null
	cat $resultsfolder/companyusers_first_space_last.txt | sed 's/\(.*\) \(.*\)/\1.\2/g' | sort -u > $resultsfolder/companyusers_first_dot_last.txt
	cat $resultsfolder/companyusers_first_space_last.txt | sed 's/\(.\).* \(.*\)/\1\2/g' | sort -u > $resultsfolder/companyusers_flast.txt
	# TO-DO check users validity, when it is done, add valid usernames to default_wordlist.txt
	cat $resultsfolder/companyusers_first_dot_last.txt $resultsfolder/companyusers_flast.txt | sed 's/,:,$//g' | sed 's/,:,/\n/g' | sort -u > $dictfolder/companyusers_without_validation.txt
#	cat $SUB_MODULES_FOLDER/cupp/default_wordlist.txt $resultsfolder/companyusers_without_validation.txt | sort -u > $resultsfolder/aux_wordlist_passwords.txt
	cat $SUB_MODULES_FOLDER/cupp/default_wordlist.txt > $resultsfolder/aux_wordlist_passwords.txt
	cat $companynamefile >> $resultsfolder/aux_wordlist_passwords.txt
	cat $companynamefile | sed 's/ /\n/g' >> $resultsfolder/aux_wordlist_passwords.txt
	cat $companynamefile | sed 's/ /\n/g' | tr '[:upper:]' '[:lower:]' | awk '{$1=toupper(substr($1,0,1))substr($1,2)}1' >> $resultsfolder/aux_wordlist_passwords.txt
	cat $companynamefile | sed 's/ /\n/g' | tr '[:lower:]' '[:upper:]' >> $resultsfolder/aux_wordlist_passwords.txt
	cat $companynamefile | sed 's/ /\n/g' | awk '{$1=toupper(substr($1,0,1))substr($1,2)}1' >> $resultsfolder/aux_wordlist_passwords.txt
	cat $companynamefile | tr '[:upper:]' '[:lower:]' >> $resultsfolder/aux_wordlist_passwords.txt
	cat $companynamefile | tr '[:lower:]' '[:upper:]' >> $resultsfolder/aux_wordlist_passwords.txt
        cat $companynamefile | tr '[:upper:]' '[:lower:]' | awk '{$1=toupper(substr($1,0,1))substr($1,2)}1' >> $resultsfolder/aux_wordlist_passwords.txt
else
	cat $SUB_MODULES_FOLDER/cupp/default_wordlist.txt > $resultsfolder/aux_wordlist_passwords.txt
fi
cat $resultsfolder/../targets.txt | sed 's/\.*[^\.]*$//g' | sed 's/\./\n/g' | sort -u >> $resultsfolder/aux_wordlist_passwords.txt
cat $resultsfolder/aux_wordlist_passwords.txt | sort -u > $dictfolder/passwords_small.txt
cp $dictfolder/passwords_small.txt $resultsfolder/aux_wordlist_passwords.txt
python $SUB_MODULES_FOLDER/cupp/cupp-med.py -w $resultsfolder/aux_wordlist_passwords.txt -q &> /dev/null
mv $resultsfolder/aux_wordlist_passwords.txt.cupp.txt $dictfolder/passwords_medium.txt 
python $SUB_MODULES_FOLDER/cupp/cupp-big.py -w $resultsfolder/aux_wordlist_passwords.txt -q &> /dev/null
mv $resultsfolder/aux_wordlist_passwords.txt.cupp.txt $dictfolder/passwords_big.txt
rm $resultsfolder/aux_wordlist_passwords.txt #When adding users validation, remove the auxiliar files to get the correct users
