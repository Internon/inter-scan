#!/bin/bash
#Wrote by Mario Sala - INTERNON
declare -A modules_dict
declare -A plugins_dict
declare -A modules_association
declare -A modules_association_fullscan
function initvariables(){
	MODULES_FOLDER=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/src/modules/
	PLUGINS_FOLDER=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/src/plugins/
	INTEREXCLUDEDOMAINS=0
        BlueColor="\e[96m"
        OrangeColor="\e[33m"
        ResetColor="\e[0m"
        RedColor="\e[91m"
        GreenColor="\e[32m"
	PurpleColor="\e[35m"
}
function foldervariables(){
	WORKING_FOLDER=$(pwd)/inter-output-scan/
	for target in $(cat $INTERTARGETFILE); do
		if [ ! -d "$WORKING_FOLDER" ]; then
			mkdir -p $WORKING_FOLDER$(echo $target | sed 's/\//-/g')"/tmp"
		else
			if [ ! -d "$WORKING_FOLDER$(echo $target | sed 's/\//-/g')"/tmp ]; then
				mkdir -p $WORKING_FOLDER$(echo $target | sed 's/\//-/g')'/tmp'
			else
				rm -rf $WORKING_FOLDER$(echo $target | sed 's/\//-/g')'/tmp'
				mkdir -p $WORKING_FOLDER$(echo $target | sed 's/\//-/g')"/tmp"
			fi
		fi
	done

}

function displaytime {
        local T=$1
        local D=$((T/60/60/24))
        local H=$((T/60/60%24))
        local M=$((T/60%60))
        local S=$((T%60))
        timecalc=""
        (( $D > 0 )) && stringreturn="$timecalc $D days "
        (( $H > 0 )) && stringreturn="$timecalc $H hours "
        (( $M > 0 )) && timecalc="$timecalc $M minutes "
        timecalc="$timecalc $S seconds"
}
function banner(){
	echo "------------   INTERNON   ------------------"
}
function programhelp(){
	banner
        echo "Usage: $0 [OPTIONS]"
        echo "  Options:"
        echo "          -T {file with targets by line}"
        echo "          -t {IP or IP/CIDR or domain}"
	echo "          -m {all/MODULE-NUMBER (Check the number on -l parameter)}"
	echo "          -s {all/SPEED-NUMBER} (Check the number on -l parameter) Important: slower is thorough"
	echo "          -l {any} List modules and speed"
	echo "          -i Interactive execution"
	echo "          -c {company name} for extra recon"
	echo "          -e exclude domain recon, just perform the target"
        echo "  Examples:"
        echo "          $0 -t 127.0.0.1 -s all -m all -c {COMPANY}"
	echo "          $0 -l any"
        echo "          $0 -T targets.txt -m all -c {COMPANY}"

}
function loadmodules(){
	for file in $(ls $MODULES_FOLDER ); do
		modules_dict[$(echo $file | sed "s/\.[^\.]*$//g")]=$file
	done
}
function loadplugins(){
        for file in $(ls -r $PLUGINS_FOLDER ); do
                plugins_dict[$(echo $file | sed "s/\.[^\.]*$//g")]=$file
        done
}
function associatemodulesandplugins(){
	module_num=1
        for key in "${!modules_dict[@]}"; do
                if [[ "$key" != "make_folder_structure" ]]; then
                        modules_association[$module_num]=${modules_dict[$key]}
                        module_num=$(($module_num+1))
                fi
        done
	for key in "${!plugins_dict[@]}"; do
		modules_association[$module_num]=${plugins_dict[$key]}
		module_num=$(($module_num+1))
	done
}
function listspeed(){
	echo "-------- SCAN SPEED MENU ---------"
	echo "Select from the menu:"
	echo "   0) Return to main menu"
	echo "   1) all"
	echo "   2) quick"
	echo "   3) medium"
	echo "   4) slow"
}
function generatespeedfile(){
	if [ $1 == "1" ]; then
		echo "all speed chosen, we will make an execution of each speed starting by quick"
		for target in $(cat $INTERTARGETFILE); do
			echo "quick" > $WORKING_FOLDER$(echo $target | sed 's/\//-/g')"/tmp/scan_speed.txt"
			echo "medium" >> $WORKING_FOLDER$(echo $target | sed 's/\//-/g')"/tmp/scan_speed.txt"
			echo "slow" >> $WORKING_FOLDER$(echo $target | sed 's/\//-/g')"/tmp/scan_speed.txt"
		done
	elif [ $1 == "2" ]; then
		for target in $(cat $INTERTARGETFILE); do
			echo "quick" > $WORKING_FOLDER$(echo $target | sed 's/\//-/g')"/tmp/scan_speed.txt"
		done
	elif [ $1 == "3" ]; then
		for target in $(cat $INTERTARGETFILE); do
			echo "medium" > $WORKING_FOLDER$(echo $target | sed 's/\//-/g')"/tmp/scan_speed.txt"
		done
	elif [ $1 == "4" ]; then
		for target in $(cat $INTERTARGETFILE); do
			echo "slow" > $WORKING_FOLDER$(echo $target | sed 's/\//-/g')"/tmp/scan_speed.txt"
		done
	else
		echo -e $RedColor"Bad speed choosen, the speed parameter must be a number or all"$ResetColor
	fi
}

function printmenu(){
	echo "--------- MAIN INTERACTIVE MENU ------------"
	echo "Select from the menu:"
	echo "   1) Exit"
	echo "   2) Help (Print this message)"
	echo "   3) All scan (It will execute all files from src/modules/)"
	echo "   4) List modules"
	echo "   5) List speed"
}

function listmodules(){
	echo "-------- MODULES MENU ---------"
	echo "Select from the menu:"
	module_num=1
	echo "   0) Return to main menu"
	for key in "${!modules_dict[@]}"; do
		if [[ "$key" != "make_folder_structure" ]]; then
			echo "   $module_num) $key module"
			module_num=$(($module_num+1))
		fi
	done
	echo "Plugins:"
	for key in "${!plugins_dict[@]}"; do
		echo "   $module_num) $key plugin"
		module_num=$(($module_num+1))
	done
}

function validateaction(){
	action=$1
	re='^[0-9]+$'
	if ! [[ $action =~ $re ]] ; then
		echo -e $RedColor"[ERROR] - The action must be a number "$ResetColor
		validaction=1
	fi
	validaction=0

}
function targetscan(){
	echo "[INFO] - We are executing the following scripts in this order:"
        echo "   1 - port_recon.sh"
        modules_association_fullscan[1]="port_recon.sh"
        echo "   2 - vulnerability_recon.sh"
        modules_association_fullscan[2]="vulnerability_recon.sh"
        echo "   3 - make_documentation.sh"
        modules_association_fullscan[3]="make_documentation.sh"
        echo "   4 - web_recon.sh"
        modules_association_fullscan[4]="web_recon.sh"
        execution_num=5
        for key in "${!modules_dict[@]}"; do
                if [[ ! " ${modules_association_fullscan[*]} " =~ " ${modules_dict[$key]} " ]] && [[ "$key" != "make_folder_structure" ]] && [[ "$key" != "domain_recon" ]]; then
                        echo "   $execution_num - ${modules_dict[$key]}"
                        modules_association_fullscan[$execution_num]=${modules_dict[$key]}
                        execution_num=$(($execution_num+1))
                fi
        done
	if [[ -z $INTERTARGETFILE ]] && [[ -z $INTERTARGET ]]; then
                echo -e $OrangeColor"[WARNING] - It is needed an IP or domain to continue with the execution"$ResetColor
                while true
                do
                        echo -e $BlueColor"> Add the target or the target file path:"$ResetColor
                        read target
                        if [ -f $target ]; then
                                echo -e "Target file found"
                                INTERTARGETFILE=$target
                                echo -e $GreenColor"[INFO] - Executing file "$MODULES_FOLDER"make_folder_structure.sh"$ResetColor
                                startexecution=`date +%s`
				$MODULES_FOLDER"make_folder_structure.sh" $INTERTARGETFILE $WORKING_FOLDER
                                endexecution=`date +%s`
                                displaytime `expr $endexecution - $startexecution`
                                echo -e $PurpleColor"[INFO] - Execution time of the file:$timecalc."$ResetColor
                                break
                        else
                                re='^(0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))\.){3}.[0-2]?[0-9]|'
                                re+='0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))$'
                                re2='^[A-Za-z0-9\-\.]+'
                                if [[ ! "$target" =~ $re ]] && [[ ! "$target" =~ $re2 ]]; then
                                        echo -e $RedColor"[ERROR] - Target should be an IP, IP/CIDR or domain or target file not found"$ResetColor
                                else
                                        echo -e "Target is correct"
                                        INTERTARGET=$target
                                        echo $INTERTARGET > $(pwd)/target.txt
                                        INTERTARGETFILE=$(pwd)/target.txt
                                        echo -e $GreenColor"[INFO] - Executing file "$MODULES_FOLDER"make_folder_structure.sh"$ResetColor
                                        startexecution=`date +%s`
					$MODULES_FOLDER"make_folder_structure.sh" $INTERTARGETFILE $WORKING_FOLDER
                                        endexecution=`date +%s`
                                        displaytime `expr $endexecution - $startexecution`
                                        echo -e $PurpleColor"[INFO] - Execution time of the file:$timecalc."$ResetColor
                                        break
                                fi
                        fi
                done
        fi
	for target in $(cat $INTERTARGETFILE); do
        	for speed in $(cat $WORKING_FOLDER$(echo $target | sed 's/\//-/g')"/tmp/scan_speed.txt"); do
                        echo $INTERCOMPANYNAME > $WORKING_FOLDER$(echo $target | sed 's/\//-/g')/$speed/tmp/company_name.txt
                	echo "EXECUTING SPEED "$speed
                	for module_number in $(seq 1 $(($execution_num-1))); do
                        	execute_module ${modules_association_fullscan[$module_number]} $speed $target
                	done
        	done
        	for speed in $(cat $WORKING_FOLDER$(echo $target | sed 's/\//-/g')"/tmp/scan_speed.txt"); do
                	echo "EXECUTING SPEED "$speed
                	for key in "${!plugins_dict[@]}"; do
                        	execute_plugin ${plugins_dict[$key]} $speed $target
                	done
        	done
	done
}

function fullscan(){
	echo "[INFO] - We are executing the following scripts in this order:"
	echo "   1 - domain_recon.sh"
	modules_association_fullscan[1]="domain_recon.sh"
	echo "   2 - port_recon.sh"
	modules_association_fullscan[2]="port_recon.sh"
	echo "   3 - vulnerability_recon.sh"
	modules_association_fullscan[3]="vulnerability_recon.sh"
	echo "   4 - make_documentation.sh"
	modules_association_fullscan[4]="make_documentation.sh"
	echo "   5 - web_recon.sh"
	modules_association_fullscan[5]="web_recon.sh"
	execution_num=6
	for key in "${!modules_dict[@]}"; do
		if [[ ! " ${modules_association_fullscan[*]} " =~ " ${modules_dict[$key]} " ]] && [[ "$key" != "make_folder_structure" ]]; then
			echo "   $execution_num - ${modules_dict[$key]}"
			modules_association_fullscan[$execution_num]=${modules_dict[$key]}
			execution_num=$(($execution_num+1))
		fi
        done
	if [[ -z $INTERTARGETFILE ]] && [[ -z $INTERTARGET ]]; then
		echo -e $OrangeColor"[WARNING] - It is needed an IP or domain to continue with the execution"$ResetColor
		while true
		do
			echo -e $BlueColor"> Add the target or the target file path:"$ResetColor
			read target
			if [ -f $target ]; then
				echo -e "Target file found"
				INTERTARGETFILE=$target
				echo -e $GreenColor"[INFO] - Executing file "$MODULES_FOLDER"make_folder_structure.sh"$ResetColor
				startexecution=`date +%s`
				$MODULES_FOLDER"make_folder_structure.sh" $INTERTARGETFILE $WORKING_FOLDER
				endexecution=`date +%s`
				displaytime `expr $endexecution - $startexecution`
				echo -e $PurpleColor"[INFO] - Execution time of the file:$timecalc."$ResetColor
				break
			else
				re='^(0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))\.){3}.[0-2]?[0-9]|'
                                re+='0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))$'
                                re2='^[A-Za-z0-9\-\.]+'
                                if [[ ! "$target" =~ $re ]] && [[ ! "$target" =~ $re2 ]]; then
                                        echo -e $RedColor"[ERROR] - Target should be an IP, IP/CIDR or domain or target file not found"$ResetColor
                                else
                                        echo -e "Target is correct"
					INTERTARGET=$target
                                        echo $INTERTARGET > $(pwd)/target.txt
                                        INTERTARGETFILE=$(pwd)/target.txt
                                        echo -e $GreenColor"[INFO] - Executing file "$MODULES_FOLDER"make_folder_structure.sh"$ResetColor
                                        startexecution=`date +%s`
					$MODULES_FOLDER"make_folder_structure.sh" $INTERTARGETFILE $WORKING_FOLDER
                                        endexecution=`date +%s`
                                        displaytime `expr $endexecution - $startexecution`
                                        echo -e $PurpleColor"[INFO] - Execution time of the file:$timecalc."$ResetColor
                                        break
                                fi
                        fi
                done
        fi

	for target in $(cat $INTERTARGETFILE); do
		for speed in $(cat $WORKING_FOLDER$(echo $target | sed 's/\//-/g')"/tmp/scan_speed.txt"); do
			echo $INTERCOMPANYNAME > $WORKING_FOLDER$(echo $target | sed 's/\//-/g')/$speed/tmp/company_name.txt
			echo "EXECUTING SPEED "$speed
			for module_number in $(seq 1 $(($execution_num-1))); do
				execute_module ${modules_association_fullscan[$module_number]} $speed $target
			done
		done
		for speed in $(cat $WORKING_FOLDER$(echo $target | sed 's/\//-/g')"/tmp/scan_speed.txt"); do
                	echo "EXECUTING SPEED "$speed
                	for key in "${!plugins_dict[@]}"; do
                        	execute_plugin ${plugins_dict[$key]} $speed $target
                	done
        	done
	done
}
function execute_module(){
	if [[ -z $INTERTARGETFILE ]] && [[ -z $INTERTARGET ]]; then
		echo -e $OrangeColor"[WARNING] - It is needed an IP or domain to continue with the execution"$ResetColor
		while true
		do
			echo -e $BlueColor"> Add the target or the target file path:"$ResetColor
			read target
			if [ -f $target ]; then
				echo -e "Target file found"
				INTERTARGETFILE=$target
				echo -e $GreenColor"[INFO] - Executing file "$MODULES_FOLDER"make_folder_structure.sh"$ResetColor
				startexecution=`date +%s`
				$MODULES_FOLDER"make_folder_structure.sh" $INTERTARGETFILE $WORKING_FOLDER
				endexecution=`date +%s`
				displaytime `expr $endexecution - $startexecution`
				echo -e $PurpleColor"[INFO] - Execution time of the file:$timecalc."$ResetColor
				break
			else
				re='^(0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))\.){3}.[0-2]?[0-9]|'
        			re+='0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))$'
        			re2='^[A-Za-z0-9\-\.]+'
                		if [[ ! "$target" =~ $re ]] && [[ ! "$target" =~ $re2 ]]; then
                        		echo -e $RedColor"[ERROR] - Target should be an IP, IP/CIDR or domain or target file not found"$ResetColor
				else
					echo -e "Target is correct"
					INTERTARGET=$target
					echo $INTERTARGET > $(pwd)/target.txt
					INTERTARGETFILE=$(pwd)/target.txt
					echo -e $GreenColor"[INFO] - Executing file "$MODULES_FOLDER"make_folder_structure.sh"$ResetColor
					startexecution=`date +%s`
					$MODULES_FOLDER"make_folder_structure.sh" $INTERTARGETFILE $WORKING_FOLDER
					endexecution=`date +%s`
					displaytime `expr $endexecution - $startexecution`
					echo -e $PurpleColor"[INFO] - Execution time of the file:$timecalc."$ResetColor
					break
				fi
                	fi
		done
	fi
	echo -e $GreenColor"[INFO] - Executing file "$MODULES_FOLDER$1" with speed "$2" to target "$3" "$ResetColor
	startexecution=`date +%s`
	$MODULES_FOLDER$1 $3 $WORKING_FOLDER $2
	endexecution=`date +%s`
        displaytime `expr $endexecution - $startexecution`
        echo -e $PurpleColor"[INFO] - Execution time of the file:$timecalc."$ResetColor
}
function execute_plugin(){
	if [[ -z $INTERTARGETFILE ]] && [[ -z $INTERTARGET ]]; then
                echo -e $OrangeColor"[WARNING] - It is needed an IP or domain to continue with the execution"$ResetColor
                while true
                do
                        echo -e $BlueColor"> Add the target or the target file path:"$ResetColor
                        read target
                        if [ -f $target ]; then
                                echo -e "Target file found"
                                INTERTARGETFILE=$target
                                echo -e $GreenColor"[INFO] - Executing file "$MODULES_FOLDER"make_folder_structure.sh"$ResetColor
                                startexecution=`date +%s`
				$MODULES_FOLDER"make_folder_structure.sh" $INTERTARGETFILE $WORKING_FOLDER
                                endexecution=`date +%s`
                                displaytime `expr $endexecution - $startexecution`
                                echo -e $PurpleColor"[INFO] - Execution time of the file:$timecalc."$ResetColor
                                break
                        else
                                re='^(0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))\.){3}.[0-2]?[0-9]|'
                                re+='0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))$'
                                re2='^[A-Za-z0-9\-\.]+'
                                if [[ ! "$target" =~ $re ]] && [[ ! "$target" =~ $re2 ]]; then
                                        echo -e $RedColor"[ERROR] - Target should be an IP, IP/CIDR or domain or target file not found"$ResetColor
                                else
                                        echo -e "Target is correct"
                                        INTERTARGET=$target
                                        echo $INTERTARGET > $(pwd)/target.txt
                                        INTERTARGETFILE=$(pwd)/target.txt
                                        echo -e $GreenColor"[INFO] - Executing file "$MODULES_FOLDER"make_folder_structure.sh"$ResetColor
                                        startexecution=`date +%s`
					$MODULES_FOLDER"make_folder_structure.sh" $INTERTARGETFILE $WORKING_FOLDER
                                        endexecution=`date +%s`
                                        displaytime `expr $endexecution - $startexecution`
                                        echo -e $PurpleColor"[INFO] - Execution time of the file:$timecalc."$ResetColor
                                        break
                                fi
                        fi
                done
        fi
        echo -e $GreenColor"[INFO] - Executing file "$PLUGINS_FOLDER$1" with speed "$2" to target "$3" "$ResetColor
        startexecution=`date +%s`
        $PLUGINS_FOLDER$1 $3 $WORKING_FOLDER $2 
        endexecution=`date +%s`
	displaytime `expr $endexecution - $startexecution`
        echo -e $PurpleColor"[INFO] - Execution time of the file:$timecalc."$ResetColor
}
function interactive(){
	clear
	printmenu
	while true 
	do
		echo -e $BlueColor"Choose your action from menu: "$ResetColor
		read action
		validateaction $action
		if [[ $validaction == 0 ]]; then
                	case $action in
				1)
					echo -e $OrangeColor"Exiting ....."$ResetColor
					exit 1
					;;
				2)
					printmenu
					;;
				3)
					if [[ ! -z $INTERSPEEDTYPE ]]; then
						if [ $INTERSPEEDTYPE == "all" ]; then
							generatespeedfile 1
						else
							generatespeedfile $INTERSPEEDTYPE
						fi
					else
						echo -e $OrangeColor"[WARNING] - Not speed parameter found, using default speed quick"$ResetColor
						generatespeedfile 2
					fi
					if [[ $INTEREXCLUDEDOMAINS == 0 ]]; then
                                               	fullscan
                                        else
                                               	targetscan
                                        fi
					exit 1
					;;
				4)
					clear
					while true
					do
						listmodules
						echo -e $BlueColor"Choose the module from menu: "$ResetColor
						read modulenumber
						validateaction $modulenumber
						if [[ $modulenumber == 0 ]]; then
							clear
							printmenu
							break
						fi
						if [[ $validaction == 0 ]]; then
							module=${modules_association[$modulenumber]}
							if [[ ! -z $INTERSPEEDTYPE ]]; then
								if [ $INTERSPEEDTYPE == "all" ]; then
									generatespeedfile 1
								else
									generatespeedfile $INTERSPEEDTYPE
								fi
							else
								echo -e $OrangeColor"[WARNING] - Not speed parameter found, using default speed quick"$ResetColor
								generatespeedfile 2
							fi
							for target in $(cat $INTERTARGETFILE); do
								for speed in $(cat $WORKING_FOLDER$(echo $target | sed 's/\//-/g')"/tmp/scan_speed.txt"); do
									echo $INTERCOMPANYNAME > $WORKING_FOLDER$(echo $target | sed 's/\//-/g')/$speed/tmp/company_name.txt
									echo "EXECUTING SPEED $speed"
									if [[ " ${plugins_dict[*]} " =~ "$module" ]]; then
										execute_plugin $module $speed $target
									else
										execute_module $module $speed $target
									fi
								done
							done
						else
							echo -e RedColor"[ERROR] - The module number doesn't exists "$ResetColor
						fi

					done
					;;
				5)
					clear
					while true
					do
						listspeed
						echo -e $BlueColor"Choose the speed of the scan: "$ResetColor
						read speednumber
						validateaction $speednumber
						if [[ $speednumber == 0 ]]; then
                                                        clear
                                                        printmenu
                                                        break
                                                fi
                                                if [[ $validaction == 0 ]]; then
                                                        generatespeedfile $speednumber
							break
                                                else
                                                        echo -e $RedColor"[ERROR] - The speed number doesn't exists "$ResetColor
                                                fi
					done
					;;
				*)
					echo -e $RedColor"[ERROR] - The action doesn't exists "$ResetColor
					;;
			esac
		fi
	done
}
banner
initvariables
loadmodules
loadplugins
associatemodulesandplugins
while getopts "h:T:t:w:m:s:i:l:c:e" OPTION
	do
		case $OPTION in
			h)
				programhelp
				exit 1
		   		;;
	       		T)
		   		INTERTARGETFILE=$OPTARG
		   		;;
	       		t)
		   		INTERTARGET=$OPTARG
		   		;;
			m)
				INTERMODULE=$OPTARG
				;;
	       		s)
		   		INTERSPEEDTYPE=$OPTARG
		   		;;
	       		i) 
				INTERACTIVE=$OPTARG
		   		;;
			l)
				listspeed
				listmodules
				exit 1
				;;
			e)
				INTEREXCLUDEDOMAINS=1
				;;
			c)
				INTERCOMPANYNAME=$OPTARG
				;;
			*)
				programhelp
				exit 1
				;;
	   	esac
	done
if [[ -z $INTERACTIVE ]] && ([[ ! -z $INTERTARGET ]] || [[ ! -z $INTERTARGETFILE ]]); then
        re='^(0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))\.){3}.[0-2]?[0-9]|'
        re+='0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))$'
        re2='^[A-Za-z0-9\-\.]+'
	if [[ ! -z $INTERTARGETFILE ]]; then
               if [ ! -f $INTERTARGETFILE ]; then
                       echo -e $RedColor"ERROR:   Parameter -T , target file not found"$ResetColor
                       programhelp
                       exit 1
	       fi
        fi
        if [[ ! -z $INTERTARGET ]]; then
		echo $INTERTARGET > $(pwd)/target.txt
		INTERTARGETFILE=$(pwd)/target.txt
                if [[ ! "$INTERTARGET" =~ $re ]] && [[ ! "$INTERTARGET" =~ $re2 ]]; then
                        echo -e $RedColor"ERROR:    Parameter -t should be an IP, IP/CIDR or domain"$ResetColor
                        programhelp
			exit
		fi
	fi
	foldervariables
	if [[ ! -z $INTERSPEEDTYPE ]]; then
                if [ $INTERSPEEDTYPE == "all" ]; then
                        generatespeedfile 1
                else
                        generatespeedfile $INTERSPEEDTYPE
                fi
        else
                echo -e $OrangeColor"[WARNING] - Not speed parameter found, using default speed quick"$ResetColor
                generatespeedfile 2
        fi
	if [[ -z $INTERCOMPANYNAME ]]; then
                echo -e $RedColor"ERROR: Parameter -c {companyname} not found"$ResetColor
                programhelp
                exit 1
        fi
	if [[ ! -z $INTERMODULE ]]; then
		if [[ $INTERMODULE == "all" ]]; then
			echo -e $GreenColor"[INFO] - Executing file "$MODULES_FOLDER"make_folder_structure.sh"$ResetColor
			startexecution=`date +%s`
			$MODULES_FOLDER"make_folder_structure.sh" $INTERTARGETFILE $WORKING_FOLDER
			endexecution=`date +%s`
			displaytime `expr $endexecution - $startexecution`
			echo -e $PurpleColor"[INFO] - Execution time of the file:$timecalc."$ResetColor
			if [[ $INTEREXCLUDEDOMAINS == 0 ]]; then
				fullscan
			else
				targetscan
			fi
		else
			if [[ " ${modules_dict[*]} " =~ " ${modules_association[$INTERMODULE]} " ]] || [[ " ${plugins_dict[*]} " =~ " ${modules_association[$INTERMODULE]} " ]]; then
				module=${modules_association[$INTERMODULE]}
				echo -e $GreenColor"[INFO] - Executing file "$MODULES_FOLDER"make_folder_structure.sh"$ResetColor
				startexecution=`date +%s`
				$MODULES_FOLDER"make_folder_structure.sh" $INTERTARGETFILE $WORKING_FOLDER $module
				endexecution=`date +%s`
				displaytime `expr $endexecution - $startexecution`
				echo -e $PurpleColor"[INFO] - Execution time of the file:$timecalc."$ResetColor
				for target in $(cat $INTERTARGETFILE); do
					for speed in $(cat $WORKING_FOLDER$(echo $target | sed 's/\//-/g')"/tmp/scan_speed.txt"); do
						echo $INTERCOMPANYNAME > $WORKING_FOLDER$(echo $target | sed 's/\//-/g')/$speed/tmp/company_name.txt
						echo "EXECUTING SPEED $speed"
						if [[ " ${plugins_dict[*]} " =~ " ${modules_association[$INTERMODULE]} " ]]; then
							execute_plugin $module $speed $target
						else
							execute_module $module $speed $target
						fi
					done
				done
			else
				echo -e $RedColor"[ERROR] - Module not found, the module parameter must be 'all' or a number"$ResetColor
			fi
		fi
	else
		echo -e $OrangeColor"[WARNING] - No module parameter found, using default module parameter all"$ResetColor
		if [[ $INTEREXCLUDEDOMAINS == 0 ]]; then
			fullscan
		else
			targetscan
		fi
	fi
else
	interactive
fi
