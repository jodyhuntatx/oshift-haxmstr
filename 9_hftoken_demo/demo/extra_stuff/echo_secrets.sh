#!/bin/bash

main() {
        printf "\n\nValue for %s is: %s\n" "DB_UNAME" $DB_UNAME
        printf "Value for %s is: %s\n\n" "DB_PWD" $DB_PWD
}

main $@
