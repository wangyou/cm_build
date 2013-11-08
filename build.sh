clear
compile_user=NX111


rdir=`dirname $0`
[ "$rdir" != "." ] && cd $rdir
TOP=`pwd`

if [ ! -f build/envsetup.sh ]; then
	repo init -u git://github.com/CyanogenMod/android.git -b cm-10.2
	repo sync
fi

lastDevice="edison"
[ -f .device ] && lastDevice=`cat .device`

KERNELOPT=""
device=edison
opKernel="jbx"
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
   fi
done

echo "$device">.device

. build/envsetup.sh

[ ! -f vendor/cm/proprietary/Term.apk ] && vendor/cm/get-prebuilts
cm_version=`grep "^\s*<default revision=\"refs/heads/cm-" .repo/manifest.xml  | sed -e "s/^\s*<default revision=\"refs\/heads\/\(cm-.*\)\"/\1/"`

.myfiles/patch.sh $device 

########Delete old files#############################
if [ -d out/target/product/$device/obj/PACKAGING/target_files_intermediates ]; then
  cd out/target/product/$device/obj/PACKAGING/target_files_intermediates
  ls -t  | awk '{if(NR>2){print $0}}' | xargs rm -rf 
  cd $TOP
fi
if [ -d out/target/product/$device/ ]; then
  cd out/target/product/$device
  ls -t cm-*.zip | awk '{if(NR>3){print $0}}' |xargs rm -rf 
  cd $TOP
fi
rm -rf out/target/product/$device/system/*
if [ "$lastDevice" != "$device" -a "$device" = "mb526" ]; then
	mv out/target/common out/target/common.cm
	[ -d out/target/common.quarx2k ] && mv out/target/common.quarx2k out/target/common
elif [ "$lastDevice" != "$device" -a "$lastDevice" = "mb526" ]; then
	mv out/target/common out/target/common.quarx2k
	[ -d out/target/common.cm ] && mv out/target/common.cm out/target/common
fi

#############lunch######################
lunch cm_$device-userdebug 

########## MAKE #########################
if [ "$opKernel" = "jbx" -o "$opKernel" = "jbx-kernel" ] && [ "$device" = "edison" -o "$device" = "spyder" ]; then
	if [ "$device" = "edison" ]; then 
		make bacon -j4 TARGET_BOOTLOADER_BOARD_NAME=$device TARGET_KERNEL_SOURCE=kernel/motorola/omap4-common-jbx \
  		       TARGET_KERNEL_CONFIG=mapphone_OCEdison_defconfig  \
		       BOARD_KERNEL_CMDLINE='root=/dev/ram0 rw mem=1023M@0x80000000 console=null vram=10300K omapfb.vram=0:8256K,1:4K,2:2040K init=/init ip=off mmcparts=mmcblk1:p7(pds),p15(boot),p16(recovery),p17(cdrom),p18(misc),p19(cid),p20(kpanic),p21(system),p22(cache),p23(preinstall),p24(webtop),p25(userdata) mot_sst=1 androidboot.bootloader=0x0A72'
	else
		make bacon -j4 TARGET_BOOTLOADER_BOARD_NAME=$device TARGET_KERNEL_SOURCE=kernel/motorola/omap4-common-jbx \
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
	make -j4 bacon $KERNELOPT
	if [ -f out/target/product/$device/${cm_version}-`date -u +%Y%m%d`-UNOFFICIAL-$device.zip ] ; then
		mv out/target/product/$device/${cm_version}-`date -u +%Y%m%d`-UNOFFICIAL-$device.zip out/target/product/$device/${cm_version}-`date +%Y%m%d`-${compile_user}-$device.zip
	fi
else 
	make -j4 bacon $KERNELOPT
	if [ -f out/target/product/$device/${cm_version}-`date -u +%Y%m%d`-UNOFFICIAL-$device.zip ] ; then
		mv out/target/product/$device/${cm_version}-`date -u +%Y%m%d`-UNOFFICIAL-$device.zip out/target/product/$device/${cm_version}-`date +%Y%m%d`-${compile_user}-$device.zip
	fi
fi

.myfiles/patch.sh -r 


rm -f out/target/product/$device/cm_$device-ota-*.zip
rm -f out/target/product/$device/cm-*.zip.md5sum
