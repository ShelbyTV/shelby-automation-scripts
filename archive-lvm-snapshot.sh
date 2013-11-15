#!/bin/bash

set -e

OPTIND=1 # Reset in case getopts has been used previously in the shell.

# argument defaults
volumeGroup="/dev/vg0/"
snapshotName="snap"
mountRootFolder="/mnt"

while getopts "s:" opt; do
    case "$opt" in
    s)
      snapshotName=$OPTARG
      ;;
    \?)
      exit 1
      ;;
    esac
done

snapshotVolume="${volumeGroup}${snapshotName}"
mountPoint="${mountRootFolder}/${snapshotName}"
backupArchiveFile="~/${snapshotName}.tar.gz"

if [ ! -d ${mountRootFolder} ]
then
  echo "Creating folder $mountRootFolder"
  mkdir $mountRootFolder
fi

echo "Creating mount point $mountPoint"
bash -c "set -x;mkdir $mountPoint"

echo "Mounting LVM snapshot $snapshotVolume at $mountPoint"
bash -c "set -x;mount $snapshotVolume $mountPoint"

echo "Compressing backup files"
bash -c "set -x;tar -zcvf $backupArchiveFile $mountPoint"

echo "Unmounting LVM snapshot $snapshotVolume"
set +e
bash -c "set -x;umount $snapshotVolume"
set -e

echo "Deleting mount point $mountPoint"
bash -c "set -x;rmdir $mountPoint"

echo "Uploading compressed backup archive"
bash -c "set -x;s3cmd --progress --multipart-chunk-size-mb=100 put $backupArchiveFile s3://shelby-gt-db-backup/shelbySet/"