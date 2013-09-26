set -e

date=${date-$(date +%Y-%m-%d)}
exportFilename="$date"-frames.json
# if the export file doesn't already exist, do the export, otherwise go straight to the upload
if [ ! -e $exportFilename ]
then
  mongoexport -u gt_admin -p Ov3rt1m3#4# --authenticationDatabase admin -d gt-roll-frame -c frames --host gt-db-roll-frame-s0-c --slaveOk 1 -o "$exportFilename"
fi
s3cmd --progress --multipart-chunk-size-mb=100 put "$exportFilename" s3://dev-shelby-mortar-share/input/frames/"$date"/frames.json