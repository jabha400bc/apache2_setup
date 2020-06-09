# Apache Web Server Setup
1. This document describes steps for Apache Web Server setup for three domains.
    * A primary domain
    * A static domain and
    * A dynamic domain
2. The setup does following
    * Installs apache web server
    * Generates self-signed certificates for the three domains i.e. primary, static and dynamic.
    * Sets up primary, static and dynamic sites using their respective SSL certificates.
    * Make custom settings as mentioned in [this page](https://docs.appian.com/suite/help/19.4/Configuring_Apache_Web_Server_with_Appian.html)
3. There are few differences between the the above page and this ubuntu implementation.
    * In Ubuntu, the apache web server service is called apache2 and not httpd
    * The config file name is apache2.conf and not httpd.conf
    * The recommended way to create virtual-hosts is to
        * Create separate file for each virtual host in /etc/apache2/sites-available
        * Then call `sudo a2ensite <site-name>` to enable the site.
# Steps
## Prepare
1. Launch an Ubuntu 18.04 instance.
2. SSH into the instance.
3. Clone this repo
    ```
    git clone https://github.com/jabha400bc/apache2_setup.git
    cd apache2_setup
    ```
4. Modify nodes_list.txt file with the IP addresses of the nodes that will be behind this web server
5. Modify domains_config.sh to details for your domain
## Run setup
1. Execute the setup. Make sure you are in apache2_setup directory
    ```
    . ./setup.sh
    setup_apache2
    ```
2. Verify that apache2 service is up and running
    ```
    sudo systemctl status apache2
    ```
3. Verify that all required modules are loaded.
    ```
    apachectl -M
    ```
4. In the above listing you should be able to see following key modules, as required by appian doc.
    * mod_jk
    * expires
    * headers
    * ssl
5. Copy Web Resources to the Web Server.
    * Refer to [this page](https://docs.appian.com/suite/help/19.4/Configuring_Apache_Web_Server_with_Appian.html)
    * Search for "Copy Web Resources to the Web Server"
    * The <APACHE_HOME> is /etc/apache2. The www folder is already created and it is owned by root. So, you will need sudo to copy anything here.
5. Modify nodes custom.properties. 
    * Refer [this page](https://docs.appian.com/suite/help/19.4/Configuring_Apache_Web_Server_with_Appian.html)
    * Search for "Configure URL Properties in Appian"

# Verify
1. In your /etc/hosts file against localhost, make three more entries like below
    ```
    127.0.0.1 localhost primary.mydomain.com static.mydomain.com dynamic.mydomain.com
    ```
2. Now, try to access the three domains. The purpose of "curl -k" is to ignore HTTPS warning. This warning comes because SSL certificates are self-signed and not issued by a globally trusted CA.
    ```
    curl -k https://primary.mydomain.com
    curl -k https://static.mydomain.com
    curl -k https://dynamic.mydomain.com
    ```
3. If everything is setup properly, and web server is able to route traffic to nodes then you should see valid pages being rendered.

# Open Questions
1. In [this page](https://docs.appian.com/suite/help/19.4/Configuring_Apache_Web_Server_with_Appian.html), search for "Load Balancing Multiple Application Servers"
    * It says "ensuring that the AJP port is different for each server based on the following example"
    * But in example all three are using same port. Which port needs to be changed?