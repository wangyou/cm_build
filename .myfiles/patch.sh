#!/bin/bash

branch=cm-11.0

mode=""
oldupdate=1
releaseKernel=1
kernelUpdate=0
opKernel=cm
device=edison
kernelBranchOptionStart=1
KernelBranchName=$branch
childmode=1

KernelBranches=("cm-11.0" "JBX" "JBX_30X" "cm-11.0" "cm-11.0")
KernelOpts=("cm" "jbx" "j30x" "jordan" "n880e")

isKernelOpt()
{
    [ $# -lt 1 ] && return 1
    for((i=0;i<${#KernelOpts[@]};i++)) do
        if [ "${KernelOpts[$i]}" = "$1" ]; then
            return 0
        fi
    done
    return 1
}

#############################################################
## function to get kernel branch name from kernel options
##############################################################
getKernelBranchName()
{
	i=0
     if [ "$1" != "" -a "$KernelBranchName" != "" ]; then
         for e in ${KernelOpts[@]}; do
		    if [ "$e" = "$1" -a "$e" != "" ]; then
                   KernelBranchName=${KernelBranches[$i]}
			    break
		    fi
		    i=$((i+1))
	    done
     fi
	echo  $KernelBranchName
}

#newBranch <dir> <localBranchName> <remoteName> <remote.git> <remote_branch> [checkout]
newBranch()
{
     local curdir=`pwd`
     if [ $# -lt 5 ]; then return 1;fi
     [ -d $1 ] || mkdir -p $1
     cd $1
     git branch | grep -q -e "[[:space:]?]$branch$" || git branch $branch
     git remote | grep -q -e "[[:space:]?]$3$" || git remote add $3 $4
     
     if ! git branch | grep -q -e "[[:space:]?]$2$"; then
          echo "Create branch $2 for $1..."
          git checkout --orphan $2 >/dev/null 2>/dev/null
          git rm -rf . >/dev/null
          git pull $3 $5 >/dev/null 2>/dev/null
     fi
     
      if [ _$6 = _checkout ]; then
          if [ _`git branch | grep "\*" |cut -f2 -d" "` != _$2 ] ; then 
              git stash >/dev/null
              git checkout $2 >/dev/null 2>/dev/null
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
     
     if ! git branch | grep -q -e  "[[:space:]?]$2$"; then
          echo "Create branch $2 for $1..."
          git checkout --orphan $2 >/dev/null 2>/dev/null
          git rm -rf . >/dev/null
          git pull github $2
     fi
     
      if [ _$3 = _checkout ]; then
          if [ _`git branch | grep "\*" |cut -f2 -d" "` != _$2 ] ; then 
              git stash >/dev/null
              git checkout $2 >/dev/null 2>/dev/null
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

     if ! git branch | grep -q -e "[[:space:]?]$branch$"; then
          echo "$1 not exists branch $branch !"
          cd $curdir
          return 1
     elif [ _`git branch | grep "\*" |cut -f2 -d" "` != _$2 ] ; then 
          git stash >/dev/null
          git checkout -f $2 >/dev/null 2>/dev/null
     fi
     cd $curdir
     return 0
}

#updateBranch <dir> <localBranch> <remoteName> <remoteBranch>
updateBranch()
{
     local curdir=`pwd`
     if [ $# -lt 4 ]; then return 1;fi
     [ -d $1 ] || mkdir -p $1
     cd $1
     echo "update project:$1 branch:$2 <-- $4  ..."
     git checkout $2 >/dev/null 2>/dev/null
     git fetch $3 $4 >/dev/null 2>/dev/null
     git merge FETCH_HEAD -m "$3:$4 `date +%Y%m%d`" >/dev/null 2>/dev/null
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
     git remote | grep -q -e "[[:space:]?]$1$" || git remote add $2 $3
     cd $curdir
}

resetProject()
{
     local var;
     local project="";
     local mode="";
     local targetBranch="";

     for  var in $*;do 
          if [ _${var:0:1} = "_-" -a -z "$mode" ]; then
               mode="${var:1}"
          elif [ -z "$project" ]; then
               project=$var
          elif [ ! -z "$project" ]; then
               targetBranch=$var
          fi
     done
     if [ -z "$project" ]; then return 1; fi
     if [ ! -d $basedir/$project ]; then return 1; fi
#     echo "reset project: $project"
     local curdir=`pwd`
     cd $basedir/$project
     local remote=`git branch -r | grep  "\->" | sed "s/.*->//g;s/ $//g;s/^ //g;s/\/.*//g"`
     local branch=`LANG=en_US git branch | grep "*"| sed "s/\* *//g"`
     if echo $branch | grep -q "(" ; then 
          branch=""
     fi
     if [ "$branch" != "$targetBranch" -a "$targetBranch" != "" ] && git branch | sed -e "s/\s//g" -e "s/\*//g" | eval grep -qe "^${targetBranch}$"; then
         git checkout -f $targetBranch >/dev/null 2>/dev/null
     fi
     
     if [ "$mode" = "keep" ]; then
          git clean -f > /dev/null
     else
          git clean -df > /dev/null
     fi

     git stash > /dev/null
     cd $curdir
}

############################################################################

jbx=1

### parse params #########

for op in $*;do 
   if [ $kernelBranchOptionStart -eq 0 ]; then
      KernelBranchName=$op
      kernelBranchOptionStart=1
      opKernel=$device_$kernelBranchName
   elif [ "$op" = "spyder" -o "$op" = "edison" -o "$device" = "targa"  -o "$op" = "n880e" ]; then
        device="$op"
   elif [ "$op" = "jordan" -o "$op" = "mb526" ]; then
     device="mb526"
     opKernel="jordan"
   elif isKernelOpt $op; then
     opKernel="$op"
   elif [ "$op" = "-kernel-branch" -o "$op" = "-kb" ]; then
     kernelBranchOptionStart=0
   elif [ "$op" = "-jbx" ]; then
      jbx=0
   elif [ "$op" = "-ku" ]; then
     kernelUpdate=1
   elif [ "$op" = "-kuo" ]; then
     kernelUpdate=2
   elif [ "$op" = "-r" -o "$op" = "-kbranch" -o "$op" = "-u" ]; then
     mode="${op#-*}"
   elif [ "$op" = "old" ]; then
     oldupdate=1
   elif [ "$op" = "new" ]; then
     oldupdate=0
   elif [ "${op:0:6}" = "-child" ]; then
     childmode=0
   fi
done

cdir=`pwd`
rdir=`cd \`dirname $0\`;pwd`

basedir=`dirname $rdir`
if [ -s $basedir/.lastBuild ]; then
   lastDevice=`grep device: $basedir/.lastBuild|cut -d: -f2|sed -e "s/^ //g" -e "s/ $//g"`
   lastOpKernel=`grep opKernel: $basedir/.lastBuild|cut -d: -f2|sed -e "s/^ //g" -e "s/ $//g"`
fi

[ -z "$device" ] && device=$lastDevice
[ -z "$opKernel" ] && opKernel=$lastOpKernel

if [ "$device" != "mb526" -a "$device" != "n880e" ]; then
     DeviceDir="device/motorola/$device"
elif [ "$device" != "n880e" ]; then
     DeviceDir="device/moto/$device"
     opKernel=jordan
else
     DeviceDir="device/zte/$device"
     opKernel=n880e
fi

[ "${opKernel:0:1}" = "j" ]&& jbx=0
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
   fi
fi

if [ "$mode" = "r"  -o "$lastDevice" != "$device" ]; then
     resetProject build $branch
     resetProject device/motorola/edison
     resetProject device/motorola/omap4-common
     resetProject -keep vendor/cm $branch
     resetProject system/core $branch
     resetProject frameworks/base $branch
     resetProject frameworks/native $branch
     resetProject frameworks/av $branch
     resetProject frameworks/webview $branch
     resetProject frameworks/opt/telephony $branch
     resetProject packages/services/Telephony
     resetProject packages/apps/Settings
     resetProject packages/apps/Browser $branch
     resetProject external/wpa_supplicant_8
     resetProject vendor/motorola
     resetProject vendor/cm $branch
     resetProject kernel/zte/msm7x27a
     resetProject device/zte/n880e
     resetProject device/zte/atlas40
     resetProject hardware/ril $branch
     resetProject hardware/ti/wlan $branch
     resetProject bootable/recovery $branch
    
     rm -f $basedir/.atlas40_patched

     ### reset kernel/motorola/omap4-common
     curdir=`pwd`
     cd $basedir/kernel/motorola/omap4-common
     kernel_omap4_branch_remote=`grep -e "<project.*kernel/motorola/omap4-common.*revision=" $basedir/.repo/local_manifests/local_manifest.xml | sed -e "s:<project.*kernel/motorola/omap4-common.*revision=\"\(.*\)\".*/>:\1:g" `
     kernel_omap4_branch_local=`LANG=en_US git branch | grep "*"| sed "s/\* *//g"`
     if [ "${kernel_omap4_branch_remote}" != "${kernel_omap4_branch_local}" ]; then
          resetProject kernel/motorola/omap4-common ${kernel_omap4_branch_remote}
     fi
     cd $curdir

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

     [ "$mode" = "r" ] && exit
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
if [ "$device" != "mb526" -a "$device" != "n880e" ]; then
   ### if not kernel branch switch start ####
   if [ "$mode" != "kbranch" -a $jbx -eq 0 ]; then
       if ! grep -q "static ssize_t store_frequency_limit(struct device \*dev" \
              $basedir/device/motorola/omap4-common/pvr-source/services4/system/omap4/sgxfreq.c; then
             cd $basedir/device/motorola/omap4-common
             patch -N -p1 -s < $rdir/patchs/device_omap4-common.diff
             cd $rdir
       fi
   fi
   ### if not kernel branch switch end ####


  echo "Use $kbranch kernel ..."
  cd $basedir/kernel/motorola/omap4-common
  oldBranch=`git branch | grep "\*" |cut -f2 -d" "`
  addBranch $basedir/kernel/motorola/omap4-common $kbranch
  checkoutBranch $basedir/kernel/motorola/omap4-common $kbranch 
  [ $? -ne 0 ] && exit 1
  if [ -f $basedir/.lastBuild ] && [ "$mode" != "kbranch" ]; then
     sed -e "s/opKernel:.*/opKernel: $opKernel/" -i $basedir/.lastBuild
  else
     echo "opKernel: $opKernel" > $basedir/.lastBuild
  fi

  addRemote cm https://github.com/CyanogenMod/android_kernel_motorola_omap4-common.git
  addRemote jbx https://github.com/RAZR-K-Devs/android_kernel_motorola_omap4-common.git
  
  if [ $kernelUpdate -eq 1 ]; then
      cd $basedir/kernel/motorola/omap4-common
      git pull github $kbranch
      cd $rdir
  elif [ $kernelUpdate -eq 2 ] ; then
     cd $basedir/kernel/motorola/omap4-common
     git pull github $kbranch
     if [ $opKernel = "cm" ]; then
         git pull cm $kbranch
     elif echo $kbranch | grep -q JBX ; then
         git pull jbx $kbranch
     fi
     cd $rdir
  fi

  if [ $jbx -eq 0 ]; then
      kernel_config=mapphone_OCE_defconfig
      if [ "$device" = "edison" ]; then
	  kernel_config=mapphone_OCEdison_defconfig
      elif [ "$device" = "targa" ]; then
	  kernel_config=mapphone_OCETarga_defconfig
      elif [ "$device" != "mb526" ]; then
	  kernel_config=mapphone_OCE_defconfig
      fi
  else
	kernel_config=mapphone_mmi_defconfig
  fi

  if [ $jbx -eq 0 ] && [ "$mode" != "kbranch" ] ; then
      sed -e "s/^\(\s*echo \\\#define LINUX_COMPILE_HOST \s*\\\\\"\)\`echo dtrail\`\(\\\\\"\)/\1\\\`echo \$LINUX_COMPILE_HOST | sed -e \\\"s\/\\\s\/_\/g\\\"\`\2/"  -i $basedir/kernel/motorola/omap4-common/scripts/mkcompile_h

     if  [ -f $basedir/kernel/motorola/omap4-common/arch/arm/configs/${kernel_config} ] ; then
         if [ "$device" = "edison" ]; then
            sed -i $basedir/kernel/motorola/omap4-common/arch/arm/configs/${kernel_config} \
                -e "s/# CONFIG_MAPPHONE_EDISON is not set/CONFIG_MAPPHONE_EDISON=y/g" \
                -e "s/# CONFIG_NLS_UTF8 is not set/CONFIG_NLS_UTF8=y/g" #\
#                -e "s/^CONFIG_OMAP_SMARTREFLEX_CUSTOM_SENSOR=y/# CONFIG_OMAP_SMARTREFLEX_CUSTOM_SENSOR is not set/g" \
#                -e "s/^CONFIG_OMAP_OCFREQ_12=y/# CONFIG_OMAP_OCFREQ_12 is not set/g" 
         elif [ "$device" = "targa" ]; then
            sed -i $basedir/kernel/motorola/omap4-common/arch/arm/configs/${kernel_config} \
                -e "s/# CONFIG_MAPPHONE_TARGA is not set/CONFIG_MAPPHONE_TARGA=y/g" \
                -e "s/# CONFIG_NLS_UTF8 is not set/CONFIG_NLS_UTF8=y/g"
         else
            sed -i $basedir/kernel/motorola/omap4-common/arch/arm/configs/${kernel_config} \
                -e "s/# CONFIG_NLS_UTF8 is not set/CONFIG_NLS_UTF8=y/g"
         fi
     fi
     ################# Limit the GPU frequency to 307 mhz for edison at JBX-Kernel ###############
     if [ "$device" = "edison" ]; then
         mkdir -p $basedir/vendor/motorola/edison/proprietary/etc/init.d
         cp $rdir/patchs/kernel/jbx/80GPU $basedir/vendor/motorola/edison/proprietary/etc/init.d/
         if ! grep -q "init.d/80GPU" $basedir/vendor/motorola/edison/edison-vendor-blobs.mk ; then
             sed -e "/PRODUCT_COPY_FILES/a\    vendor/motorola/edison/proprietary/etc/init.d/80GPU:system/etc/init.d/80GPU \\\\" \
                 -i $basedir/vendor/motorola/edison/edison-vendor-blobs.mk 
         fi
     fi

  elif [ "$opKernel" = "cm" ]; then
      sed -i $basedir/kernel/motorola/omap4-common/arch/arm/configs/mapphone_mmi_defconfig \
          -e "s/# CONFIG_NLS_UTF8 is not set/CONFIG_NLS_UTF8=y/g"
  fi

  cd $basedir
  echo "Process kernel ended."

  ## clean some audios
  cp $rdir/patchs/squisher-extras.txt $basedir/device/motorola/$device/

: <<'COMMENT'
elif [ "$device" = "mb526" ]; then
   ###### for jordan ##########
   newBranch frameworks/av quarx2k_$branch quarx2k https://github.com/Quarx2k/android_frameworks_av.git $branch checkout
   newBranch frameworks/base quarx2k_$branch  quarx2k https://github.com/Quarx2k/android_frameworks_base.git $branch checkout
   newBranch frameworks/native quarx2k_$branch  quarx2k https://github.com/Quarx2k/android_frameworks_native.git $branch checkout
   newBranch frameworks/opt/telephony quarx2k_$branch  quarx2k https://github.com/Quarx2k/android_frameworks_opt_telephony.git $branch checkout
   newBranch system/core quarx2k_$branch  quarx2k https://github.com/Quarx2k/android_system_core.git $branch checkout
   newBranch hardware/ril quarx2k_$branch  quarx2k https://github.com/Quarx2k/android_hardware_ril.git $branch checkout
   newBranch bootable/recovery twrp  twrp https://github.com/omnirom/android_bootable_recovery.git android-4.4 checkout
   newBranch hardware/ti/wlan quarx2k_$branch  quarx2k https://github.com/Quarx2k/android_hardware_ti_wlan.git $branch checkout

   if [ "$mode" = "u" ]; then
        updateBranch frameworks/av quarx2k_$branch quarx2k $branch
        updateBranch frameworks/base quarx2k_$branch  quarx2k  $branch
        updateBranch frameworks/native quarx2k_$branch  quarx2k $branch
        updateBranch frameworks/opt/telephony quarx2k_$branch  quarx2k $branch
        updateBranch system/core quarx2k_$branch  quarx2k $branch
        updateBranch hardware/ril quarx2k_$branch  quarx2k $branch
        updateBranch hardware/ti/wlan quarx2k_$branch quarx2k $branch
        updateBranch bootable/recovery twrp twrp android-4.4
   fi
COMMENT

elif [ "$device" = "n880e" ]; then

   if [ ! -f $basedir/.atlas40_patched ] ; then
       $basedir/device/zte/atlas40/patches/install.sh && touch $basedir/.atlas40_patched
   fi
fi

[ "$mode" = "kbranch" ] && exit

####### patch for vendor cm  ########
   sed -i $basedir/vendor/cm/config/common.mk -e "/CMAccount/d" -e "/Basic \\\\/d"  -e "/CMFota/d" -e "/Launcher3/d"
   sed -i $basedir/vendor/cm/config/common.mk -e "s/^\(\s*CM_BUILDTYPE := EXPERIMENTAL\)/#\1/g" 
   sed -i $basedir/vendor/cm/config/common.mk -e '/LatinIME \\/ a\
    PinyinIME \\'
   sed -e "/LiveWallpapers/d" -e "/LiveWallpapersPicker/d" -e "/MagicSmokeWallpapers/d" -e "/NoiseField/d" -i $basedir/vendor/cm/config/common_full.mk
   sed -e "s/\(PRODUCT_BOOTANIMATION :=\).*/\1/g" -i $basedir/vendor/cm/config/common.mk
   sed -e "s/.*bootanimation\.zip//" -i $basedir/vendor/cm/config/common_full_phone.mk
   sed -e "s/.*bootanimation\.zip//" -i $basedir/vendor/cm/config/common_mini_phone.mk
   sed -e "s/.*bootanimation\.zip//" -i $basedir/vendor/cm/config/common_full_tablet_wifionly.mk
   sed -e "s/.*bootanimation\.zip//" -i $basedir/vendor/cm/config/common_mini_tablet_wifionly.mk


#### patch build for clean some files before make systemimage
   [ ! -f $basedir/build/tools/extra_files.sh ] && cp $rdir/scripts/prepack.sh $basedir/build/tools/
   if ! grep -q "systemimage-extras" $basedir/build/core/Makefile; then
      sed  -i  $basedir/build/core/Makefile -e 's/\(FULL_SYSTEMIMAGE_DEPS :=.*\)/\
\#\# add extra_files for clean some file before make systemimage\
systemimage-extras: \$(INTERNAL_SYSTEMIMAGE_FILES)\
ifeq (\$(TARGET_SYSTEMIMAGE_USE_SQUISHER),true)\
	@echo -e \${CL_YLW}"Running Extras..."\${CL_RST}\
	\$(hide) APKCERTS=\$(APKCERTS_FILE) \.\/build\/tools\/prepack.sh\
endif\
\
\.PHONY: systemimage-extras\
\
\1 systemimage-extras/g' 
   fi 

  [ $oldupdate -eq 1 ] && sed -e "/use_set_metadata=1/d" -i $basedir/build/core/Makefile

## Not use ccache
#sed -e "s/ifneq (\$(USE_CCACHE),)/ifneq (\$(USE_CCACHE),\$(USE_CCACHE))/g" -i $basedir/build/core/tasks/kernel.mk

#### LOG for KERNEL ##########
sed -e "s/^\(#define KLOG_DEFAULT_LEVEL\s*\)3\(\s*.*\)/\16\2/" -i $basedir/system/core/include/cutils/klog.h



####Translation#################
python $rdir/scripts/mTrans.py -wt >/dev/null

####some patchs###########

#   sed -e "s/if (selinux_check_access(sctx, tctx, class, perm, name) == 0)/if (selinux_check_access(sctx, tctx, class, perm, (void*)name) == 0)/" -i $basedir/system/core/init/property_service.c

#   if ! grep -q "if (\!uuid && findDevice){" $basedir/frameworks/base/core/jni/android_os_FileUtils.cpp; then
#       cd $basedir/frameworks/base
#       patch -N -p1 -s < $rdir/patchs/fileutils.diff
#       cd $rdir
#   fi 

   ##fix for battery charging over 100%
   if ! grep -q "batteryLevel = mbatteryLevel > 100 ? 100 : mbatteryLevel;" \
     $basedir/frameworks/native/services/batteryservice/BatteryProperties.cpp; then
     cd $basedir/frameworks/native
     patch -N -p1 -s < $rdir/patchs/batteryProperties.diff
     cd $rdir
   fi
   
   ## remove cmupdater ##
   if grep -q "removePreferenceIfPackageNotInstalled(findPreference(KEY_CM_UPDATES));" \
           $basedir/packages/apps/Settings/src/com/android/settings/DeviceInfoSettings.java; then
       cd $basedir/packages/apps/Settings
       patch -N -p1 -s <$rdir/patchs/setting_device_info.diff
       cd $rdir
   fi
   sed -e "/CMUpdater/d" -i $basedir/vendor/cm/config/common.mk

   sed -e "/OMX_FreeBuffer for buffer header %p successful/d" -i $basedir/frameworks/av/media/libstagefright/omx/OMXNodeInstance.cpp

   ## fix media_profiles.xml for HFR encode
   [ "$device" != "mb526" -a "$device" != "n880e" ] && \
   if grep -q "maxHFRFrameWidth" $basedir/frameworks/av/media/libmedia/MediaProfiles.cpp; then
      if ! grep -q "maxHFRFrameWidth" $basedir/device/motorola/$device/media_profiles.xml; then
         cd $basedir/device/motorola/$device
         patch -N -p1 -s < $rdir/patchs/media_profiles.diff
         cd $rdir
      fi
   fi

   ## hdmi toggle 
   [ "$device" != "mb526" -a "$device" != "n880e" ] && \
   if ! grep -q "HdmiToggle" $basedir/device/motorola/omap4-common/common.mk; then
        cd $basedir/device/motorola/omap4-common
        patch -N -p1 -s < $rdir/patchs/hdmiToggle.diff
        cd $rdir
   fi

   ## child mode
   [ $childmode -eq 0 ] && \
   if ! grep -q "android.pm.updateonly" $basedir/frameworks/base/core/java/android/app/ApplicationPackageManager.java; then
        cd $basedir/frameworks/base
        patch -N -p1 -s < $rdir/patchs/child_mode.diff
        cd $rdir
   fi

###return####
exit 0

