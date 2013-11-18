#!/bin/bash

set -e

# argument defaults
volumeGroup="/dev/vg0/"
snapshotPrefix="mongodb-snap"

echo "Looking for most recent snapshot with prefix $snapshotPrefix"

mostRecentSnapshot=`lvscan | grep -o -i -P "(?<=snapshot '${volumeGroup})${snapshotPrefix}-[[:digit:]]{8}-[[:digit:]]{6}" | tail -1`
if [ -n "$mostRecentSnapshot" ]
then
  echo "Found snapshot $mostRecentSnapshot, archiving"
  ./archive-lvm-snapshot.sh -s $mostRecentSnapshot
else
  echo "No matching snapshot found"
fi
