#!/bin/bash
#
# Squish a CM otapackage for distribution
# cyanogen
#

CL_RED="\033[31m"
CL_GRN="\033[32m"
CL_YLW="\033[33m"
CL_BLU="\033[34m"
CL_MAG="\033[35m"
CL_CYN="\033[36m"
CL_RST="\033[0m"

OUT_TARGET_HOST=`uname -s`
if [ x"$OUT_TARGET_HOST" != x"Linux" -a x"$OUT_TARGET_HOST" != x"Darwin" ]; then
    echo -e $CL_RED"ERROR: unknown/unsupported host OS!"$CL_RST
    exit 1
fi

if [ -z "$OUT" -o ! -d "$OUT" ]; then
    echo -e $CL_RED"ERROR: $0 only works with a full build environment. $OUT should exist."$CL_RST
    exit 1
fi

UIET=-q
###################################################################
#  remove unnecessary file

echo "Extra: Remove unnecessary files ...."

DELETE_BINS="applypatch applypatch_static check_prereq recovery updater"

# Delete unnecessary binaries
( cd "$OUT"/system/bin; echo $DELETE_BINS | xargs rm -f; )

# We should fix the build to stop this from being installed in the first place
rm -rf "$OUT"/system/extras

# Delete files defined in custom squisher extras list
VENDOR=$(cat "$OUT"/system/build.prop | grep 'ro.product.brand=' | tr '[:upper:]' '[:lower:]' | sed 's/ro.product.brand=//')
DEVICE=$(cat "$OUT"/system/build.prop | grep 'ro.build.product=' | tr '[:upper:]' '[:lower:]' | sed 's/ro.build.product=//')
SQUISHER_EXTRAS_FILE="$ANDROID_BUILD_TOP/device/$VENDOR/$DEVICE/squisher-extras.txt"
if [ -f "$SQUISHER_EXTRAS_FILE" ]; then
    for FILE in `cat "$SQUISHER_EXTRAS_FILE" | grep -v "^ *#" | grep -v "^ *$"`; do
        EXTRAS="$EXTRAS $FILE"
    done
    ( cd "$OUT"/system; echo $EXTRAS | xargs rm -rf; )
fi

####################################################################
###  copy file to $OUT

COPY_EXTRAS_FILE="$ANDROID_BUILD_TOP/device/$VENDOR/$DEVICE/copy-extras.txt"
if [ -f "$COPY_EXTRAS_FILE" ]; then
    echo "Extra: copy extra files to target system directory..."
    for LINE in `cat "$COPY_EXTRAS_FILE" | grep -v "^ *#" | grep -v "^ *$"`; do
	   SOURCEFILE=`echo $LINE | cut -f 1 -d:`
	   DESTFILE=`echo $LINE | cut -f 2 -d:`
 	   [ "$SOURCEFILE" = "" -o "$DESTFILE" = "" ] && continue
	   [ ! -f "$ANDROID_BUILD_TOP/$SOURCEFILE" ] && continue
	   cp $ANDROID_BUILD_TOP/$SOURCEFILE $OUT/$DESTFILE
    done

fi

#######################################################################
##  cut LatinIME
list_keepdict(){
cat <<EOF
main.dict
empty.dict
main_en.dict
main_de.dict
main_fr.dict
main_it.dict
main_es.dict
main_pt_br.dict
EOF
}
curdir=`pwd`
if [ -f $OUT/system/app/LatinIME.apk ]; then
    echo "LatinIME: cutting some dictionaries..."
    rm -rf $OUT/obj/APPS/LatinIME_intermediates/unpacked_files/*
    rm -f $OUT/obj/APPS/LatinIME_intermediates/LatinIME.apk
    unzip $OUT/system/app/LatinIME.apk -d $OUT/obj/APPS/LatinIME_intermediates/unpacked_files >/dev/null 2>/dev/null
    for f in $(find $OUT/obj/APPS/LatinIME_intermediates/unpacked_files/res/raw -name *.dict); do
	dict=`basename "$f"`
	if ! (list_keepdict|grep -q $dict); then
	    rm -rf $f
        fi
    done
    rm -f $OUT/obj/APPS/LatinIME_intermediates/LatinIME.apk.unsigned
    cd $OUT/obj/APPS/LatinIME_intermediates/unpacked_files
    ### res/raw/* could not be compressed
    zip -0 $OUT/obj/APPS/LatinIME_intermediates/LatinIME.apk.unsigned -r res/raw >/dev/null 2>/dev/null
    zip -u $OUT/obj/APPS/LatinIME_intermediates/LatinIME.apk.unsigned -r * >/dev/null 2>/dev/null
    java -jar $ANDROID_BUILD_TOP/prebuilts/sdk/tools/lib/signapk.jar \
              $ANDROID_BUILD_TOP/build/target/product/security/shared.x509.pem \
              $ANDROID_BUILD_TOP/build/target/product/security/shared.pk8 \
              $OUT/obj/APPS/LatinIME_intermediates/LatinIME.apk.unsigned $OUT/obj/APPS/LatinIME_intermediates/LatinIME.apk
    if [ -f $OUT/obj/APPS/LatinIME_intermediates/LatinIME.apk ]; then
	mv $OUT/obj/APPS/LatinIME_intermediates/LatinIME.apk $OUT/system/app/LatinIME.apk
    fi
    rm -rf $OUT/obj/APPS/LatinIME_intermediates/unpacked_files
fi

exit 0
