#!/bin/bash 

. ./image_list.env

num_rows=8
for ((i=1;i<num_rows;i++)) do
  iname=${IMAGE_LIST[$i]}
  fname=${FILE_LIST[$i]}

  # skip if image tarfile not found
  if [ ! -f ./$fname ]; then
    echo "File $fname not found, skipping..."
    continue
  fi

  # skip if image already loaded
  irepo=$(echo $iname | cut -d ":" -f1)
  itag=$(echo $iname | cut -d ":" -f2)
  if [[ "$(docker images | grep $irepo | grep $itag)" != "" ]]; then
    echo "Image $iname already loaded, skipping..."
    continue
  fi

  echo "Loading image $iname from file $fname..."
  docker load -i $fname
done
