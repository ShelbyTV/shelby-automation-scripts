set -e

date=${date-$(date +%Y-%m-%d)}
exportFilename=${date}-users.json
uploadCompleteFileName=${date}-users-upload-complete.txt
# if the export file doesn't already exist, do the export, otherwise go straight to the upload
if [ ! -e $exportFilename ]
then
  echo "Export file not created yet, exporting to $exportFilename"
  mongoexport -u gt_admin -p Ov3rt1m3#4# --authenticationDatabase admin -d nos-production -c users --host nos-db-s0-b:27018 --slaveOk 1 -o "$exportFilename" -f roll_followings,aa,ab,ad,ae,af,ac,ag,as,authentications,nickname,downcase_nickname,current_sign_in_at,last_sign_in_at,bb
fi
if [ ! -e $uploadCompleteFileName ]
then
  echo "Upload not completed yet, uploading $exportFilename"
  s3cmd --progress --multipart-chunk-size-mb=100 put "$exportFilename" s3://dev-shelby-mortar-share/input/users/"$date"/users.json
  echo "Upload complete, creating indicator file $uploadCompleteFileName"
  echo "1" > $uploadCompleteFileName
else
  echo "Export and upload already complete, skipping"
fi