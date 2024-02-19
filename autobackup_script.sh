#!/bin/bash

# Подключение файла с переменными
source /usr/lib/pearl/tokens

autobackup(){
    # Получаем список всех OpenVPN инстансов
    instances=($(find /etc/openvpn -maxdepth 1 -type d -name "server-*" -exec basename {} \; | sort))
    server_ip=($(curl ifconfig.me))
    # Проверяем, есть ли инстансы для создания резервной копии
    if [[ "${#instances[@]}" -eq 0 ]]; then
        echo "Отсутствуют OpenVPN инстансы для создания резервной копии."
        return
    fi

    local backup_dir="/root/openvpn_backup"
    local backup_file="openvpn_backup.tar.gz"

    # Создание временной директории для архивации
    mkdir -p "$backup_dir"

    for instance_name in "${instances[@]}"; do
        instance_dir="/etc/openvpn/$instance_name"
        instance_service_dir="/etc/systemd/system"
        instance_iptables_dir="/etc/iptables"
        instance_client_dir="/root/OVPNConfigs/$instance_name"

        # Копирование директории server_part
        mkdir -p "$backup_dir/$instance_name/server_part/"
        cp -r "$instance_dir" "$backup_dir/$instance_name/server_part/$instance_name"

        # Копирование директории service_part
        mkdir -p "$backup_dir/$instance_name/service_part"
        cp "$instance_service_dir/openvpn-$instance_name.service" "$backup_dir/$instance_name/service_part" 
        cp "$instance_service_dir/iptables-openvpn-$instance_name.service" "$backup_dir/$instance_name/service_part"  
        cp "$instance_iptables_dir/add-openvpn-$instance_name.sh" "$backup_dir/$instance_name/service_part"
        cp "$instance_iptables_dir/rm-openvpn-$instance_name.sh" "$backup_dir/$instance_name/service_part"

        # Копирование директории client_part
        mkdir -p "$backup_dir/$instance_name/client_part"
        cp -r "$instance_client_dir" "$backup_dir/$instance_name/client_part/$instance_name"
    done

    # Упаковка архива
    tar -czf "$backup_file" -C "$backup_dir" .

    # Загрузка на файлообменники
    transfersh_upload_link=$(curl -s -F "file=@$backup_file" https://transfer.sh)
    file_io_upload_link=$(curl -F "file=@$backup_file" https://file.io/?expires=1d | jq -r .link)

    # Отправка сообщения в Telegram
    telegram_message="📅 $(date '+%d.%m.%Y %H:%M:%S')"$'\n'
    telegram_message+="Создана резервная копия OpenVPN инстансов на сервере $server_ip."$'\n'
    telegram_message+="Ссылка на transfer.sh: $transfersh_upload_link"$'\n'
    telegram_message+="Ссылка на file.io: $file_io_upload_link"

    # Отправка архива и ссылок в Telegram
    curl -s -F "chat_id=$chat_id" -F "document=@$backup_file" -F "caption=$telegram_message" "https://api.telegram.org/bot$api_token/sendDocument"
    
    # Удаление временной директории
    rm -r "$backup_dir"
    # Очистка экрана
    clear
}

autobackup
