curdir=`pwd`
basedir=$(dirname $(dirname $(dirname $0)))
mydir=$(dirname $0)
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

copy()
{
  [ $# -lt 2 ] && return 1
  local targetdir=$2
  local src=$1
  [ "${src: -1}" != "/" ] && targetdir=`dirname $2`
  [ _$targetdir = _  ] && targetdir="./"
  [ -d $targetdir ] || mkdir -p $targetdir
  cp -f $src $targetdir
  return 0
}

outfile=`basename $1| sed -e "s/pa_gapps/gapps/" -e "s/-modular//" -e "s/-full//" `
nameitemset=(`basename $1 | sed -e "s/-/ /g"`)
updatetime=""
version=""
for ((i=0; i<${#nameitemset[@]}; i++)); do
     if date -d ${nameitemset[$i]} > /dev/null 2>/dev/null; then
         updatetime=`date -d ${nameitemset[$i]} +%Y-%m-%d`
         version=${nameitemset[$i]}
         break
     fi 
done


edir=`mktemp -d /tmp/gapps_XXXXXX`
echo "Unpacking << $1..."
unzip -q $1 -d $edir >/dev/null 2>/dev/null

if [ `du -b $edir/META-INF/com/google/android/updater-script | cut -f1` -lt 5120 ]; then
   #gapp installer v2.0
   cp -r $mydir/gapps/* $edir/
   rm -rf $edir/META-INF/com/google/android/updater-script
   . $edir/installer.data

   sed -e "s/@@update_time@@/${updatetime}/g" -i $edir/inc/updater-script_1
   sed -e "s/@@version@@/${version}/g" -i $edir/inc/updater-script_1
   sed -e "s/@@req_android_version@@/${req_android_version}/g" -i $edir/inc/updater-script_1
   sed -e "s/@@installer_name@@/${installer_name}/g" -i $edir/inc/updater-script_1

   cat $edir/inc/updater-script_1 > $edir/META-INF/com/google/android/updater-script

   removefiles=($remove_list)
   for ((i=0;i<${#removefiles[@]}-1;i++)); do
       echo "    \"${removefiles[$i]}\"," >> $edir/META-INF/com/google/android/updater-script
   done
   echo "    \"${removefiles[$i]}\"" >> $edir/META-INF/com/google/android/updater-script
   echo "    );" >> $edir/META-INF/com/google/android/updater-script


    cat $edir/inc/updater-script_2 >> $edir/META-INF/com/google/android/updater-script

    [ -d $edir/system ] || mkdir $edir/system
    mv $edir/Core/required/* $edir/system/
    for f in `find $edir/GApps -mindepth 3`; do 
        targetApp=`echo $f |sed -e "s:$edir::" -e "s:[^/]*/[^/]*/[^/]*/::"`
         [ -d $f ] || copy  $f $edir/system/$targetApp
    done
    cp -rf $edir/GMSCore/common/* $edir/system/
    cp -rf $edir/GMSCore/0/* $edir/system/
    rm -f $edir/gapps-list.txt
    touch $edir/gapps-list.txt
    for f in `find $edir/system -type f`; do
         echo "$f" | sed -e "s:$edir::g" >> $edir/gapps-list.txt
    done
    [ ! -d $edir/system/addon.d ] && mkdir -p $edir/system/addon.d


    cat $edir/inc/addon-gapps_1 > $edir/system/addon.d/70-gapps.sh

    for f in `find $edir/system -type f`; do
         echo "$f" | sed -e "s:$edir/system/::g" >> $edir/system/addon.d/70-gapps.sh
    done

    cat $edir/inc/addon-gapps_2 >> $edir/system/addon.d/70-gapps.sh

    for ((i=0;i<${#removefiles[@]};i++)); do
        echo "    rm -rf ${removefiles[$i]}" >> $edir/system/addon.d/70-gapps.sh
    done

    cat $edir/inc/addon-gapps_3 >> $edir/system/addon.d/70-gapps.sh

    rm -rf $edir/GMSCore $edir/GApps $edir/Core
    rm -f $edir/installer.data $edir/bkup_tail.sh
    rm -rf $edir/inc

fi

   # gapp installer v1.0
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
javabin=$(which java)
[ "$javabin" = "" -a -f "$basedir/java" ] && javabin=$basedir/java
if [ -f "$javabin" -a -f $certdir/testkey.x509.pem -a  -f $certdir/testkey.pk8 -a -f $basedir/prebuilts/sdk/tools/lib/signapk.jar ]; then
	echo "Signing $outputfile..."
	$javabin -jar $basedir/prebuilts/sdk/tools/lib/signapk.jar ${certdir}/testkey.x509.pem ${certdir}/testkey.pk8 $dst/$outfile  $dst/$outfile.signed
	[ $? -eq 0 ] && mv $dst/$outfile.signed $dst/$outfile
fi
cd $curdir
rm -rf $edir
