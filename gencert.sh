#!/bin/bash
############# Helper Functions ######################################
function ensure_certs_dir(){
    mkdir -p ${CERTS_DIR}
}
function check_domains(){
    if [ -z "$DOMAINS" ]
    then
        echo "Argument not present."
        echo "Useage $0 [common name]"

        exit 99
    fi
}

function gen_key_req(){
    echo "Generating key request for $DOMAIN" \
    && openssl genrsa -des3 -passout pass:${PASSWORD} -out ${CERTS_DIR}/${DOMAIN}.key 2048
}
function remove_passphrase_from_key(){
    #Remove passphrase from the key.
    echo "Removing passphrase from key" \
    && openssl rsa -in ${CERTS_DIR}/${DOMAIN}.key -passin pass:${PASSWORD} -out ${CERTS_DIR}/${DOMAIN}.key
}
function create_csr(){
    #Create the request
    echo "Creating CSR" \
    && openssl req -new -key ${CERTS_DIR}/${DOMAIN}.key -out ${CERTS_DIR}/${DOMAIN}.csr -passin pass:${PASSWORD} \
        -subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORG}/OU=${ORG_UNIT}/CN=${COMMON_NAME}/emailAddress=${EMAIL}"
}
function sign_csr(){
    openssl x509 -in ${CERTS_DIR}/${DOMAIN}.csr -out ${CERTS_DIR}/${DOMAIN}.crt -req -signkey ${CERTS_DIR}/${DOMAIN}.key -days 365
}
function gen_certs(){
    for d in ${DOMAINS[@]}
    do
        export DOMAIN=${d} \
        && export COMMON_NAME=$DOMAIN \
        && echo '*********************'START: generate cert for $DOMAIN'*********************' \
        && gen_key_req \
        && remove_passphrase_from_key \
        && create_csr \
        && sign_csr \
        && echo '*********************'COMPLETE: generate cert for $DOMAIN'*********************'
    done
}
###################################################################################
check_domains \
&& ensure_certs_dir \
&& gen_certs