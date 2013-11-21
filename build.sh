clear
compile_user=NX111
branch=cm-11.0

ScriptName=`basename $0`
rdir=`dirname $0`
[ "$rdir" != "." ] && cd $rdir
TOP=`pwd`


lastDevice="edison"
[ -f .device ] && lastDevice=`cat .device`

KERNELOPT=""
device=edison
opKernel="jbx"
mkJop=""
mod=bacon
mkOp=""
for op in $*;do
   if [ "$op" = "spyder" ]; then
	device="$op"
   elif [ "$op" = "edison" ]; then
	device="edison"
   elif [ "$op" = "jordan" -o "$op" = "mb526" ]; then
	device="mb526"
	KERNELOPT="TARGET_KERNEL_SOURCE=kernel/motorola/jordan"
	rm -rf $TOP/vendor/motorola/jordan-common
	[ -d  $TOP/vendor/moto/jordan-common ] && cp -r $TOP/vendor/moto/jordan-common $TOP/vendor/motorola/jordan-common
   elif [ "$op" = "jbx" -o "$op" = "jbx-kernel" -o "$op" = "cm" ]; then
	opKernel="$op"
   elif [ "${op:0:2}" = "-j" ]; then
	mkJop=$op
   elif [ "${op:0:1}" = "-" ]; then
	mode="${op#-*}"
   elif [ "${op:0:4}" = "mod=" ]; then
	mod="${op#mod=*}"
   elif [ "$op" = "old" ]; then
	oldupdate="$op"
   else
	mkOp=$op
   fi
done

if [ "$mode" = "cleanall" ]; then
    for f in * .*; do
	[ "$f" != "$ScriptName" -a "$f" != ".myfiles" -a "$f" != ".git" -a "$f" != ".gitignore" -a "$f" != ".repo" ] \
	   && [ "$f" != "." -a "$f" != ".." ] && rm -rf $f
    done
   exit
fi

if [ ! -f build/envsetup.sh -o "$mode" = "init" ]; then
	repo init -u git://github.com/CyanogenMod/android.git -b $branch
	repo sync
	repo start $branch .
	exit
fi

if [ "$mode" = "sync" ]; then
    while true 
    do 
	if repo sync; then
		echo "sync successed!"
		break
		exit
	fi
    done
fi

. build/envsetup.sh

[ ! -f vendor/cm/proprietary/Term.apk ] && vendor/cm/get-prebuilts
cm_version=`grep "^\s*<default revision=\"refs/heads/cm-" .repo/manifest.xml  | sed -e "s/^\s*<default revision=\"refs\/heads\/\(cm-.*\)\"/\1/"`

echo "$device">.device
.myfiles/patch.sh $device $mode $oldupdate

########Delete old files#############################
if [ -d out/target/product/$device/obj/PACKAGING/target_files_intermediates ]; then
  cd out/target/product/$device/obj/PACKAGING/target_files_intermediates
  ls -t  | awk '{if(NR>2){print $0}}' | xargs rm -rf 
  cd $TOP
fi
if [ -d out/target/product/$device/ ]; then
  cd out/target/product/$device
  ls -t cm-*.zip 2>/dev/null | awk '{if(NR>3){print $0}}' |xargs rm -rf 
  cd $TOP
fi
rm -f out/target/product/$device/system/build.prop

#############lunch######################
lunch cm_$device-userdebug 

########## MAKE #########################
if [ "$opKernel" = "jbx" -o "$opKernel" = "jbx-kernel" ] && [ "$device" = "edison" -o "$device" = "spyder" ]; then
	if [ "$device" = "edison" ]; then 
		LANG=en_US make $mod $mkJop $mkOp TARGET_BOOTLOADER_BOARD_NAME=$device TARGET_KERNEL_SOURCE=kernel/motorola/omap4-common-jbx \
  		       TARGET_KERNEL_CONFIG=mapphone_OCEdison_defconfig  \
		       BOARD_KERNEL_CMDLINE='root=/dev/ram0 rw mem=1023M@0x80000000 console=null vram=10300K omapfb.vram=0:8256K,1:4K,2:2040K init=/init ip=off mmcparts=mmcblk1:p7(pds),p15(boot),p16(recovery),p17(cdrom),p18(misc),p19(cid),p20(kpanic),p21(system),p22(cache),p23(preinstall),p24(webtop),p25(userdata) mot_sst=1 androidboot.bootloader=0x0A72'
	else
		LANG=en_US make $mod $mkJop $mkOp TARGET_BOOTLOADER_BOARD_NAME=$device TARGET_KERNEL_SOURCE=kernel/motorola/omap4-common-jbx \
  		       TARGET_KERNEL_CONFIG=mapphone_OCE_defconfig  

	fi

	if [ "$opKernel" = "jbx-kernel" ]; then
		[ -d out/target/product/$device/jbx-kernel/rls/system/lib/modules ] || mkdir -p out/target/product/$device/jbx-kernel/rls/system/lib/modules/
		[ -d out/target/product/$device/jbx-kernel/rls/system/etc/kexec ] || mkdir -p out/target/product/$device/jbx-kernel/rls/system/etc/kexec/
		cp -r out/target/product/$device/system/lib/modules/* out/target/product/$device/jbx-kernel/rls/system/lib/modules/
		cp out/target/product/$device/kernel out/target/product/$device/jbx-kernel/rls/system/etc/kexec/
		curdir=`pwd`
		cd out/target/product/$device/jbx-kernel/rls/
		zip -r "../JBX-Kernel-1.4-Hybrid-$device-4.3_$(date +"%Y-%m-%d").zip" *
		cd $curdir
	fi

	if [ -f out/target/product/$device/${cm_version}-`date -u +%Y%m%d`-UNOFFICIAL-$device.zip ] ; then
		mv out/target/product/$device/${cm_version}-`date -u +%Y%m%d`-UNOFFICIAL-$device.zip out/target/product/$device/${cm_version}-`date +%Y%m%d`-JBX_KERNEL-${compile_user}-$device.zip
	fi
elif [ "$opKernel" = "cm" ]; then
	LANG=en_US make $mkJop $mkOp $mod $KERNELOPT
	if [ -f out/target/product/$device/${cm_version}-`date -u +%Y%m%d`-UNOFFICIAL-$device.zip ] ; then
		mv out/target/product/$device/${cm_version}-`date -u +%Y%m%d`-UNOFFICIAL-$device.zip out/target/product/$device/${cm_version}-`date +%Y%m%d`-${compile_user}-$device.zip
	fi
else 
	LANG=en_US make $mkJop $mkOp $mod $KERNELOPT
	if [ -f out/target/product/$device/${cm_version}-`date -u +%Y%m%d`-UNOFFICIAL-$device.zip ] ; then
		mv out/target/product/$device/${cm_version}-`date -u +%Y%m%d`-UNOFFICIAL-$device.zip out/target/product/$device/${cm_version}-`date +%Y%m%d`-${compile_user}-$device.zip
	fi
fi

#.myfiles/patch.sh -r 


#rm -f out/target/product/$device/cm_$device-ota-*.zip
#rm -f out/target/product/$device/cm-*.zip.md5sum
