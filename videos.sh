set -e

date=${date-$(date +%Y-%m-%d)}
exportFilename="$date"-videos.json
# if the export file doesn't already exist, do the export, otherwise go straight to the upload
if [ ! -e $exportFilename ]
then
  mongoexport -u gt_admin -p Ov3rt1m3#4# --authenticationDatabase admin -d gt-video -c videos --host gt-db-video-s0-b --slaveOk 1 -o "$exportFilename"
fi
s3cmd --progress --multipart-chunk-size-mb=100 put "$exportFilename" s3://dev-shelby-mortar-share/input/videos/"$date"/videos.json