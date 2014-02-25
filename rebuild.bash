#!/bin/bash

# Usage:  bash rebuild.bash YOUR.src.rpm 'bumpspec comment' f19
# Author: Christopher Markieta

download=0
workdir=$(pwd)

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
    # SRPM provided
    if [[ $1 = *.rpm ]]; then
        src=$1
    # List of packages
    else
        src=$(cat $1)
    fi 

    echo -e "$src" | while read pkg; do
        found=0
        package=$(echo $pkg | rev | cut -d- -f3- | rev)
        spkg=$(repoquery --whatprovides -s $package | head -1)

        # Download option enabled
        if [ $download -eq 1 ]; then
            package=$(echo $spkg | rev | cut -d- -f3- | rev) # Repoclosure name
            version=$(echo $pkg  | rev | cut -d- -f2  | rev)
            release=$(echo $pkg  | rev | cut -d- -f1  | cut -d. -f2- | rev)
            workdir='japan.proximity.on.ca/kojifiles/packages/'$package\/$version\/$release'/src/'
            wget -P /tmp -r -l1 --no-parent -A.rpm $workdir
            found=$?
            cd /tmp/$workdir
        fi

        # SRPM was found
        if [ $found -eq 0 ]; then
            rpm2cpio *rpm | cpio -idmv
            spec=$(ls -tu *.spec | tail -1)
            rpmdev-bumpspec -c "$2" $spec
            cp -Rf * ~/rpmbuild/SOURCES/
            newSRPM=$(rpmbuild -bs $spec | awk '{print $2}')
                                                                      #--scratch for testing
            nohup koji -s 'http://japan.proximity.on.ca/kojihub' build "$3" "$newSRPM" > /dev/null 2>&1
        fi

        rm -rf $workdir
    done
    
    rm -rf /tmp/japan.proximity.on.ca/
fi
