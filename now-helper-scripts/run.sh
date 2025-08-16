#!/usr/bin/env bash

# TODO be able to set the drive_prefix

# ssh targets and log search pattern
user="etservice" # remote ssh user
password="magnumhdtv" # remote ssh password
#drive_prefix="/drives/n/Downloads"
drive_prefix=/drives/c/Users/hshabbir/Downloads
dir="run_`date +"%Y-%m-%d"`"

# VARS: username, password, command/script, ips
# SECONDARY: table output (required script), 

# TODO
function help_doc () {
read -r -d '' HELPDOC <<- ENDHELPDOC
Usage: $0 [-h] [-u username] [-p password] 
  -h                   show this help message
  -u username          username to use to ssh 
                           DEFAULT: etservice
  -p password          password to use to ssh
                           DEFAULT: magnumhdtv
  -i ips               ips of hosts to tail
                           WARNING: in non-spaced csv format
                               e.g. 10.193.70.34,10.193.70.38,10.193.70.42
  -c command           command to run on all ips
ENDHELPDOC

echo "$HELPDOC"	
}

while getopts "?hu:p:i:c:" option; do
	case $option in
		h) help_doc; exit ;;
		u) user="$OPTARG"; echo "Setting username to: $user" ;;
		p) password="$OPTARG"; echo "Setting password to: $password" ;;
		i) hosts_str="$OPTARG"; echo "Setting ips to: $hosts_str" ;;
		c) command="$OPTARG"; echo "Setting command to: $command" ;;
		?) echo "error: option -$OPTARG is not implemented"; exit ;;
	esac
done


IFS=',' read -a hosts <<< "$hosts_str"

echo ""
printf "Parsed IPs: ( "; printf '%s ' "${hosts[@]}"; echo ")"

echo ""
echo "Installing sshpass:"
/bin/MobApt install -y sshpass

echo ""
mkdir -p "$drive_prefix/$dir"



echo =e "================================================================================" >> "$drive_prefix/$dir/run.log"
echo "Running at $(date +"%Y-%m-%dT%H:%M:%S") the command: $command" \
	| tee -a "$drive_prefix/$dir/run.log"

for host in "${hosts[@]}"; do 
	echo "$host:" \
		| tee -a "$drive_prefix/$dir/run.log"
	sshpass -p $password ssh -o "LogLevel Error" -o "ConnectTimeout 3" -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" \
		$user@$host "$command" \
		| tee -a "$drive_prefix/$dir/run.log"
done

echo -e "\n" >> "$drive_prefix/$dir/run.log"
