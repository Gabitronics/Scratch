#!/bin/bash
###############################################################
#--------------------------------------------------------------
PATCHMGR_HOME=/opt/patchmgr
#--------------------------------------------------------------
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
export PATH
###############################################################
#--------------------------------------------------------------
INFO_LOGS_HOME=$PATCHMGR_HOME/info_logs
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

###############################################################
#  Gather Relevant OS Data
###############################################################

echo "Backing up /etc/..."
date >> $OUTDIR/etc_backup_list.txt
(cd /;tar cvf - ./etc 2>> $OUTDIR/etc_backup_list.txt)| gzip -c > $OUTDIR/etc_backup.tar.gz
date >> $OUTDIR/etc_backup_list.txt

echo "Backing up /boot..."
date >> $OUTDIR/slash_boot.txt
(cd /;tar cvf - ./boot 2>> $OUTDIR/slash_boot.txt)|gzip -c > $OUTDIR/slash_boot.tar.gz
date >> $OUTDIR/slash_boot.txt

echo "Backing up crontabs..."
date >> $OUTDIR/crontabs.txt
(cd /;tar cvf - ./var/spool/cron 2>> $OUTDIR/crontabs.txt)|gzip -c > $OUTDIR/crontabs.tar.gz
date >> $OUTDIR/crontabs.txt

echo "Getting uname -a..."
/bin/uname -a > $OUTDIR/uname.txt

echo "Getting df -k..."
/bin/df -k > $OUTDIR/df_k.txt

echo "Getting root crontab -l..."
crontab -l > $OUTDIR/crontab_l.txt

echo "Getting ps -ef..."
/bin/ps -ef > $OUTDIR/ps_ef.txt

echo "Getting uptime..."
/usr/bin/uptime > $OUTDIR/uptime.txt

echo "Getting who -r..."
/usr/bin/who -r > $OUTDIR/who_r.txt

echo "Getting anaconda-ks.cfg..."
cp /anaconda-ks.cfg $OUTDIR/ 2>/dev/null
cp /root/anaconda-ks.cfg $OUTDIR/ 2>/dev/null

echo "Getting last..."
/usr/bin/last > $OUTDIR/last.txt

echo "Getting package-cleanup --dupes..."
if [[ ! -f /usr/bin/package-cleanup ]]; then 
     utils_rpm=`rpm -qa |grep yum-utils`  
     if [[ $? -eq 1 ]]; then 
        echo "Package yum-utils does not seem to be installed.  Attempting installation..."
        yum -y install yum-utils > $OUTDIR/package-cleanup_dupes.txt
     fi
fi
/usr/bin/package-cleanup --dupes >> $OUTDIR/package-cleanup_dupes.txt

echo "Getting yum list updates..."
/usr/bin/yum list updates > $OUTDIR/yum_list_updates.txt

echo "Getting rpm -qa..."
/bin/rpm -qa > $OUTDIR/rpm_qa.txt

echo "Getting ip addr..."
/sbin/ip addr > $OUTDIR/ip_addr.txt

echo "Getting vgdisplay..."
$VGDISPLAY > $OUTDIR/vgdisplay.txt

echo "Getting lspci..."
/sbin/lspci > $OUTDIR/lspci.txt

echo "Getting lvdisplay..."
$LVDISPLAY > $OUTDIR/lvdisplay.txt

echo "Getting pvdisplay..."
$PVDISPLAY> $OUTDIR/pvdisplay.txt

echo "Getting netstat -rn..."
/bin/netstat -rn > $OUTDIR/netstat_rn.txt

echo "Getting netstat -an..."
/bin/netstat -an > $OUTDIR/netstat_an.txt

echo "Getting top -n 1..."
/usr/bin/top -n 1 > $OUTDIR/top_n1.txt

echo "Getting multipath -ll..."
/sbin/multipath -ll > $OUTDIR/multipath_ll.txt

echo "Getting fstab.."
cat /etc/fstab > $OUTDIR/fstab.txt

echo "Getting /etc/redhat-release..."
cat /etc/redhat-release > $OUTDIR/redhat-release.txt

echo "Get currently mounted filesystems..."
mount > $OUTDIR/mount.txt

echo "Fixing permissions to o+r in $OUTDIR files..."
chmod o+r $OUTDIR/*

##############################################################################

