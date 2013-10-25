rdir=`dirname $0`
[ "$rdir" != "." ] && cd $rdir
if [ ! -f build/envsetup.sh ]; then
	repo init -u git://github.com/CyanogenMod/android.git -b cm-10.2
	repo sync
fi

. build/envsetup.sh

[ ! -f vendor/cm/proprietary/Term.apk ] && vendor/cm/get-prebuilts

lunch cm_edison-userdebug 
[ "$1" = "jbx" ] && jbx="TARGET_PREBUILT_KERNEL=kernel/JBX-KERNEL/edison"
make bacon $jbx

[ -d out/target/product/edison ] || exit
sf=`find out/target/product/edison -name cm-*-UNOFFICIAL-edison.zip`
[ "$sf" = "" ] && exit

farray=($sf)
for f in ${farray[@]} 
do
	 mv $f `echo $f|sed -e "s/UNOFFICIAL/NX111/"`
done
