#!/bin/bash
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