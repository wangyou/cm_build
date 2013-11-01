device=edison
compile_user=NX111

rdir=`dirname $0`
[ "$rdir" != "." ] && cd $rdir
TOP=`pwd`

if [ ! -f build/envsetup.sh ]; then
	repo init -u git://github.com/CyanogenMod/android.git -b cm-10.2
	repo sync
fi

. build/envsetup.sh

[ ! -f vendor/cm/proprietary/Term.apk ] && vendor/cm/get-prebuilts
cm_version=`grep "^\s*<default revision=\"refs/heads/cm-" .repo/manifest.xml  | sed -e "s/^\s*<default revision=\"refs\/heads\/\(cm-.*\)\"/\1/"`

.myfiles/patch.sh

find out/target/product/$device/obj/PACKAGING/target_files_intermediates/  -maxdepth 1 -type d -mtime +1  -exec rm -rf {} \;
find out/target/product/$device/obj/PACKAGING/target_files_intermediates/  -type f -name cm_$device-*.zip -mtime +1 -exec rm -rf {} \;

lunch cm_$device-userdebug 
if [ "$1" = "jbx" -o "$1" = "jbx-kernel" -o "$1" = "" ]; then
	make bacon -j4 TARGET_BOOTLOADER_BOARD_NAME=$device TARGET_KERNEL_SOURCE=kernel/motorola/omap4-common-jbx \
  		       TARGET_KERNEL_CONFIG=mapphone_OCEdison_defconfig  \
		       KBUILD_BUILD_HOST="Aim Hi" \
		       BOARD_KERNEL_CMDLINE='root=/dev/ram0 rw mem=1023M@0x80000000 console=null vram=10300K omapfb.vram=0:8256K,1:4K,2:2040K init=/init ip=off mmcparts=mmcblk1:p7(pds),p15(boot),p16(recovery),p17(cdrom),p18(misc),p19(cid),p20(kpanic),p21(system),p22(cache),p23(preinstall),p24(webtop),p25(userdata) mot_sst=1 androidboot.bootloader=0x0A72'

	if [ $? -eq 0 -a "$1" = "jbx-kernel" -a "$device" = "edison" ]; then	
		[ -d out/target/product/$device/jbx-kernel/rls/system/lib/modules ] || mkdir -p out/target/product/$device/jbx-kernel/rls/system/lib/modules/
		[ -d out/target/product/$device/jbx-kernel/rls/system/etc/kexec ] || mkdir -p out/target/product/$device/jbx-kernel/rls/system/etc/kexec/
		cp -r out/target/product/$device/system/lib/modules/* out/target/product/$device/jbx-kernel/rls/system/lib/modules/
		cp out/target/product/$device/kernel out/target/product/$device/jbx-kernel/rls/system/etc/kexec/
		curdir=`pwd`
		cd out/target/product/$device/jbx-kernel/rls/
		zip -r "../JBX-Kernel-1.4-Hybrid-Edison-4.3_$(date +"%Y-%m-%d").zip" *
		cd $curdir
	fi

	if [ -f out/target/product/$device/${cm_version}-`date -u +%Y%m%d`-UNOFFICIAL-$device.zip ] ; then
		mv out/target/product/$device/${cm_version}-`date -u +%Y%m%d`-UNOFFICIAL-$device.zip out/target/product/$device/${cm_version}-`date -u +%Y%m%d`-JBX_KERNEL-${compile_user}-$device.zip
	fi
elif [ "$1" = "orig" -o "$1" = "cm" ]; then
	make -j4 bacon 
	if [ -f out/target/product/$device/${cm_version}-`date -u +%Y%m%d`-UNOFFICIAL-$device.zip ] ; then
		mv out/target/product/$device/${cm_version}-`date -u +%Y%m%d`-UNOFFICIAL-$device.zip out/target/product/$device/${cm_version}-`date +%Y%m%d`-${compile_user}-$device.zip
	fi

fi


rm -f out/target/product/$device/cm_$device-ota-*.zip
rm -f out/target/product/$device/cm-*.zip.md5sum
