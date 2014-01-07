device=edison
branch=cm-11.0

#JBX 2.0.5 ----   Added todays changelog and updated full history
releaseKernelCommit=fe12ed0e818eb73a73fff8751fdeee7a10339906
mode=""
oldupdate=1
releaseKernel=1
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

revertProject()
{
	if [ $# -lt 1 ]; then return -1; fi
	if [ ! -d $1 ]; then return -1; fi
	curdir=`pwd`
	cd $1
	git clean -f >/dev/null
	git stash >/dev/null
	git rebase m/$branch >/dev/null
	cd $curdir
}

### parse params #########
for op in $*;do 
   if [ "$op" = "spyder" ]; then
   	device="$op"
   elif [ "$op" = "edison" ]; then
	device="edison"
   elif [ "$op" = "jordan" -o "$op" = "mb526" ]; then
	device="mb526"
   elif [ "$op" = "jbx" -o "$op" = "jbx-kernel" -o "$op" = "cm" ]; then
	opKernel="$op"
   elif [ "$op" = "-rk" ]; then
	releaseKernel=0
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
	revertProject build
	revertProject device/motorola/edison
	revertProject device/motorola/omap4-common
	revertProject kernel/motorola/omap4-common-jbx
	revertProject vendor/cm
	revertProject system/core
        revertProject frameworks/base
        revertProject frameworks/native
        revertProject frameworks/av
	revertProject packages/apps/Settings
	revertProject packages/services/Telephony
	revertProject packages/apps/Dialer
	revertProject external/wpa_supplicant_8
	revertProject vendor/motorola
	rm -rf $basedir/vendor/motorola/jordan-common
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


   ### patch for apns-conf #########
   if [ -f $basedir/device/motorola/edison/apns-conf.xml ]; then
	sed -e "s/<apns version=\"7\">/<apns version=\"8\">/" \
            -e "s/\"China Mobile\"/\"中国移动\"/g" \
            -e "s/\"China Mobile MMS\"/\"中国移动彩信\"/g" \
	    -e "s/\"China Unicom 3G\"/\"中国联通3G\"/g" \
            -e "s/\"China Unicom MMS\"/\"中国联通彩信\"/g" \
	    -i $basedir/device/motorola/edison/apns-conf.xml 
   fi

   ### jbx-kernel patch ###########
   if [ "$opKernel" = "jbx" -o "$opKernel" = "jbx-kernel" ]; then
      sed -e "s/^\(\s*echo \\\#define LINUX_COMPILE_HOST \s*\\\\\"\)\`echo dtrail\`\(\\\\\"\)/\1\\\`echo \$LINUX_COMPILE_HOST | sed -e \\\"s\/\\\s\/_\/g\\\"\`\2/"  -i $basedir/kernel/motorola/omap4-common-jbx/scripts/mkcompile_h
   fi

   ### patch for vendor cm  ########
   sed -e "/PRODUCT_BOOTANIMATION :=/d" -e "/CMAccount/d"  -e "/CMFota/d" -i $basedir/vendor/cm/config/common.mk
   sed -e "s/^\(\s*CM_BUILDTYPE := EXPERIMENTAL\)/#\1/g" -i $basedir/vendor/cm/config/common.mk
   sed -e "/LiveWallpapers/d" -e "/LiveWallpapersPicker/d" -e "/MagicSmokeWallpapers/d" -e "/NoiseField/d" -i $basedir/vendor/cm/config/common_full.mk
   if ! grep -q "^\s*vendor\/cm\/prebuilt\/common\/bootanimation\/480.zip:system\/media\/bootanimation.zip" \
		$basedir/vendor/cm/config/common_full_phone.mk \
        $basedir/vendor/cm/config/common_full.mk; then
	cd $basedir/vendor/cm
	patch -N -p1 <$rdir/patchs/vendor_cm.diff
	cd $rdir
   fi
   
  sed -e "s/BOARD_HOSTAPD_DRIVER             := NL80211/BOARD_HOSTAPD_DRIVER_TI          := NL80211/" \
      -i $basedir/device/motorola/omap4-common/BoardConfigCommon.mk

  [ "$opKernel" = "jbx" -o "$opKernel" = "jbx-kernel" ] && \
  if ! grep -q "static ssize_t store_frequency_limit(struct device \*dev" \
              $basedir/device/motorola/omap4-common/pvr-source/services4/system/omap4/sgxfreq.c; then
        cd $basedir/device/motorola/omap4-common
        patch -N -p1 < $rdir/patchs/device_omap4-common.diff
        cd $rdir
  fi

  [ "$opKernel" = "jbx" -o "$opKernel" = "jbx-kernel" ] && \
  if [ $releaseKernel -eq 0 ]; then
  	cd $basedir/kernel/motorola/omap4-common-jbx
	if ! git log -1 | grep -q $releaseKernelCommit; then
		echo "Reset JBX Kernel to Release commit: $releaseKernelCommit"
		git reset --hard $releaseKernelCommit
	fi
	if ! grep -q "static int plat_uart_asleep(void)" $basedir/kernel/motorola/omap4-common-jbx/arch/arm/mach-omap2/board-mapphone.c; then
		patch -N -p1 < $rdir/patchs/kernel/wakelock.diff
	fi
	cd $rdir
  fi

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
	sed -e "/use_set_metadata=1/d" -i $basedir/build/core/Makefile
fi


if grep -q "^#CONFIG_IEEE80211R=y" $basedir/external/wpa_supplicant_8/hostapd/android.config; then 
   sed -s "s/^#\(CONFIG_IEEE80211R=y\)/\1/g" -i $basedir/external/wpa_supplicant_8/hostapd/android.config
fi

####Translation#################
cp $rdir/patchs/trans/packages_apps_Settings-cm_strings.xml $basedir/packages/apps/Settings/res/values-zh-rCN/cm_strings.xml
cp $rdir/patchs/trans/packages_apps_Settings-cm_plurals.xml $basedir/packages/apps/Settings/res/values-zh-rCN/cm_plurals.xml

[ -f $basedir/packages/services/Telephony/res/values-zh-rCN/cm_strings.xml ] || \
   cp $rdir/patchs/trans/packages_services_Telephony-cm_strings.xml $basedir/packages/services/Telephony/res/values-zh-rCN/cm_strings.xml

[ -f $basedir/packages/apps/Dialer/res/values-zh-rCN/cm_strings.xml ] || \
   cp $rdir/patchs/trans/packages_apps_Dialer-cm_strings.xml $basedir/packages/apps/Dialer/res/values-zh-rCN/cm_strings.xml

[ -f $basedir/packages/apps/Camera2/res/values-zh-rCN/cm_strings.xml ] || \
   cp $rdir/patchs/trans/packages_apps_Camera2-cm_strings.xml $basedir/packages/apps/Camera2/res/values-zh-rCN/cm_strings.xml

####some patchs###########

   sed -e "s/if (selinux_check_access(sctx, tctx, class, perm, name) == 0)/if (selinux_check_access(sctx, tctx, class, perm, (void*)name) == 0)/" -i $basedir/system/core/init/property_service.c

   if ! grep -q "if (\!uuid && findDevice){" $basedir/frameworks/base/core/jni/android_os_FileUtils.cpp; then
       cd $basedir/frameworks/base
       patch -N -p1 < $rdir/patchs/fileutils.diff
       cd $rdir
   fi 

 
   ##fix for battery charging over 100%
  sed -e "s/if (batteryState.batteryLevel == 100)/if (batteryState.batteryLevel >= 100)/g" \
      -i $basedir/frameworks/base/packages/SystemUI/src/com/android/systemui/statusbar/phone/QuickSettings.java
