#!/bin/bash

CLIENT_NAME="$common_name"
CLIENT_LOCAL_IP="$ifconfig_pool_remote_ip"
CLIENT_FILE="$path_to_conf/ccd/$CLIENT_NAME"

connect() {
    if [ -f "$CLIENT_FILE" ] && grep -q "#access=granted" "$CLIENT_FILE"; then
        update_connection_status true
        if [ -f "$CLIENT_FILE" ] && grep -q "ifconfig-push" "$CLIENT_FILE"; then
            exit 0
        else
            echo "ifconfig-push $CLIENT_LOCAL_IP 255.255.0.0" >> "$CLIENT_FILE"
        fi
    else
        exit 1
    fi
}

disconnect() {
    update_connection_status false
}

update_connection_status() {
    local status="$1"
    sed -i "s/#connected=.*/#connected=$status/" "$CLIENT_FILE"
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
