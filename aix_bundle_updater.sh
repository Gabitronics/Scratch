#!/bin/bash
################################################
#
AP_PATCHMGR_DIR=/opt/patchmgr
AP_PATCH_DIR=/mkimage/patchmgr/latest_bundle
orig_dir=`pwd`
#
################################################
#
echo "INFO: Running $0..."
[[ -z `ls $AP_PATCH_DIR/* 2>/dev/null` ]] && echo "INFO: No patch bundle found on $AP_PATCH_DIR" && exit

echo "INFO: Removing .toc, if it exists..."
if [[ -f "$AP_PATCH_DIR/.toc" ]];then
    rm $AP_PATCH_DIR/.toc
else
    echo "INFO: No .toc to remove."
fi

cd $AP_PATCH_DIR
lslpp -L > $AP_PATCHMGR_DIR/lslpp_Before_Bundle
#
#
#
#
echo "INFO: Reporting Broken Filesets (lppchk -v)..."
lppchk -v
echo "INFO: End of lppchk -v"

ERRCODE=$?
echo "ERR $ERRCODE"
if [[ $ERRCODE -ne 0 ]];then
   echo "ERROR: LPPCHK  FAILED! Bye."
   exit 2
fi 
################################################
# PREVIEWING BUNDLE INSTALLATION
#
echo "INFO: PREVIEWING BUNDLE..."
sleep 2

install_all_updates -V -p -Y -d . 
ERRCODE=$?
echo "ERR $ERRCODE"
if [[ $ERRCODE -ne 0 ]]; then
   echo "INFO: Preview FAILED! Bye."
   exit 2
fi
################################################
# APPLYING BUNDLE INSTALLATION
#
echo "INFO: COMMITTING ALL FILESETS IN APPLIED STATE..."
installp -cgX all
ERRCODE=$?
echo "ERR $ERRCODE"
if [[ $ERRCODE -ne 0 ]]; then
   echo "INFO: Failed to commit all filesets in applied state! Bye."
   exit 2
fi

echo "INFO: APPLYING BUNDLE..."
sleep 2

install_all_updates -V -s -Y -d .
ERRCODE=$?
echo "ERR $ERRCODE"
if [[ $ERRCODE -ne 0 ]]; then
   echo "ERROR: Bundle installation FAILED! Bye."
   exit 2
fi

cd $orig_dir    
echo
#
#
lslpp -L > $AP_PATCHMGR_DIR/lslpp_After_Bundle

diff $AP_PATCHMGR_DIR/lslpp_Before_Bundle $AP_PATCHMGR_DIR/lslpp_After_Bundle

echo "INFO: Finished applying bundle..."

