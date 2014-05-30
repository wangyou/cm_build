#!/system/bin/sh

## switch package manager to updateonly or not.

updateonly=`getprop android.pm.updateonly`
if [ "$updateonly" = "" -o "$updateonly" = "0" ]; then
   setprop android.pm.updateonly 1
   echo "PackageMananger in UpdateOnly mode now."
else
   setprop android.pm.updateonly 0
   echo "PackageMananger in Normal mode now."
fi

exit 0
