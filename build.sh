reset
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
mkForce=""
oldupdate="old"
keepPatch=1

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
   elif [ "${op}" = "-k" ]; then
	keepPatch=0
   elif [ "$op" = "-B" ]; then
	mkForce=$op
   elif [ "${op:0:1}" = "-" ]; then
	mode="${op#-*}"
   elif [ "${op:0:4}" = "mod=" ]; then
	mod="${op#mod=*}"
   elif [ "$op" = "new" -o "$op" = "old" ]; then
	oldupdate="$op"
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
export CM_BUILDTYPE=NIGHTLY
export CM_EXTRAVERSION=NX111

if [ "$opKernel" = "jbx" -o "$opKernel" = "jbx-kernel" ] && [ "$device" = "edison" -o "$device" = "spyder" ]; then
	if [ "$device" = "edison" ]; then 
		LANG=en_US make $mod $mkJop $mkForce TARGET_BOOTLOADER_BOARD_NAME=$device TARGET_KERNEL_SOURCE=kernel/motorola/omap4-common-jbx \
  		       TARGET_KERNEL_CONFIG=mapphone_OCEdison_defconfig  
	else
		LANG=en_US make $mod $mkJop $mkForce TARGET_BOOTLOADER_BOARD_NAME=$device TARGET_KERNEL_SOURCE=kernel/motorola/omap4-common-jbx \
  		       TARGET_KERNEL_CONFIG=mapphone_OCE_defconfig  

	fi

	if [ "$opKernel" = "jbx-kernel" ]; then
		[ -d out/target/product/$device/jbx-kernel/rls/system/lib/modules ] || mkdir -p out/target/product/$device/jbx-kernel/rls/system/lib/modules/
		[ -d out/target/product/$device/jbx-kernel/rls/system/etc/kexec ] || mkdir -p out/target/product/$device/jbx-kernel/rls/system/etc/kexec/
		cp -r out/target/product/$device/system/lib/modules/* out/target/product/$device/jbx-kernel/rls/system/lib/modules/
		cp out/target/product/$device/kernel out/target/product/$device/jbx-kernel/rls/system/etc/kexec/
		curdir=`pwd`
		cd out/target/product/$device/jbx-kernel/rls/
		zip -r "../JBX-Kernel-1.4-Hybrid-$device-4.4_$(date +"%Y-%m-%d").zip" *
		cd $curdir
	fi

elif [ "$opKernel" = "cm" ]; then
	LANG=en_US make $mkJop $mkForce $mod $KERNELOPT
	if [ -f out/target/product/$device/${cm_version}-`date -u +%Y%m%d`-UNOFFICIAL-$device.zip ] ; then
		mv out/target/product/$device/${cm_version}-`date -u +%Y%m%d`-UNOFFICIAL-$device.zip out/target/product/$device/${cm_version}-`date +%Y%m%d`-${compile_user}-$device.zip
	fi
else 
	LANG=en_US make $mkJop $mkForce $mod $KERNELOPT
fi

[ $keepPatch -eq 0 ] || $rdir/patch.sh -r 


rm -f out/target/product/$device/cm_$device-ota-*.zip
rm -f out/target/product/$device/cm-*.zip.md5sum
