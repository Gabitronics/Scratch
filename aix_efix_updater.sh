#!/bin/bash

###########################
VERSION="2.15.0416a"
#
#  2.15.0416a: -Sort efixes to remove by name before applying.
#              -Added a check after removal to verify when last
#               efix has been removed.             
#
#
###########################
AP_EFIX_DIR=/mkimage/patchmgr/latest_efixes
REMOVE=0
APPLY=0
###########################


while getopts ":hravy" opt
do
        case "$opt" in
        h)
            echo "Usage: ${0##*/}  [-r] [-a] [-v] [-h]"
            echo
            echo "          -r    Remove all efixes."
            echo "          -a    Apply all efixes in $AP_EFIX_DIR."
            echo "          -v    Display version."
            echo "          -h    Help."
            echo
            exit 0
            ;;
        r)
            REMOVE=1
            ;;
        a)  
	    APPLY=1
	    ;;
        v)
            echo "Version: $VERSION"
            echo
            exit 0
            ;;
        esac
done

echo "INFO: Running $0..." 
[[ -z `ls $AP_EFIX_DIR/* 2>/dev/null` ]] && echo "INFO: No efixes found on $AP_EFIX_DIR" && exit



if [[ $REMOVE = "1" ]]; then

############################################
# CHECK INSTALLED EFIXES
#
echo "INFO: Listing installed efixes..."
emgr_result=`emgr -l 2>&1`

############################################
# REMOVE INSTALLED EFIXES
#
if [[ $emgr_result = "There is no efix data on this system." ]] ; then
    echo "INFO: No patches to remove."
else 
    echo "INFO: Removing ALL efixes..."
    emgr_error_code="0"
    while  [[ $emgr_error_code = "0" ]]
    do
   	emgr -r -n 1
        sleep 2
        emgr -c -q -n 1 > /dev/null
     	emgr_error_code=$?
        sleep 1
    done 

fi

#############################################
# CHECK THAT ALL EFIXES ARE GONE
#
echo "INFO: Checking that all efixes are really gone..."
emgr_result=`emgr -l 2>&1`
if [[ $emgr_result = "There is no efix data on this system." ]] ; then
    echo "INFO: All patches have been removed."
else
    echo "ERROR: For some reason not all efixes have been removed.  Stopping..."
    exit 1
fi


fi


if [[ $APPLY = "1" ]]; then

   echo "INFO: Installing new efixes..."
##############################################
# Try to identify the which element number whithin the path is teh actual filename
#
   sort_key=`find $AP_EFIX_DIR -name "*.epkg.Z" |tail -1|awk -F'/' '{ print NF }'`
   echo "INFO: SORT KEY: $sort_key"
##############################################
# Sort the efix_list by filename across all subdirectories to improve chances newer efixes get installed over
# older ones when the older ones are not removed from latest_efixes directory.
   efix_list=`find $AP_EFIX_DIR -name "*.epkg.Z" 2>/dev/null|sort -r -t'/' -k"$sort_key","$sort_key"`
##############################################

for i in $efix_list
do
    echo "INFO: Previewing efix: $i"
    emgr -e $i -p > /dev/null 2>&1
    if [[ $? = "0" ]];then
       echo "INFO: Applying efix: $i"       
       emgr -e $i -X
       echo
    else
       echo "WARINING: Efix $i failed the preview. Skipping."
       echo
    fi
done
    
echo
echo "INFO: Finished applying efixes..."

fi

emgr -l
