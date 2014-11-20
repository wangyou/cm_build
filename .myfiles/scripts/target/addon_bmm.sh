#!/sbin/sh
# 
# /system/addon.d/50-cm.sh
# During a CM11 upgrade, this script backs up /system/etc/hosts,
# /system is formatted and reinstalled, then the file is restored.
#

. /tmp/backuptool.functions

list_files() {
cat <<EOF
bin/battd
bin/battd.bak
bin/logwrapper
bin/logwrapper.bin
etc/bmm/conf/bootmenu.prop
etc/bmm/conf/charge.rc
etc/bmm/conf/recovery.fstab
etc/bmm/conf/recovery.keys
etc/bmm/conf/recovery.rc
EOF
}

check_bmm(){
    ICS_LOGWRAPPER_SHA1=4a63fec78956def045b442910a754fa640db8f5a
    BMM_LOGWRAPPER_SHA1=f73feb83c768efd634e67fd074d64e3615eb5fda
    ICS_LOGWRAPPER=/system/bin/logwrapper.bin
    BMM_LOGWRAPPER=/system/bin/logwrapper
    BMM_INSTALL=/system/etc/bmm/sbin

    if [ -x "$ICS_LOGWRAPPER" ]; then
    if [ -x "$BMM_LOGWRAPPER" ]; then
    if [ -d "$BMM_INSTALL" ]; then
        BKP_ICS_LOGWRAPPER_SHA1=$(sha1sum $ICS_LOGWRAPPER | awk '{ print $1 }')
        BKP_BMM_LOGWRAPPER_SHA1=$(sha1sum $BMM_LOGWRAPPER | awk '{ print $1 }')
        if [ "$BKP_ICS_LOGWRAPPER_SHA1" == "$ICS_LOGWRAPPER_SHA1" ]; then
	    if [ "$BKP_BMM_LOGWRAPPER_SHA1" == "$BMM_LOGWRAPPER_SHA1" ]; then
		echo "BMM check : OK!"
	        return 0
	    fi
	fi
    fi
    fi
    fi
    return 1
}

case "$1" in
  backup)
    if check_bmm; then
        list_files | while read FILE DUMMY; do
            backup_file $S/"$FILE"
        done
    fi
  ;;
  restore)
    list_files | while read FILE REPLACEMENT; do
      R=""
      [ -n "$REPLACEMENT" ] && R="$S/$REPLACEMENT"
      [ -f "$C/$S/$FILE" ] && restore_file $S/"$FILE" "$R"
    done
  ;;
  pre-backup)
    # Stub
  ;;
  post-backup)
    # Stub
  ;;
  pre-restore)
    # Stub
  ;;
  post-restore)
    # Stub
  ;;
esac
