#!/bin/bash

# Usage:  bash rebuild.bash YOUR.src.rpm 'bumpspec comment' f19
# Author: Christopher Markieta

download=0

while getopts ":d:" o; do
    case "${o}" in
        d)
            download=1
            shift 1
            ;;
    esac
done

if [ -z "$1" ]; then
    echo 'Missing source RPM'
elif [ -z "$2" ]; then
    echo 'Missing bumpspec comment'
elif [ -z "$3" ]; then
    echo 'Missing last argument'
else
    if [[ $1 = *.rpm ]]; then
        src=$1
    else
        src=$(cat $1)
    fi 

    echo -e "$src" | while read pkg; do
        found=0
        workdir='.'
        spkg=$(repoquery --whatprovides -s $pkg | head -1)

        if [ $download -eq 1 ]; then
            package=$(echo $spkg | rev | cut -d- -f3- | rev)
            version=$(echo $spkg | rev | cut -d- -f2  | rev)
            release=$(echo $spkg | rev | cut -d- -f1  | cut -d. -f2- | rev)
            workdir='japan.proximity.on.ca/kojifiles/packages/'$package\/$version\/$release'/src/'
            wget -r -l1 --no-parent -A.rpm $workdir
            found=$?
        fi

        if [ $found -eq 0 ]; then
            rpm2cpio $workdir/*rpm | cpio -idmv
            spec=$(ls -tu *.spec | tail -1)
            rpmdev-bumpspec -c "$2" $spec
            cp -Rf * ~/rpmbuild/SOURCES/
            newSRPM=$(rpmbuild -bs $spec | awk '{print $2}')
            nohup koji -s 'http://japan.proximity.on.ca/kojihub' build --scratch "$3" "$newSRPM" > /dev/null 2>&1
        fi
    done
fi
