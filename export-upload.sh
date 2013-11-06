set -e

OPTIND=1 # Reset in case getopts has been used previously in the shell.

# argument defaults
collection="frames"
method="export" #valid values are "export" and "dump"

while getopts "c:m:" opt; do
    case "$opt" in
    c)
      collection=$OPTARG
      ;;
    m)
      method=$OPTARG
      if [ "$method" != "export" -a "$method" != "dump" ]
      then
        echo "valid values for -m option are export, dump"
        exit 1
      fi
      ;;
    \?)
      exit 1
      ;;
    esac
done

echo "Collection to $method is $collection"

# lookup the MongoDB database, host, port and other configuration for the collection
# being exported
line=`grep "${collection} .* .* .*" <<EOF
frames gt-roll-frame gt-db-roll-frame-s0-c default default
users nos-production nos-db-s0-e 27018 roll_followings,aa,ab,ad,ae,af,ac,ag,as,authentications,nickname,downcase_nickname,current_sign_in_at,last_sign_in_at,bb
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

case "$method" in
  export)
    # figure out the paths and filenames of the files we'll be working with
    exportFile=${collection}.json
    exportFileFullPath="$folderForDate/$exportFile"
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
      bash -c "set -x;mongoexport -u gt_admin -p --authenticationDatabase admin -d $database -c $collection --host $host$port --slaveOk 1 -o $exportFileFullPath$fields" <<FRED
Ov3rt1m3#4#
FRED
    fi
    ;;
  dump)
    dumpFolder="$folderForDate/$database"
    # if the dump folder doesn't already exist, do the dump, otherwise go straight to the upload
    if [ ! -d $dumpFolder ]
    then
      echo "Dump not created yet, dumping to $dumpFolder"
      echo "Executing:"
      if [ $port != "default" ]
      then
        port=":$port"
      else
        port=""
      fi
      # echo the command to stdout, using a here document to hide the password
      bash -c "set -x;mongodump -u gt_admin -p --authenticationDatabase admin --host $host$port --oplog -o $folderForDate" <<FRED
Ov3rt1m3#4#
FRED
    fi
    ;;

esac

uploadCompleteFile=${collection}-upload-complete.txt
uploadCompleteFileFullPath="$folderForDate/$uploadCompleteFile"
# if the upload completion indicator file isn't there, we still need to do the upload
if [ ! -e $uploadCompleteFileFullPath ]
then
  case "$method" in
    export)
      echo "Upload not completed yet, uploading $exportFile"
      echo "Executing:"
      # echo the command to stdout
      bash -c "set -x; s3cmd --progress --multipart-chunk-size-mb=100 put $exportFileFullPath s3://dev-shelby-mortar-share/input/$collection/$date/$collection.json"
      ;;
    dump)
      echo "Upload not completed yet, uploading $database"
      echo "Executing:"
      # echo the command to stdout
      bash -c "set -x; s3cmd --progress --multipart-chunk-size-mb=100 put --recursive $dumpFolder s3://shelby-gt-db-backup/$collection/"
      ;;
  esac
  # upload completed succesfully, create an indicator file so we know this finished
  echo "Upload complete, creating indicator file $uploadCompleteFile"
  echo "1" > $uploadCompleteFileFullPath
else
  echo "$method and upload already complete, skipping"
fi