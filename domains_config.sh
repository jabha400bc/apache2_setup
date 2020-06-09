# Domain details.
export PRIMARY_DOMAIN=primary.mydomain.com
export STATIC_DOMAIN=static.mydomain.com
export DYNAMIC_DOMAIN=dynamic.mydomain.com
export DOMAINS=( $PRIMARY_DOMAIN $STATIC_DOMAIN $DYNAMIC_DOMAIN ) 

########################################################
# These variables are used for generating self-signed certificates
export CERTS_DIR=${HOME}/secrets/certs # Directory where generated self signed certificates will be kept
# Other details needed to generate self-signed certificate
export COUNTRY=IN
export STATE=Karnataka
export LOCALITY=Bengaluru
export ORG=mydomain.com
export ORG_UNIT=IT
export EMAIL=abc@xyz.com
########################################################
export PASSWORD=pass123