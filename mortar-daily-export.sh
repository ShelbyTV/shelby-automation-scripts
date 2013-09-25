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

if [ $statusFrames -a $statusUsers -a $statusVideos ]
then
  exit 1
else
  exit 0
fi