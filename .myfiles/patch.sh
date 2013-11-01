cdir=`pwd`
rdir=`cd \`dirname $0\`;pwd`

basedir=`dirname $rdir`

## local_manifest.xml   ####
if [ -d $basedir/.repo -a -f $rdir/local_manifest.xml ]; then
   cp $rdir/local_manifest.xml $basedir/.repo/
fi

### patch for CAMERA_CMD_LONGSHOT_ON  ##########
if [ -f $basedir/device/motorola/omap4-common/include/system/camera.h ]; then
	grep CAMERA_CMD_LONGSHOT_ON $basedir/device/motorola/omap4-common/include/system/camera.h >/dev/null
	if [ $? -eq 1 ]; then
		cd $basedir/device/motorola/omap4-common
		patch -N -p1 <$rdir/omap4-common.diff
		cd $rdir
	fi
fi

### patch for vendor cm  ########

if [ -f $basedir/vendor/cm/config/common_full.mk ]; then
	grep "#\$(call inherit-product, frameworks/base/data/videos/VideoPackage2.mk)" $basedir/vendor/cm/config/common_full.mk >/dev/null
	if [ $? -eq 1 ]; then
		cd $basedir/vendor/cm
		patch -N -p1 <$rdir/vendor_cm.diff
		cd $rdir
	fi
fi


### jbx-kernel patch ###########
sed -e "s/^\(\s*\)\(OPP_INITIALIZER(\"gpu\", \"dpll_per_m7x2_ck\", \"core\", \)true\(, 512000000, OMAP4430_VDD_CORE_OPP100_OV_UV),\)/\1\2false\3/" -i $basedir/kernel/motorola/omap4-common-jbx/arch/arm/mach-omap2/opp4xxx_data.c 

sed -e "s/^\(\s*echo \\\#define LINUX_COMPILE_HOST \s*\\\\\"\)\`echo dtrail\`\(\\\\\"\)/\1\\\`echo \$LINUX_COMPILE_HOST | sed -e \\\"s\/\\\s\/_\/g\\\"\`\2/" \
    -i $basedir/kernel/motorola/omap4-common-jbx/scripts/mkcompile_h

#### LOG for KERNEL ##########
sed -e "s/^\(#define KLOG_DEFAULT_LEVEL\s*\)3\(\s*.*\)/\16\2/" -i $basedir/system/core/include/cutils/klog.h

