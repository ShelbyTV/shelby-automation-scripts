export date=$(date +%Y-%m-%d)

echo "Starting run for $date"

# cleanup old export folders
for dir in $(find . -maxdepth 1 -name '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]' -type d)
do
  # only remove export files from earlier dates
  if [ $(basename $dir) \< $date ]
  then
    echo "Removing old export folder $dir"
    bash -c "set -x; rm -rf $dir"
  fi
done

export folderForDate="./$date"
completionFile="$date-complete.txt"
completionFileFullPath="$folderForDate/$completionFile"
# if the completion file already exists, we've already run for the current date, so exit
if [ -e $completionFileFullPath ]
then
  echo "Completion file $completionFile already exists"
  echo "Upload and export for $date already done"
  exit
fi

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
  ./export-upload.sh -c ${collection} 1>${folderForDate}/${collection}-export.log 2>&1 &
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
  echo "Creating completion file $completionFile"
  echo "1" > $completionFileFullPath
  echo "Uploading completion file $completionFile"
  s3cmd --progress put $completionFileFullPath s3://dev-shelby-mortar-share/input/
  exit 0
else
  exit 1
fi