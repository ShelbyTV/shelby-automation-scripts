set -e

# date=$(date +%Y-%m-%d)
exportFilename="$date"-users.json
mongoexport -u gt_admin -p Ov3rt1m3#4# --authenticationDatabase admin -d nos-production -c users --host nos-db-s0-b:27018 --slaveOk 1 -o "$exportFilename" -q "{ '_id' : { '\$oid' : '4ff5a74ed1041268c204d748'} }" -f roll_followings,aa,ab,ad,ae,af,ac,ag,as,authentications,nickname,downcase_nickname,current_sign_in_at,last_sign_in_at,bb
s3cmd --progress --multipart-chunk-size-mb=100 put "$exportFilename" s3://dev-shelby-mortar-share/input/users/"$date"/users.json