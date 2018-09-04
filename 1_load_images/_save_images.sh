#!/bin/bash  -x
awk '{ printf "docker save %s -o %s\n",$2,$1 }' load_list.txt | xargs -0 bash -c
