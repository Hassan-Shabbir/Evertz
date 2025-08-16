#! /bin/bash

# TODO input from script when it is run? in progress
# TODO create restore point config using magnum_backup_service_api.rst API https://evertz.atlassian.net/wiki/spaces/PA/pages/623738915/Magnum+APIs
#      - do for both pre and post work, and have them downloaded
# TODO add in sdp, etc into grabbing as folders
#      - sdp will be in /var/lib/magnum-sdp-service/ or /var/lib/magnum-driver-service/magdrvsdp/
# TODO help docs should have a TL;DR section

# TODO diff each of the static files on each of the Magnums
# TODO when are config backups taken?

user=etservice
password=magnumhdtv
# TODO make `drive_prefix` a variable
drive_prefix=/drives/c/Users/hshabbir/Downloads


#hosts=(132.145.143.56) # main Reflex
#hosts=(150.136.211.222 129.213.129.80) # clustered Reflex
# TODO 129.213.16.125 isn't getting downloaded
hosts=(132.145.143.56 150.136.211.222 129.213.16.125 129.213.129.80) # space-separated ssh hosts list


# TODO
# TODO short for graphite and long versions
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
  -s services          services to upgrade
                           WARNING: in long non-spaced csv format
                               e.g. magnum-reflex,magnum-client-service
                           for documentation related purposes primarily
ENDHELPDOC

echo "$HELPDOC"	
}

while getopts "?hu:p:i:s:" option; do
	case $option in
		h) help_doc; exit ;;
		u) user="$OPTARG"; echo "Setting username to: $user" ;;
		p) password="$OPTARG"; echo "Setting password to: $password" ;;
		i) hosts_str="$OPTARG"; echo "Setting ips to: $hosts_str" ;;
		s) service_long="$OPTARG"; echo "Setting long service name to: $service_long" ;;
		?) echo "error: option -$OPTARG is not implemented"; exit ;;
	esac
done


IFS=',' read -a hosts <<< "$hosts_str"

dir=${service_long}_`date +"%Y-%m-%d"`
mkdir -p "$drive_prefix/$dir"

echo ""
printf "Parsed IPs: ( "; printf '%s ' "${hosts[@]}"; echo ")"
echo ""
echo "Dir: $drive_prefix/$dir"
echo ""


echo "Installing packages:" # TODO uncomment
/bin/MobApt install -y sshpass jq # > /dev/null 2>&1


### Pre Upgrade
state=pre

################################################################################################################################################

for host in "${hosts[@]}"; do 

echo "Connecting to $host:"

hostname=$(sshpass -p $password ssh -o "LogLevel Error" -o "ConnectTimeout 3" -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" \
	$user@$host 2>/dev/null 'hostname')

read -r -d '' remote_script << ENDSSH

echo "========================= ${state}-${service_long} upgrade on $hostname ($host) at `date +"%Y-%m-%dT%H:%M:%S"` ========================="
mkdir -p $dir/$state/$host

echo
echo "Hostname:"
hostname | tee $dir/$state/$host/hostname.txt
echo

echo
echo "Linux Version:"
cat /etc/os-release | awk -F'"' '/VERSION=/ {print \$2}' | tee $dir/$state/$host/uname.txt
#uname -a | tee $dir/$state/$host/uname.txt
echo

echo
echo "Local Time:"
date | tee $dir/$state/$host/date.txt
echo

echo "Saving History."
HISTFILE=~/.bash_history
set -o history
history | tail -n 100 > $dir/$state/$host/history.txt
echo

#echo
#echo "Saving All Files."
#find / 2>/dev/null > $dir/$state/$host/files.txt
#echo

echo "Saving Health Metrics."
/opt/magnum-self-monitor-service/bin/get_health_metrics > $dir/$state/$host/health_metrics.txt
echo

echo
echo "Health Summary:"
/opt/magnum-self-monitor-service/bin/get_health_summary --no-color | tee $dir/$state/$host/health_summary.txt
echo

echo
echo "VUE Filter Files:"
#cd /etc/magnum-client-service
#declare -A files
#for file in *; do files[\$file]="\$(cat \$file)"; done
#(for file in "\${!files[@]}"; do echo "\$file: \${files[\$file]}"; done) | tee ~/$dir/$state/$host/vue-filter-files.txt
#cat * | sort | uniq -c
#cd ~
tail -n +1 /etc/magnum-client-service/* | tee ~/$dir/$state/$host/vue-filter-files.txt
echo

echo
echo "Tweaks File:"
cat /opt/eqx-server/config.d/tweaks.cfg | tee $dir/$state/$host/tweaks.cfg
echo

echo
echo "Magnum Flags (defined, non-debug):"
cat /etc/default/magnum | tee $dir/$state/$host/magnum | grep '-' | grep -v -- '--debug'
echo

echo
echo "MagScript:"
cp -r /opt/eqx-server/config.d/magscript.d | tee $dir/$state/$host/magscript.d
echo

echo
echo "Uptime:"
uptime -p | tee    $dir/$state/$host/uptime.txt
uptime    | tee -a $dir/$state/$host/uptime.txt
echo

echo
echo "Top Processes:"
COLUMNS=1024 top -bn1 | tee $dir/$state/$host/top.txt | head -n 12
echo

echo
echo "Free Memory:"
free -h | tee $dir/$state/$host/free.txt
echo

echo
echo "Disk Usage:"
df -h | tee $dir/$state/$host/df.txt
echo

echo
echo "Offline Devices:"
/opt/magnum-support-tools/bin/jsonrpc_cli -p 12013 "device.status()" > $dir/$state/$host/device-status.txt
grep False $dir/$state/$host/device-status.txt
echo

echo
echo "Down Links:"
/opt/magnum-support-tools/bin/get_link_states --filepath $dir/$state/$host/link-states 1>/dev/null
echo
grep Down $state/$host/link-states.csv
echo

echo
echo "Cluster Status:"
crm status simple | tee $dir/$state/$host/crm-overview.txt
echo
crm status brief | awk '1;/Active Resources/ {exit}' | head -n -2 | tee $dir/$state/$host/crm-summary.txt
echo

echo
echo "Relevant Magnum Packages (searching for $service_long):"
dpkg -l | grep -Ei 'rootfs'
dpkg -l | grep -Ei 'buddy-panel-service|busybox|configshell|coreutils|corosync|crmsh|crossbar|efpinstall|evertz|logrotate|magnum|mdl|ntp|pacemaker|snmp|systemd|vueweb' | tee $dir/$state/$host/dpkg.txt | grep -Ei '${service_long}'
echo
ENDSSH

# Print your script for verification
#echo "$remote_script"


#exit ### !!!!! ###

sshpass -p $password ssh -o "LogLevel Error" -o "ConnectTimeout 3" -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" \
	$user@$host 2>/dev/null <<< "$remote_script"


echo
echo "Copying $dir to local device:"
sshpass -p $password scp -r $user@$host:/home/etservice/$dir $drive_prefix
echo

echo
echo "Copying Latest Backup:"
sshpass -p $password scp -r $user@$host:"/var/lib/magnum-backup-service/$(sshpass -p $password ssh -o "LogLevel Error" -o "ConnectTimeout 3" -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" $user@$host "ls /var/lib/magnum-backup-service | tail -n 1" | sed 's/ /\\\ /g')" $drive_prefix/$dir/$state/$host # copy latest backup
echo

exit ### !!! ###

echo
echo "Copying Graphite graphs to $drive_prefix/$dir/graphite:"
mkdir -p $drive_prefix/$dir/graphite/$state # TODO remove for post/rollback


# TODO shorten URL using relative times
echo "Generating Graphite graphs (will take approximately 2 mins):"
durations=('-24 hours' '-1 month' '-1 year')
#for host in 132.145.143.56; do #150.136.211.222 129.213.16.125 129.213.129.80; do
for host in ${hosts[@]}; do #150.136.211.222 129.213.16.125 129.213.129.80; do
for server in $(curl -ksS "https://$host/metrics/find/?_dc=1742787021741&query=*&format=treejson&path=&node=GraphiteTree" | jq -r '.[].text'); do 
for metric in cpu memory; do
for service in reflex; do # TODO variablize
for index in "${!durations[@]}"; do
# TODO uncomment
curl -ksS --output "$drive_prefix/$dir/graphite/$state/$server-$metric-$service-p$index-`echo ${durations[$index]} | sed 's/ /-/g'`.png" "https://$host/render/?width=1500&height=800&target=$server.services-percent_$metric.service-$service.value&from=`date --date="${durations[$index]}" +'%H%%3A%M_%Y%m%d'`"
printf "."
done
done
done
done
done


done # END host loop


################################################################################################################################################

echo
echo
read -p "Continue with uploading upgrade files (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
	echo "EXITED as per user!!!"
	[[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
fi
echo


# TODO need to variablize reflex
echo
echo "Uploading Upgrade Files:"
for host in "${hosts[@]}"; do 
sshpass -p $password scp $drive_prefix/magnum-reflex-3.0.8_bionic.efp.md5 $user@$host:/home/etservice
sshpass -p $password scp $drive_prefix/magnum-reflex-3.0.8_bionic.efp     $user@$host:/home/etservice
echo

read -r -d '' remote_script << ENDSSH
echo
echo "Files:"
ls magnum-reflex-3.0.8_bionic.efp*

echo
echo "Listing Corrupted Files (no result is good):"
(md5sum magnum-reflex-3.0.8_bionic.efp; cat magnum-reflex-3.0.8_bionic.efp.md5) | uniq -c | grep -vE '^\s*2'
ENDSSH

sshpass -p $password ssh -t -o "LogLevel Error" -o "ConnectTimeout 3" -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" \
	$user@$host 2>/dev/null <<< "$remote_script"

done

echo
echo "Manually upgrade the services on *ALL* nodes in cluster now..."
echo
sleep 10s


echo
read -p "Was upgrade successfully completed on *ALL* nodes in cluster (y = post; n = rollback): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
	state=post
	echo "Upgrade successful"
else
	state=rollback
	echo "Upgrade unsuccessful"
fi
echo


################################################################################################################################################


### Post Upgrade / Rollback


for host in "${hosts[@]}"; do 

hostname=$(sshpass -p $password ssh -o "LogLevel Error" -o "ConnectTimeout 3" -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" \
	$user@$host 2>/dev/null 'hostname')

read -r -d '' remote_script << ENDSSH

echo "========================= ${state}-${service_long} upgrade on $hostname ($host) at `date +"%Y-%m-%dT%H:%M:%S"`: ========================="
mkdir -p $dir/$state/$host

echo
echo "Hostname:"
hostname | tee $dir/$state/$host/hostname.txt
echo

echo
echo "Linux Version:"
uname -a | tee $dir/$state/$host/uname.txt
echo

echo
echo "Local Time:"
date | tee $dir/$state/$host/date.txt
echo

echo "Saving History."
HISTFILE=~/.bash_history
set -o history
history | tail -n 100 > $dir/$state/$host/history.txt
echo

echo "Saving Health Metrics."
/opt/magnum-self-monitor-service/bin/get_health_metrics > $dir/$state/$host/health_metrics.txt
echo

echo
echo "Health Summary:"
/opt/magnum-self-monitor-service/bin/get_health_summary | tee $dir/$state/$host/health_summary.txt
echo

echo
echo "VUE Filter Files:"
cd /etc/magnum-client-service
declare -A files
for file in *; do files[\$file]="\$(cat \$file)"; done
(for file in "\${!files[@]}"; do echo "\$file: \${files[\$file]}"; done) | tee ~/$dir/$state/$host/vue-filter-files.txt
cd ~
echo

echo
echo "Tweaks File:"
cat /opt/eqx-server/config.d/tweaks.cfg | tee $dir/$state/$host/tweaks.cfg
echo

echo
echo "Defined Magnum Flags:"
cat /etc/default/magnum | tee $dir/$state/$host/magnum | grep '-' | grep -v -- '--debug'
echo

echo
echo "MagScript:"
cp -r /opt/eqx-server/config.d/magscript.d | tee $dir/$state/$host/magscript.d
echo

echo
echo "Uptime:"
uptime -p | tee    $dir/$state/$host/uptime.txt
uptime    | tee -a $dir/$state/$host/uptime.txt
echo

echo
echo "Top Processes:"
top -bn1 | tee $dir/$state/$host/top.txt | head -n 12
echo

echo
echo "Free Memory:"
free -h | tee $dir/$state/$host/free.txt
echo

echo
echo "Disk Usage:"
df -h | tee $dir/$state/$host/df.txt
echo

echo
echo "Offline Devices:"
/opt/magnum-support-tools/bin/jsonrpc_cli -p 12013 "device.status()" > $dir/$state/$host/device-status.txt
grep False $dir/$state/$host/device-status.txt
echo

echo
echo "Down Links:"
/opt/magnum-support-tools/bin/get_link_states --filepath $dir/$state/$host/link-states 1>/dev/null
echo
grep Down $state/$host/link-states.csv
echo

echo
echo "Cluster Status:"
crm status simple | tee $dir/$state/$host/crm-overview.txt
echo
crm status brief | awk '1;/Active Resources/ {exit}' | head -n -2 | tee $dir/$state/$host/crm-summary.txt
echo

echo
echo "Relevant Magnum Packages:"
dpkg -l | grep -Ei 'buddy-panel-service|busybox|configshell|coreutils|corosync|crmsh|crossbar|efpinstall|evertz|logrotate|magnum|mdl|ntp|pacemaker|snmp|systemd|vueweb' | tee $dir/$state/$host/dpkg.txt | grep -E 'rootfs|${service_long}'
echo
ENDSSH

# Print your script for verification
#echo "$remote_script"


sshpass -p $password ssh -o "LogLevel Error" -o "ConnectTimeout 3" -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" \
	$user@$host 2>/dev/null <<< "$remote_script"


echo
echo "Copying $dir to local device:"
sshpass -p $password scp -r $user@$host:/home/etservice/$dir $drive_prefix
echo


echo
echo "Copying Graphite graphs to $drive_prefix/$dir/graphite:"
mkdir -p $drive_prefix/$dir/graphite/$state

echo "Generating Graphite graphs (will take approximately 2 mins):"
# TODO variablize
durations=('-24 hours' '-1 month' '-1 year')
for host in 132.145.143.56 150.136.211.222 129.213.16.125 129.213.129.80; do
for server in $(curl -ksS "https://$host/metrics/find/?_dc=1742787021741&query=*&format=treejson&path=&node=GraphiteTree" | jq -r '.[].text'); do 
for metric in cpu memory; do
for service in reflex; do # TODO variablize
for index in "${!durations[@]}"; do
# TODO uncomment
# TODO `| sed` is required, {{$foo// /} does not work (with this bash-y thing)
echo curl -ksS --output "$drive_prefix/$dir/graphite/$state/$server-$metric-$service-p$index-`echo ${durations[$index]} | sed 's/ /-/g'`.png" "https://$host/render/?width=1500&height=800&target=$server.services-percent_$metric.service-$service.value&from=`date --date="${durations[$index]}" +'%H%%3A%M_%Y%m%d'`"
#printf "."
done
done
done
done
done


done # END host loop


