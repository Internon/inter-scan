module=$(echo $0 | awk -F '/' '{print $NF}' | sed "s/\.[^\.]*$//g")
SUB_MODULES_FOLDER=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../sub-modules
target=$1
burpjar=/home/kali/BurpSuitePro/burpsuite_pro.jar
#burpjar=/opt/BurpSuitePro/burpsuite_pro.jar
#javapath=/opt/BurpSuitePro/jre/bin/java
javapath=/home/kali/BurpSuitePro/jre/bin/java
apikey=3XpCiAVXHcTLMY0LLrXJ48ZqpnrbraaM
userConfigFile=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../conf/userGenericOptions.json
#Important to configure a Resource Pool on the project file to change the default configuration and use more threads and more thorought config
projectfolder=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../conf/burp-project
if [[ ! -d $projectfolder ]]; then
	mkdir $projectfolder
fi	
resultsfolder=$2$(echo $target | sed 's/\//-/g')/$3/$(echo $module | sed 's/^[0-9]*_//g')
mkdir -p $resultsfolder
threads=$(cat $resultsfolder/../tmp/scan_threads.txt)
outputfolder=$resultsfolder/ScanOutput
mkdir -p $outputfolder
echo "Generating config file"
echo "{
    \"sites\" : [" > $resultsfolder/config.json
count=0
for url in $(cat $resultsfolder/../tmp/full-urls.txt)
do 
	if [ $count == 0 ]; then
		count=1
	else
		echo "," >> $resultsfolder/config.json
	fi
	echo "{
        \"scanURL\" : \"$url\",
        \"project\" : \"$projectfolder/scan-project.burp\",
        \"apikey\" : \"$apikey\",
	\"userburpfile\" : \"$userConfigFile\"
}" >> $resultsfolder/config.json
done
echo "
    ],
    \"burpConfigs\" : [{
        \"memory\" : \"4096m\",
        \"headless\" : \"true\",
	\"java\" : \"$javapath\",
        \"burpJar\" : \"$burpjar\",
        \"retry\" : 10,
        \"logPath\" : \"$outputfolder\",
        \"logfileName\" : \"SimpleAutoBurp\",
        \"loglevel\" : \"info\",
        \"ScanOutput\" : \"$outputfolder\"
      }
      ]
}" >> $resultsfolder/config.json
python $SUB_MODULES_FOLDER/SimpleAutoBurp/SimpleAutoBurp.py $resultsfolder/config.json
cp $projectfolder/scan-project.burp $resultsfolder/scan-project-$(echo $target | sed 's/\//-/g').burp
cp $projectfolder/2022-05-23-scan-project-backup.burp $projectfolder/scan-project.burp
