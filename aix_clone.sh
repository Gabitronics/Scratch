#!/bin/bash
DRYRUN=0
ANSWER_YES=0
VERSION="1.15.0409b"
ODMDIR=/etc/objrepos;export ODMDIR

ulimit unlimited
###############################################################
#  UPDATES:
#  
#  1.15.0325: 
#       1- Added ulimit unlimited at begining of script
#       2- Added new output line after removinf current clone
#  1.15.0409:
#       1- Handle when /var/adm/ras/alt_disk_inst.log is missing
#
###############################################################

while getopts ":hdrvy" opt
do
        case "$opt" in
        h)
            echo "Usage: ${0##*/} [-d] [-y] [-v] [-h]"
            echo
            echo "          -d    Dry run. Do not actually clone."
            echo "          -y    Answer yes to prompt."
            echo "          -v    Display version."
            echo "          -h    Help."
            echo
            exit 0
            ;;
        d)
            DRYRUN=1
            ;;
        y)
            ANSWER_YES=1
            ;;
        v)
            echo "Version: $VERSION"
            echo
            exit 0
            ;;
        esac
done

#
###############################################################
function ask {
   if [[ $ANSWER_YES = "0" ]];then
      read -r -p "$1" response
      case "$response" in
         y|Y|yes|Yes|YES)
         echo "yes"
         ;;
      *)
         echo "no"
         ;;
      esac
   else
      echo "yes"
   fi
}

function print_relevant_disks {

echo "                               Relevant Physical Volumes"
echo "                     (rootvg / altinst_rootvg / old_rootvg / None)"
echo "-----------------------------------------------------------------------------------------"
echo "Disk            Disk ID                             Volume Group    Status       Size"
echo "-----------------------------------------------------------------------------------------"
echo 
IFS=$'\n'
for i in `lspv |egrep -e 'rootvg|None'`
do 
   diskname=`echo $i|awk '{ print $1 }'`
   disksize=`bootinfo -s $diskname`
   echo $i" "$disksize
done
echo
unset IFS
echo "-----------------------------------------------------------------------------------------"
}


clear
echo
echo "[`date`]"
echo "#########################################################################################"
print_relevant_disks


#echo "#########################################################################################"
echo "                              Current Rootvg Boot Status                                 "
echo "-----------------------------------------------------------------------------------------"
echo
echo "          Current Bootlist:  `bootlist -m normal -o`"
echo 
if [[ ! -f "/var/adm/ras/alt_disk_inst.log" ]];then
     last_clone_date="Unknown: alt_disk_inst.log does not exist."
     last_clone_cmd="Unknown: alt_disk_inst.log does not exist."
else
     last_clone_date=`awk 'NR < 3 { print }' < /var/adm/ras/alt_disk_inst.log|tail -n +2`
     last_clone_cmd=`awk 'NR < 4 { print }' < /var/adm/ras/alt_disk_inst.log|tail -n +3`
fi

echo "           Last clone date:  $last_clone_date"
echo "            Last clone cmd:  ${last_clone_cmd##cmd: }"
echo
#
rootvg_disk=`lspv |egrep -e 'rootvg'|egrep -v -e 'old|altinst'| awk '{ print $1}'` 
rootvg_disk_count=`lspv |egrep -e 'rootvg'|egrep -v -e 'old|altinst'|wc -l|tr -s " "`
#
current_clone_disk=`lspv| egrep -e "old_rootvg|altinst_rootvg"|awk '{ print $1 }'`
current_clone_count=`lspv|egrep -e "old_rootvg|altinst_rootvg"|wc -l|tr -s " "`
#

echo "    Number of rootvg disks: $rootvg_disk_count"
echo "      Current rootvg disks:  $rootvg_disk"
echo
if [[ $rootvg_disk_count -ge 2 ]]; then
    echo "------------------------------------------------------------------------------------------"
    echo "I'm not smart enough to handle a rootvg with more than one disk.  Sorry... :-("
    exit 3
fi

#
echo "     Number of clone disks: $current_clone_count"

if [[ -z "$current_clone_disk" ]]; then
    echo "        Current clone disk:  N/A"
    echo
    echo "#########################################################################################"
    echo
    
    echo "Identifying suitable candidate... "
    echo
    rootvg_disksize=`bootinfo -s $rootvg_disk`
    for i in `lspv |grep 'None'|grep -v "active"` 
    do
        candidate_size=`bootinfo -s $i`
        if [[ $candidate_size = $rootvg_disksize ]]; then
            current_clone_disk=$i
        fi           
    done
        if [[ -z $current_clone_disk ]];then
            echo "No suitable disk was found to clone rootvg.  Bye."
            exit 4
        else
            echo "Clone disk candidate: $current_clone_disk"
            echo
        fi
     
else 

    echo "        Current clone disk:  "$current_clone_disk 
    echo
    echo "#########################################################################################"
    echo
    

    if [[ $DRYRUN = "0" ]]; then
         echo "Do you want me to remove current altinst_rootvg or old_rootvg clone? (y/n)?"
         answer="$(ask)"
         if [[ $answer = "yes" ]];then
             echo "Removing current clone disk..." 
             sleep 5
   
             alt_rootvg_op -X `lspv|egrep -e "old_rootvg|altinst_rootvg"|awk '{ print $3 }'`
             if [[ $? -eq 0 ]]; then 
                 echo "Clone disk removed."
		 print_relevant_disks
             else
                 echo "Error status of alt_rootvg_op -X command was not zero (0). Please check."
                 exit 2 
             fi
         fi

    else
        echo "Dry run selected.  Did not attempt to remove current clone disk."
	echo
    fi
    
fi

    if [[ $DRYRUN =  "0" ]]; then 
          echo "Do you want me to clone rootvg now? (y/n)?"
          answer="$(ask)"
          if [[ $answer = "yes" ]];then
             echo "Creating root_vg clone (altinst_rootvg) on [ $current_clone_disk ]..."
             sleep 3
             alt_disk_copy -Bd $current_clone_disk
             if [[  $? -ne 0 ]]; then
                 echo "There was an error creating the clone.  Bye."
                 exit 3
             fi
             echo "Updating bosboot info..."
             bosboot -a 
          fi
    else

       echo "Dry run selected.  Did not attempt to clone disk."
       echo
    fi
if [[ $DRYRUN = "0" ]];then

echo     
echo
echo
echo "[`date`]"
echo
echo "#########################################################################################"
print_relevant_disks
echo "-----------------------------------------------------------------------------------------"
echo "                              Current Rootvg Boot Status                                 "
echo "-----------------------------------------------------------------------------------------"
echo
echo "          Current Bootlist:  `bootlist -m normal -o`"
echo

last_clone_date=`awk 'NR < 3 { print }' < /var/adm/ras/alt_disk_inst.log|tail -n +2`
last_clone_cmd=`awk 'NR < 4 { print }' < /var/adm/ras/alt_disk_inst.log|tail -n +3`
echo "           Last clone date:  $last_clone_date"
echo "            Last clone cmd:  ${last_clone_cmd##cmd: }"
echo
#
rootvg_disk=`lspv |egrep -e 'rootvg'|egrep -v -e 'old|altinst'| awk '{ print $1}'`
rootvg_disk_count=`lspv |egrep -e 'rootvg'|egrep -v -e 'old|altinst'|wc -l|tr -s " "`
#
current_clone_disk=`lspv| egrep -e "old_rootvg|altinst_rootvg"|awk '{ print $1 }'`
current_clone_count=`lspv|egrep -e "old_rootvg|altinst_rootvg"|wc -l|tr -s " "`
#

echo "    Number of rootvg disks: $rootvg_disk_count"
echo "      Current rootvg disks:  $rootvg_disk"
#
current_clone_disk=`lspv| egrep -e "old_rootvg|altinst_rootvg"|awk '{ print $1 }'`
current_clone_count=`lspv|egrep -e "old_rootvg|altinst_rootvg"|wc -l|tr -s " "`
#
echo
#
echo "     Number of clone disks: $current_clone_count"

if [[ -z "$current_clone_disk" ]]; then
    echo "        Current clone disk:  N/A"
    echo
    echo "#########################################################################################"
    echo
else
    echo "        Current clone disk:  "$current_clone_disk
    echo
    echo "#########################################################################################"
    echo
fi

fi 

echo "End."
