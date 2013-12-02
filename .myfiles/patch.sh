device=edison
branch=cm-11.0
mode=""
oldupdate=1
#### functions ############

#initBranch <dir> <localBranchName> <remoteName> <remote.git> <remote_branch>
initBranch()
{
	curdir=`pwd`
	if [ $# -lt 5 ]; then return -1;fi
	[ -d $1 ] || mkdir -p $1
	cd $1
	git branch | grep -wq "$branch" || git branch $branch
	git remote | grep -wq "$3" || git remote add $3 $4
	
	if ! git branch | grep -wq "$2"; then
		git checkout --orphan $2
		rm -rf * 
		git add -A
		git commit -a -m "init branch"
		git fetch $3 $5
		git merge FETCH_HEAD -m "First Fetch"
	fi

	if [ _`git branch | grep "\*" |cut -f2 -d" "` != _$2 ] ; then 
		git checkout $2
	fi
	
	cd $curdir
	return 0
}

#updateBranch <dir> <localBranch> <remoteName> <remoteBranch>
updateBranch()
{
	curdir=`pwd`
	if [ $# -lt 4 ]; then return -1;fi
	[ -d $1 ] || mkdir -p $1
	cd $1
	git checkout $2
	git fetch $3 $4
	git merge FETCH_HEAD -m "$3:$4 `date +%Y%m%d`"
	cd $curdir
	return 0
}

### parse params #########
for op in $*;do 
   if [ "$op" = "spyder" ]; then
   	device="$op"
   elif [ "$op" = "edison" ]; then
	device="edison"
   elif [ "$op" = "jordan" -o "$op" = "mb526" ]; then
	device="mb526"
   elif [ "${op:0:1}" = "-" ]; then
	mode="${op#-*}"
   elif [ "$op" = "old" ]; then
	oldupdate=1
   elif [ "$op" = "new" ]; then
	oldupdate=0
   fi
done
cdir=`pwd`
rdir=`cd \`dirname $0\`;pwd`

basedir=`dirname $rdir`
[ -s $basedir/.device ] && lastDevice=`cat $basedir/.device`

## local_manifest.xml   ####
if [ -d $basedir/.repo -a -f $rdir/local_manifest.xml ]; then
   cp $rdir/local_manifest.xml $basedir/.repo/
fi

if [ "$mode" = "r" ]; then

	cd $basedir/device/motorola/omap4-common;       git stash >/dev/null
	cd $basedir/kernel/motorola/omap4-common-jbx;   git stash >/dev/null
	cd $basedir/vendor/cm;				git stash >/dev/null
	cd $basedir/system/core;			git stash >/dev/null
	cd $basedir/external/wpa_supplicant_8;		git stash >/dev/null
	cd $basedir/vendor/motorola;			git stash >/dev/null
        rm -rf $basedir/frameworks/native/libutils $basedir/frameworks/native/include/utils
	rm -rf $basedir/vendor/motorola/jordan-common
	cd $rdir
	exit
fi

if [ "$device" = "edison" -o "$device" = "spyder" ]; then
    cd $basedir/frameworks/av; 			[ _`git branch | grep "\*" |cut -f2 -d" "` = _quarx2k_$branch ] && git checkout $branch;
    cd $basedir/frameworks/base; 		[ _`git branch | grep "\*" |cut -f2 -d" "` = _quarx2k_$branch ] && git checkout $branch;
    cd $basedir/frameworks/native; 		[ _`git branch | grep "\*" |cut -f2 -d" "` = _quarx2k_$branch ] && git checkout $branch;
    cd $basedir/frameworks/opt/telephony;	[ _`git branch | grep "\*" |cut -f2 -d" "` = _quarx2k_$branch ] && git checkout $branch;
    cd $basedir/system/core;			[ _`git branch | grep "\*" |cut -f2 -d" "` = _quarx2k_$branch ] && git checkout $branch;
    cd $basedir/hardware/ril;			[ _`git branch | grep "\*" |cut -f2 -d" "` = _quarx2k_$branch ] && git checkout $branch;
    cd $basedir/bootable/recovery;		[ _`git branch | grep "\*" |cut -f2 -d" "` = _twrp2.7 ] && git checkout $branch;


   #### fix for cm-11.0
   sed -e "s/if (selinux_check_access(sctx, tctx, class, perm, name) == 0)/if (selinux_check_access(sctx, tctx, class, perm, (void*)name) == 0)/" -i $basedir/system/core/init/property_service.c

   [ -d $basedir/system/core/libutils ] && \
	mv $basedir/system/core/libutils $basedir/frameworks/native/libutils
   [ -d $basedir/system/core/include/utils ] && \
	mv $basedir/system/core/include/utils $basedir/frameworks/native/include/utils
   if ! grep -q "save_mapinfo(source_path,dest_path);" $basedir/system/core/sdcard/sdcard.c; then
        cd $basedir/system/core
        patch -N -p1<$rdir/patchs/sdcard.diff
        cd $rdir
   fi

   if ! grep -q "\/mnt\/fuse\/mapinfo" $basedir/frameworks/base/core/jni/android_os_FileUtils.cpp; then
       cd $basedir/frameworks/base
       patch -N -p1 < $rdir/patchs/fileutils.diff
       cd $rdir
   fi 

   ### patch for apns-conf #########
   [ -f $basedir/device/motorola/edison/apns-conf.xml ] && \
	sed -e "s/<apns version=\"7\">/<apns version=\"8\">/" -i $basedir/device/motorola/edison/apns-conf.xml 

   ### jbx-kernel patch ###########

   sed -e "s/^\(\s*echo \\\#define LINUX_COMPILE_HOST \s*\\\\\"\)\`echo dtrail\`\(\\\\\"\)/\1\\\`echo \$LINUX_COMPILE_HOST | sed -e \\\"s\/\\\s\/_\/g\\\"\`\2/"  -i $basedir/kernel/motorola/omap4-common-jbx/scripts/mkcompile_h

   ### patch for vendor cm  ########
   if ! grep -q "^\s*#\$(call inherit-product, frameworks\/base\/data\/videos\/VideoPackage2.mk)" \
        $basedir/vendor/cm/config/common_full.mk; then
	cd $basedir/vendor/cm
	patch -N -p1 <$rdir/patchs/vendor_cm.diff
	cd $rdir
   fi
   
  #use prebuilt libril.so
  if ! grep -q "vendor\/motorola\/edison\/proprietary\/lib\/libril.so:system\/lib\/libril.so" \
	$basedir/vendor/motorola/edison/edison-vendor-blobs.mk; then
	cd $basedir/vendor/motorola
	patch -N -p1<$rdir/patchs/vendor_edison.diff
	cd $rdir
  fi
  [ -f $basedir/vendor/motorola/edison/proprietary/lib/libril.so ] || \
	cp $rdir/prebuilts/libril.so $basedir/vendor/motorola/edison/proprietary/lib/

elif [ "$device" = "mb526" ]; then
   ###### for jordan ##########
   cp -r vendor/moto/jordan-common vendor/motorola/jordan-common
   initBranch frameworks/av quarx2k_$branch quarx2k https://github.com/Quarx2k/android_frameworks_av.git $branch
   initBranch frameworks/base quarx2k_$branch  quarx2k https://github.com/Quarx2k/android_frameworks_base.git $branch
   initBranch frameworks/native quarx2k_$branch  quarx2k https://github.com/Quarx2k/android_frameworks_native.git $branch
   initBranch frameworks/opt/telephony quarx2k_$branch  quarx2k https://github.com/Quarx2k/android_frameworks_opt_telephony.git $branch
   initBranch system/core quarx2k_$branch  quarx2k https://github.com/Quarx2k/android_system_core.git $branch
   initBranch hardware/ril quarx2k_$branch  quarx2k https://github.com/Quarx2k/android_hardware_ril.git $branch
   initBranch bootable/recovery twrp2.7  twrp https://github.com/TeamWin/Team-Win-Recovery-Project.git twrp2.7

   if [ "$mode" = "u" ]; then
   	updateBranch frameworks/av quarx2k_$branch quarx2k $branch
   	updateBranch frameworks/base quarx2k_$branch  quarx2k  $branch
   	updateBranch frameworks/native quarx2k_$branch  quarx2k $branch
   	updateBranch frameworks/opt/telephony quarx2k_$branch  quarx2k $branch
   	updateBranch system/core quarx2k_$branch  quarx2k $branch
   	updateBranch hardware/ril quarx2k_$branch  quarx2k $branch
	updateBranch bootable/recovery twrp2.7 twrp twrp2.7
   fi

   ### patch for vendor cm  ########
   if ! grep -q "^\s*#\$(call inherit-product, frameworks\/base\/data\/videos\/VideoPackage2.mk)" \
        $basedir/vendor/cm/config/common_full.mk; then
	cd $basedir/vendor/cm
	patch -N -p1 <$rdir/patchs/vendor_cm_quarx2k.diff
	cd $rdir
   fi
  if grep -q "^\s*<string-array name=\"config_vendorServices\">\s*$" \
	 $basedir/device/moto/jordan-common/overlay/frameworks/base/core/res/res/values/arrays.xml; then
	cd $basedir/device/moto/jordan-common
	patch -N -p1 <$rdir/patchs/jordan-common.diff
	cd $rdir
  fi
fi

#### LOG for KERNEL ##########
sed -e "s/^\(#define KLOG_DEFAULT_LEVEL\s*\)3\(\s*.*\)/\16\2/" -i $basedir/system/core/include/cutils/klog.h

#### update calendar ###########
if [ "$mode" = "u" ]; then
	initBranch packages/app/Calendar $branch cm https://github.com/CyanogenMod/android_packages_app_Calendar.git $branch
	updateBranch packages/app/Calendar $branch cm $branch
fi

if [ $oldupdate -eq 1 ]; then
	sed -e "s/use_set_metadata=1/use_set_metadata=0/g" -i $basedir/build/core/Makefile
else
	sed -e "s/use_set_metadata=0/use_set_metadata=1/g" -i $basedir/build/core/Makefile
fi

if grep -q "if not self.info.get(\"use_set_metadata\", False):" $basedir/device/motorola/omap4-common/releasetools/common_edify_generator.py; then
    sed -e "s/if not self.info.get(\"use_set_metadata\", False):/if \"0\" == self.info.get(\"use_set_metadata\", \"0\"):/g" \
	-i $basedir/device/motorola/omap4-common/releasetools/common_edify_generator.py
fi

if grep -q "^#CONFIG_IEEE80211R=y" $basedir/external/wpa_supplicant_8/hostapd/android.config; then 
   sed -s "s/^#\(CONFIG_IEEE80211R=y\)/\1/g" -i $basedir/external/wpa_supplicant_8/hostapd/android.config
fi

