#!/bin/bash
###############################################################
#
#
#      SCRIPT:  auto_patch.sh
#
#  2.15.0414a: -Increase delay before reboot to 120 secs.
#              -Added default stopDBs.sh with most common line.
#              -Added /etc backup on info gathering scripts/
#
#  2.15.0414b: -Added variables inside stopDBs.sh script.  File check.
#  
#  2.15.0415a: -Enclosed STOP_DB_CMD in quotes in stopDBs.sh
#              -Redirected tar output to etc_backup_list.txt
#  
#  2.15.0415b: -Added check for /opt/patchmgr/DONOTPATCH    
#
#  2.15.0415c: -Added checks for directories in aix_*_updater scripts.
#              -Sort efix list by label before processing
#
#  2.15.0417a: -Changes to aix_efix_updater.sh.
#              -Changed patch install command from installp to
#               install_all_updates in aix_patch_updater.sh
#              
#  2.15.0423a: -Disable strict error code monitoring with set -e
#               briefly during pca -i routine by setiing set +e
#               beforehand and then reenabling it afterwards.
#
#  2.15.0423b: -Added lines before and after lppchk -v in aix_patch_updater.sh 
#               and aix_bundle_updtaer.sh.  This also has the effect of 
#               not halting the script if it finds a broken fileset.
#
#  2.15.0427a: -Added options to wget in solaris_info.sh to limit 
#               connection retries. 
#
#  2.15.0501a: -Added emgr -P to aix_info.sh and package-cleanup --dupes
#               for RHEL.
#
#  2.15.0513a: -Changed rhel_info.sh to searcho for anaconda config in
#               /root in addition to /.
#              
#  2.15.0520a: -Modified aix_info.sh so that certain lslv output is
#               properly sent to its log instead of stderr.
#
#  2.15.0602a: -Fixed month_length function in ap_scheduler.sh to 
#               properly handle months with "6" weeks. Modified sed command.
#
#  2.15.0603a: -The script solaris_info.sh would wipeout patchdiag.xref
#               even when wget could not download a new one.  Now the
#               file is preserved when a new one cannot be downloaded.
# 
#  2.15.0611a: -Added the -r option to install_all_updates in aix_patch_updater.sh
#               so that rpms can also be updated automatically.
#
#  2.15.0617a: -Added lsdev -Cc adapter and lscfg -pv to aix_info.sh
#
#  2.15.0618a: -Added installp -c all to aix_bundle_updater.sh so that all
#               filesets in applieds state are committed before Service Pack 
#               installation. This establishes a more consistent point to rollback
#               to if necessary. 
#              -Added line to execute chmod o+r on all files in the info_logs
#
#  2.15.0623a: -Changed the behavior of DRYRUN so that the stop_db and stop_app
#               scripts are checked and listed.
# 
#  2.15.0625a  -Added crontab -l to info gathering scripts.
#              -Added zypper lp (list patches) to zlinux_info.sh
#
#  2.15.0713a: -Fixed lvdisplay,vgdisplay and pvdisplay output in zlinux_info.sh
#              -Added backup of /boot in linux and /var/spool/cron in all unix servers.
#
#  2.15.0716a: -Added svcs -a to solaris_info.sh script, and netstat -an and netstat -rn
#               to all info scripts
#
###################################################################################
VERSION="Auto Patch Script v2.15.0716a"
###################################################################################
#
###############################################################
#    VARIABLES
###############################################################
#
echo    # FIRST EMPTY LINE
declare -a suffix=(" " "st" "nd" "rd" "th" "th" "th" "th" "th" "th" "th") # Append suffix to appropiate number: 1st, 2nd, 3rd, etc.
declare -a weekdaytxt=("Sunday" "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday") # Append suffix to appropiate number: 1st, 
#
export PATH=$PATH:/usr/sbin:/sbin:/usr/bin:/bin:/usr/local/bin:/usr/local/sbin
#
# IF PATCHMGR is empty or does not exist, then exit.
#
if [[ -z $PATCHMGR_HOME ]]; then
        echo "INFO: PATCHMGR_HOME variable empty, using default location: [/opt/patchmgr]."
        PATCHMGR_HOME=/opt/patchmgr
fi

if [[ ! -d $PATCHMGR_HOME ]]; then 
        echo "ERROR: Directory for PATCHMGR_HOME [$PATCHMGR_HOME] does not exist Bye."
        exit 18
fi
#
#set -e     # exit the script if any statement returns a non-true return value
set -u     # exit the script if you try to use an uninitialised variable
#

#--------------------------------------------------------------
#
ODMDIR=/etc/objrepos
PATCHMGR_SCRIPT_HOME=$PATCHMGR_HOME/scripts
INFO_LOGS_HOME=$PATCHMGR_HOME/info_logs
AP_SCHEDULER_SCRIPT=$PATCHMGR_SCRIPT_HOME/ap_scheduler.sh
#
AIX_GATHER_INFO_SCRIPT=$PATCHMGR_SCRIPT_HOME/aix_info.sh
SOLARIS_GATHER_INFO_SCRIPT=$PATCHMGR_SCRIPT_HOME/solaris_info.sh
RHEL_GATHER_INFO_SCRIPT=$PATCHMGR_SCRIPT_HOME/rhel_info.sh
ZLINUX_GATHER_INFO_SCRIPT=$PATCHMGR_SCRIPT_HOME/zlinux_info.sh
#
#--------------------------------------------------------------
DATESTAMP=`date "+%d-%m-%Y_%H%M"`
OUTDIR=$INFO_LOGS_HOME/$DATESTAMP;export OUTDIR
#--------------------------------------------------------------
OPTIND=1
ANSWER_YES=0
REBOOT=0
DRYRUN=0
FORCE_RUN_NOW=FALSE
#--------------------------------------------------------------

###############################################################

while getopts ":hdnrvy" opt
do
        case "$opt" in
        h)
            echo
            echo "Usage: ${0##*/} [-y] [-d] [-n] [-r] [-v] [-h]"
            echo
            echo "          -y    Answer yes to any prompt."
            echo "          -d    Dry run. Do not actually patch or reboot."
            echo "          -n    Run now.  Don't check date variables."
            echo "          -r    Reboot after patching."
            echo "          -v    Display version."
            echo "          -h    Help."
            echo
            exit 0
            ;;
        n)
            FORCE_RUN_NOW=TRUE
            ;;
        r)
            REBOOT=1
            ;;
        d)
            DRYRUN=1
            ;;
        v)
            echo
            echo "Version: $VERSION"
            echo
            exit 0
            ;;
        y)
            ANSWER_YES=1
            ;;
        esac
done

###############################################################
###############################################################
#  Exit script if you can't load the environment variable file
if [[ ! -f $PATCHMGR_HOME/auto_patch.env ]] ; then
   echo "ERROR: Could not find environment variable file: $PATCHMGR_HOME/auto_patch.env. Bye."
   exit 2
fi
. $PATCHMGR_HOME/auto_patch.env
###############################################################


###############################################################
#  Validate certain variables

###############################################################

echo
echo "=========================================================="
echo "             $VERSION"
echo "=========================================================="
echo "                       Variables"
echo "----------------------------------------------------------"
echo 
echo "    PATCHMGR_HOME=$PATCHMGR_HOME"
echo "   INFO_LOGS_HOME=$INFO_LOGS_HOME"
echo "           OUTDIR=$OUTDIR"
echo "   AUTO_PATCH_ENV=$PATCHMGR_HOME/auto_patch.env"
echo
echo "    FORCE_RUN_NOW=$FORCE_RUN_NOW"
echo "           REBOOT=$REBOOT"
echo "           DRYRUN=$DRYRUN"
echo "       ANSWER_YES=$ANSWER_YES"
echo
echo "----------------------------------------------------------"

###############################################################
#  FUNCTION: ask
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
function ctrl_c() {
        echo "INFO: CTRL-BREAK detected.  Stopping..."
}

##############################################################################
### Update AIX Patches and Fixes
##############################################################################
#
function aix_update {
	$PATCHMGR_SCRIPT_HOME/aix_efix_updater.sh -r  # Remove all efixes
	$PATCHMGR_SCRIPT_HOME/aix_bundle_updater.sh   # Apply Bundle
	$PATCHMGR_SCRIPT_HOME/aix_patch_updater.sh    # Apply patches
	$PATCHMGR_SCRIPT_HOME/aix_efix_updater.sh -a  # Apply efixes
}

##############################################################################
### Update Operating System with PCA
##############################################################################
#
function solaris_update {
set +e
        echo "--> Running PCA Patch Update..."
        /usr/local/bin/pca -i missingrs && $PATCHMGR_SCRIPT_HOME/motd > /etc/motd
        ERRCODE=$?
        if [ $ERRCODE -eq 0 ] || [ $ERRCODE -gt 2 ]; then
            echo "INFO: PCA patch update successful."
        else
            echo "ERROR: Exit Code $ERRCODE: There seemed to be a problem with the patches installation. Bye."
            exit 1
        fi
set -e
}

##############################################################################
### Update Operating System with YUM
##############################################################################
#
function rhel_update {
	echo "INFO: Running yum clean all..."  # >/opt/LINUXexplo/linux/YumUpdateList.txt
	/usr/bin/yum clean all

        echo "INFO: Running /usr/bin/yum list updates >> $OUTDIR/YumUpdateList.txt"
	/usr/bin/yum list updates >> $OUTDIR/YumUpdateList.txt

        echo "INFO: Running /usr/bin/yum -y update >> $OUTDIR/YumUpdate.txt"
	/usr/bin/yum -y update >> $OUTDIR/YumUpdate.txt

	if [[ $? = 0 ]]; then
   	    echo "INFO: Yum update successful."
	else
   	    echo "ERROR: There seemed to be a problem with the patches installation. Halting script now."
   	exit 1
	fi
}

##############################################################################
### Update Operating System with Zypper
##############################################################################
#
function zlinux_update {
echo "INFO: Running Zypper Update..."
/usr/bin/zypper --non-interactive lu >> $OUTDIR/ZypperUpdateList.txt
/usr/bin/zypper --non-interactive update >> $OUTDIR/ZypperUpdate.txt
if [[ $? = 0 ]]; then
   echo "INFO: Zypper update successful."
else
   echo "ERROR: There seemed to be a problem with the patches installation. Halting script now."
   exit 1
fi
#
}

###############################################################
#
if [ -f "$PATCHMGR_HOME/DONOTPATCH" ] || [ -f "$PATCHMGR_HOME/NOPATCH" ]; then
   echo "WARNING: FOUND DONOTPATCH file: [`ls $PATCHMGR_HOME/*NO*PATCH`] Bye."
   exit 1
fi
#


#####    REALLY BEGIN PATCHING HERE !!!   
echo "INFO: AUTOPATCH BEGIN [`date`]"
#####

###############################################################
# RUN AP_SCHEDULER.SH TO CHECK IF YOU MUST RUN TODAY 
###
if [[ ! -f $AP_SCHEDULER_SCRIPT ]]; then
      echo "ERROR: Auto Patch Scheduling Script [ap_scheduler.sh] was not found.  Bye."
      exit 34
fi
if [[ $FORCE_RUN_NOW == "FALSE" ]];then
     $AP_SCHEDULER_SCRIPT
     if [[ ! $? -eq 0 ]]; then 
        exit 77 # Not my run day
     fi
fi
###############################################################



###############################################################
# LIST OLD LOGS FOR REMOVAL
#
echo "INFO: Removing old info_log subdirectories.  Deleting all except the five (5) most recent:"
echo "`ls -drt $PATCHMGR_HOME/info_logs/* 2>/dev/null|tail -5`" 
#

###############################################################
#  CREATE NEW OUTDIR DIRECTORY TO STORE INFO_LOGS
#
echo "INFO: Creating new directory for info_logs: $OUTDIR"
#
mkdir -p $OUTDIR
if [[ ! -d $OUTDIR ]]; then
    echo "ERROR:  There was a problem accessing directory [ $OUTDIR ]."
    exit 4
fi

###############################################################
#  REMOVE OLD INFO_LOG DIRS (KEEP THE 5 MOST RECENT)
#

set -o nounset

OLD_INFO_LOGS=`ls -dt $PATCHMGR_HOME/info_logs/* 2> /dev/null|awk 'NR>5{print $1}'`

if [[ -z $OLD_INFO_LOGS ]];then
	echo "INFO: No logs to remove."
else
	for i in $OLD_INFO_LOGS 
	do
           info_log_test=`echo $i|grep "info_logs"` # Check to see if "info_logs" is in the path's name
           if [[ ! -z $info_log_test ]]; then 
               echo "INFO: Removing old info_log directory: $i" 
               rm -f $i/* 2>/dev/null
               rmdir $i
          else 
               echo "WARNING: I should not remove this directory: [$i]" 
           fi
	   done
fi
#
###############################################################
set +e  #  From now on continue regardless of error code
###############################################################
#  Gather Relevant OS Data and define Patcher function
###############################################################
OS_VERSION=`uname -s`

        case "$OS_VERSION" in
        AIX)
            $AIX_GATHER_INFO_SCRIPT
            PATCHER="aix_update"
            REBOOT_CMD="/usr/sbin/shutdown -Fr" 
            ;;
        SunOS)
            $SOLARIS_GATHER_INFO_SCRIPT
            PATCHER="solaris_update"
            REBOOT_CMD="/etc/reboot"
            ;;
        Linux)
            LINUX_VERSION=`python -m platform`
            if [[ ! -z "`echo $LINUX_VERSION|grep 'centos'`" ]]; then 
                 $RHEL_GATHER_INFO_SCRIPT
                 PATCHER="rhel_update"
                 REBOOT_CMD="/sbin/reboot"
            elif [[ ! -z "`echo $LINUX_VERSION|grep 'SUSE'`" ]];then 
                 $ZLINUX_GATHER_INFO_SCRIPT
                 PATCHER="zlinux_update"
                 REBOOT_CMD="/sbin/reboot"
            else
                 echo "WARNING: Don't know how to gather info on this Linux version: $LINUX_VERSION"
            fi
            ;;
        *)
	    echo "ERROR: Cannot determine OS version. Bye."
            exit 23
            ;;
        esac

echo "PATCHER=$PATCHER"
##############################################################################
set -e #   STOP SCRIPT ON ERROR 
##############################################################################


#########################
### Shutdown APPs
#########################
if [[ -f "$PATCHMGR_SCRIPT_HOME/stopAPPs.sh" ]];then 
        echo "INFO: Executing the [$PATCHMGR_SCRIPT_HOME/stopAPPs.sh] shell script."
        if [[ $DRYRUN = "0" ]]; then

             $PATCHMGR_SCRIPT_HOME/stopAPPs.sh
        else 
         
             echo "INFO: DRYRUN enabled.  Listing $PATCHMGR_SCRIPT_HOME/stopAPPs.sh."
             ls -ld $PATCHMGR_SCRIPT_HOME/stopAPPs.sh
        fi
else 
	echo "WARNING: The [$PATCHMGR_SCRIPT_HOME/stopAPPs.sh] script was not found... Good Luck!"
fi 
#########################
if [[ -f "$PATCHMGR_SCRIPT_HOME/stopDBs.sh" ]];then
        echo "INFO: Executing the [$PATCHMGR_SCRIPT_HOME/stopDBs.sh] shell script."
        if [[ $DRYRUN = "0" ]]; then
 
             $PATCHMGR_SCRIPT_HOME/stopDBs.sh
        else
             echo "INFO: DRYRUN enabled.  Listing $PATCHMGR_SCRIPT_HOME/stopDBs.sh."
             ls -ld $PATCHMGR_SCRIPT_HOME/stopDBs.sh
        fi

else
        echo "WARNING: The [$PATCHMGR_SCRIPT_HOME/stopDBs.sh] script was not found... Good Luck!"
fi 

if [[ $DRYRUN = "0" ]]; then
     echo "INFO: Patching server..."

##############################################################################
### PERFORM PATCH UPDATES!
##############################################################################

$PATCHER

##############################################################################
### Reboot server to finish appliying patches !!!
##############################################################################
trap 'ctrl_c; exit' SIGINT SIGQUIT

  if [[ $REBOOT = "1" ]] ; then

     echo "Do you want me to REBOOT the server now? (y/n)?"
     answer="$(ask)"
     if [[ $answer = "yes" ]];then
      date
      echo "INFO: Performing Reboot in 120 seconds!!!..."
      sleep 120
########################
      $REBOOT_CMD 
########################
     else 
      echo "INFO: No reboot will be performed."
      echo "END OF $0"
     fi
  fi

else 
   echo "INFO: DRY RUN. No patches or fixes have been applied. No reboot will be performed."
   echo "END OF $0"
   date
fi
##############################################################################
