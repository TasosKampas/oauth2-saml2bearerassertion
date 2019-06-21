#!/bin/bash
#set -x
 
protocol="http"
host="openam.example.com"
port="38080"
deployment="openam"
user="demo"
password="changeit"
client_id="myClientID"
client_password="password"
scope="profile"
sts="mytest"
ASSERTION_FILE="/opt/tmp/SAML_ASSERTION.xml"
TMP_FILE="/opt/tmp/SAML_ASSERTION_2.xml"
 
# Obtain a user Token
tokenid=`curl -s -X POST \
--header "Accept-API-Version: resource=2.0, protocol=1.0" \
--header "X-OpenAM-Username: $user" \
--header "X-OpenAM-Password: $password" \
--header "Content-Type: application/json" \
"$protocol://$host:$port/$deployment/json/authenticate" | jq -r .tokenId`
echo "tokenid is " $tokenid
 
# Exchange the SSOToken for a SAML Assertion
saml_assertion=`curl -v -X POST \
--header "Content-Type: application/json" \
--header "Cache-Control: no-cache" \
--data "{\"input_token_state\":{\"token_type\":\"OPENAM\",\"session_id\":\"${tokenid}\"},\"output_token_state\":{\"token_type\":\"SAML2\",\"subject_confirmation\":\"BEARER\"}}" \
"$protocol://$host:$port/$deployment/rest-sts/$sts?_action=translate" 2>/dev/null | python -m json.tool | grep issued_token | cut -f6- -d" " | sed 's/^"\(.*\)"$/\1/'`
 
echo "STS Result is "
echo ${saml_assertion}
echo ${saml_assertion} >${ASSERTION_FILE}
# We remove the newlines, slashes and we base64encode the assertion
cat ${ASSERTION_FILE} | awk '{gsub(/\\n/,"\n")}1' | awk '{gsub(/\\"/,"\"")}1'| base64 --wrap=0  > ${TMP_FILE}
echo "SAML2 Assertion is "
assertion=`cat ${TMP_FILE}`
echo $assertion
 
# Exchange the SAML Assertion with an OAuth2 Access token
access_token=`curl -v \
--request POST \
--header "application/x-www-form-urlencoded" \
--data "grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Asaml2-bearer" \
--data-urlencode "assertion=${assertion}" \
--data "client_id=${client_id}" \
--data "scope=${scope}" \
"$protocol://$host:$port/$deployment/oauth2/access_token" 2>/dev/null | python -m json.tool | grep access_token | cut -f4 -d'"'`
echo "OAuth2 Access token is " $access_token
 
rm ${TMP_FILE} ${ASSERTION_FILE}
