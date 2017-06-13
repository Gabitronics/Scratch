#!/bin/bash
###############################################################
#--------------------------------------------------------------
PATCHMGR_HOME=/opt/patchmgr
#--------------------------------------------------------------
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

echo "Getting root's crontab -l..."
crontab -l > $OUTDIR/crontab_l.txt

echo "Getting ps -ef..."
/bin/ps -ef > $OUTDIR/ps_ef.txt

echo "Getting uptime..."
/usr/bin/uptime > $OUTDIR/uptime.txt

echo "Getting who -r..."
/usr/bin/who -r > $OUTDIR/who_r.txt

echo "Getting last..."
/usr/bin/last > $OUTDIR/last.txt

echo "Getting zypper list updates..."
/usr/bin/zypper --non-interactive lu > $OUTDIR/zypper_list_updates.txt

echo "Getting zypper list patches..."
/usr/bin/zypper --non-interactive lp > $OUTDIR/zypper_list_patches.txt

echo "Getting ip addr..."
/sbin/ip addr > $OUTDIR/ip_addr.txt

echo "Getting vgdisplay..."
/sbin/vgdisplay > $OUTDIR/vgdisplay.txt

echo "Getting lvdisplay..."
/sbin/lvdisplay > $OUTDIR/lvdisplay.txt

echo "Getting pvdisplay..."
/sbin/pvdisplay > $OUTDIR/pvdisplay.txt

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

echo "Getting zipl.conf..."
cat /etc/zipl.conf > $OUTDIR/zipl.txt

echo "Getting lsluns..."
/usr/sbin/lsluns > $OUTDIR/lsluns.txt

echo "Getting lszfcp -D..."
/sbin/lszfcp -D > $OUTDIR/lszfcp-D.txt

echo "Getting lsscsi..."
/usr/bin/lsscsi > $OUTDIR/lssci.txt

echo "Getting /etc/SuSE-release..."
cat /etc/SuSE-release > $OUTDIR/SuSE-release.txt

echo "Get currently mounted filesystems..."
mount > $OUTDIR/mount.txt

##############################################################################

