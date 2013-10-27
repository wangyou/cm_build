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

### apns-conf.xml #######
[ -d $basedir/vendor/cm/prebuilt/common/etc ] && cp $rdir/apns-conf.xml $basedir/vendor/cm/prebuilt/common/etc/
[ -d $basedir/device/motorola/edison ] && cp $rdir/apns-conf.xml $basedir/device/motorola/edison/


