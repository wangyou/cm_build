rdir=`dirname $0`
[ "$rdir" != "." ] && cd $rdir
if [ ! -f build/envsetup.sh ]; then
	repo init -u git://github.com/CyanogenMod/android.git -b cm-10.2
	repo sync
fi

. build/envsetup.sh

[ ! -f vendor/cm/proprietary/Term.apk ] && vendor/cm/get-prebuilts

.myfiles/patch.sh

lunch cm_edison-userdebug 
if [ "$1" = "jbx" ]; then
	make bacon -j4 TARGET_BOOTLOADER_BOARD_NAME=edison TARGET_KERNEL_SOURCE=kernel/motorola/omap4-common-jbx  TARGET_KERNEL_CONFIG=mapphone_OCEdison_defconfig  
	if [ $? -eq 0 -a "$2" = "kernel" ]; then	
		[ -d out/target/product/edison/jbx-kernel/rls/system/lib/modules ] || mkdir -p out/target/product/edison/jbx-kernel/rls/system/lib/modules/
		[ -d out/target/product/edison/jbx-kernel/rls/system/etc/kexec ] || mkdir -p out/target/product/edison/jbx-kernel/rls/system/etc/kexec/
		cp -r out/target/product/edison/system/lib/modules/* out/target/product/edison/jbx-kernel/rls/system/lib/modules/
		cp out/target/product/edison/kernel out/target/product/edison/jbx-kernel/rls/system/etc/kexec/
		curdir=`pwd`
		cd out/target/product/edison/jbx-kernel/rls/
		zip -r "../JBX-Kernel-1.4-Hybrid-Edison-4.3_$(date +"%Y-%m-%d").zip" *
		cd $curdir
	fi
else
	make -j4 bacon 
fi

[ -d out/target/product/edison ] || exit
sf=`find out/target/product/edison -name cm-*-UNOFFICIAL-edison.zip`
[ "$sf" = "" ] && exit

farray=($sf)
for f in ${farray[@]} 
do
	 mv $f `echo $f|sed -e "s/UNOFFICIAL/NX111/"`
done
