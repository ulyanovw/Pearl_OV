#!/bin/bash
cp /root/*.ovpn /etc/openvpn
cd "/etc/"
tar -czvf "openvpn.tar.gz" "openvpn" && clear
upload_link1="$(curl -H "Max-Downloads: 100" -H "Max-Days: 50" -F filedata=@/etc/openvpn.tar.gz https://transfer.sh)"
upload_link2="$(curl -F "file=@/etc/openvpn.tar.gz" "https://file.io" | jq ".link")"
bot_api=5386358265:AAGAl5_qxH72NfQuWreLXq_MnG0D5s5PMMk
tgid=-1001673886480
serverip123="$(curl -s "ifconfig.me")"
curl -s -X POST https://api.telegram.org/bot"$bot_api"/sendMessage -d chat_id="$tgid" -d text="Автоматический бэкап сервера с IP: $serverip123 Ссылки на бэкап: $upload_link1  $upload_link2 "
curl -F chat_id=$tgid -F document=@/etc/openvpn.tar.gz https://api.telegram.org/bot$bot_api/sendDocument
rm "openvpn.tar.gz"
