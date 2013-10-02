export date=$(date +%Y-%m-%d)

echo "Starting run for $date"
export folderForDate="./$date"
if [ ! -d ${folderForDate} ]
then
  echo "Creating folder $folderForDate"
  mkdir "$folderForDate"
fi

collections=("frames" "users" "videos")

# start export and upload jobs for all collections in parallel
for collection in ${collections[@]}
do
  echo "Starting $collection"
  pidVar="${collection}Pid"
  ./export-upload.sh ${collection} 1>${folderForDate}/${collection}-export.log 2>&1 &
  export ${pidVar}=$!
done

# wait for all jobs to finish
for collection in ${collections[@]}
do
  pidVar="${collection}Pid"
  statusVar="${collection}Status"
  wait ${!pidVar}
  export ${statusVar}=$?
done

echo "All jobs done"

finalStatus=0
# report on success or failre of all jobs
for collection in ${collections[@]}
do
  statusVar="${collection}Status"
  echo "$collection returned status ${!statusVar}"
  if [ ${!statusVar} -ne 0 ]
  then
    finalStatus=1
  fi
done

if [ $finalStatus -eq 0 ]
then
  # if we succeed create a file and upload it that signals mortar we completed successfully
  set -e
  completionFile="$date-complete.txt"
  completionFileFullPath="$folderForDate/$completionFile"
  echo "Creating completion file $completionFile"
  echo "1" > $completionFileFullPath
  echo "Uploading completion file $completionFile"
  s3cmd --progress put $completionFileFullPath s3://dev-shelby-mortar-share/input/
  exit 0
else
  exit 1
fi