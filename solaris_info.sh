#!/bin/bash
###############################################################
#--------------------------------------------------------------
PATCHMGR_HOME=/opt/patchmgr
INFO_LOGS_HOME=$PATCHMGR_HOME/info_logs
#--------------------------------------------------------------
###############################################################
export PATH=$PATH:/usr/sbin:/sbin:/usr/bin:/bin:/usr/local/bin:/usr/local/sbin:/usr/sfw/bin:/usr/sfw/sbin
PCA_URL=http://10.1.34.199:88/latest_patchdiag.xref
WGET=`which wget`
#--------------------------------------------------------------

# IF OUTDIR is empty or does not exist, then create one
if [ ! -d $OUTDIR ] || [ -z $OUTDIR ]; then 
        echo "OUTDIR variable empty or directory does not exist."
	DATESTAMP=`date "+%d-%m-%Y_%H%M"`
	OUTDIR=$INFO_LOGS_HOME/$DATESTAMP
        echo "Creating directory [$OUTDIR]"
        mkdir -p $OUTDIR
        if [[ ! $? -eq 0 ]];then 
           echo "Error creating OUTDIR [$OUTDIR]."
           exit 55
        fi
fi
##################################################
# GET THIS CICLE'S patchdiag.xref
##################################################

if [[ $WGET = "/usr/sfw/bin/wget" ]]
then
   /usr/sfw/bin/wget --tries=2 --connect-timeout=5 $PCA_URL -O /var/tmp/latest_patchdiag.xref
   if [[ $? = 0 ]]; then
       cp /var/tmp/latest_patchdiag.xref /var/tmp/patchdiag.xref
   fi
elif [[ $WGET = "/usr/local/bin/wget" ]]
then
   /usr/local/bin/wget --tries=2  $PCA_URL -O /var/tmp/latest_patchdiag.xref
   if [[ $? = 0 ]]; then
       cp /var/tmp/latest_patchdiag.xref /var/tmp/patchdiag.xref
   fi
fi

#  Gather Relevant OS Data
###############################################################
echo "Backing up /etc/..."
date >> $OUTDIR/etc_backup_list.txt
(cd /;tar cvf - /etc 2>> $OUTDIR/etc_backup_list.txt)| gzip -c > $OUTDIR/etc_backup.tar.gz
date >> $OUTDIR/etc_backup_list.txt

echo "Backing up crontabs..."
date >> $OUTDIR/crontabs.txt
(cd /;tar cvf - /var/spool/cron 2>> $OUTDIR/crontabs.txt)|gzip -c > $OUTDIR/crontabs.tar.gz
date >> $OUTDIR/crontabs.txt

##################################################
echo "Getting hostname..."
date >> $OUTDIR/hostname.txt
/usr/bin/hostname >> $OUTDIR/hostname.txt 2>&1
date >> $OUTDIR/hostname.txt
##################################################
echo "Getting /etc/release..."
date >> $OUTDIR/release.txt
cat /etc/release >> $OUTDIR/release.txt 2>&1
date >> $OUTDIR/release.txt
##################################################
echo "Getting root's crontab -l..."
date >> $OUTDIR/crontab_l.txt
cat /etc/release >> $OUTDIR/crontab_l.txt 2>&1
date >> $OUTDIR/crontab_l.txt
##################################################
echo "Getting svcs -a..."
date >> $OUTDIR/svcs_a.txt
/usr/bin/svcs -a >> $OUTDIR/svcs_a.txt 2>&1
date >> $OUTDIR/svcs_a.txt
##################################################
echo "Getting /etc/passwd..."
date >> $OUTDIR/passwd.txt
cat /etc/passwd >> $OUTDIR/passwd.txt 2>&1
date >> $OUTDIR/passwd.txt
##################################################
echo "Getting /etc/shadow..."
date >> $OUTDIR/shadow.txt
cat /etc/shadow >> $OUTDIR/shadow.txt 2>&1
date >> $OUTDIR/shadow.txt
##################################################
echo "Getting netstat -an..."
date >> $OUTDIR/netstat_an.txt
netstat -an >> $OUTDIR/netstat_an.txt 2>&1
date >> $OUTDIR/netstat_an.txt
##################################################
echo "Getting netstat -rn..."
date >> $OUTDIR/netstat_rn.txt
netstat -rn >> $OUTDIR/netstat_rn.txt 2>&1
date >> $OUTDIR/netstat_rn.txt
##################################################
echo "Getting /etc/group..."
date >> $OUTDIR/group.txt
cat /etc/group >> $OUTDIR/group.txt 2>&1
date >> $OUTDIR/group.txt
#########################################
echo "Getting uname -a..."
date >> $OUTDIR/uname.txt
/usr/bin/uname -a >> $OUTDIR/uname.txt 2>&1
date >> $OUTDIR/uname.txt
##################################################
echo "Getting showrev -p..."
date >> $OUTDIR/showrev_p.txt
/usr/bin/showrev -p >> $OUTDIR/showrev_p.txt 2>&1
date >> $OUTDIR/showrev_p.txt
##################################################
echo "Getting pkginfo..."
date >> $OUTDIR/pkginfo.txt
/usr/bin/pkginfo >> $OUTDIR/pkginfo.txt 2>&1
date >> $OUTDIR/pkginfo.txt
##################################################
echo "Getting df-k..."
date >>  $OUTDIR/df_k.txt
/usr/bin/df -k >> $OUTDIR/df_k.txt 2>&1
date >>  $OUTDIR/df_k.txt
##################################################
echo "Getting mount..."
date >>  $OUTDIR/mount.txt
/usr/sbin/mount >> $OUTDIR/mount.txt 2>&1
date >>  $OUTDIR/mount.txt
##################################################
echo "Getting ps_ef..."
date >>  $OUTDIR/ps_ef.txt
/usr/bin/ps -ef >> $OUTDIR/ps_ef.txt 2>&1
date >>  $OUTDIR/ps_ef.txt
##################################################
echo "Getting uptime..."
date >> $OUTDIR/uptime.txt 2>&1
/usr/bin/uptime >> $OUTDIR/uptime.txt 2>&1
date >> $OUTDIR/uptime.txt
##################################################
echo "Getting who -r..."
date >> $OUTDIR/who_r.txt
/usr/bin/who -r >> $OUTDIR/who_r.txt 2>&1
date >> $OUTDIR/who_r.txt
##################################################
echo "Getting last..."
date >> $OUTDIR/last.txt
/usr/bin/last -n 50 >> $OUTDIR/last.txt 2>&1
date >> $OUTDIR/last.txt
##################################################
echo "Getting ifconfig -a..."
date  >> $OUTDIR/ifconfig_a.txt
/usr/sbin/ifconfig -a >> $OUTDIR/ifconfig_a.txt 2>&1
date  >> $OUTDIR/ifconfig_a.txt
##################################################
echo "Getting zpool info..."
date  >> $OUTDIR/zpool.txt
/usr/sbin/zpool list >> $OUTDIR/zpool.txt 2>&1
/usr/sbin/zpool status >> $OUTDIR/zpool.txt 2>&1
date  >> $OUTDIR/zpool.txt
##################################################
echo "Getting zfs list..."
date  >> $OUTDIR/zfs_list.txt
/usr/sbin/zfs list >> $OUTDIR/zfs_list.txt 2>&1
date  >> $OUTDIR/zfs_list.txt
##################################################
echo "Getting zoneadm list -cv..."
date  >> $OUTDIR/zoneadm_list.txt
/usr/sbin/zoneadm list -cv >> $OUTDIR/zoneadm_list.txt 2>&1
date  >> $OUTDIR/zoneadm_list.txt
##################################################
echo "Getting /etc/system..."
date  >> $OUTDIR/system.txt
cat /etc/system >> $OUTDIR/system.txt 2>&1
date  >> $OUTDIR/system.txt
##################################################
echo "Getting pca -l -missingrs..."
date  >> $OUTDIR/pca_l_missingrs.txt
/usr/local/bin/pca -l missingrs >> $OUTDIR/pca_l_missingrs.txt 2>&1
date  >> $OUTDIR/pca_l_missingrs.txt

