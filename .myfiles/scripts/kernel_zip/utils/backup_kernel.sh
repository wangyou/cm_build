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

mkdir -p /tmp/kernel_backup/system/lib/modules
mkdir -p /tmp/kernel_backup/system/etc/kexec
list_kfiles | while read FILE; do
	cp -rf /system/$FILE /tmp/kernel_backup/system/`dirname $FILE`
done

curdir=`pwd`
cd /tmp/kernel_backup
KernelZip=KernelBackup_$(date +"%Y%m%d_%H%M").zip 
rm -f $KernelZip
find  | sed -e "s:^./::g" | while read FILE; do
    if [ $FILE != "." -a  $FILE != ".." -a ! -d $FILE ]; then
        /tmp/minizip -a $KernelZip $FILE
    fi
done
cd $curdir
