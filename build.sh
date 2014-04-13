reset
compile_user=NX111
branch=cm-11.0

KernelBranches=("cm-11.0" "JBX" "JBX_4.4" "JBX_30X" "cm-11.0" "test")
KernelOpts=("cm" "jbx" "j44" "j30x" "jordan" "jtest")

isKernelOpt()
{
    [ $# -lt 1 ] && return 1
    for((i=0;i<${#KernelOpts[@]};i++)) do
        if [ "${KernelOpts[$i]}" = "$1" ]; then
            return 0
        fi
    done
    return 1
}
#############################################################

list_kfiles()
{
cat <<EOF
etc/kexec/kernel
lib/modules/*
EOF
}

prepare_kernelzip()
{
	rm -rf $basedir/out/target/product/$device/kernel_zip/rls/*
	mkdir -p $basedir/out/target/product/$device/kernel_zip/rls/system/lib/modules/
	mkdir -p $basedir/out/target/product/$device/kernel_zip/rls/system/etc/kexec/
	mkdir -p $basedir/out/target/product/$device/kernel_zip/rls/system/etc/init.d/
	cp -r $basedir/.myfiles/scripts/kernel_zip/META-INF $basedir/out/target/product/$device/kernel_zip/rls/
	cp -r $basedir/.myfiles/scripts/kernel_zip/utils $basedir/out/target/product/$device/kernel_zip/rls/
	list_kfiles | while read FILE; do
		cp -r $basedir/out/target/product/$device/system/$FILE $basedir/out/target/product/$device/kernel_zip/rls/system/`dirname $FILE`
	done

}

##############################################################
getKernelBranchName()
{
	[ "$1" = "" ] && return 
	i=0
        for e in ${KernelOpts[@]}; do
		if [ "$e" = "$1" -a "$e" != "" ]; then
			echo  ${KernelBranches[$i]}
			return
		fi
		i=$((i+1))
	done
	return 1
}


#############################################################

ScriptName=`basename $0`
rdir=`dirname $0`
[ "$rdir" != "." ] && cd $rdir
basedir=`pwd`
rm -f .lastBuild.tmp

KERNELOPT=""
device=edison
opKernel="cm"
mkJop=""
mod=bacon
mkForce=""
oldupdate="old"
keepPatch=1
kernelzip=1
kernelonly=1
moreopt=""
nomake=1

lastDevice="edison"
lastOpKernel=""
if [ -f .lastBuild ]; then
   lastDevice=`grep device: .lastBuild|cut -d: -f2|sed -e "s/^ //g" -e "s/ $//g"`
   lastOpKernel=`grep opKernel: .lastBuild|cut -d: -f2|sed -e "s/^ //g" -e "s/ $//g"`
   for((i=0;i<${#KernelBranches[@]};i++)) do
	elemI=${KernelBranches[$i]}
	[ "${KernelOpts[$i]}" = "jordan" ] && elemI="JORDAN"
        for((j=0;j<$i;j++)) do
		elemJ=${KernelBranches[$j]}
		[ "${KernelOpts[$j]}" = "jordan" ] && elemJ="JORDAN"
		[ "$elemI" = "$elemJ" ] && break
	done
	if [ $j -lt $i ]; then
		continue
	fi
	kbccount=`echo $elemI | sed -e "s/[\._-]//g"`_CCNUM
	tempvalue=`grep ${kbccount}: .lastBuild|cut -d: -f2|sed -e "s/^ //g" -e "s/ $//g"`
	if [ ! -z "$tempvalue" ]; then
		eval $"$kbccount"=$tempvalue
	fi
   done
   [ -z $lastOpKernel ] && lastOpKernel="cm"
fi

for op in $*;do
   transop=0
   if [ "$op" = "spyder" -o "$op" = "edison" -o "$device" = "targa" ]; then
	device="$op"
   elif [ "$op" = "jordan" -o "$op" = "mb526" ]; then
	device="mb526"
	KERNELOPT="TARGET_KERNEL_SOURCE=kernel/motorola/mb526"
	rm -rf $basedir/vendor/motorola/jordan-common
	[ -d  $basedir/vendor/moto/jordan-common ] && cp -r $basedir/vendor/moto/jordan-common $basedir/vendor/motorola/jordan-common
   elif isKernelOpt $op; then
	opKernel="$op"
	transop=1
   elif [ "${op:0:2}" = "-j" ]; then
	mkJop=$op
	transop=1
   elif [ "${op}" = "-kernel-zip" ]; then
	kernelzip=0
	transop=1
   elif [ "$op" = "-kernel" ]; then
	kernelonly=0
   elif [ "${op}" = "-k" ]; then
	keepPatch=0
   elif [ "$op" = "-nomake" ]; then
        nomake=0
	transop=1
   elif [ "$op" = "-B" ]; then
	mkForce=$op
	transop=1
   elif [ "$op" = "-cleanall" -o "$op" = "-init" -o "$op" = "-sync"  ]; then
	mode="${op#-*}"
	transop=1
   elif [ "${op:0:4}" = "mod=" ]; then
	mod="${op#mod=*}"
	transop=1
   elif [ "$op" = "new" -o "$op" = "old" ]; then
	oldupdate="$op"
	transop=1
   fi
   [ $transop -eq 0 ] && moreopt="$moreopt $op"
done

[ "$device" = "mb526" ] && opKernel="cm"

if [ "$mode" = "cleanall" ]; then
    for f in * .*; do
	[ "$f" != "$ScriptName" -a "$f" != ".myfiles" -a "$f" != ".git" -a "$f" != ".gitignore" -a "$f" != ".repo" ] \
	   && [ "$f" != "." -a "$f" != ".." ] && rm -rf $f
    done
   exit 0
fi

if [ ! -f build/envsetup.sh -o "$mode" = "init" ]; then
	repo init -u git://github.com/CyanogenMod/android.git -b $branch
	repo sync
	repo start $branch --all
	exit 0
fi

if [ "$mode" = "sync" ]; then
    if [ -d  kernel/motorola/omap4-common ]; then
        cd kernel/motorola/omap4-common
        kbranch=`git branch | grep "\*" |cut -f2 -d" "`
        sed -e "s:\(<project.*kernel/motorola/omap4-common.*revision=\).*\(/>\):\1\"$kbranch\"\2:" \
            -i $basedir/.repo/local_manifests/local_manifest.xml
        cd $basedir
    fi
    while true 
    do 
	if repo sync; then
		for kop in ${KernelOpts[@]}; do 
			.myfiles/patch.sh $device -kbranch  $kop -kuo
 		done
		echo "sync successed!"
		break
		exit 0
	fi
    done
    exit 0
fi

echo "Starting ............."
if [ $nomake -ne 0 -o "$device" != "$lastDevice" ]; then
	export USE_CCACHE=1
	source build/envsetup.sh > /dev/null
   	lunch cm_$device-userdebug >/dev/null
fi

[ ! -f vendor/cm/proprietary/Term.apk ] && vendor/cm/get-prebuilts
cm_version=`grep "^\s*<default revision=\"refs/heads/cm-" .repo/manifest.xml  | sed -e "s/^\s*<default revision=\"refs\/heads\/\(cm-.*\)\"/\1/"`

if [ "${opKernel:0:1}" = "j" ]; then
    export kernel_config=mapphone_OCE_defconfig
    if [ "$device" = "edison" ]; then
	export kernel_config=mapphone_OCEdison_defconfig
    elif [ "$device" = "targa" ]; then
	export kernel_config=mapphone_OCETarga_defconfig
    elif [ "$device" != "mb526" ]; then
	export kernel_config=mapphone_OCE_defconfig
    fi
fi

if [ $nomake -ne 0 -o "$device" != "$lastDevice" ]; then
   .myfiles/patch.sh $device $moreopt $opKernel
   echo "device: $device">.lastBuild.tmp
   echo "opKernel: $opKernel">>.lastBuild.tmp

    ######generate projects's last 10 logs########
    if [ $kernelonly -eq 1 ]; then
    	echo "Generating projects's snapshot logs..."
    	PROJECTLIST=$rdir/.repo/project.list
   	 OUTLOG=$basedir/out/target/product/$device/system/etc/SNAPSHOT.txt
    	[ -d $basedir/out/target/product/$device/system/etc/ ] || mkdir -p $basedir/out/target/product/$device/system/etc/
    	rm -f $OUTLOG
    	touch $OUTLOG
    	while read project
   	do
		cd $basedir/$project
		echo $project: >>$OUTLOG
		git log -10 --pretty=format:'    %h  %ad  %s' --date=short >>$OUTLOG
		echo -e "\n">>$OUTLOG
    	done < $PROJECTLIST
    	cd $basedir

    	########Delete old files#############################
    	if [ -d out/target/product/$device/obj/PACKAGING/target_files_intermediates ]; then
       		cd out/target/product/$device/obj/PACKAGING/target_files_intermediates
       		ls -t  | awk '{if(NR>2){print $0}}' | xargs rm -rf 
       		cd $basedir
    	fi
    	if [ -d out/target/product/$device/ ]; then
       		cd out/target/product/$device
       		ls -t cm-*.zip 2>/dev/null | awk '{if(NR>4){print $0}}' |xargs rm -rf 
       		cd $basedir
    	fi
    	rm -f out/target/product/$device/system/build.prop
    fi
    [ _"$opKernel" != _"$lastOpKernel" ] && rm -rf out/target/product/$device/obj/KERNEL_OBJ/*
    [ -d $basedir/out/target/product/$device/obj/KERNEL_OBJ ] || mkdir -p $basedir/out/target/product/$device/obj/KERNEL_OBJ

fi

########## MAKE #########################
export CM_BUILDTYPE=NIGHTLY
export CM_EXTRAVERSION=NX111

if [ "${opKernel:0:1}" = "j" -a "$device" != "mb526" ]; then
	KERNEL_BRANCH_SHORTNAME=`getKernelBranchName $opKernel|sed -e "s/[_-\.]//g"`
	[ "$opKernel" = "jbx" ] && KERNEL_BRANCH_SHORTNAME="JBX"
   	export CM_EXTRAVERSION=${CM_EXTRAVERSION}_${KERNEL_BRANCH_SHORTNAME}
fi

[ "$device" != "mb526" ] && KBCCOUNT=`getKernelBranchName $opKernel|sed -e "s/[_-\.]//g"`_CCNUM
[ "$device" != "mb526" ] || KBCCOUNT=JORDAN_CCNUM
[ -z "${!KBCCOUNT}" ] && eval $"$KBCCOUNT"=0

retcode=1
[ $kernelonly -eq 0 ] && mod=$OUT/boot.img
if [ "${opKernel:0:1}" = "j" -a "$device" != "mb526" ]; then

	export BOARD_HAS_SDCARD_INTERNAL=false

        if [ $nomake -ne 0 -o "$device" != "$lastDevice" ]; then
            [ ! -z "${!KBCCOUNT}" ] &&  echo ${!KBCCOUNT} > $basedir/out/target/product/$device/obj/KERNEL_OBJ/.version
	    LANG=en_US make $mod $mkJop $mkForce TARGET_BOOTLOADER_BOARD_NAME=$device \
  		        TARGET_KERNEL_CONFIG=${kernel_config}  
        fi
	retcode=$?
	if [ $retcode -eq 0 -a $kernelzip -eq 0 ]; then
		prepare_kernelzip
		[ -f $basedir/out/target/product/$device/system/etc/init.d/80GPU -a "$device" = "edison" ] && \
		cp $basedir/out/target/product/$device/system/etc/init.d/80GPU $basedir/out/target/product/$device/kernel_zip/rls/system/etc/init.d/
		curdir=`pwd`
		cd out/target/product/$device/kernel_zip/rls/
		rm -f "../Kernel-${KERNEL_BRANCH_SHORTNAME}-$device-4.4_$(date +"%Y%m%d").zip"
		zip -r "../Kernel-${KERNEL_BRANCH_SHORTNAME}-$device-4.4_$(date +"%Y%m%d").zip" * >/dev/null
		cd $curdir
	fi

elif [ "$opKernel" = "cm" ]; then
        if [ $nomake -ne 0 -o "$device" != "$lastDevice" ]; then
            [ ! -z "${!KBCCOUNT}" ] && echo ${!KBCCOUNT} > $basedir/out/target/product/$device/obj/KERNEL_OBJ/.version
	    LANG=en_US make $mkJop $mkForce $mod $KERNELOPT
        fi
	retcode=$?
	if [ $retcode -eq 0 -a $kernelzip -eq 0 ]; then
		prepare_kernelzip
		curdir=`pwd`
		cd out/target/product/$device/kernel_zip/rls/
		rm -f "../Kernel-CM11-$device-$(date +"%Y%m%d").zip"
		zip -r "../Kernel-CM11-$device-$(date +"%Y%m%d").zip" * >/dev/null
		cd $curdir
	fi

fi

if [ $nomake -ne 0 -o "$device" != "$lastDevice" ]; then
   [ $keepPatch -eq 0 ] || $rdir/.myfiles/patch.sh -r 

   eval $"$KBCCOUNT"=`cat $basedir/out/target/product/$device/obj/KERNEL_OBJ/.version`

   for((i=0;i<${#KernelBranches[@]};i++)) do
	elemI=${KernelBranches[$i]}
	[ "${KernelOpts[$i]}" = "jordan" ] && elemI="JORDAN"
        for((j=0;j<$i;j++)) do
		elemJ=${KernelBranches[$j]}
		[ "${KernelOpts[$j]}" = "jordan" ] && elemJ="JORDAN"
		[ "$elemI" = "$elemJ" ] && break
	done
	if [ $j -lt $i ]; then
		continue
	fi
	kbccount=`echo $elemI | sed -e "s/[\._-]//g"`_CCNUM
	tempvalue=${!kbccount}
	if [ ! -z "$tempvalue" -a "$tempvalue" != "0" ]; then
		echo ${kbccount}:$tempvalue >> .lastBuild.tmp
	fi
   done
   mv .lastBuild.tmp .lastBuild
   rm -f out/target/product/$device/cm_$device-ota-*.zip
   rm -f out/target/product/$device/cm-*.zip.md5sum
   rm -f $basedir/out/target/product/$device/system/etc/init.d/80GPU
fi
exit $retcode
