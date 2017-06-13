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

#  Gather Relevant OS Data
###############################################################
echo "Backing up /etc/..."
date >> $OUTDIR/etc_backup_list.txt
(cd /;tar cvf - ./etc 2>> $OUTDIR/etc_backup_list.txt)| gzip -c > $OUTDIR/etc_backup.tar.gz
date >> $OUTDIR/etc_backup_list.txt
sleep 1
##################################################
echo "Getting hostname..."
date >> $OUTDIR/hostname.txt
/usr/bin/hostname >> $OUTDIR/hostname.txt 2>&1
date >> $OUTDIR/hostname.txt
sleep 1
##################################################
echo "Getting root's crontab -l..."
date >> $OUTDIR/crontab_l.txt
crontab -l >> $OUTDIR/crontab_l.txt 2>&1
date >> $OUTDIR/crontab_l.txt
sleep 1
##################################################
echo "Backing up crontabs..."
date >> $OUTDIR/crontabs.txt
(cd /;tar cvf - ./var/spool/cron 2>> $OUTDIR/crontabs.txt)|gzip -c > $OUTDIR/crontabs.tar.gz
date >> $OUTDIR/crontabs.txt
sleep 1
##################################################
echo "Getting oslevel -s..."
date >> $OUTDIR/oslevel.txt
/usr/bin/oslevel -s >> $OUTDIR/oslevel.txt 2>&1
date >> $OUTDIR/oslevel.txt
sleep 1
##################################################
echo "Getting uname -a..."
date >> $OUTDIR/uname.txt
/usr/bin/uname -a >> $OUTDIR/uname.txt 2>&1  
date >> $OUTDIR/uname.txt
sleep 1
##################################################
echo "Getting df-k..."
date >>  $OUTDIR/df_k.txt
/usr/bin/df -k >> $OUTDIR/df_k.txt 2>&1
date >>  $OUTDIR/df_k.txt
sleep 1
##################################################
echo "Getting ps_ef..."
date >>  $OUTDIR/ps_ef.txt
/usr/bin/ps -ef >> $OUTDIR/ps_ef.txt 2>&1
date >>  $OUTDIR/ps_ef.txt
sleep 1
##################################################
echo "Getting uptime..."
date >> $OUTDIR/uptime.txt 2>&1
/usr/bin/uptime >> $OUTDIR/uptime.txt 2>&1
date >> $OUTDIR/uptime.txt
sleep 1
##################################################
echo "Getting who -r..."
date >> $OUTDIR/who_r.txt
/usr/bin/who -r >> $OUTDIR/who_r.txt 2>&1
date >> $OUTDIR/who_r.txt
sleep 1
##################################################
echo "Getting netstat -an..."
date >> $OUTDIR/netstat_an.txt
netstat -an >> $OUTDIR/netstat_an.txt 2>&1
date >> $OUTDIR/netstat_an.txt
sleep 1
##################################################
echo "Getting netstat -rn..."
date >> $OUTDIR/netstat_rn.txt
netstat -rn >> $OUTDIR/netstat_rn.txt 2>&1
date >> $OUTDIR/netstat_rn.txt
sleep 1
##################################################
echo "Getting last..."
date >> $OUTDIR/last.txt
/usr/bin/last -n 50 >> $OUTDIR/last.txt 2>&1
date >> $OUTDIR/last.txt
sleep 1
##################################################
echo "Getting emgr -l..."
date >> $OUTDIR/emgr_l.txt
/usr/sbin/emgr -l >> $OUTDIR/emgr_l.txt 2>&1
date >> $OUTDIR/emgr_l.txt
sleep 1
##################################################
echo "Getting emgr -P..."
date >> $OUTDIR/emgr_P.txt
/usr/sbin/emgr -P >> $OUTDIR/emgr_P.txt 2>&1
date >> $OUTDIR/emgr_P.txt
sleep 1

##################################################
echo "Getting lslpp -L..."
date >> $OUTDIR/lslpp_L.txt
/usr/bin/lslpp -L >> $OUTDIR/lslpp_L.txt 2>&1
date >> $OUTDIR/lslpp_L.txt
sleep 1
#################################################
echo "Getting lppchk -v..."
date >> $OUTDIR/lppchk_v.txt
/usr/bin/lppchk -v >> $OUTDIR/lppchk_v.txt 2>&1
date >> $OUTDIR/lppchk_v.txt
sleep 1
#################################################
echo "Getting lscfg -pv..."
date >> $OUTDIR/lscfg_pv.txt
/usr/sbin/lscfg -pv >> $OUTDIR/lscfg_pv.txt 2>&1
date >> $OUTDIR/lscfg_pv.txt
sleep 1
##################################################
echo "Getting lsdev -Cc..."
date >> $OUTDIR/lsdev_Cc_adapter.txt
/usr/sbin/lsdev -Cc adapter >> $OUTDIR/lsdev_Cc_adapter.txt 2>&1
date >> $OUTDIR/lsdev_Cc_adapter.txt
sleep 1
##################################################
echo "Getting rpm -qa..."
date >> $OUTDIR/rpm_qa.txt
/usr/bin/rpm -qa >> $OUTDIR/rpm_qa.txt 2>&1
date >> $OUTDIR/rpm_qa.txt
sleep 1
##################################################
echo "Getting /etc/filesystems..."
date >> $OUTDIR/filesystems.txt
cat /etc/filesystems >> $OUTDIR/filesystems.txt
date >> $OUTDIR/filesystems.txt
sleep 1
##################################################
echo "Getting ifconfig -a..."
date  >> $OUTDIR/ifconfig_a.txt
/usr/sbin/ifconfig -a >> $OUTDIR/ifconfig_a.txt 2>&1
date  >> $OUTDIR/ifconfig_a.txt
sleep 1
##################################################
echo "Getting lsvg -l..."
date  >> $OUTDIR/lsvg_l.txt
/usr/sbin/lsvg -l `/usr/sbin/lsvg` >> $OUTDIR/lsvg_l.txt 2>&1
/usr/sbin/lsvg >> $OUTDIR/lsvg_l.txt 2>&1
date  >> $OUTDIR/lsvg_l.txt
sleep 1
#################################################
echo "Getting lspv -l..."
date >>  $OUTDIR/lspv_l.txt
lspv >>  $OUTDIR/lspv_l.txt 2>&1
for i in `lspv |awk '{print $1}'`
do
lspv -l $i >>  $OUTDIR/lspv_l.txt 2>&1
done
date >>  $OUTDIR/lspv_l.txt
#################################################
echo "Getting bootlist -m normal -o..."
date >>  $OUTDIR/bootlist.txt
/usr/bin/bootlist -m normal -o >> $OUTDIR/bootlist.txt 2>&1
date >>  $OUTDIR/bootlist.txt
#################################################

