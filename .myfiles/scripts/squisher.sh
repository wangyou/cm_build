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

exit 0
