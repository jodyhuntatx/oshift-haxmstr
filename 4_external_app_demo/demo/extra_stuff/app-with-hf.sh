#!/bin/bash 

CONJUR_APPLIANCE_URL=$OPENSHIFT_IP/api
CONJUR_CERT_FILE=/etc/conjur-$CONJUR_ACCOUNT.pem

#####
# HARD CODED VALUES from policy .yml 
declare HOST_FACTORY_NAME=jodytest-svc
declare HOST_NAME=user-pref-svc-1
declare VAR_ID=jodytest-rsrc/db-password 
######

# data specs and time math are not portable - set DATE_SPEC to the correct platform
readonly MAC_DATE='date -v+"$dur_time_secs"S +%Y-%m-%dT%H%%3A%M%%3A%S%z'
readonly LINUX_DATE='date --iso-8601=seconds --date="$dur_time_secs seconds"'
DATE_SPEC=$MAC_DATE
if [[ "$(uname -s)" == "Linux" ]]; then
        DATE_SPEC=$LINUX_DATE
fi

# global variables
declare ADMIN_SESSION_TOKEN
declare CONJUR_HOST_FACTORY_TOKEN
declare HOST_API_KEY
declare HOST_SESSION_TOKEN
declare SECRET_VALUE
declare URLIFIED

declare DEBUG_BREAKPT=""
#declare DEBUG_BREAKPT="read -n 1 -s -p 'Press any key to continue'"

################  MAIN   ################
main() {
	# authenticate (login) user
	user_authn  # get admin session token based on user name and password
	urlify $HOST_FACTORY_NAME
	HOST_FACTORY_NAME=$URLIFIED
	
	hf_show $HOST_FACTORY_NAME
	# create a host factory token
	hf_token_create $HOST_FACTORY_NAME 200000	# sets CONJUR_HOST_FACTORY_TOKEN
	printf "\nHF token is: %s\n" $CONJUR_HOST_FACTORY_TOKEN
	hf_show $HOST_FACTORY_NAME
				# NOTE hostname not in URL format - sets HOST_API_KEY global value
	hf_register_host $CONJUR_HOST_FACTORY_TOKEN $HOST_NAME
	hf_token_revoke $CONJUR_HOST_FACTORY_TOKEN 

	if [[ "$HOST_API_KEY" == "" ]]; then
		printf "\n\nAPI key not generated. Perhaps host factory token has expired. Please regenerate...\n\n"
		exit 1
	fi

	printf "\n\nAPI key for %s is: %s \n\n" $HOST_NAME $HOST_API_KEY
	read -n 1 -s -p "Press any key to continue"

	host_authn $HOST_NAME $HOST_API_KEY  		# sets HOST_SESSION_TOKEN value

#	list_resources $HOST_NAME

	urlify $VAR_ID
	VAR_ID=$URLIFIED
	fetch_secret $VAR_ID				# sets SECRET_VALUE

	echo
	echo
	echo "Value for" $var_id "is:" $SECRET_VALUE
	echo
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
        local access_token=$(curl \
                                 -s \
                                --cacert $CONJUR_CERT_FILE \
                                --user $admin_name:$admin_pwd \
                                $CONJUR_APPLIANCE_URL/authn/users/login)

        local response=$(curl -s \
                        --cacert $CONJUR_CERT_FILE  \
                        --data $access_token \
                        $CONJUR_APPLIANCE_URL/authn/users/$admin_name/authenticate)
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

################  MAIN   ################
# HOST FACTORY TOKEN CREATE a new HF token with a defined expiration date
# $1 - host factory id
# $2 - dur time - hf token lifespan in seconds
hf_token_create() {
        local hf_id=$1; shift
        local dur_time_secs=$1; shift

        local token_exp_time=$(eval $DATE_SPEC)
	urlify $token_exp_time
	token_exp_time=$URLIFIED
        printf "Token exp time= %s\n" $token_exp_time

        CONJUR_HOST_FACTORY_TOKEN=$( curl \
	 -s \
         --cacert $CONJUR_CERT_FILE \
         --request POST \
         -H "Content-Type: application/json" \
         -H "Authorization: Token token=\"$ADMIN_SESSION_TOKEN\"" \
         $CONJUR_APPLIANCE_URL/host_factories/{$hf_id}/tokens?expiration=$token_exp_time \
         | jq -r '.[] | .token')
}

################
# HOST FACTORY SHOW - show info about host factory including all associated tokens
hf_show() {
        local hf_id=$1; shift

	printf "\nHost factory %s:\n" $hf_id
	curl \
	-s \
	--cacert $CONJUR_CERT_FILE \
	--header "Content-Type: application/json" \
	--header "Authorization: Token token=\"$ADMIN_SESSION_TOKEN\"" \
	$CONJUR_APPLIANCE_URL/host_factories/{$hf_id} \
	| jq -r ' .tokens | .[] '
}

################
# HOST FACTORY TOKEN REVOKE (delete) the host factory token
hf_token_revoke() {
        local hf_token=$1; shift
        curl \
         -s \
         --cacert $CONJUR_CERT_FILE \
         --request DELETE \
         -H "Content-Type: application/json" \
         -H "Authorization: Token token=\"$ADMIN_SESSION_TOKEN\"" \
         $CONJUR_APPLIANCE_URL/host_factories/tokens/$hf_token
}

################
# REGISTER HOST to the associated layer using the host factory token 
#    Note that if the host already exists, this command will create a new API key for it 
# $1 - application name

hf_register_host() {
	local hf_token=$1; shift
	local host_name=$1; shift

	HOST_API_KEY=$( curl \
	 -s \
	 --cacert $CONJUR_CERT_FILE \
	 --request POST \
     	 -H "Content-Type: application/json" \
	 -H "Authorization: Token token=\"$hf_token\"" \
	 $CONJUR_APPLIANCE_URL/host_factories/hosts?id=$host_name \
	 | jq -r '.api_key')

}

################
# HOST AUTHN using its name and API key to get session token
# $1 - host name 
# $2 - API key
host_authn() {
	local host_name=$1; shift
	local host_api_key=$1; shift

	urlify $host_name
	local host_name_urlfmt=host%2F$URLIFIED		# authn requires host/ prefix

	# Authenticate host w/ its name & API key to get session token
	 response=$(curl -s \
	 --cacert $CONJUR_CERT_FILE \
	 --request POST \
	 --data-binary $host_api_key \
	 $CONJUR_APPLIANCE_URL/authn/users/{$host_name_urlfmt}/authenticate)
	 HOST_SESSION_TOKEN=$(echo -n $response| base64 | tr -d '\r\n')
}

################
# FETCH SECRET using session token
# $1 - name of secret to fetch
fetch_secret() {
	local var_id=$1; shift

	urlify $var_id
	local var_id_urlfmt=$URLIFIED

	# FETCH variable value
	SECRET_VALUE=$(curl -s \
	 --cacert $CONJUR_CERT_FILE \
         --request GET \
         -H "Content-Type: application/json" \
         -H "Authorization: Token token=\"$HOST_SESSION_TOKEN\"" \
         $CONJUR_APPLIANCE_URL/variables/{$var_id_urlfmt}/value)

}

 
main "$@"
