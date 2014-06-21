curdir=`pwd`
basedir=$(dirname $(dirname $(dirname $0)))
dst=`pwd`
if [ $# -lt 1 ]; then
   echo " usage: $0 <source_zipfile> [dest_dir]"
   exit 0
elif [ ! -f $1 ]; then
   echo " File: $1 not exist! exit. "
   exit -1
elif [ $# -eq 2 ]; then
   if [ ! -d $2 ]; then
   	echo "Directory $2 not exists! exit."
   	exit -1
   else
        dst=$2
   fi
fi
outfile=`basename $1| sed -e "s/pa_gapps/gapps/" -e "s/-modular//" -e "s/-full//" `

edir=`mktemp -d /tmp/gapps_XXXXXX`
echo "Unpacking << $1..."
unzip $1 -d $edir >/dev/null

sed -e "/^[[:space:]]*\"\/system\/app\/Calendar\.apk\"[[:space:]]*,\{0,1\}[[:space:]]*/d" \
    -e "s/\"[^\"]*Calendar\.apk\",?//g" \
    -e "/^[[:space:]]*\"[^\"\/]*\/Trebuchet\.apk\"[[:space:]]*,\{0,1\}[[:space:]]*/d" \
    -e "s/\"[^\"]*Trebuchet\.apk\",?//g" \
    -e "s/PA GApps.*Modular/GApps/g" \
    -i $edir/META-INF/com/google/android/updater-script
for f in $edir/system/addon.d/*; do
	sed -i $f \
	    -e "/rm -f \/system\/app\/Calendar\.apk/d" \
	    -e "/rm -f \/system\/.*Trebuchet\.apk/d" \
         -e "/^priv-app\/SetupWizard\.apk$/d"
done

[ -f $edir/delete-list.txt ] &&
	sed -e "/\/system\/app\/Calendar\.apk/d" -i $edir/delete-list.txt

[ -f $edir/gapps-list.txt ] &&
	sed -e "/\/system\\app\\PlayGames\.apk/d" \
	    -e "/\/system\\app\\Books\.apk/d" \
	    -e "/\/system\\app\\Magazines\.apk/d" \
            -e "/\/system\\priv-app\\SetupWizard\.apk/d" \
	    -i $edir/gapps-list.txt


#rm -f $edir/system/app/GoogleHome.apk
#rm -f $edir/system/app/GoogleCalendar.apk
rm -f $edir/system/app/PlayGames.apk
rm -f $edir/system/app/Books.apk
rm -f $edir/system/app/Magazines.apk
#rm -f $edir/system/app/CalendarGoogle.apk
rm -f $edir/system/priv-app/SetupWizard.apk

if [ -f $edir/system/etc/g.prop ]; then
	gapps_size=`du -s $edir/system|cut -f1`
	sed -e "s/\(ro.addon.pa_size=\).*/\1$gapps_size/" -i $edir/system/etc/g.prop
fi

cd $edir
echo "Repacking >> $dst/$outfile..."
zip $dst/$outfile -r * >/dev/null

##signed package
certdir=$basedir/build/target/product/security
if [ -f "$(which java)" -a -f $certdir/testkey.x509.pem -a  -f $certdir/testkey.pk8 -a -f $basedir/prebuilts/sdk/tools/lib/signapk.jar ]; then
	echo "Signing $outputfile..."
	java -jar $basedir/prebuilts/sdk/tools/lib/signapk.jar ${certdir}/testkey.x509.pem ${certdir}/testkey.pk8 $dst/$outfile  $dst/$outfile.signed
	[ $? -eq 0 ] && mv $dst/$outfile.signed $dst/$outfile
fi
cd $curdir
rm -rf $edir
