
TARGETFILE=$1
WORKING_FOLDER=$2
module=$(echo $3 | sed "s/\.[^\.]*$//g")
if [ ! -d "$WORKING_FOLDER"old ]; then
        mkdir $WORKING_FOLDER"old"
fi
for target in $(cat $TARGETFILE)
do
	for SPEED in $(cat $WORKING_FOLDER$(echo $target | sed 's/\//-/g')"/tmp/scan_speed.txt")
	do
		echo "Generating folder structure for "$target" with speed "$SPEED
		if [ -d "$WORKING_FOLDER$(echo $target | sed 's/\//-/g')/$SPEED" ]; then
			if [[ -z $module ]]; then
				echo "Folder $(echo $target | sed 's/\//-/g') with speed $SPEED exist, moving it to old folder and creating the new one"
				datenow=`date +%Y-%m-%d-%H-%M-%S`
				mkdir -p $WORKING_FOLDER"old/"$(echo $target | sed 's/\//-/g')"_"$datenow/
				mv $WORKING_FOLDER$(echo $target | sed 's/\//-/g')/$SPEED $WORKING_FOLDER"old/"$(echo $target | sed 's/\//-/g')"_"$datenow/$SPEED
				mkdir -p $WORKING_FOLDER$(echo $target | sed 's/\//-/g')/$SPEED/tmp
			else
				if [ -d "$WORKING_FOLDER$(echo $target | sed 's/\//-/g')/$SPEED/$module" ]; then
					echo "Folder $(echo $target | sed 's/\//-/g') with speed $SPEED exist, coping it to old folder and removing the $module folder"
                        		datenow=`date +%Y-%m-%d-%H-%M-%S`
                        		cp -r $WORKING_FOLDER$(echo $target | sed 's/\//-/g') $WORKING_FOLDER"old/"$(echo $target | sed 's/\//-/g')"_"$datenow
					rm -rf $WORKING_FOLDER$(echo $target | sed 's/\//-/g')/$SPEED/$module
				fi
			fi
		else
			mkdir -p $WORKING_FOLDER$(echo $target| sed 's/\//-/g')/$SPEED/tmp
		fi
		INTERINITFOLDER=$WORKING_FOLDER$(echo $target| sed 's/\//-/g')/$SPEED
		echo $target >> $INTERINITFOLDER/targets.txt
	done
done
