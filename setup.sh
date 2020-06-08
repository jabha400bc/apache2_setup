#!/bin/bash
export APACHE_HOME=/etc/apache2
export SCRIPT_DIR=$(dirname "$BASH_SOURCE")
function setup_apache2(){
    set -x \
    && update_os \
    && install_apache2 \
    && install_mod_jk \
    && stop_apache \
    && load_config \
    && gen_certs \
    && write_apache_conf \
    && enable_expires_headers_modules \
    && set_vhosts \
    && make_www_dir \
    && start_apache \
    && set +x
}
echo $SCRIPT_DIR
function load_config(){
    . ${SCRIPT_DIR}/domains_config.sh
}
function make_www_dir(){
    sudo mkdir -p ${APACHE_HOME}/www/suite
}
function stop_apache(){
    sudo systemctl stop apache2
}
function start_apache(){
    sudo systemctl start apache2
}
function update_os(){
    sudo apt-get update -y
}
function install_apache2(){
   sudo apt-get install apache2 apache2-utils -y
}
function install_mod_jk(){
    sudo apt-get install libapache2-mod-jk -y \
    && apachectl -M | grep jk_module
}
function enable_expires_headers_modules(){
    sudo a2enmod expires \
    && sudo a2enmod headers \
    && sudo systemctl restart apache2 \
    && apachectl -M | grep headers \
    && apachectl -M | grep expires
}
function prepare_vhosts(){
    sudo sed 's/<PRIMARY_DOMAIN>/'${PRIMARY_DOMAIN}'/g' ${APACHE_HOME}/sites-available/primary.conf \
    && sudo sed 's/<CERTS_DIR>/'${CERTS_DIR}'/g' ${APACHE_HOME}/sites-available/primary.conf \
    && sudo sed 's/<STATIC_DOMAIN>/'${STATIC_DOMAIN}'/g' ${APACHE_HOME}/sites-available/static.conf \
    && sudo sed 's/<CERTS_DIR>/'${CERTS_DIR}'/g' ${APACHE_HOME}/sites-available/static.conf \
    && sudo sed 's/<DYNAMIC_DOMAIN>/'${DYNAMIC_DOMAIN}'/g' ${APACHE_HOME}/sites-available/dynamic.conf \
    && sudo sed 's/<CERTS_DIR>/'${CERTS_DIR}'/g' ${APACHE_HOME}/sites-available/dynamic.conf
}
function prepare_hosts1(){
    cat $SCRIPT_DIR/vhost_primary_tmpl.conf \
    | awk -v r="${PRIMARY_DOMAIN}" '{gsub(/<PRIMARY_DOMAIN>/,r)}1' \
    | awk -v r="${CERTS_DIR}" '{gsub(/<CERTS_DIR>/,r)}1' | sudo tee ${APACHE_HOME}/sites-available/primary.conf \
    && \
    cat $SCRIPT_DIR/vhost_static_tmpl.conf \
    | awk -v r="${STATIC_DOMAIN}" '{gsub(/<STATIC_DOMAIN>/,r)}1' \
    | awk -v r="${CERTS_DIR}" '{gsub(/<CERTS_DIR>/,r)}1' | sudo tee ${APACHE_HOME}/sites-available/static.conf \
    && \
    cat $SCRIPT_DIR/vhost_dynamic_tmpl.conf \
    | awk -v r="${DYNAMIC_DOMAIN}" '{gsub(/<DYNAMIC_DOMAIN>/,r)}1' \
    | awk -v r="${CERTS_DIR}" '{gsub(/<CERTS_DIR>/,r)}1' | sudo tee ${APACHE_HOME}/sites-available/dynamic.conf
}
function copy_vhosts(){
    sudo cp vhost_primary_tmpl.conf $APACHE_HOME/sites-available/primary.conf \
    && sudo cp vhost_static_tmpl.conf $APACHE_HOME/sites-available/static.conf \
    && sudo cp vhost_dynamic_tmpl.conf $APACHE_HOME/sites-available/dynamic.conf
}
function set_vhosts(){
    prepare_hosts1 \
    && enable_sites
}
function enable_sites(){
    sudo a2ensite primary \
    && sudo a2ensite static \
    && sudo a2ensite dynamic
}
function get_node_tmpl(){
cat << EOF
JKWorkerProperty worker.node1.host=<SERVER_IP_ADDRESS>
JKWorkerProperty worker.node1.port=8009
JKWorkerProperty worker.node1.type=ajp13
JKWorkerProperty worker.node1.socket_connect_timeout=5000
EOF
}
function get_nodes_conf(){
    for n in `cat nodes_list.txt`
    do
        get_node_tmpl | sed 's/<SERVER_IP_ADDRESS>/'${n}'/g'
    done
}

function get_nodes_list(){
    NUM_NODES=$(cat nodes_list.txt | wc -l) \
    && seq $NUM_NODES | awk '{print("node"$1);}' \
    | xargs | tr ' ' ','
}
function get_apache2_conf(){
    cat  apache2_template.conf \
    | awk -v r="$(get_nodes_conf)" '{gsub(/<NODES_CONFIG>/,r)}1' \
    | awk -v r="$(get_nodes_list)" '{gsub(/<NODES_LIST>/,r)}1'
}
function write_apache_conf(){
    get_apache2_conf | sudo tee ${APACHE_HOME}/apache2.conf
}
############# START:SSL Helper Functions ######################################
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
function gen_certs4domains(){
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
function gen_certs(){
    check_domains \
    && ensure_certs_dir \
    && gen_certs4domains
}
############# END:SSL Helper Functions ######################################