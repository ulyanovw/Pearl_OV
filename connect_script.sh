#!/bin/bash
if [ -f "$path_to_conf/ccd/$common_name" ] && grep -q "ifconfig-push" "$path_to_conf/ccd/$common_name"; then
    exit 0
else
    echo "ifconfig-push $ifconfig_pool_remote_ip 255.255.0.0" >> "$path_to_conf/ccd/$common_name"
fi
