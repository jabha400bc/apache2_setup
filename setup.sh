#!/bin/bash
export APACHE_HOME=/etc/apache2
function setup_apache2(){
    set -x \
    && update_os \
    && install_apache2 \
    && install_mod_jk \
    && enable_expires_headers_modules \
    && set +x
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
    sudo sed 's/<PRIMARY_DOMAIN>/'${PRIMARY_DOMAIN}'/g' ${APACHE_HOME}/primary.conf \
    && sudo sed 's/<CERTS_DIR>/'${CERTS_DIR}'/g' ${APACHE_HOME}/primary.conf \
    && sudo sed 's/<STATIC_DOMAIN>/'${STATIC_DOMAIN}'/g' ${APACHE_HOME}/static.conf \
    && sudo sed 's/<CERTS_DIR>/'${CERTS_DIR}'/g' ${APACHE_HOME}/static.conf \
    && sudo sed 's/<DYNAMIC_DOMAIN>/'${DYNAMIC_DOMAIN}'/g' ${APACHE_HOME}/dynamic.conf \
    && sudo sed 's/<CERTS_DIR>/'${CERTS_DIR}'/g' ${APACHE_HOME}/dynamic.conf
}
function copy_vhosts(){
    sudo cp vhost_primary_tmpl.conf $APACHE_HOME/primary.conf \
    && sudo vhost_static_tmpl.conf $APACHE_HOME/static.conf \
    && sudo vhost_dynamic_tmpl.conf $APACHE_HOME/dynamic.conf
}
function set_vhosts(){
    copy_vhosts \
    && prepare_vhosts
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