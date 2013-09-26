set -e

date=${date-$(date +%Y-%m-%d)}
exportFilename=${date}-videos.json
uploadCompleteFileName=${date}-videos-upload-complete.txt
# if the export file doesn't already exist, do the export, otherwise go straight to the upload
if [ ! -e $exportFilename ]
then
  echo "Export file not created yet, exporting to $exportFilename"
  mongoexport -u gt_admin -p Ov3rt1m3#4# --authenticationDatabase admin -d gt-video -c videos --host gt-db-video-s0-b --slaveOk 1 -o "$exportFilename"
fi
if [ ! -e $uploadCompleteFileName ]
then
  echo "Upload not completed yet, uploading $exportFilename"
  s3cmd --progress --multipart-chunk-size-mb=100 put "$exportFilename" s3://dev-shelby-mortar-share/input/videos/"$date"/videos.json
  echo "Upload complete, creating indicator file $uploadCompleteFileName"
  echo "1" > $uploadCompleteFileName
else
  echo "Export and upload already complete, skipping"
fi