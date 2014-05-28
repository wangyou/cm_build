reset
compile_user=NX111
branch=cm-11.0

KernelBranches=("cm-11.0" "JBX" "JBX_30X" "cm-11.0" "cm-11.0")
KernelOpts=("cm" "jbx" "j30x" "jordan" "n880e")

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
lib/libc.so
lib/libstdc++.so
lib/libdl.so
lib/libm.so
EOF
}

prepare_kernelzip()
{
	rm -rf $basedir/out/target/product/$device/kernel_zip/rls/*
	mkdir -p $basedir/out/target/product/$device/kernel_zip/rls/system/lib/modules/
	mkdir -p $basedir/out/target/product/$device/kernel_zip/rls/system/etc/kexec/
	mkdir -p $basedir/out/target/product/$device/kernel_zip/rls/system/etc/init.d/
	cp -r $basedir/.myfiles/scripts/kernel_zip/META-INF $basedir/out/target/product/$device/kernel_zip/rls/
        if [ "$device" = "n880e" -o "$device" = "atlas4" ]; then
            mv $basedir/out/target/product/$device/kernel_zip/rls/META-INF/com/google/android/updater-script.atlas40 \
               $basedir/out/target/product/$device/kernel_zip/rls/META-INF/com/google/android/updater-script
            cp $basedir/out/target/product/$device/boot.img $basedir/out/target/product/$device/kernel_zip/rls/
        else
            rm $basedir/out/target/product/$device/kernel_zip/rls/META-INF/com/google/android/updater-script.atlas40
        fi
	cp -r $basedir/.myfiles/scripts/kernel_zip/utils $basedir/out/target/product/$device/kernel_zip/rls/
	list_kfiles | while read FILE; do
		if echo $FILE | grep -q "kernel"; then
			cp -f $basedir/out/target/product/$device/kernel $basedir/out/target/product/$device/kernel_zip/rls/system/`dirname $FILE`
		else
			cp -rf $basedir/out/target/product/$device/system/$FILE $basedir/out/target/product/$device/kernel_zip/rls/system/`dirname $FILE`
		fi
	done

}

##############################################################
getKernelBranchName()
{
	i=0
     if [ "$1" != "" -a "$KernelBranchName" != "" ]; then
         for e in ${KernelOpts[@]}; do
		    if [ "$e" = "$1" -a "$e" != "" ]; then
                   KernelBranchName=${KernelBranches[$i]}
			    break
		    fi
		    i=$((i+1))
	    done
     fi
	echo  $KernelBranchName
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
kernelBranchOptionStart=1
KernelBranchName=$branch
jbx=1
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
	[ "${KernelOpts[$i]}" = "n880e" ] && elemI="N880E"
        for((j=0;j<$i;j++)) do
		elemJ=${KernelBranches[$j]}
		[ "${KernelOpts[$j]}" = "jordan" ] && elemJ="JORDAN"
		[ "${KernelOpts[$j]}" = "n880e" ] && elemJ="N880E"
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
   if [ $kernelBranchOptionStart -eq 0 ]; then
      KernelBranchName=$op
      kernelBranchOptionStart=1
      opKernel=${device}_${KernelBranchName}
   elif [ "$op" = "spyder" -o "$op" = "edison" -o "$op" = "targa" -o "$op" = "n880e" ]; then
	device="$op"
   elif [ "$op" = "jordan" -o "$op" = "mb526" ]; then
	device="mb526"
	KERNELOPT="TARGET_KERNEL_SOURCE=kernel/motorola/mb526"
	rm -rf $basedir/vendor/motorola/jordan-common
	[ -d  $basedir/vendor/moto/jordan-common ] && cp -r $basedir/vendor/moto/jordan-common $basedir/vendor/motorola/jordan-common
   elif isKernelOpt $op; then
	opKernel="$op"
	[ "$op" = "n880e" ] && device="n880e"
	transop=1
   elif [ "$op" = "-jbx" ]; then
      jbx=0
   elif [ "${op:0:2}" = "-j" ]; then
	mkJop=$op
	transop=1
   elif [ "${op}" = "-kernel-zip" -o "${op}" = "-kz" ]; then
	kernelzip=0
	transop=1
   elif [ "$op" = "-kernel-only" -o "$op" = "-ko" ]; then
	kernelonly=0
     transop=1
   elif [ "$op" = "-kernel-branch" -o "$op" = "-kb" ]; then
     kernelBranchOptionStart=0
     transop=0
   elif [ "${op}" = "-keep" ]; then
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

[ "$device" = "mb526" -o "$device" = "n880e" ] && opKernel="cm"
[ $kernelonly -eq 0 ] && kernelzip=0

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
    while true 
    do 
	if repo sync; then
		for kop in ${KernelOpts[@]}; do 
			.myfiles/patch.sh $device -kbranch  $kop -ku
 		done
		echo "sync successed!"
		break
		exit 0
	fi
    done
    exit 0
fi

echo "Start compiling for ${device^^} ............."
if [ $nomake -ne 0 -o "$device" != "$lastDevice" ]; then
	export USE_CCACHE=1
	source build/envsetup.sh > /dev/null
   	lunch cm_$device-userdebug > /dev/null
fi
#if [ "$device" != "$lastDevice" -o "$opKernel" != "$lastOpKernel" ]; then
#	export USE_CCACHE=
#	rm -rf ~/.ccache
#fi

cm_version=`grep "^\s*<default revision=\"refs/heads/cm-" .repo/manifest.xml  | sed -e "s/^\s*<default revision=\"refs\/heads\/\(cm-.*\)\"/\1/"`

if [ "${opKernel:0:1}" = "j" ]; then
    jbx=0
    kernel_config=mapphone_OCE_defconfig
    if [ "$device" = "edison" ]; then
	kernel_config=mapphone_OCEdison_defconfig
    elif [ "$device" = "targa" ]; then
	kernel_config=mapphone_OCETarga_defconfig
    elif [ "$device" != "mb526" ]; then
	kernel_config=mapphone_OCE_defconfig
    fi
else
	kernel_config=mapphone_mmi_defconfig
fi

if [ $nomake -ne 0 -o "$device" != "$lastDevice" ]; then
   if ! $basedir/.myfiles/patch.sh $device $moreopt $opKernel; then
        $basedir/.myfiles/patch.sh -r
        echo "Error happended...exit!"
        exit -1
   fi   
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

if [ ! -f vendor/cm/proprietary/Term.apk ]; then
   if  [ -f $basedir/.myfiles/Term.apk ]; then
        mkdir -p $basedir/vendor/cm/proprietary
        cp $basedir/.myfiles/Term.apk $basedir/vendor/cm/proprietary/
        unzip -o -d $basedir/vendor/cm/proprietary $basedir/vendor/cm/proprietary/Term.apk lib/* >/dev/null
   else
        vendor/cm/get-prebuilts
   fi
fi

########## MAKE #########################
export CM_BUILDTYPE=NIGHTLY
export CM_EXTRAVERSION=NX111

if [ ! -f $basedir/Makefile ]; then
    echo "include build/core/main.mk" > $basedir/Makefile
elif ! grep -q "build/core/main.mk" $basedir/Makefile; then
    mv $basedir/Makefile $basedir/Makefile.bak
    echo "include build/core/main.mk" > $basedir/Makefile
fi

if [ $jbx -eq 0 -a "$device" != "mb526" -a "$device" != "n880e" ]; then
	KERNEL_BRANCH_SHORTNAME=`getKernelBranchName $opKernel|sed -e "s/[_-\.]//g"`
	[ "$opKernel" = "jbx" ] && KERNEL_BRANCH_SHORTNAME="JBX"
   	export CM_EXTRAVERSION=${CM_EXTRAVERSION}_${KERNEL_BRANCH_SHORTNAME}
fi

[ "$device" != "mb526" -a "$device" != "n880e" ] && KBCCOUNT=`getKernelBranchName $opKernel|sed -e "s/[_-\.]//g"`_CCNUM
[ "$device" = "mb526" ] && KBCCOUNT=JORDAN_CCNUM
[ "$device" = "n880e" ] && KBCCOUNT=N880E_CCNUM
[ -z "${!KBCCOUNT}" ] && eval $"$KBCCOUNT"=0

retcode=1
if [ $kernelonly -eq 0 ]; then
	mod=$OUT/boot.img
fi

#do or not make realy, for debug
if [ 1 -eq 1 ]; then   

#realy make
if [ "${opKernel:0:1}" = "j" -a "$device" != "mb526" -a "$device" != "n880e" ]; then

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
        KERNELZIP_NAME=Kernel-${KERNEL_BRANCH_SHORTNAME}-$device-4.4_$(date +"%Y%m%d").zip
        echo "Creating ${KERNELZIP_NAME}..."
		rm -f "../${KERNELZIP_NAME}"
		zip -r "../${KERNELZIP_NAME}" * >/dev/null
		cd $curdir
	fi

else
        if [ $nomake -ne 0 -o "$device" != "$lastDevice" ]; then
            [ ! -z "${!KBCCOUNT}" ] && echo ${!KBCCOUNT} > $basedir/out/target/product/$device/obj/KERNEL_OBJ/.version
	    LANG=en_US make $mkJop $mkForce $mod $KERNELOPT
        fi
	retcode=$?
	if [ $retcode -eq 0 -a $kernelzip -eq 0 ]; then
		prepare_kernelzip
		curdir=`pwd`
		cd out/target/product/$device/kernel_zip/rls/
        KERNELZIP_NAME=Kernel-CM11-$device-$(date +"%Y%m%d").zip
        echo "Creating ${KERNELZIP_NAME}..."
		rm -f "../${KERNELZIP_NAME}"
		zip -r "../${KERNELZIP_NAME}" * >/dev/null
		cd $curdir
	fi

fi

fi

export TARGET_KERNEL_CUSTOM_TOOLCHAIN=

if [ $nomake -ne 0 -o "$device" != "$lastDevice" ]; then
   [ $keepPatch -eq 0  -o $retcode -ne 0 ] || $rdir/.myfiles/patch.sh -r 

   eval $"$KBCCOUNT"=`cat $basedir/out/target/product/$device/obj/KERNEL_OBJ/.version`

   for((i=0;i<${#KernelBranches[@]};i++)) do
	elemI=${KernelBranches[$i]}
	[ "${KernelOpts[$i]}" = "jordan" ] && elemI="JORDAN"
	[ "${KernelOpts[$i]}" = "n880e" ] && elemI="N880E"

        for((j=0;j<$i;j++)) do
		elemJ=${KernelBranches[$j]}
		[ "${KernelOpts[$j]}" = "jordan" ] && elemJ="JORDAN"
		[ "${KernelOpts[$j]}" = "n880e" ] && elemJ="N880E"
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
