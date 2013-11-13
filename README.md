shelby-automation-scripts
================

Scripts to automate common operations (usually involving our mongodb) on Ubuntu, including:

+ Exporting and uploading our data to Mortar so they can generate recommendations

####Script Descriptions

+ **mongo-export-upload.sh** - mongoexports or mongodumps a mongodb collection and uploads it to Amazon s3
+ **mortar-daily-export.sh** - exports and uploads our data (using mongo-export-upload.sh) to Mortar so they can generate recommendations
