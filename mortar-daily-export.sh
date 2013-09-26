export date=$(date +%Y-%m-%d)

echo "Starting run for $date"
echo "Starting frames"
./frames.sh 1>./frames_export.log 2>&1 &
pidFrames=$!
echo "Starting users"
./users.sh 1>./users_export.log 2>&1 &
pidUsers=$!
echo "Starting videos"
./videos.sh 1>./videos_export.log 2>&1 &
pidVideos=$!

wait $pidFrames
statusFrames=$?
wait $pidUsers
statusUsers=$?
wait $pidVideos
statusVideos=$?

echo "All jobs done"
echo "frames returned status $statusFrames"
echo "users returned status $statusUsers"
echo "videos returned status $statusVideos"

if [ $statusFrames -eq 0 -a $statusUsers -eq 0 -a $statusVideos -eq 0 ]
then
  # if we succeed create a file and upload it that signals mortar we completed successfully
  set -e
  completionFileName="$date"-complete.txt
  echo "1" > $completionFileName
  echo "Uploading completion file"
  s3cmd --progress put $completionFileName s3://dev-shelby-mortar-share/input/
  exit 0
else
  exit 1
fi