set -e

# date=$(date +%Y-%m-%d)
exportFilename="$date"-frames.json
mongoexport -u gt_admin -p Ov3rt1m3#4# --authenticationDatabase admin -d gt-roll-frame -c frames --host gt-db-roll-frame-s0-c --slaveOk 1 -o "$exportFilename" -q "{ '_id' : { '\$oid' : '4f9393169a725b07de000014'} }"
s3cmd --progress --multipart-chunk-size-mb=100 put "$exportFilename" s3://dev-shelby-mortar-share/input/frames/"$date"/frames.json