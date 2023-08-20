#!/bin/bash

CLIENT_NAME="$common_name"
CLIENT_LOCAL_IP="$ifconfig_pool_remote_ip"

connect() {
    if [ -f "$path_to_conf/ccd/$CLIENT_NAME" ] && grep -q "ifconfig-push" "$path_to_conf/ccd/$CLIENT_NAME"; then
        exit 0
    else
        echo "ifconfig-push $CLIENT_LOCAL_IP 255.255.0.0" >> "$path_to_conf/ccd/$CLIENT_NAME"
    fi
    update_connection_status true
}

disconnect() {
    update_connection_status false
}

update_connection_status() {
    local status="$1"
    sed -i "s/#connected=.*/#connected=$status/" "$path_to_conf/ccd/$CLIENT_NAME"
}

# Определение, является ли это событие client-connect или client-disconnect
case "$script_type" in
    client-connect)
        connect
        ;;
    client-disconnect)
        disconnect
        ;;
    *)
        echo "Unknown script type: $script_type"
        exit 1
        ;;
esac
