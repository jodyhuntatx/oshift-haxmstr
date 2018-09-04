#!/bin/bash  -x
awk '{ printf "docker load -i %s \n",$1 }' load_list.txt | xargs -0 bash -c
