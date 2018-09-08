#!/bin/bash 

# name of secret to retrieve from Conjur
VAR1=secrets/db-password

main() {
  CONT_SESSION_TOKEN=$(cat $CONJUR_AUTHN_TOKEN_FILE | base64 | tr -d '\r\n')

  urlify "$VAR1"
  VAR1=$URLIFIED

  VAR1_VALUE=$(curl -s -k \
	--request GET \
	-H "Content-Type: application/json" \
	-H "Authorization: Token token=\"$CONT_SESSION_TOKEN\"" \
	$CONJUR_APPLIANCE_URL/variables/$VAR1/value)

  echo
  echo "The retrieved value for $VAR1 is: $VAR1_VALUE"
  echo
}

################
# URLIFY - converts '/' and ':' in input string to hex equivalents
# in: $1 - string to convert
# out: URLIFIED - converted string in global variable
urlify() {
        local str=$1; shift
        str=$(echo $str | sed 's= =%20=g')
        str=$(echo $str | sed 's=/=%2F=g')
        str=$(echo $str | sed 's=:=%3A=g')
        URLIFIED=$str
}

main "$@"

exit
