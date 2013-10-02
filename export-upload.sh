set -e

collection=${1-"frames"}

echo "Collection to export is $collection"

# lookup the MongoDB database, host, port and other configuration for the collection
# being exported
line=`grep "${collection} .* .* .*" <<EOF
frames gt-roll-frame gt-db-roll-frame-s0-c default default
users nos-production nos-db-s0-b 27018 roll_followings,aa,ab,ad,ae,af,ac,ag,as,authentications,nickname,downcase_nickname,current_sign_in_at,last_sign_in_at,bb
videos gt-video gt-db-video-s0-b default default
EOF`

set -- $line
database=$2
host=$3
port=$4
fields=$5

date=${date-$(date +%Y-%m-%d)}
# all files are placed in a folder named for the date,
# if that folder doesn't exist already, create it
folderForDate=${folderForDate-"./$date"}
if [ ! -d ${folderForDate} ]
then
  echo "Creating folder $folderForDate"
  mkdir "$folderForDate"
fi

# figure out the paths and filenames of the files we'll be working with
exportFile=${collection}.json
exportFileFullPath="$folderForDate/$exportFile"
uploadCompleteFile=${collection}-upload-complete.txt
uploadCompleteFileFullPath="$folderForDate/$uploadCompleteFile"

# if the export file doesn't already exist, do the export, otherwise go straight to the upload
if [ ! -e $exportFileFullPath ]
then
  echo "Export file not created yet, exporting to $exportFile"
  echo "Executing:"
  if [ $port != "default" ]
  then
    port=":$port"
  else
    port=""
  fi
  if [ $fields != "default" ]
  then
    fields=" -f $fields"
  else
    fields=""
  fi
  # echo the command to stdout, using a here document to hide the password
  bash -ci "set -x;mongoexport -u gt_admin -p --authenticationDatabase admin -d $database -c $collection --host $host$port --slaveOk 1 -o $exportFileFullPath$fields" <<FRED
Ov3rt1m3#4#
FRED
fi
# if the upload completion indicator file isn't there, we still need to do the upload
if [ ! -e $uploadCompleteFileFullPath ]
then
  echo "Upload not completed yet, uploading $exportFile"
  echo "Executing:"
  # echo the command to stdout
  bash -c "set -x; s3cmd --progress --multipart-chunk-size-mb=100 put $exportFileFullPath s3://dev-shelby-mortar-share/input/$collection/$date/$collection.json"
  # upload completed succesfully, create an indicator file so we know this finished
  echo "Upload complete, creating indicator file $uploadCompleteFile"
  echo "1" > $uploadCompleteFileFullPath
else
  echo "Export and upload already complete, skipping"
fi