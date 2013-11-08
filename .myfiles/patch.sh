###switch directory ,usage: swDirectory <basedir> <ext_target> <ext_src> ####
swDirectory()
{
	if [ $# -lt 3 ]; then
		echo "##Error: function swDirectory failed!"
		echo "  usage: swDirectory <basedir> <ext_target> <ext_src> "
		return -1;
	fi
	if [ -d $1.$2  ]; then
		rm -rf $1.$3
		mv $1 $1.$3
		mv $1.$2 $1
	fi
	return 0
}

device=edison
mode=""
### parse params #########
for op in $*;do 
   if [ "$op" = "spyder" ]; then
   	device="$op"
   elif [ "$op" = "edison" ]; then
	device="edison"
   elif [ "$op" = "jordan" -o "$op" = "mb526" ]; then
	device="mb526"
   elif [ "$op" = "-r" ]; then
	mode="r"
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
	swDirectory $basedir/frameworks/base cm quarx2k
	swDirectory $basedir/frameworks/av cm quarx2k
	swDirectory $basedir/frameworks/native cm quarx2k
	swDirectory $basedir/frameworks/opt/telephony cm quarx2k
	swDirectory $basedir/system/core cm quarx2k
	swDirectory $basedir/hardware/ril cm quarx2k

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

	swDirectory $basedir/frameworks/base cm quarx2k
	swDirectory $basedir/frameworks/av cm quarx2k
	swDirectory $basedir/frameworks/native cm quarx2k
	swDirectory $basedir/frameworks/opt/telephony cm quarx2k
	swDirectory $basedir/system/core cm quarx2k
	swDirectory $basedir/hardware/ril cm quarx2k
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
	swDirectory $basedir/frameworks/base quarx2k cm
	swDirectory $basedir/frameworks/av quarx2k cm
	swDirectory $basedir/frameworks/native quarx2k cm
	swDirectory $basedir/frameworks/opt/telephony quarx2k cm
	swDirectory $basedir/system/core quarx2k cm
	swDirectory $basedir/hardware/ril quarx2k cm
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


