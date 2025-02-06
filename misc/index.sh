#! /bin/env bash
# this script generates the index.json file in the json directory
# it reads all the json files in the json directory and generates the index.json file,
# creating a json object with the filename as the key and the contents of the file as the value
# including only the files that have a "type"="ct" key-value pair

# get the current directory
DIR="$( pwd )"

# get the json directory
JSON_DIR="$DIR/json"

# get the index file
INDEX_FILE="$DIR/json/ct-index.json"

# delete the index file if it exists
rm -f $INDEX_FILE

# get the list of json files in the json directory
JSON_FILES=$(ls $JSON_DIR)

# create the index file
echo "{" > $INDEX_FILE

# loop through the json files
for JSON_FILE in $JSON_FILES
do
  # get the type of the json file
  JSON_TYPE=$(jq -r '.type' $JSON_DIR/$JSON_FILE)

  # check if the json file is a container
  if [ "$JSON_TYPE" == "ct" ]; then
    # get the contents of the json file
    JSON_CONTENT=$(cat $JSON_DIR/$JSON_FILE)

    # write the contents to the index file
    # removing ".json" from the filename

    echo "\"${JSON_FILE%.*}\": $JSON_CONTENT," >> $INDEX_FILE


    #echo "\"$JSON_FILE\": $JSON_CONTENT," >> $INDEX_FILE
  fi
done

# remove the last comma
sed -i '$ s/.$//' $INDEX_FILE

# close the json object
echo "}" >> $INDEX_FILE


