#!/system/bin/sh

## switch package manager to read-only or not.

if [ -f /data/property/android.pm.readonly ]; then
    rm -f /data/property/android.pm.readonly
else
   touch /data/property/android.pm.readonly
 fi

if [ ! -f /data/property/android.pm.readonly ]; then
    echo "PackageMananger in Normal mode now."
else
   echo "PackageMananger in ReadOnly mode now."
fi

exit 0
