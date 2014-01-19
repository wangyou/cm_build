reset
compile_user=NX111
branch=cm-11.0

ScriptName=`basename $0`
rdir=`dirname $0`
[ "$rdir" != "." ] && cd $rdir
TOP=`pwd`


KERNELOPT=""
device=edison
opKernel="cm"
mkJop=""
mod=bacon
mkForce=""
oldupdate="old"
keepPatch=1
kernelzip=1
moreopt=""

lastDevice="edison"
if [ -f .lastBuild ]; then
   lastDevice=`grep device: .lastBuild|cut -d: -f2|sed -e "s/^ //g" -e "s/ $//g"`
   opKernel=`grep opKernel: .lastBuild|cut -d: -f2|sed -e "s/^ //g" -e "s/ $//g"`
   [ -z $opKernel ] && opKernel="cm"
fi

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
   elif [ "${op}" = "-kernel-zip" ]; then
	kernelzip=0
   elif [ "${op}" = "-k" ]; then
	keepPatch=0
   elif [ "$op" = "-B" ]; then
	mkForce=$op
   elif [ "$op" = "-rk" ]; then
	moreopt="$moreopt $op"
   elif [ "${op:0:1}" = "-" ]; then
	mode="${op#-*}"
   elif [ "${op:0:4}" = "mod=" ]; then
	mod="${op#mod=*}"
   elif [ "$op" = "new" -o "$op" = "old" ]; then
	oldupdate="$op"
   else
	moreopt="$moreopt $op"
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
	repo start $branch --all
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


echo "device: $device">.lastBuild
echo "opKernel: $opKernel">>.lastBuild

.myfiles/patch.sh $device $mode $oldupdate $moreopt $opKernel

######generate projects's last 5 logs########
echo "Generating projects's last 5 logs..."
PROJECTLIST=$rdir/.repo/project.list
OUTLOG=$TOP/out/target/product/$device/system/etc/ChangeLog-5.log
[ -d $TOP/out/target/product/$device/system/etc/ ] || mkdir -p $TOP/out/target/product/$device/system/etc/
rm -f $OUTLOG
touch $OUTLOG
while read project
do
	cd $TOP/$project
	echo $project: >>$OUTLOG
	git log -5 --pretty=format:'    %h  %ad  %s' --date=short >>$OUTLOG
	echo -e "\n">>$OUTLOG
done < $PROJECTLIST
cd $TOP

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

if [ "$opKernel" = "jbx" ] && [ "$device" = "edison" -o "$device" = "spyder" ]; then
	CM_EXTRAVERSION=NX111_JBX \
	LANG=en_US make $mod $mkJop $mkForce TARGET_BOOTLOADER_BOARD_NAME=$device \
  		        TARGET_KERNEL_CONFIG=mapphone_OCE_defconfig  

	if [ $kernelzip -eq 0 ]; then
		[ -d out/target/product/$device/kernel_zip/rls/system/lib/modules ] || mkdir -p out/target/product/$device/kernel_zip/rls/system/lib/modules/
		[ -d out/target/product/$device/kernel_zip/rls/system/etc/kexec ] || mkdir -p out/target/product/$device/kernel_zip/rls/system/etc/kexec/
		[ -d out/target/product/$device/kernel_zip/rls/META-INF/com/google/android/ ] || mkdir -p out/target/product/$device/kernel_zip/rls/META-INF/com/google/android/ 
		cp .myfiles/scripts/kernel_zip/* out/target/product/$device/kernel_zip/rls/META-INF/com/google/android/
		cp -r out/target/product/$device/system/lib/modules/* out/target/product/$device/kernel_zip/rls/system/lib/modules/
		cp out/target/product/$device/kernel out/target/product/$device/kernel_zip/rls/system/etc/kexec/
		curdir=`pwd`
		cd out/target/product/$device/kernel_zip/rls/
		zip -r "../JBX-Kernel-2.0-Hybrid-$device-4.4_$(date +"%Y-%m-%d").zip" * >/dev/null
		cd $curdir
	fi

elif [ "$opKernel" = "cm" ]; then
	LANG=en_US make $mkJop $mkForce $mod $KERNELOPT

	if [ $kernelzip -eq 0 ]; then
		[ -d out/target/product/$device/kernel_zip/rls/system/lib/modules ] || mkdir -p out/target/product/$device/kernel_zip/rls/system/lib/modules/
		[ -d out/target/product/$device/kernel_zip/rls/system/etc/kexec ] || mkdir -p out/target/product/$device/kernel_zip/rls/system/etc/kexec/
		[ -d out/target/product/$device/kernel_zip/rls/META-INF/com/google/android/ ] || mkdir -p out/target/product/$device/kernel_zip/rls/META-INF/com/google/android/ 
		cp .myfiles/scripts/kernel_zip/* out/target/product/$device/kernel_zip/rls/META-INF/com/google/android/
		cp -r out/target/product/$device/system/lib/modules/* out/target/product/$device/kernel_zip/rls/system/lib/modules/
		cp out/target/product/$device/kernel out/target/product/$device/kernel_zip/rls/system/etc/kexec/
		curdir=`pwd`
		cd out/target/product/$device/kernel_zip/rls/
		zip -r "../Kernel-$device-4.4_$(date +"%Y-%m-%d").zip" * >/dev/null
		cd $curdir
	fi

else 
	LANG=en_US make $mkJop $mkForce $mod $KERNELOPT
	if [ $kernelzip -eq 0 ]; then
		[ -d out/target/product/$device/kernel_zip/rls/system/lib/modules ] || mkdir -p out/target/product/$device/kernel_zip/rls/system/lib/modules/
		[ -d out/target/product/$device/kernel_zip/rls/system/etc/kexec ] || mkdir -p out/target/product/$device/kernel_zip/rls/system/etc/kexec/
		[ -d out/target/product/$device/kernel_zip/rls/META-INF/com/google/android/ ] || mkdir -p out/target/product/$device/kernel_zip/rls/META-INF/com/google/android/ 
		cp .myfiles/scripts/kernel_zip/* out/target/product/$device/kernel_zip/rls/META-INF/com/google/android/
		cp -r out/target/product/$device/system/lib/modules/* out/target/product/$device/kernel_zip/rls/system/lib/modules/
		cp out/target/product/$device/kernel out/target/product/$device/kernel_zip/rls/system/etc/kexec/
		curdir=`pwd`
		cd out/target/product/$device/kernel_zip/rls/
		zip -r "../Kernel-$device-4.4_$(date +"%Y-%m-%d").zip" * >/dev/null
		cd $curdir
	fi
fi

[ $keepPatch -eq 0 ] || $rdir/.myfiles/patch.sh -r 


rm -f out/target/product/$device/cm_$device-ota-*.zip
rm -f out/target/product/$device/cm-*.zip.md5sum
