module=$(echo $0 | awk -F '/' '{print $NF}' | sed "s/\.[^\.]*$//g")
deepnuclei=1
target=$1
nuclei --update &> /dev/null
nuclei -ut &> /dev/null
resultsfolder=$2$(echo $target | sed 's/\//-/g')/$3/$module
mkdir -p $resultsfolder/
#Generating file with all the URLs to fuzz
echo -e "Executing nuclei for URLs found for "$target
if [[ $deep_nuclei == 1 ]]; then
	cat $resultsfolder/../tmp/all-urls-fuzzing-results.txt | sort -u >> $resultsfolder/nuclei-urls.txt
	cat $resultsfolder/../tmp/full-initial-files.txt | sort -u >> $resultsfolder/nuclei-urls.txt
else
	cat $resultsfolder/../tmp/full-initial-files.txt | sort -u >> $resultsfolder/nuclei-urls.txt
fi
nuclei -update &> /dev/null
nuclei -ut &> /dev/null
echo -e "Info severity (No output on tty)"
nuclei -l $resultsfolder/nuclei-urls.txt -t ~/nuclei-templates -o $resultsfolder/nuclei-report-info.txt -silent -s info &> /dev/null
echo -e "Low severity"
nuclei -l $resultsfolder/nuclei-urls.txt -t ~/nuclei-templates -o $resultsfolder/nuclei-report-low.txt -silent -s low
echo -e "Medium severity"
nuclei -l $resultsfolder/nuclei-urls.txt -t ~/nuclei-templates -o $resultsfolder/nuclei-report-medium.txt -silent -s medium
echo -e "High severity"
nuclei -l $resultsfolder/nuclei-urls.txt -t ~/nuclei-templates -o $resultsfolder/nuclei-report-high.txt -silent -s high
echo -e "Critical severity"
nuclei -l $resultsfolder/nuclei-urls.txt -t ~/nuclei-templates -o $resultsfolder/nuclei-report-critical.txt -silent -s critical
