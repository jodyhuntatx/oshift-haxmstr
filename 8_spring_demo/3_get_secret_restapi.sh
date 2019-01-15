#!/bin/sh 

# Variables from environment
# CONJUR_VERSION
# CONJUR_ACCOUNT
# CONJUR_APPLIANCE_URL
# CONJUR_AUTHN_LOGIN
# CONJUR_AUTHN_API_KEY

################  MAIN   ################
# $1 - name of input file containing three lines for HF token, host name and name of variable to read

main() {
	if [[ $# -ne 1 ]] ; then
		printf "\n\tUsage: %s <variable-name>\n\n" $0
		exit 1
	fi
	var_id=$1

	host_name=$CONJUR_AUTHN_LOGIN
	HOST_API_KEY=$CONJUR_AUTHN_API_KEY

	echo "API key for" $host_name "is:" $HOST_API_KEY
	host_authn $host_name $HOST_API_KEY  		# sets HOST_SESSION_TOKEN value
	fetch_secret $var_id				# sets SECRET_VALUE

	echo
	echo
	echo "Value for" $var_id "is:" $SECRET_VALUE
	echo
}
 
################
# HOST AUTHN using its name and API key to get session token
# $1 - host name 
# $2 - API key
host_authn() {
	local host_name=$1; shift
	local host_api_key=$1; shift

	urlify $host_name
	local host_name_urlfmt=$URLIFIED		# authn requires host/ prefix

	# Authenticate host w/ its name & API key to get session token
	 response=$(curl -s \
	 --cacert $CONJUR_CERT_FILE \
	 --data $host_api_key \
	 $CONJUR_APPLIANCE_URL/authn/$CONJUR_ACCOUNT/$host_name_urlfmt/authenticate )
	 HOST_SESSION_TOKEN=$(echo -n $response| base64 | tr -d '\r\n')
}

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

################
# FETCH SECRET using session token
# $1 - name of secret to fetch
fetch_secret() {
	local var_id=$1; shift

	urlify $var_id
	local var_id_urlfmt=$URLIFIED

	# FETCH variable value
#	SECRET_VALUE=$(curl -s \
curl -v \
	 --cacert $CONJUR_CERT_FILE \
         --request GET \
         -H "Content-Type: application/json" \
         -H "Authorization: Token token=\"$HOST_SESSION_TOKEN\"" \
         $CONJUR_APPLIANCE_URL/secrets/$CONJUR_ACCOUNT/variable/$var_id_urlfmt
#)

}

main "$@"

