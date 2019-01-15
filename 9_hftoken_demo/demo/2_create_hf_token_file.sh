#!/bin/bash 
#
# This script simulates the role of a security administrator that creates and distributes Host Factory tokens.
#
#####
# HARD CODED VALUES defined in webapp-*.yml policy files 
declare HOST_FACTORY_NAME=$CONJUR_ACCOUNT:host_factory:webapp/tomcat_factory
declare HOST_NAME=tomcat_host_from_hf_token
declare VAR_ID=webapp-secrets/database_password 
######

# get pointers to Conjur REST API endpoint and SSL certificate
export CONJUR_CERT_FILE=/etc/conjur-$CONJUR_ACCOUNT.pem

# data specs and time math are not portable - set DATE_SPEC to the correct platform
readonly MAC_DATE='date -v+"$dur_time_secs"S +%Y-%m-%dT%H%%3A%M%%3A%S%z'
readonly LINUX_DATE='date --iso-8601=seconds --date="$dur_time_secs seconds"'
DATE_SPEC=$MAC_DATE
if [[ "$(uname -s)" == "Linux" ]]; then
        DATE_SPEC=$LINUX_DATE
fi

#declare DEBUG_BREAKPT=""
declare DEBUG_BREAKPT="read -n 1 -s -p 'Press any key to continue'"

# global variables
declare ADMIN_SESSION_TOKEN
declare CONJUR_HOST_FACTORY_TOKEN
declare URLIFIED

################  MAIN   ################
# $1 - name of output file
main() {

        if [[ $# -ne 1 ]] ; then
                printf "\n\tUsage: %s <output-filename>\n\n" $0
                exit 1
        fi

	echo "This script generates a host factory token and writes it to the filename provide"
	echo "along with a proposed hostname and variable name. This information"
	echo "is used as input to the next script."
        local output_file=$1

	# authenticate (login) user
	user_authn  # get admin session token based on user name and password
        if [[ "$ADMIN_SESSION_TOKEN" == "" ]]; then
          echo "Authentication failed..."
          exit -1
        fi

	# create a host factory token
	hf_token_create $HOST_FACTORY_NAME 200000
	printf "\nHF token is: %s\n" $CONJUR_HOST_FACTORY_TOKEN

	# write out host factory token, host name and variable name to file
	echo $CONJUR_HOST_FACTORY_TOKEN > $output_file
	echo $HOST_NAME >> $output_file
	echo $VAR_ID >> $output_file
	printf "\n\nWrote HF token, app name and variable name to file '%s'...\n\n\n" $output_file
}

##################
# USER AUTHN - get admin session token based on user name and password
# - no arguments
user_authn() {
        printf "\nEnter admin user name: "
        read admin_name
        printf "Enter the admin password (it will not be echoed): "
        read -s admin_pwd

        # Login user, authenticate and get API key for session
        local api_key=$(curl \
				-s \
                                --cacert $CONJUR_CERT_FILE \
                                --user $admin_name:$admin_pwd \
                                $CONJUR_APPLIANCE_URL/authn/$CONJUR_ACCOUNT/login)

        local response=$(curl -s \
                        --cacert $CONJUR_CERT_FILE  \
                        --data $api_key \
                        $CONJUR_APPLIANCE_URL/authn/$CONJUR_ACCOUNT/$admin_name/authenticate)
        ADMIN_SESSION_TOKEN=$(echo -n $response| base64 | tr -d '\r\n')

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
	str=$(echo $str | sed 's=+=-=g')   # added as hack to change + to - in timezone offset in linux date string
	URLIFIED=$str
}

##################
# HOST FACTORY TOKEN CREATE a new HF token with a defined expiration date
# $1 - host factory id
# $2 - dur time - hf token lifespan in seconds
hf_token_create() {
        local hf_id=$1; shift
        local dur_time_secs=$1; shift

        local token_exp_time=$(eval $DATE_SPEC)
        printf "\n\nToken exp time= %s\n" $token_exp_time

        CONJUR_HOST_FACTORY_TOKEN=$(curl -s \
		--request POST \
		--cacert $CONJUR_CERT_FILE \
	     	-H "Authorization: Token token=\"$ADMIN_SESSION_TOKEN\"" \
		--data-urlencode "expiration=$token_exp_time" \
		--data-urlencode "host_factory=$hf_id" \
		$CONJUR_APPLIANCE_URL/host_factory_tokens \
		| jq -r '.[] | .token')

}

################
# HOST FACTORY SHOW - show info about host factory including all associated tokens
hf_show() {
        local hf_id=$1; shift

	printf "\nHost factory %s:\n" $hf_id
	curl -s \
	--request POST \
	--cacert $CONJUR_CERT_FILE \
	-H "Authorization: Token token=\"$ADMIN_SESSION_TOKEN\"" \
	--data-urlencode "host_factory=$hf_id" \
         $CONJUR_APPLIANCE_URL/host_factory_tokens \
	jq .
}

################
# HOST FACTORY TOKEN REVOKE (delete) the host factory token
hf_token_revoke() {
        local hf_token=$1; shift
        curl \
         -s \
         --request DELETE \
         --cacert $CONJUR_CERT_FILE \
         -H "Authorization: Token token=\"$ADMIN_SESSION_TOKEN\"" \
         $CONJUR_APPLIANCE_URL/host_factory_tokens?$hf_token
}

main "$@"
exit
