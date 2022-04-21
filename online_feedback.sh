#!/bin/bash
server_id=NPBmain
number_of_active=$(cat /etc/openvpn/server/openvpn-status.log | grep CLIENT_LIST | tail -n +2 | grep -c CLIENT_LIST)
bot_api=5386358265:AAGAl5_qxH72NfQuWreLXq_MnG0D5s5PMMk
tgid=-1001673886480
serverip123="$(curl -s "ifconfig.me")"
curl -s -X POST https://api.telegram.org/bot"$bot_api"/sendMessage -d chat_id="$tgid" -d text="Онлайн на сервере $serverip123 : $number_of_active подключений"

