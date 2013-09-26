set -e

# date=$(date +%Y-%m-%d)
exportFilename="$date"-videos.json
mongoexport -u gt_admin -p Ov3rt1m3#4# --authenticationDatabase admin -d gt-video -c videos --host gt-db-video-s0-b --slaveOk 1 -o "$exportFilename"
s3cmd --progress --multipart-chunk-size-mb=100 put "$exportFilename" s3://dev-shelby-mortar-share/input/videos/"$date"/videos.json