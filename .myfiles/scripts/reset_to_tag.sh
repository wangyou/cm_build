#!/bin/sh
#set -x

getLastTag()
{
	local nmajor=0
	local nrevision=0
	local ntag=""
        local nextra=""
 	git tag > /tmp/gittagtmp.txt
        while read tag
        do
		prefix=$(echo $tag |  sed -e "s/\([[:alpha:]-]*\)\([[:digit:].]*\)_r\([[:digit:].]*\)\(.*\)/\1/g")
		echo $prefix | grep -q "android-" || continue
		major=$(echo $tag |  sed -e "s/\([[:alpha:]-]*\)\([[:digit:].]*\)_r\([[:digit:].]*\)\(.*\)/\2/g")
		revision=$(echo $tag |  sed -e "s/\([[:alpha:]-]*\)\([[:digit:].]*\)_r\([[:digit:].]*\)\(.*\)/\3/g")
		extra=$(echo $tag |  sed -e "s/\([[:alpha:]-]*\)\([[:digit:].]*\)_r\([[:digit:].]*\)\(.*\)/\4/g")
		[ "$major" = "" ] && major=0
		[ "$reviison" = "" ] && revision=0
		echo $major | grep -q "android-" && continue
		echo $revision | grep -q "android-" && continue

		b=$((1000*1000*1000))
		num=0
		for i in `echo $major | sed -e "s:\.: :g"`; do
			 num=$((num + i*b));
			 [ $b -eq 1 ] && break;
			 b=$((b/1000))
		done
		major=$num
		b=$((1000*1000*1000))
		num=0
		for i in `echo $revision | sed -e "s:\.: :g"`; do
			 num=$((num + i*b));
			 [ $b -eq 1 ] && break;
			 b=$((b/1000))
		done 
		revison=$num
                setvalue=0
		if [ $major -gt $nmajor ]; then
			 setvalue=1
                elif [ $major -eq $nmajor -a $revision -gt $nrevision ]; then
			 setvalue=1
                elif [ $major -eq $nmajor -a $revision -eq $nrevision -a "$extra" \> "$nextra" ]; then
			 setvalue=1
		fi

		if [ $setvalue -eq 1 ]; then
			ntag="$tag"
			nmajor=$major
			nrevision=$revision
			nextra=$extra
		fi
       done < /tmp/gittagtmp.txt
       rm -f /tmp/gittagtmp.txt
       echo $ntag
       return 0
}
curdir=`pwd`
basedir=$(cd $(dirname $0)/../..;pwd)
PROJECTLIST=$basedir/.repo/project.list
username=`git config --global --get user.name`
TAGNAME="android-4.4.4"

if [ "$1" = "-main" ]; then
	OUTLOG=$basedir/SNAPSHOT.txt
	rm -f $OUTLOG
	touch $OUTLOG
	while read project
    	do
 		 cd $basedir/$project
		 echo "process $project ..."
		 author=$(git log -1 --pretty=format:"%an")
                 commit=$(git log -1 --pretty=format:"%s")
		 if echo $commit | grep -q "Merge tag" && [ "$author" = "$username" ]; then
			lastTag=$(getLastTag)
			if echo $lastTag | grep -q "$TAGNAME"; then
				git reset --hard $lastTag
			fi
		 fi
	done < $PROJECTLIST
	cd $curdir
fi


