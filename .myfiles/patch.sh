### parse params #########
for op in $*;do 
	if echo $op | grep -q "device="; then
		dev=`echo $op | sed "s/device=\(.*\)/\1/"`
		[ ! -z "$dev" ] && device=$dev
	fi
	if echo $op | grep -q "mode="; then
		mo=`echo $op | sed "s/mode=\(.*\)/\1/"`
		[ ! -z "$mo" ] && mode=$mo
	fi

done
cdir=`pwd`
rdir=`cd \`dirname $0\`;pwd`

basedir=`dirname $rdir`

## local_manifest.xml   ####
if [ -d $basedir/.repo -a -f $rdir/local_manifest.xml ]; then
   cp $rdir/local_manifest.xml $basedir/.repo/
fi

if [ "$mode" = "r" ]; then
	if [ -d $basedir/frameworks/base.cm -a ! -d $basedir/frameworks/base.quarx2k ]; then
		mv $basedir/frameworks/base $basedir/frameworks/base.quarx2k
		mv $basedir/frameworks/base.cm $basedir/frameworks/base
	fi
		
	if [ -d $basedir/frameworks/av.cm -a ! -d $basedir/frameworks/av.quarx2k ]; then
		mv $basedir/frameworks/av $basedir/frameworks/av.quarx2k
		mv $basedir/frameworks/av.cm $basedir/frameworks/av
	fi
	if [ -d $basedir/frameworks/native.cm -a ! -d $basedir/frameworks/native.quarx2k ]; then
		mv $basedir/frameworks/native $basedir/frameworks/native.quarx2k
		mv $basedir/frameworks/native.cm $basedir/frameworks/native
	fi
	if [ -d $basedir/system/core.cm -a ! -d $basedir/system/core.quarx2k ]; then
		mv $basedir/system/core $basedir/system/core.quarx2k
		mv $basedir/system/core.cm $basedir/system/core
	fi
	if [ -d $basedir/hardware/ril.cm -a ! -d $basedir/hardware/ril.quarx2k ]; then
		mv $basedir/hardware/ril $basedir/hardware/ril.quarx2k
		mv $basedir/hardware/ril.cm $basedir/hardware/ril
	fi
	if [ -d $basedir/frameworks/opt/telephony.cm -a ! -d $basedir/frameworks/opt/telephony.quarx2k ]; then
		mv $basedir/frameworks/opt/telephony $basedir/frameworks/opt/telephony.quarx2k
		mv $basedir/frameworks/opt/telephony.cm $basedir/frameworks/opt/telephony
	fi
	
	cd $basedir/frameworks/base;			git stash >/dev/null
	cd $basedir/frameworks/av;			git stash >/dev/null
	cd $basedir/frameworks/native;			git stash >/dev/null
	cd $basedir/frameworks/opt/telephony;		git stash >/dev/null
	cd $basedir/system/core;			git stash >/dev/null
	cd $basedir/hardware/ril;			git stash >/dev/null
	cd $basedir/frameworks/base.quarx2k		git stash >/dev/null
	cd $basedir/frameworks/av.quarx2k;		git stash >/dev/null
	cd $basedir/frameworks/native.quarx2k;		git stash >/dev/null
	cd $basedir/frameworks/opt/telephony.quarx2k;	git stash >/dev/null
	cd $basedir/system/core.quarx2k;		git stash >/dev/null
	cd $basedir/hardware/ril.quarx2k;		git stash >/dev/null

	cd $basedir/device/motorola/omap4-common;       git stash >/dev/null
	cd $basedir/kernel/motorola/omap4-common-jbx;   git stash >/dev/null
	cd $basedir/device/moto/jordan-common; 		git stash >/dev/null
	cd $basedir/frameworks/av;			git stash >/dev/null
	cd $basedir/vendor/cm;				git stash >/dev/null
	cd $basedir/system/core;			git stash >/dev/null
	rm -rf $basedir/vendor/motorola/jordan-common
	cd $rdir
	exit
	
fi


if [ "$device" = "edison" -o "$device" = "spyder" ]; then

	if [ -d $basedir/frameworks/base.cm -a ! -d $basedir/frameworks/base.quarx2k ]; then
		mv $basedir/frameworks/base $basedir/frameworks/base.quarx2k
		mv $basedir/frameworks/base.cm $basedir/frameworks/base
	fi
		
	if [ -d $basedir/frameworks/av.cm -a ! -d $basedir/frameworks/av.quarx2k ]; then
		mv $basedir/frameworks/av $basedir/frameworks/av.quarx2k
		mv $basedir/frameworks/av.cm $basedir/frameworks/av
	fi
	if [ -d $basedir/frameworks/native.cm -a ! -d $basedir/frameworks/native.quarx2k ]; then
		mv $basedir/frameworks/native $basedir/frameworks/native.quarx2k
		mv $basedir/frameworks/native.cm $basedir/frameworks/native
	fi
	if [ -d $basedir/frameworks/opt/telephony.cm -a ! -d $basedir/frameworks/opt/telephony.quarx2k ]; then
		mv $basedir/frameworks/opt/telephony $basedir/frameworks/opt/telephony.quarx2k
		mv $basedir/frameworks/opt/telephony.cm $basedir/frameworks/opt/telephony
	fi
	if [ -d $basedir/system/core.cm -a ! -d $basedir/system/core.quarx2k ]; then
		mv $basedir/system/core $basedir/system/core.quarx2k
		mv $basedir/system/core.cm $basedir/system/core
	fi
	if [ -d $basedir/hardware/ril.cm -a ! -d $basedir/hardware/ril.quarx2k ]; then
		mv $basedir/hardware/ril $basedir/hardware/ril.quarx2k
		mv $basedir/hardware/ril.cm $basedir/hardware/ril
	fi
	rm -rf $basedir/frameworks/base.quarx2k/*
	rm -rf $basedir/frameworks/av.quarx2k/*
	rm -rf $basedir/frameworks/native.quarx2k/*
	rm -rf $basedir/frameworks/opt/telephony.quarx2k/*
	rm -rf $basedir/system/core.quarx2k/*
	rm -rf $basedir/hardware/ril.quarx2k/*
	cd $basedir/frameworks/base;			git stash >/dev/null
	cd $basedir/frameworks/av;			git stash >/dev/null
	cd $basedir/frameworks/native;			git stash >/dev/null
	cd $basedir/frameworks/opt/telephony;		git stash >/dev/null
	cd $basedir/system/core;			git stash >/dev/null
	cd $basedir/hardware/ril;			git stash >/dev/null

   ### patch for CAMERA_CMD_LONGSHOT_ON  ##########
   if ! grep -q CAMERA_CMD_LONGSHOT_ON $basedir/device/motorola/omap4-common/include/system/camera.h;  then
	cd $basedir/device/motorola/omap4-common
	patch -N -p1 <$rdir/omap4-common.diff
	cd $rdir
   fi

   ### jbx-kernel patch ###########
   sed -e "s/^\(\s*\)\(OPP_INITIALIZER(\"gpu\", \"dpll_per_m7x2_ck\", \"core\", \)true\(, 512000000, OMAP4430_VDD_CORE_OPP100_OV_UV),\)/\1\2false\3/" -i $basedir/kernel/motorola/omap4-common-jbx/arch/arm/mach-omap2/opp4xxx_data.c 

   sed -e "s/^\(\s*echo \\\#define LINUX_COMPILE_HOST \s*\\\\\"\)\`echo dtrail\`\(\\\\\"\)/\1\\\`echo \$LINUX_COMPILE_HOST | sed -e \\\"s\/\\\s\/_\/g\\\"\`\2/"  -i $basedir/kernel/motorola/omap4-common-jbx/scripts/mkcompile_h

   ### patch for vendor cm  ########
   if ! grep -q "^\s*#\$(call inherit-product, frameworks\/base\/data\/videos\/VideoPackage2.mk)" \
        $basedir/vendor/cm/config/common_full.mk; then
	cd $basedir/vendor/cm
	patch -N -p1 <$rdir/vendor_cm.diff
	cd $rdir
   fi

elif [ "$device" = "mb526" ]; then
   ###### for jordan ##########

	if [  -d $basedir/frameworks/base.quarx2k -a ! -d $basedir/frameworks/base.cm ]; then
		mv $basedir/frameworks/base $basedir/frameworks/base.cm
		mv $basedir/frameworks/base.quarx2k $basedir/frameworks/base
	fi
		
	if [ -d $basedir/frameworks/av.quarx2k -a ! -d $basedir/frameworks/av.cm ]; then
		mv $basedir/frameworks/av $basedir/frameworks/av.cm
		mv $basedir/frameworks/av.quarx2k $basedir/frameworks/av
	fi
	if [ -d $basedir/frameworks/native.quarx2k -a ! -d $basedir/frameworks/native.cm ]; then
		mv $basedir/frameworks/native $basedir/frameworks/native.cm
		mv $basedir/frameworks/native.quarx2k $basedir/frameworks/native
	fi
	if [ -d $basedir/frameworks/opt/telephony.quarx2k -a ! -d $basedir/frameworks/opt/telephony.cm ]; then
		mv $basedir/frameworks/opt/telephony $basedir/frameworks/opt/telephony.cm
		mv $basedir/frameworks/opt/telephony.quarx2k $basedir/frameworks/opt/telephony
	fi
	if [ -d $basedir/system/core.quarx2k -a ! -d $basedir/system/core.cm ]; then
		mv $basedir/system/core $basedir/system/core.cm
		mv $basedir/system/core.quarx2k $basedir/system/core
	fi
	if [ -d $basedir/hardware/ril.quarx2k -a ! -d $basedir/hardware/ril.cm ]; then
		mv $basedir/hardware/ril $basedir/hardware/ril.cm
		mv $basedir/hardware/ril.quarx2k $basedir/hardware/ril
	fi
	rm -rf $basedir/frameworks/base.cm/*
	rm -rf $basedir/frameworks/av.cm/*
	rm -rf $basedir/frameworks/native.cm/*
	rm -rf $basedir/frameworks/opt/telephony.cm/*
	rm -rf $basedir/system/core.cm/*
	rm -rf $basedir/hardware/ril.cm/*
	cd $basedir/frameworks/base;			git stash >/dev/null
	cd $basedir/frameworks/av;			git stash >/dev/null
	cd $basedir/frameworks/native;			git stash >/dev/null
	cd $basedir/frameworks/opt/telephony;		git stash >/dev/null
	cd $basedir/system/core;			git stash >/dev/null
	cd $basedir/hardware/ril;			git stash >/dev/null

   ### patch for vendor cm  ########
   if ! grep -q "^\s*#\$(call inherit-product, frameworks\/base\/data\/videos\/VideoPackage2.mk)" \
        $basedir/vendor/cm/config/common_full.mk; then
	cd $basedir/vendor/cm
	patch -N -p1 <$rdir/vendor_cm_quarx2k.diff
	cd $rdir
   fi

fi

#### LOG for KERNEL ##########
sed -e "s/^\(#define KLOG_DEFAULT_LEVEL\s*\)3\(\s*.*\)/\16\2/" -i $basedir/system/core/include/cutils/klog.h


