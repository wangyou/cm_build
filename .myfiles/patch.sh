branch=cm-11.0

mode=""
oldupdate=1
releaseKernel=1
kernelUpdate=0
opKernel=cm

KernelBranches=("cm-11.0" "JBX_30X" "JBX_4.4" "JBX_30X" "JBX_HDMI" "cm-11.0")
KernelOpts=("cm" "jbx" "j44" "j30x" "jhdmi" "jordan")

#############################################################
## function to get kernel branch name from kernel options
##############################################################
getKernelBranchName()
{
	[ "$1" = "" ] && return 
	i=0
        for e in ${KernelOpts[@]}; do
		if [ "$e" = "$1" -a "$e" != "" ]; then
			echo  ${KernelBranches[$i]}
			return
		fi
		i=$((i+1))
	done
	return 1
}

#newBranch <dir> <localBranchName> <remoteName> <remote.git> <remote_branch> [checkout]
newBranch()
{
	local curdir=`pwd`
	if [ $# -lt 5 ]; then return 1;fi
	[ -d $1 ] || mkdir -p $1
	cd $1
	git branch | grep -wq "$branch" || git branch $branch
	git remote | grep -wq "$3" || git remote add $3 $4
	
	if ! git branch | grep -wq "$2"; then
		echo "Create branch $2..."
		git checkout --orphan $2
		git rm -rf . >/dev/null
		git pull $3 $5
	fi
	
 	if [ _$6 = _checkout ]; then
	    if [ _`git branch | grep "\*" |cut -f2 -d" "` != _$2 ] ; then 
		git stash >/dev/null
		git checkout $2 >/dev/null
	    fi
	fi 

	cd $curdir
	return 0
}

#addBranch <dir> <localBranchName>  [checkout]
addBranch()
{
	local curdir=`pwd`
	if [ $# -lt 2 ]; then return 1;fi
	[ -d $1 ] || return 1
	cd $1
	
	if ! git branch | grep -wq "$2"; then
		echo "Create branch $2..."
		git checkout --orphan $2
		git rm -rf . >/dev/null
                git pull github $2
	fi
	
 	if [ _$3 = _checkout ]; then
	    if [ _`git branch | grep "\*" |cut -f2 -d" "` != _$2 ] ; then 
		git stash >/dev/null
		git checkout $2 >/dev/null
	    fi
	fi 

	cd $curdir
	return 0
}

#checkoutBranch <dir> <branchName>
checkoutBranch()
{
	local curdir=`pwd`
	if [ $# -lt 2 ]; then return 1;fi
	[ -d $1 ] || return 1
	cd $1

	if [ _`git branch | grep "\*" |cut -f2 -d" "` != _$2 ] ; then 
		git stash >/dev/null
		git checkout -f $2 >/dev/null
	fi
	cd $curdir
}

#updateBranch <dir> <localBranch> <remoteName> <remoteBranch>
updateBranch()
{
	local curdir=`pwd`
	if [ $# -lt 4 ]; then return 1;fi
	[ -d $1 ] || mkdir -p $1
	cd $1
	git checkout $2
	git fetch $3 $4
	git merge FETCH_HEAD -m "$3:$4 `date +%Y%m%d`"
	cd $curdir
	return 0
}

#addRemote <dir> <remoteName> <remote.git>
addRemote()
{
	local curdir=`pwd`
	if [ $# -lt 3 ]; then return 1; fi
	if [ ! -d $1  ]; then return 1; fi
	if [ $curdir = $1 ]; then return 0; fi

	cd $1
	git remote | grep -wq "$1" || git remote add $2 $3
	cd $curdir
}

resetProject()
{
	if [ $# -lt 1 ]; then return 1; fi
	if [ ! -d $basedir/$1 ]; then return 1; fi
#	echo "reset project: $1"
	local curdir=`pwd`
	cd $basedir/$1
	local remote=`git branch -r | grep  "\->" | sed "s/.*->//g;s/ $//g;s/^ //g;s/\/.*//g"`
	local branch=`LANG=en_US git branch | grep "*"| sed "s/\* *//g"`
	if echo $branch | grep -q "(" ; then 
		branch=""
	fi
	git clean -f > /dev/null
	git stash > /dev/null
#	if [ "$branch" = "" ]; then
#		git rebase -f >/dev/null
#	else
#		git rebase -f $branch >/dev/null
#	fi
	cd $curdir
}

reset_for_manifest()
{
    cd $basedir/frameworks/av; 			[ _`git branch | grep "\*" |cut -f2 -d" "` = _quarx2k_$branch ] && git checkout -f $branch;
    cd $basedir/frameworks/base; 		[ _`git branch | grep "\*" |cut -f2 -d" "` = _quarx2k_$branch ] && git checkout -f $branch;
    cd $basedir/frameworks/native; 		[ _`git branch | grep "\*" |cut -f2 -d" "` = _quarx2k_$branch ] && git checkout -f $branch;
    cd $basedir/frameworks/opt/telephony;	[ _`git branch | grep "\*" |cut -f2 -d" "` = _quarx2k_$branch ] && git checkout -f $branch;
    cd $basedir/system/core;			[ _`git branch | grep "\*" |cut -f2 -d" "` = _quarx2k_$branch ] && git checkout -f $branch;
    cd $basedir/hardware/ril;			[ _`git branch | grep "\*" |cut -f2 -d" "` = _quarx2k_$branch ] && git checkout -f $branch;
    cd $basedir/hardware/ti/wlan;		[ _`git branch | grep "\*" |cut -f2 -d" "` = _quarx2k_$branch ] && git checkout -f $branch;
    cd $basedir/bootable/recovery;		[ _`git branch | grep "\*" |cut -f2 -d" "` = _twrp ] && git checkout -f $branch;
}
############################################################################

### parse params #########
for op in $*;do 
   if [ "$op" = "spyder" -o "$op" = "edison" -o "$device" = "targa" ]; then
   	device="$op"
   elif [ "$op" = "jordan" -o "$op" = "mb526" ]; then
	device="mb526"
	opKernel="jordan"
   elif [ "$op" = "jbx" -o "$op" = "j30x"  -o "$op" = "j44"  -o "$op" = "jhdmi" -o "$op" = "cm" ]; then
	opKernel="$op"
   elif [ "$op" = "-ku" ]; then
	kernelUpdate=1
   elif [ "$op" = "-kuo" ]; then
	kernelUpdate=2
   elif [ "$op" = "-r" -o "$op" = "-kbranch" ]; then
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
if [ -s $basedir/.lastBuild ]; then
   lastDevice=`grep device: $basedir/.lastBuild|cut -d: -f2|sed -e "s/^ //g" -e "s/ $//g"`
   lastOpKernel=`grep opKernel: .lastBuild|cut -d: -f2|sed -e "s/^ //g" -e "s/ $//g"`
fi

[ -z "$device" ] && device=$lastDevice
[ -z "$opKernel" ] && opKernel=$lastOpKernel

if [ "$device" != "mb526" ]; then
	DeviceDir="device/motorola/$device"
else
	DeviceDir="device/moto/$device"
	opKernel=jordan
fi
kbranch=`getKernelBranchName $opKernel`

## local_manifest.xml   ####
if [ -d $basedir/.repo -a -f $rdir/local_manifest.xml ]; then
   if [ -f $basedir/.repo/local_manifest.xml ]; then
	if [ -f $basedir/.repo/local_manifests/local_manifest.xml ]; then
	    rm $basedir/.repo/local_manifest.xml
	else
	    mv $basedir/.repo/local_manifest.xml $basedir/.repo/local_manifests/
        fi
   fi
   if [ _$rdir/local_manifest.xml = _`find $rdir/local_manifest.xml -newer $basedir/.repo/local_manifests/local_manifest.xml` ]; then
   	cp $rdir/local_manifest.xml $basedir/.repo/local_manifests/

       [ "$device" != "mb526" ] && \
	sed -e "s:\(<project.*kernel/motorola/omap4-common.*revision=\).*\(/>\):\1\"$kbranch\"\2:" \
            -i $basedir/.repo/local_manifests/local_manifest.xml

   fi
fi

if [ "$mode" = "r" ]; then
	resetProject build
	resetProject device/motorola/edison
	resetProject device/motorola/omap4-common
	resetProject vendor/cm
	resetProject system/core
        resetProject frameworks/base
        resetProject frameworks/native
        resetProject frameworks/av
	resetProject packages/services/Telephony
        resetProject packages/apps/Settings
	resetProject external/wpa_supplicant_8
	resetProject vendor/motorola
	resetProject kernel/motorola/omap4-common

	reset_for_manifest

	#reset that translation local
	for fl in $rdir/trans/*; do
	   if [ -d $fl ]; then
	       fLang=`echo $fl|sed "s:$rdir/trans/::"`
	       for f in $rdir/trans/$fLang/*; do
		   if [ -f $f ]; then
	               fpath=`echo $f|sed "s:$rdir/trans/$fLang::"`   
	               xml=`echo $fpath| cut -f2 -d-`
	               project=`echo $fpath | sed "s:-.*::g;s:_:/:g;s:^/::"`
	               [ -d $basedir/$project ] && resetProject $project
		   fi
	        done
	   fi
	done

	rm -rf $basedir/vendor/motorola/jordan-common
	exit
fi

####### patch for vendor cm  ########
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

   ### patch for apns-conf #########
   if [ -f $basedir/$DeviceDir/apns-conf.xml ]; then
	sed -e "s/<apns version=\"7\">/<apns version=\"8\">/" \
            -e "s/\"China Mobile\"/\"中国移动\"/g" \
            -e "s/\"China Mobile MMS\"/\"中国移动彩信\"/g" \
	    -e "s/\"China Unicom 3G\"/\"中国联通3G\"/g" \
            -e "s/\"China Unicom MMS\"/\"中国联通彩信\"/g" \
	    -i $basedir/$DeviceDir/apns-conf.xml 
   fi


########## Device Edison/Spyder/Targa,etc OMAP4-COMMON...#########
if [ "$device" != "mb526" ]; then

   reset_for_manifest

   ### if not kernel branch switch start ####
   if [ "$mode" != "kbranch" -a "${opKernel:0:1}" = "j" ]; then
  	if ! grep -q "static ssize_t store_frequency_limit(struct device \*dev" \
              $basedir/device/motorola/omap4-common/pvr-source/services4/system/omap4/sgxfreq.c; then
        	cd $basedir/device/motorola/omap4-common
        	patch -N -p1 < $rdir/patchs/device_omap4-common.diff
        	cd $rdir
  	fi
   fi
   ### if not kernel branch switch end ####


  echo "Use $opKernel $kbranch kernel ..."
  cd $basedir/kernel/motorola/omap4-common
  oldBranch=`git branch | grep "\*" |cut -f2 -d" "`
  addBranch $basedir/kernel/motorola/omap4-common $kbranch
  checkoutBranch $basedir/kernel/motorola/omap4-common $kbranch
  if [ -f $basedir/.lastBuild ] && [ "$mode" != "kbranch" ]; then
	sed -e "s/opKernel:.*/opKernel: $opKernel/" -i $basedir/.lastBuild
  else
	echo "opKernel: $opKernel" > $basedir/.lastBuild
  fi
  sed -e "s:\(<project.*kernel/motorola/omap4-common.*revision=\).*\(/>\):\1\"$kbranch\"\2:" \
      -i $basedir/.repo/local_manifests/local_manifest.xml
  git branch --unset-upstream $oldBranch >/dev/null 2>/dev/null
  git branch --set-upstream-to github/$kbranch $kbranch >/dev/null 2>/dev/null	     
  addRemote cm https://github.com/CyanogenMod/android_kernel_motorola_omap4-common.git
  addRemote jbx https://github.com/RAZR-K-Devs/android_kernel_motorola_omap4-common.git
  
  if [ $kernelUpdate -eq 1 ]; then
      repo sync  .
  elif [ $kernelUpdate -eq 2 ] ; then
     repo sync  .
     if [ $opKernel = "cm" ]; then
	git pull cm $kbranch
     elif echo $kbranch | grep -q JBX ; then
	git pull jbx $kbranch
     fi
  fi

  if [ "${opKernel:0:1}" = "j" ] && [ "$mode" != "kbranch" ] ; then
      sed -e "s/^\(\s*echo \\\#define LINUX_COMPILE_HOST \s*\\\\\"\)\`echo dtrail\`\(\\\\\"\)/\1\\\`echo \$LINUX_COMPILE_HOST | sed -e \\\"s\/\\\s\/_\/g\\\"\`\2/"  -i $basedir/kernel/motorola/omap4-common/scripts/mkcompile_h

     [ "${kernel_config}" = "" ] && kernel_config=mapphone_OCE_defconfig
     if  [ -f $basedir/kernel/motorola/omap4-common/arch/arm/configs/${kernel_config} ] ; then
         if [ "$device" = "edison" ]; then
            sed -i $basedir/kernel/motorola/omap4-common/arch/arm/configs/${kernel_config} \
   	        -e "s/# CONFIG_MAPPHONE_EDISON is not set/CONFIG_MAPPHONE_EDISON=y/g" \
                -e "s/# CONFIG_PANEL_MAPPHONE_SKIP_FIRSTBOOT is not set/CONFIG_PANEL_MAPPHONE_SKIP_FIRSTBOOT=y/g" \
	        -e "s/CONFIG_CPU_FREQ_DEFAULT_GOV_KTOONSERVATIVE=y/# CONFIG_CPU_FREQ_DEFAULT_GOV_KTOONSERVATIVE is not set/g" \
	        -e "s/# CONFIG_CPU_FREQ_DEFAULT_GOV_INTERACTIVEX is not set/CONFIG_CPU_FREQ_DEFAULT_GOV_INTERACTIVEX=y/g" \
                -e "s/# CONFIG_NLS_UTF8 is not set/CONFIG_NLS_UTF8=y/g"
         elif [ "$device" = "targa" ]; then
            sed -i $basedir/kernel/motorola/omap4-common/arch/arm/configs/${kernel_config} \
   	        -e "s/# CONFIG_MAPPHONE_TARGA is not set/CONFIG_MAPPHONE_TARGA=y/g" \
#                -e "s/CONFIG_PANEL_MAPPHONE_SKIP_FIRSTBOOT=y/# CONFIG_PANEL_MAPPHONE_SKIP_FIRSTBOOT is not set/g" \
	        -e "s/CONFIG_CPU_FREQ_DEFAULT_GOV_KTOONSERVATIVE=y/# CONFIG_CPU_FREQ_DEFAULT_GOV_KTOONSERVATIVE is not set/g" \
	        -e "s/# CONFIG_CPU_FREQ_DEFAULT_GOV_INTERACTIVEX is not set/CONFIG_CPU_FREQ_DEFAULT_GOV_INTERACTIVEX=y/g" \
                -e "s/# CONFIG_NLS_UTF8 is not set/CONFIG_NLS_UTF8=y/g"
         else
            sed -i $basedir/kernel/motorola/omap4-common/arch/arm/configs/${kernel_config} \
	        -e "s/CONFIG_CPU_FREQ_DEFAULT_GOV_KTOONSERVATIVE=y/# CONFIG_CPU_FREQ_DEFAULT_GOV_KTOONSERVATIVE is not set/g" \
	        -e "s/# CONFIG_CPU_FREQ_DEFAULT_GOV_INTERACTIVEX is not set/CONFIG_CPU_FREQ_DEFAULT_GOV_INTERACTIVEX=y/g" \
                -e "s/# CONFIG_NLS_UTF8 is not set/CONFIG_NLS_UTF8=y/g"
         fi
     fi
     ################# Limit the GPU frequency to 307 mhz for edison at JBX-Kernel ###############
     if [ "$device" = "edison" ]; then
	mkdir -p $basedir/vendor/motorola/edison/proprietary/etc/init.d
	cp $rdir/patchs/kernel/jbx/80GPU $basedir/vendor/motorola/edison/proprietary/etc/init.d/
	sed -e "/PRODUCT_COPY_FILES/vendor\/motorola\/edison\/proprietary\/etc\/init.d\/80GPU:system\/etc\/init.d\/80GPU \\" \
		$basedir/vendor/motorola/edison/edison-vendor-blobs.mk 
     fi

  elif [ "$opKernel" = "cm" ]; then
      sed -i $basedir/kernel/motorola/omap4-common/arch/arm/configs/mapphone_mmi_defconfig \
          -e "s/# CONFIG_NLS_UTF8 is not set/CONFIG_NLS_UTF8=y/g"
  fi

  #some patch for kernel
#  if  grep -q "^#if defined(CONFIG_MAPPHONE_EDISON) || defined(CONFIG_MAPPHONE_TARGA)" \
#            $basedir/kernel/motorola/omap4-common/arch/arm/mach-omap2/sr_device.c; then
#      patch -p1 -N < $rdir/patchs/kernel/jbx/jbx_sr-device.diff
#  fi

#  if ! grep -q "static bool skip_first_boot = true" \
#     $basedir/kernel/motorola/omap4-common/drivers/video/omap2/displays/panel-mapphone.c; then
#     patch -p1 -N < $rdir/patchs/kernel/first_boot.diff
#  fi

  cd $basedir
  echo "Process kernel ended."

elif [ "$device" = "mb526" ]; then
   ###### for jordan ##########
#   newBranch frameworks/av quarx2k_$branch quarx2k https://github.com/Quarx2k/android_frameworks_av.git $branch checkout
#   newBranch frameworks/base quarx2k_$branch  quarx2k https://github.com/Quarx2k/android_frameworks_base.git $branch checkout
#   newBranch frameworks/native quarx2k_$branch  quarx2k https://github.com/Quarx2k/android_frameworks_native.git $branch checkout
#   newBranch frameworks/opt/telephony quarx2k_$branch  quarx2k https://github.com/Quarx2k/android_frameworks_opt_telephony.git $branch checkout
#   newBranch system/core quarx2k_$branch  quarx2k https://github.com/Quarx2k/android_system_core.git $branch checkout
#   newBranch hardware/ril quarx2k_$branch  quarx2k https://github.com/Quarx2k/android_hardware_ril.git $branch checkout
   newBranch bootable/recovery twrp  twrp https://github.com/omnirom/android_bootable_recovery.git android-4.4 checkout
   newBranch hardware/ti/wlan quarx2k_$branch  quarx2k https://github.com/Quarx2k/android_hardware_ti_wlan.git $branch checkout

   if [ "$mode" = "u" ]; then
#   	updateBranch frameworks/av quarx2k_$branch quarx2k $branch
#   	updateBranch frameworks/base quarx2k_$branch  quarx2k  $branch
#   	updateBranch frameworks/native quarx2k_$branch  quarx2k $branch
#   	updateBranch frameworks/opt/telephony quarx2k_$branch  quarx2k $branch
#   	updateBranch system/core quarx2k_$branch  quarx2k $branch
#   	updateBranch hardware/ril quarx2k_$branch  quarx2k $branch
	updateBranch hardware/ti/wlan quarx2k_$branch quarx2k $branch
	updateBranch bootable/recovery twrp twrp android-4.4
   fi

   ### patch for vendor cm  ########
#   if ! grep -q "^\s*#\$(call inherit-product, frameworks\/base\/data\/videos\/VideoPackage2.mk)" \
#        $basedir/vendor/cm/config/common_full.mk; then
#	cd $basedir/vendor/cm
#	patch -N -p1 <$rdir/patchs/vendor_cm_quarx2k.diff
#	cd $rdir
#   fi
#  if grep -q "^\s*<string-array name=\"config_vendorServices\">\s*$" \
#	 $basedir/device/moto/jordan-common/overlay/frameworks/base/core/res/res/values/arrays.xml; then
#	cd $basedir/device/moto/jordan-common
#	patch -N -p1 <$rdir/patchs/jordan-common.diff
#	cd $rdir
#  fi
fi

[ "$mode" = "kbranch" ] && exit

#### LOG for KERNEL ##########
sed -e "s/^\(#define KLOG_DEFAULT_LEVEL\s*\)3\(\s*.*\)/\16\2/" -i $basedir/system/core/include/cutils/klog.h

#### update calendar ###########
if [ "$mode" = "u" ]; then
	newBranch packages/app/Calendar $branch cm https://github.com/CyanogenMod/android_packages_app_Calendar.git $branch
	updateBranch packages/app/Calendar $branch cm $branch
fi

if [ $oldupdate -eq 1 ]; then
	sed -e "/use_set_metadata=1/d" -i $basedir/build/core/Makefile
fi


####Translation#################
python $rdir/scripts/mTrans.py -wt >/dev/null

####some patchs###########

   sed -e "s/if (selinux_check_access(sctx, tctx, class, perm, name) == 0)/if (selinux_check_access(sctx, tctx, class, perm, (void*)name) == 0)/" -i $basedir/system/core/init/property_service.c

   if ! grep -q "if (\!uuid && findDevice){" $basedir/frameworks/base/core/jni/android_os_FileUtils.cpp; then
       cd $basedir/frameworks/base
       patch -N -p1 < $rdir/patchs/fileutils.diff
       cd $rdir
   fi 

   ##fix for battery charging over 100%
   if ! grep -q "batteryLevel = mbatteryLevel > 100 ? 100 : mbatteryLevel;" \
	$basedir/frameworks/native/services/batteryservice/BatteryProperties.cpp; then
	cd $basedir/frameworks/native
	patch -N -p1 < $rdir/patchs/batteryProperties.diff
	cd $rdir
   fi
   
   ## remove cmupdater ##
   if grep -q "removePreferenceIfPackageNotInstalled(findPreference(KEY_CM_UPDATES));" \
           $basedir/packages/apps/Settings/src/com/android/settings/DeviceInfoSettings.java; then
       cd $basedir/packages/apps/Settings
       patch -p1 <$rdir/patchs/cmupdater.diff
       cd $rdir
   fi
   sed -e "/CMUpdater/d" -i $basedir/vendor/cm/config/common.mk

   sed -e "/OMX_FreeBuffer for buffer header %p successful/d" -i $basedir/frameworks/av/media/libstagefright/omx/OMXNodeInstance.cpp

   ## fix media_profiles.xml for HFR encode
   [ "$device" != "mb526" ] && \
   if grep -q "maxHFRFrameWidth" $basedir/frameworks/av/media/libmedia/MediaProfiles.cpp; then
      if ! grep -q "maxHFRFrameWidth" $basedir/device/motorola/$device/media_profiles.xml; then
         cd $basedir/device/motorola/$device
         patch -p1 < $rdir/patchs/media_profiles.diff
         cd $rdir
      fi
   fi

###  fix for compile error ##########

