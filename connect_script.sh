#!/bin/bash
CLIENT_NAME=$common_name
CLIENT_LOCAL_IP=$ifconfig_pool_remote_ip

if [ -f "$path_to_conf/ccd/$CLIENT_NAME" ] && grep -q "ifconfig-push" "$path_to_conf/ccd/$CLIENT_NAME"; then
    exit 0
else
    echo "ifconfig-push $CLIENT_LOCAL_IP 255.255.0.0" >> "$path_to_conf/ccd/$CLIENT_NAME"
fi
