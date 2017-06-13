#!/bin/bash
################################################
#
AP_PATCHMGR_DIR=/opt/patchmgr
AP_PATCH_DIR=/mkimage/patchmgr/latest_patches
orig_dir=`pwd`
#
################################################
#
echo "INFO: Running $0..."
[[ -z `ls $AP_PATCH_DIR/* 2>/dev/null` ]] && echo "INFO: No patches found on $AP_PATCH_DIR" && exit

echo "INFO: Removing .toc, if it exists..."
if [[ -f "$AP_PATCH_DIR/.toc" ]];then
    rm $AP_PATCH_DIR/.toc
else
    echo "INFO: No .toc to remove."
fi

cd $AP_PATCH_DIR
lslpp -L > $AP_PATCHMGR_DIR/lslpp_Before_Patches
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
# PREVIEWING PATCHES 
#
echo "INFO: PREVIEWING PATCHES..."
sleep 2

install_all_updates -V -r -p -Y -d . 
ERRCODE=$?
echo "ERR $ERRCODE"
if [[ $ERRCODE -ne 0 ]]; then
   echo "ERROR: Preview FAILED! Bye."
   exit 2
fi

################################################
# APPLYING PATCHES
#
echo "INFO: APPLYING PATCHES..."
sleep 2

install_all_updates -V -s -r -Y -d .
ERRCODE=$?
echo "ERR $ERRCODE"
if [[ $ERRCODE -ne 0 ]]; then
   echo "ERROR: Patches installation FAILED! Bye."
   exit 2
fi

cd $orig_dir    
echo
#
#
lslpp -L > $AP_PATCHMGR_DIR/lslpp_After_Patches

diff $AP_PATCHMGR_DIR/lslpp_Before_Patches $AP_PATCHMGR_DIR/lslpp_After_Patches

echo "INFO: Finished applying patches..."

