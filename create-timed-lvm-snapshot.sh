#!/bin/bash

set -e

OPTIND=1 # Reset in case getopts has been used previously in the shell.

# argument defaults
snapshotSize="10G"
snapshotTime=$(date +%Y%m%d-%H%M%S)
volumeGroup="/dev/vg0/"
logicalVolume="mongodb"

while getopts "l:s:" opt; do
    case "$opt" in
    l)
      logicalVolume=$OPTARG
      ;;
    s)
      snapshotSize=$OPTARG
      ;;
    \?)
      exit 1
      ;;
    esac
done

lvToSnapshot="${volumeGroup}${logicalVolume}"
snapshotPrefix="${logicalVolume}-snap"

echo "Creating LVM snapshot ${snapshotPrefix}-${snapshotTime}"
bash -c "set -x;lvcreate --size $snapshotSize --snapshot --name ${snapshotPrefix}-${snapshotTime} $lvToSnapshot"

echo "Looking for old LVM snapshots to remove"
for snapshot in `lvscan | grep -o -i -P "(?<=snapshot ')${volumeGroup}${snapshotPrefix}-[[:digit:]]{8}-[[:digit:]]{6}"`
do
  # if the snapshot is older than the one we just created, get rid of it
  if [ ${snapshot:(-15)} \< $snapshotTime ]
  then
    echo "Removing $snapshot"
    echo "Make sure it's not mounted"
    set +e
    bash -c "set -x;umount $snapshot"
    set -e
    echo "Remove"
    bash -c "set -x;lvremove $snapshot" <<HERE
y
HERE
  fi
done
