#!/bin/bash
#
# Usage: bash bump.sh YOUR.src.rpm 'bumpspec comment' f19
#
# Author: Christopher Markieta
 
if [ -z "$1" ]; then
    echo 'Missing source RPM'
elif [ -z "$2" ]; then
    echo 'Missing bumpspec comment'
elif [ -z "$3" ]; then
    echo 'Missing last argument'
else
    rpm2cpio "$1" | cpio -idmv;
    rpmdev-bumpspec -c "$2" *.spec;
    cp -Rf * ~/rpmbuild/SOURCES/;
    newSRPM=$(rpmbuild -bs *.spec | awk '{print $2}');
    koji -s 'http://japan.proximity.on.ca/kojihub' build "$3" "$newSRPM";
fi
