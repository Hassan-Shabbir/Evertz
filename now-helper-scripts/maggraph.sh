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

echo
echo "Copying Graphite graphs to $drive_prefix/$dir/graphite:"
mkdir -p $drive_prefix/$dir/graphite/$state

# TODO shorten URL using relative times
echo "Generating Graphite graphs (will take approximately 2 mins):"
durations=('-4 hours' '-1 month')
for host in 10.223.86.46; do
for server in $(curl -ksS "https://$host/metrics/find/?_dc=1742787021741&query=*&format=treejson&path=&node=GraphiteTree" | jq -r '.[].text'); do 
for metric in cpu memory; do
for service in asteroid collectd corosync crossbar eventd lldpd magbackupsrv magcfgsrv magdrvmgr magdrvsrv magep3srv magfsharesrv magnum magnum-web-config magquartz magrtrqrysrv magrtrsrv magsalvo magsdpsrv magsysmgr magthirdpartytallysrv magwampsrv magwebcfgmgt magwebdevices magwebmv magwebnames mysql named nginx nundina pacemaker postgresql@10-main snmpd tallyd thirdpartydriverservice triton1 triton2 triton3 triton4 zeus; do # TODO variablize
for index in "${!durations[@]}"; do
# TODO uncomment
curl -ksS --output "$drive_prefix/$dir/graphite/$state/$server-$metric-$service-p$index-`echo ${durations[$index]} | sed 's/ /-/g'`.png" "https://$host/render/?width=1500&height=800&target=$server.services-percent_$metric.service-$service.value&from=`date --date="${durations[$index]}" +'%H%%3A%M_%Y%m%d'`"
sleep 1s
done
done
done
done
done


done # END host loop
