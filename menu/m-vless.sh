#!/bin/bash

#!/bin/bash
clear

# =============================================
#           [ Konfigurasi Warna ]
# =============================================
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export NC='\033[0m'

# =============================================
#          [ Fungsi Pengecekan IP ]
check_ip_and_get_info() {
    local ip=$1
    while IFS= read -r line; do
        # Hapus karakter khusus dan spasi berlebih
        line=$(echo "$line" | tr -d '\r' | sed 's/[^[:print:]]//g' | xargs)
        
        # Split baris menjadi array
        read -ra fields <<< "$line"
        
        
        # Kolom 4 = IP Address (index 3)
        if [[ "${fields[3]}" == "$ip" ]]; then
            client_name="${fields[1]}"  # Kolom 2
            exp_date="${fields[2]}"     # Kolom 3
            
            # Bersihkan tanggal dari karakter khusus
            exp_date=$(echo "$exp_date" | sed 's/[^0-9-]//g' | xargs)
            
            return 0
        fi
    done <<< "$permission_file"
    return 1
}

# =============================================
#          [ Main Script ]
# =============================================

# Ambil data dari GitHub dengan timeout
# --- KONFIGURASI PRIVATE LICENSE HOST (isi sendiri) ---
GH_USER="GANTI_USERNAME_GITHUB_KAMU"
GH_REPO="GANTI_NAMA_REPO_PRIVATE_KAMU"
GH_TOKEN="GANTI_PERSONAL_ACCESS_TOKEN_KAMU"
GH_FILE="gnome"
[ -f /etc/xray/license.conf ] && source /etc/xray/license.conf
permission_file=$(curl -s --connect-timeout 10 \
  -H "Authorization: token $GH_TOKEN" \
  -H "Accept: application/vnd.github.v3.raw" \
  "https://api.github.com/repos/${GH_USER}/${GH_REPO}/contents/${GH_FILE}?ref=main")
# --------------------------------------------------------

# Validasi file permission
if [ -z "$permission_file" ]; then
    echo -e "${RED}❌ Gagal mengambil data lisensi!${NC}"
    exit 1
fi

# Ambil IP VPS dengan metode alternatif
IP_VPS=$(curl -s ipv4.icanhazip.com)

# =============================================
#          [ Pengecekan IP ]
# =============================================
echo -e "${GREEN}⌛ Memeriksa lisensi...${NC}"
if check_ip_and_get_info "$IP_VPS"; then
    
    # Validasi format tanggal ISO 8601
    if ! [[ "$exp_date" =~ ^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$ ]]; then
        echo -e "${RED}❌ Format tanggal invalid: '$exp_date' (harus YYYY-MM-DD)${NC}"
        exit 1
    fi

    # Validasi tanggal menggunakan date
    if ! date -d "$exp_date" "+%s" &>/dev/null; then
        echo -e "${RED}❌ Tanggal tidak valid secara kalender: $exp_date${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ IP tidak terdaftar!${NC}"
    echo -e "➥ Hubungi admin ${CYAN}「 ✦ Admin ✦ 」${NC}"
    exit 1
fi

# =============================================
#          [ Hitung Hari Tersisa ]
# =============================================
current_epoch=$(date +%s)
exp_epoch=$(date -d "$exp_date" +%s)

if (( exp_epoch < current_epoch )); then
    echo -e "${RED}❌ Masa aktif telah habis!${NC}"
    exit 1
fi

days_remaining=$(( (exp_epoch - current_epoch) / 86400 ))

biji=`date +"%Y-%m-%d" -d "$dateFromServer"`
colornow=$(cat /etc/phreakers/theme/color.conf)
NC="\e[0m"
RED="\033[0;31m"
COLOR1="$(cat /etc/phreakers/theme/$colornow | grep -w "TEXT" | cut -d: -f2|sed 's/ //g')"
COLBG1="$(cat /etc/phreakers/theme/$colornow | grep -w "BG" | cut -d: -f2|sed 's/ //g')"
WH='\033[1;37m'
 
ISP=$(cat /etc/xray/isp)
CITY=$(cat /etc/xray/city)
author=$(cat /etc/profil)
TIMES="10"
CHATID=$(cat /etc/per/id)
KEY=$(cat /etc/per/token)
URL="https://api.telegram.org/bot$KEY/sendMessage"
domain=`cat /etc/xray/domain`
CHATID2=$(cat /etc/perlogin/id)
KEY2=$(cat /etc/perlogin/token)
URL2="https://api.telegram.org/bot$KEY2/sendMessage"
cd
if [ ! -e /etc/vless/akun ]; then
mkdir -p /etc/vless/akun
fi
function add-vless(){
clear
until [[ $user =~ ^[a-zA-Z0-9_.-]+$ && ${CLIENT_EXISTS} == '0' ]]; do
echo -e "$COLOR1┌─────────────────────────────────────────────────┐${NC}"
echo -e "$COLOR1│${NC}${COLBG1}            ${WH}• Add Vless Account •                ${NC}$COLOR1│ $NC"
echo -e "$COLOR1└─────────────────────────────────────────────────┘${NC}"
echo -e ""
read -rp "User: " -e user
CLIENT_EXISTS=$(grep -w $user /etc/xray/config.json | wc -l)
if [[ ${CLIENT_EXISTS} == '1' ]]; then
clear
echo -e "$COLOR1┌─────────────────────────────────────────────────┐${NC}"
echo -e "$COLOR1│${NC}${COLBG1}            ${WH}• Add Vless Account •                ${NC}$COLOR1│ $NC"
echo -e "$COLOR1└─────────────────────────────────────────────────┘${NC}"
echo -e "$COLOR1┌─────────────────────────────────────────────────┐${NC}"
echo -e "$COLOR1│                                                 │"
echo -e "$COLOR1│${WH} Nama Duplikat Silahkan Buat Nama Lain.          $COLOR1│"
echo -e "$COLOR1│                                                 │"
echo -e "$COLOR1└─────────────────────────────────────────────────┘${NC}"
read -n 1 -s -r -p "Press any key to back"
add-vless
fi
done
uuid=$(cat /proc/sys/kernel/random/uuid)
until [[ $masaaktif =~ ^[0-9]+$ ]]; do
read -p "Expired (hari): " masaaktif
done
until [[ $iplim =~ ^[0-9]+$ ]]; do
read -p "Limit User (IP) or 0 Unlimited: " iplim
done
until [[ $Quota =~ ^[0-9]+$ ]]; do
read -p "Limit User (GB) or 0 Unlimited: " Quota
done
if [ ! -e /etc/vless ]; then
mkdir -p /etc/vless
fi
if [ ${iplim} = '0' ]; then
iplim="9999"
fi
if [ ${Quota} = '0' ]; then
Quota="9999"
fi
c=$(echo "${Quota}" | sed 's/[^0-9]*//g')
d=$((${c} * 1024 * 1024 * 1024))
if [[ ${c} != "0" ]]; then
echo "${d}" >/etc/vless/${user}
fi
echo "${iplim}" >/etc/vless/${user}IP
exp=`date -d "$masaaktif days" +"%Y-%m-%d"`
sed -i '/#vless$/a\#vl '"$user $exp $uuid"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /etc/xray/config.json
sed -i '/#vlessgrpc$/a\#vlg '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /etc/xray/config.json
sed -i '/#vlessup$/a\#vlup '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /etc/xray/config.json
sed -i '/#vlessxhttp$/a\#vlxh '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /etc/xray/config.json
vlesslink1="vless://${uuid}@${domain}:443?path=/vless&security=tls&encryption=none&host=${domain}&type=ws&sni=${domain}#${user}"
vlesslink2="vless://${uuid}@${domain}:80?path=/vless&security=none&encryption=none&host=${domain}&type=ws#${user}"
vlesslink3="vless://${uuid}@${domain}:443?mode=gun&security=tls&encryption=none&type=grpc&serviceName=vless-grpc&sni=${domain}#${user}"
vlesslink4="vless://${uuid}@${domain}:443?path=/vless-up&security=tls&encryption=none&host=${domain}&type=httpupgrade&sni=${domain}&alpn=http/1.1#${user}"
vlesslink5="vless://${uuid}@${domain}:443?path=/vless-xhttp&security=tls&encryption=none&host=${domain}&type=xhttp&sni=${domain}&alpn=h2,http/1.1#${user}"
vless1="vless://${uuid}@${domain}:443?path=/vless%26security=tls%26encryption=none%26host=${domain}%26type=ws%26sni=${domain}#${user}"
vless2="vless://${uuid}@${domain}:80?path=/vless%26security=none%26encryption=none%26host=${domain}%26type=ws#${user}"
vless3="vless://${uuid}@${domain}:443?mode=gun%26security=tls%26encryption=none%26type=grpc%26serviceName=vless-grpc%26sni=${domain}#${user}"
vless4="vless://${uuid}@${domain}:443?path=/vless-up%26security=tls%26encryption=none%26host=${domain}%26type=httpupgrade%26sni=${domain}%26alpn=http/1.1#${user}"
vless5="vless://${uuid}@${domain}:443?path=/vless-xhttp%26security=tls%26encryption=none%26host=${domain}%26type=xhttp%26sni=${domain}%26alpn=h2,http/1.1#${user}"
cat > /home/vps/public_html/vless-$user.txt <<-END
_______________________________
Format Vless WS (CDN)
_______________________________
- name: vless-$user-WS (CDN)
server: ${domain}
port: 443
type: vless
uuid: ${uuid}
cipher: auto
tls: true
skip-cert-verify: true
servername: ${domain}
network: ws
udp: true
ws-opts:
path: /vless
headers:
Host: ${domain}
_______________________________
Format Vless WS (CDN) Non TLS
_______________________________
- name: vless-$user-WS (CDN) Non TLS
server: ${domain}
port: 80
type: vless
uuid: ${uuid}
cipher: auto
tls: false
skip-cert-verify: false
servername: ${domain}
network: ws
ws-opts:
udp: true
path: /vless
headers:
Host: ${domain}
_______________________________
Format Vless gRPC (SNI)
_______________________________
- name: vless-$user-gRPC (SNI)
server: ${domain}
port: 443
type: vless
uuid: ${uuid}
cipher: auto
tls: true
skip-cert-verify: true
servername: ${domain}
network: grpc
grpc-opts:
grpc-mode: gun
grpc-service-name: vless-grpc
udp: true
_______________________________
Link Vless Account
_______________________________
Link TLS : vless://${uuid}@${domain}:443?path=/vless&security=tls&encryption=none&host=${domain}&type=ws&sni=${domain}#${user}
_______________________________
Link none TLS : vless://${uuid}@${domain}:80?path=/vless&security=none&encryption=none&host=${domain}&type=ws#${user}
_______________________________
Link GRPC : vless://${uuid}@${domain}:443?mode=gun&security=tls&encryption=none&type=grpc&serviceName=vless-grpc&sni=${domain}#${user}
_______________________________
END
if [ ${Quota} = '9999' ]; then
TEXT="
◇━━━━━━━━━━━━━━━━━◇
Premium Vless Account
◇━━━━━━━━━━━━━━━━━◇
User         : ${user}
Domain       : <code>${domain}</code>
Login Limit  : ${iplim} IP
ISP          : ${ISP}
CITY         : ${CITY}
Port TLS     : 443
Port NTLS    : 80, 8080
Port GRPC    : 443
UUID         : <code>${uuid}</code>
AlterId      : 0
Security     : auto
Network      : WS or gRPC
Path vless   : <code>/vless</code>
ServiceName  : <code>/vless-grpc</code>
◇━━━━━━━━━━━━━━━━━◇
Link TLS     :
<code>${vless1}</code>
◇━━━━━━━━━━━━━━━━━◇
Link NTLS    :
<code>${vless2}</code>
◇━━━━━━━━━━━━━━━━━◇
Link gRPC    :
<code>${vless3}</code>
◇━━━━━━━━━━━━━━━━━◇
Link UPGRADE :
<code>${vless4}</code>
◇━━━━━━━━━━━━━━━━━◇
Link XHTTP   :
<code>${vless5}</code>
◇━━━━━━━━━━━━━━━━━◇
Format OpenClash :
http://$domain:89/vless-$user.txt
◇━━━━━━━━━━━━━━━━━◇
Expired Until    : $exp
◇━━━━━━━━━━━━━━━━━◇
 
"
else
TEXT="
◇━━━━━━━━━━━━━━━━━◇
Premium Vless Account
◇━━━━━━━━━━━━━━━━━◇
User         : ${user}
Domain       : <code>${domain}</code>
Login Limit  : ${iplim} IP
Quota Limit  : ${Quota} GB
ISP          : ${ISP}
CITY         : ${CITY}
Port TLS     : 443
Port NTLS    : 80, 8080
Port GRPC    : 443
UUID         : <code>${uuid}</code>
AlterId      : 0
Security     : auto
Network      : WS or gRPC
Path vless   : <code>/vless</code>
ServiceName  : <code>/vless-grpc</code>
◇━━━━━━━━━━━━━━━━━◇
Link TLS     :
<code>${vless1}</code>
◇━━━━━━━━━━━━━━━━━◇
Link NTLS    :
<code>${vless2}</code>
◇━━━━━━━━━━━━━━━━━◇
Link GRPC    :
<code>${vless3}</code>
◇━━━━━━━━━━━━━━━━━◇
Link UPGRADE :
<code>${vless4}</code>
◇━━━━━━━━━━━━━━━━━◇
Link XHTTP   :
<code>${vless5}</code>
◇━━━━━━━━━━━━━━━━━◇
Format OpenClash :
http://$domain:89/vless-$user.txt
◇━━━━━━━━━━━━━━━━━◇
Expired Until    : $exp
◇━━━━━━━━━━━━━━━━━◇
 
"
fi
curl -s --max-time $TIMES -d "chat_id=$CHATID&disable_web_page_preview=1&text=$TEXT&parse_mode=html" $URL >/dev/null
cd
if [ ! -e /etc/tele ]; then
echo -ne
else
echo "$TEXT" > /etc/notiftele
bash /etc/tele
fi
user2=$(echo "$user" | cut -c 1-3)
TIME2=$(date +'%Y-%m-%d %H:%M:%S')
clear
echo -e "$COLOR1 ◇━━━━━━━━━━━━━━━━━◇ ${NC}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${WH}• Premium Vless Account •${NC} $COLOR1 $NC" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ◇━━━━━━━━━━━━━━━━━◇ ${NC}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${WH}User         ${COLOR1}: ${WH}${user}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${WH}ISP          ${COLOR1}: ${WH}$ISP" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${WH}City         ${COLOR1}: ${WH}$CITY" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${WH}Domain       ${COLOR1}: ${WH}${domain}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${WH}Login Limit  ${COLOR1}: ${WH}${iplim} IP" | tee -a /etc/vless/akun/log-create-${user}.log
if [ ${Quota} = '9999' ]; then
echo -ne
else
echo -e "$COLOR1 ${NC} ${WH}Quota Limit  ${COLOR1}: ${WH}${Quota} GB" | tee -a /etc/vless/akun/log-create-${user}.log
fi
echo -e "$COLOR1 ${NC} ${WH}Port TLS     ${COLOR1}: ${WH}443" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${WH}Port NTLS    ${COLOR1}: ${WH}80,8080" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${WH}Port gRPC    ${COLOR1}: ${WH}443" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${WH}UUID         ${COLOR1}: ${WH}${uuid}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${WH}Encryption   ${COLOR1}: ${WH}none" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${WH}Network      ${COLOR1}: ${WH}ws" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${WH}Path         ${COLOR1}: ${WH}/vless" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${WH}Path grpc    ${COLOR1}: ${WH}/vless-grpc" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ◇━━━━━━━━━━━━━━━━━◇ ${NC}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${COLOR1}Link Websocket TLS      ${WH}:${NC}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1${NC}${WH}${vlesslink1}${NC}"  | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ◇━━━━━━━━━━━━━━━━━◇ ${NC}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${COLOR1}Link Websocket NTLS  ${WH}:${NC}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1${NC}${WH}${vlesslink2}${NC}"  | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ◇━━━━━━━━━━━━━━━━━◇ ${NC}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${COLOR1}Link gRPC               ${WH}:${NC}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1${NC}${WH}${vlesslink3}${NC}"  | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ◇━━━━━━━━━━━━━━━━━◇ ${NC}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${COLOR1}Link HTTP UPGRADE       ${WH}:${NC}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1${NC}${WH}${vlesslink4}${NC}"  | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ◇━━━━━━━━━━━━━━━━━◇ ${NC}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${COLOR1}Link xHTTP              ${WH}:${NC}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1${NC}${WH}${vlesslink5}${NC}"  | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ◇━━━━━━━━━━━━━━━━━◇ ${NC}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${WH}Format Openclash ${COLOR1}: " | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${WH}http://$domain:89/vless-$user.txt${NC}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ◇━━━━━━━━━━━━━━━━━◇ ${NC}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${WH}Expired Until   ${COLOR1}: ${WH}$exp" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ◇━━━━━━━━━━━━━━━━━◇ ${NC}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${WH} • BLACK MAGIC STORE •    " | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ◇━━━━━━━━━━━━━━━━━◇ ${NC}" | tee -a /etc/vless/akun/log-create-${user}.log
echo "" | tee -a /etc/vless/akun/log-create-${user}.log
mkdir -p /etc/vless/akun
cat > /etc/vless/akun/${user} << EOF
username=${user}
limit_quota=${Quota}GB
usage_quota=0MB
login_time=$(date +'%H:%M:%S.%N')
login_ip=0
EOF
systemctl restart xray > /dev/null 2>&1
read -n 1 -s -r -p "Press any key to back on menu"
menu
}
function trial-vless(){
clear
cd
echo -e "$COLOR1┌─────────────────────────────────────────────────┐${NC}"
echo -e "$COLOR1 ${NC}${COLBG1}            ${WH}• Trial Vless Account •             ${NC} $COLOR1 $NC"
echo -e "$COLOR1└─────────────────────────────────────────────────┘${NC}"
until [[ $timer =~ ^[0-9]+$ ]]; do
read -p "Expired (Minutes): " timer
done
if ! [[ "$timer" =~ ^[0-9]+$ ]] || [ "$timer" -lt 1 ]; then
    timer=5
fi
user=Trial-`</dev/urandom tr -dc X-Z0-9 | head -c4`
uuid=$(cat /proc/sys/kernel/random/uuid)
masaaktif=0
iplim=1
Quota=10
if [ ! -e /etc/vless ]; then
mkdir -p /etc/vless
fi
c=$(echo "${Quota}" | sed 's/[^0-9]*//g')
d=$((${c} * 1024 * 1024 * 1024))
if [[ ${c} != "0" ]]; then
echo "${d}" >/etc/vless/${user}
fi
echo "${iplim}" > /etc/vless/${user}IP
exp=`date -d "$masaaktif days" +"%Y-%m-%d"`
sed -i '/#vless$/a\#vl '"$user $exp $uuid"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /etc/xray/config.json
sed -i '/#vlessgrpc$/a\#vlg '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /etc/xray/config.json
sed -i '/#vlessup$/a\#vlup '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /etc/xray/config.json
sed -i '/#vlessxhttp$/a\#vlxh '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /etc/xray/config.json
vlesslink1="vless://${uuid}@${domain}:443?path=/vless&security=tls&encryption=none&host=${domain}&type=ws&sni=${domain}#${user}"
vlesslink2="vless://${uuid}@${domain}:80?path=/vless&security=none&encryption=none&host=${domain}&type=ws#${user}"
vlesslink3="vless://${uuid}@${domain}:443?mode=gun&security=tls&encryption=none&type=grpc&serviceName=vless-grpc&sni=${domain}#${user}"
vlesslink4="vless://${uuid}@${domain}:443?path=/vless-up&security=tls&encryption=none&host=${domain}&type=httpupgrade&sni=${domain}&alpn=http/1.1#${user}"
vlesslink5="vless://${uuid}@${domain}:443?path=/vless-xhttp&security=tls&encryption=none&host=${domain}&type=xhttp&sni=${domain}&alpn=h2,http/1.1#${user}"
vless1="vless://${uuid}@${domain}:443?path=/vless%26security=tls%26encryption=none%26host=${domain}%26type=ws%26sni=${domain}#${user}"
vless2="vless://${uuid}@${domain}:80?path=/vless%26security=none%26encryption=none%26host=${domain}%26type=ws#${user}"
vless3="vless://${uuid}@${domain}:443?mode=gun%26security=tls%26encryption=none%26type=grpc%26serviceName=vless-grpc%26sni=${domain}#${user}"
vless4="vless://${uuid}@${domain}:443?path=/vless-up%26security=tls%26encryption=none%26host=${domain}%26type=httpupgrade%26sni=${domain}%26alpn=http/1.1#${user}"
vless5="vless://${uuid}@${domain}:443?path=/vless-xhttp%26security=tls%26encryption=none%26host=${domain}%26type=xhttp%26sni=${domain}%26alpn=h2,http/1.1#${user}"
clear
cat> /etc/cron.d/trialvless${user} << END
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/$timer * * * * root /usr/bin/trial vless $user $uuid $exp
END
cat > /home/vps/public_html/vless-$user.txt <<-END
_______________________________
Format Vless WS (CDN)
_______________________________
- name: vless-$user-WS (CDN)
server: ${domain}
port: 443
type: vless
uuid: ${uuid}
cipher: auto
tls: true
skip-cert-verify: true
servername: ${domain}
network: ws
udp: true
ws-opts:
path: /vless
headers:
Host: ${domain}
_______________________________
Format Vless WS (CDN) Non TLS
_______________________________
- name: vless-$user-WS (CDN) Non TLS
server: ${domain}
port: 80
type: vless
uuid: ${uuid}
cipher: auto
tls: false
skip-cert-verify: false
servername: ${domain}
network: ws
ws-opts:
udp: true
path: /vless
headers:
Host: ${domain}
_______________________________
Format Vless gRPC (SNI)
_______________________________
- name: vless-$user-gRPC (SNI)
server: ${domain}
port: 443
type: vless
uuid: ${uuid}
cipher: auto
tls: true
skip-cert-verify: true
servername: ${domain}
network: grpc
grpc-opts:
grpc-mode: gun
grpc-service-name: vless-grpc
udp: true
_______________________________
Link Vless Account
_______________________________
Link TLS : vless://${uuid}@${domain}:443?path=/vless&security=tls&encryption=none&host=${domain}&type=ws&sni=${domain}#${user}
_______________________________
Link NTLS : vless://${uuid}@${domain}:80?path=/vless&security=none&encryption=none&host=${domain}&type=ws#${user}
_______________________________
Link gRPC : vless://${uuid}@${domain}:443?mode=gun&security=tls&encryption=none&type=grpc&serviceName=vless-grpc&sni=${domain}#${user}
_______________________________
END
TEXT="
◇━━━━━━━━━━━━━━━━━◇
Trial Premium Vless Account
◇━━━━━━━━━━━━━━━━━◇
User         : ${user}
Domain       : <code>${domain}</code>
Login Limit  : ${iplim} IP
ISP          : ${ISP}
CITY         : ${CITY}
Port TLS     : 443
Port NTLS    : 80, 8080
Port GRPC    : 443
UUID         : <code>${uuid}</code>
AlterId      : 0
Security     : auto
Network      : WS or gRPC
Path vless   : <code>/vless</code>
ServiceName  : <code>/vless-grpc</code>
◇━━━━━━━━━━━━━━━━━◇
Link TLS     :
<code>${vless1}</code>
◇━━━━━━━━━━━━━━━━━◇
Link NTLS    :
<code>${vless2}</code>
◇━━━━━━━━━━━━━━━━━◇
Link GRPC    :
<code>${vless3}</code>
◇━━━━━━━━━━━━━━━━━◇
Link UPGRADE :
<code>${vless4}</code>
◇━━━━━━━━━━━━━━━━━◇
Link XHTTP   :
<code>${vless5}</code>
◇━━━━━━━━━━━━━━━━━◇
Format OpenClash :
http://$domain:89/vless-$user.txt
◇━━━━━━━━━━━━━━━━━◇
Expired Until    : $timer Minutes
◇━━━━━━━━━━━━━━━━━◇
 
"
curl -s --max-time $TIMES -d "chat_id=$CHATID&disable_web_page_preview=1&text=$TEXT&parse_mode=html" $URL >/dev/null
cd
if [ ! -e /etc/tele ]; then
echo -ne
else
echo "$TEXT" > /etc/notiftele
bash /etc/tele
fi
clear
echo -e "$COLOR1 ◇━━━━━━━━━━━━━━━━━◇ ${NC}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${WH}• Trial Premium Vless Account •${NC} $COLOR1 $NC" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ◇━━━━━━━━━━━━━━━━━◇ ${NC}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${WH}User         ${COLOR1}: ${WH}${user}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${WH}ISP          ${COLOR1}: ${WH}$ISP" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${WH}City         ${COLOR1}: ${WH}$CITY" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${WH}Domain       ${COLOR1}: ${WH}${domain}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${WH}Login Limit  ${COLOR1}: ${WH}${iplim} IP" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${WH}Port TLS     ${COLOR1}: ${WH}443" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${WH}Port NTLS    ${COLOR1}: ${WH}80,8080" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${WH}Port gRPC    ${COLOR1}: ${WH}443" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${WH}UUID         ${COLOR1}: ${WH}${uuid}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${WH}Encryption   ${COLOR1}: ${WH}none" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${WH}Network      ${COLOR1}: ${WH}ws" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${WH}Path         ${COLOR1}: ${WH}/vless" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${WH}Path grpc    ${COLOR1}: ${WH}/vless-grpc" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ◇━━━━━━━━━━━━━━━━━◇ ${NC}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${COLOR1}Link Websocket TLS      ${WH}:${NC}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1${NC}${WH}${vlesslink1}${NC}"  | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ◇━━━━━━━━━━━━━━━━━◇ ${NC}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${COLOR1}Link Websocket NTLS  ${WH}:${NC}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1${NC}${WH}${vlesslink2}${NC}"  | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ◇━━━━━━━━━━━━━━━━━◇ ${NC}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${COLOR1}Link gRPC               ${WH}:${NC}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1${NC}${WH}${vlesslink3}${NC}"  | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ◇━━━━━━━━━━━━━━━━━◇ ${NC}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${COLOR1}Link HTTP UPGRADE       ${WH}:${NC}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1${NC}${WH}${vlesslink4}${NC}"  | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ◇━━━━━━━━━━━━━━━━━◇ ${NC}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${COLOR1}Link xHTTP              ${WH}:${NC}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1${NC}${WH}${vlesslink5}${NC}"  | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ◇━━━━━━━━━━━━━━━━━◇ ${NC}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${WH}Format Openclash ${COLOR1}: " | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${WH}http://$domain:89/vless-$user.txt${NC}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ◇━━━━━━━━━━━━━━━━━◇ ${NC}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${WH}Expired Until   ${COLOR1}: ${WH}$timer Minutes" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ◇━━━━━━━━━━━━━━━━━◇ ${NC}" | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ${NC} ${WH}    • BLACK MAGIC STORE •    " | tee -a /etc/vless/akun/log-create-${user}.log
echo -e "$COLOR1 ◇━━━━━━━━━━━━━━━━━◇ ${NC}" | tee -a /etc/vless/akun/log-create-${user}.log
echo "" | tee -a /etc/vless/akun/log-create-${user}.log
systemctl restart xray > /dev/null 2>&1
read -n 1 -s -r -p "Press any key to back on menu"
menu
}
function limit-vless(){
clear
NUMBER_OF_CLIENTS=$(grep -c -E "^#vlg " "/etc/xray/config.json")
if [[ ${NUMBER_OF_CLIENTS} == '0' ]]; then
clear
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "$COLOR1 ${NC} ${COLBG1}    ${WH}⇱ Limit Vless Account ⇲     ${NC} $COLOR1 $NC"
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "You have no existing clients!"
echo ""
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
read -n 1 -s -r -p "Press any key to back on menu"
m-vless
fi
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "$COLOR1 ${NC} ${COLBG1}    ${WH}⇱ Limit Vless Account ⇲     ${NC} $COLOR1 $NC"
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "Select the existing client you want to change ip"
echo " ketik [0] kembali kemenu"
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "     No  User   Expired"
grep -E "^#vlg " "/etc/xray/config.json" | cut -d ' ' -f 2-3 | nl -s ') '
until [[ ${CLIENT_NUMBER} -ge 1 && ${CLIENT_NUMBER} -le ${NUMBER_OF_CLIENTS} ]]; do
if [[ ${CLIENT_NUMBER} == '1' ]]; then
read -rp "Select one client [1]: " CLIENT_NUMBER
else
read -rp "Select one client [1-${NUMBER_OF_CLIENTS}]: " CLIENT_NUMBER
if [[ ${CLIENT_NUMBER} == '0' ]]; then
m-vless
fi
fi
done
clear
until [[ $iplim =~ ^[0-9]+$ ]]; do
read -p "Limit User (IP) or 0 Unlimited: " iplim
done
until [[ $Quota =~ ^[0-9]+$ ]]; do
read -p "Limit User (GB) or 0 Unlimited: " Quota
done
if [ ! -e /etc/vless ]; then
mkdir -p /etc/vless
fi
if [ ${iplim} = '0' ]; then
iplim="9999"
fi
if [ ${Quota} = '0' ]; then
Quota="9999"
fi
user=$(grep -E "^#vlg " "/etc/xray/config.json" | cut -d ' ' -f 2 | sed -n "${CLIENT_NUMBER}"p)
c=$(echo "${Quota}" | sed 's/[^0-9]*//g')
d=$((${c} * 1024 * 1024 * 1024))
echo "${iplim}" >/etc/vless/${user}IP
if [[ ${c} != "0" ]]; then
echo "${d}" >/etc/vless/${user}
fi
TEXT="
<code>◇━━━━━━━━━━━━━━◇</code>
<b>  XRAY VLESS IP LIMIT</b>
<code>◇━━━━━━━━━━━━━━◇</code>
<b>DOMAIN   :</b> <code>${domain} </code>
<b>ISP      :</b> <code>$ISP $CITY </code>
<b>USERNAME :</b> <code>$user </code>
<b>IP LIMIT NEW :</b> <code>$iplim IP </code>
<b>QUOTA LIMIT NEW :</b> <code>$Quota GB </code>
<code>◇━━━━━━━━━━━━━━◇</code>
<i>Succes Change IP LIMIT...</i>
"
curl -s --max-time $TIMES -d "chat_id=$CHATID&disable_web_page_preview=1&text=$TEXT&parse_mode=html" $URL >/dev/null
cd
if [ ! -e /etc/tele ]; then
echo -ne
else
echo "$TEXT" > /etc/notiftele
bash /etc/tele
fi
clear
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo " VLESS Account Was Successfully Change Limit IP"
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo " Client Name : $user"
echo " Limit IP    : $iplim IP"
echo " Limit Quota : $Quota GB"
echo ""
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
read -n 1 -s -r -p "Press any key to back on menu"
m-vless
}
function renew-vless(){
clear
NUMBER_OF_CLIENTS=$(grep -c -E "^#vl " "/etc/xray/config.json")
if [[ ${NUMBER_OF_CLIENTS} == '0' ]]; then
clear
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "$COLOR1 ${NC}${COLBG1}    ${WH}⇱ Renew Vless Account ⇲      ${NC} $COLOR1 $NC"
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "You have no existing clients!"
echo ""
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
read -n 1 -s -r -p "Press any key to back on menu"
m-vless
fi
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "$COLOR1 ${NC}${COLBG1}     ${WH}⇱ Renew Vless Account ⇲      ${NC} $COLOR1 $NC"
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo " Select the existing client you want to renew"
echo " ketik [0] kembali kemenu"
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "     No  User   Expired"
grep -E "^#vl " "/etc/xray/config.json" | cut -d ' ' -f 2-3 | nl -s ') '
until [[ ${CLIENT_NUMBER} -ge 1 && ${CLIENT_NUMBER} -le ${NUMBER_OF_CLIENTS} ]]; do
if [[ ${CLIENT_NUMBER} == '1' ]]; then
read -rp "Select one client [1]: " CLIENT_NUMBER
else
read -rp "Select one client [1-${NUMBER_OF_CLIENTS}]: " CLIENT_NUMBER
if [[ ${CLIENT_NUMBER} == '0' ]]; then
m-vless
fi
fi
done
read -p "Expired (days): " masaaktif
user=$(grep -E "^#vl " "/etc/xray/config.json" | cut -d ' ' -f 2 | sed -n "${CLIENT_NUMBER}"p)
exp=$(grep -E "^#vl " "/etc/xray/config.json" | cut -d ' ' -f 3 | sed -n "${CLIENT_NUMBER}"p)
now=$(date +%Y-%m-%d)
d1=$(date -d "$exp" +%s)
d2=$(date -d "$now" +%s)
exp2=$(( (d1 - d2) / 86400 ))
exp3=$(($exp2 + $masaaktif))
exp4=`date -d "$exp3 days" +"%Y-%m-%d"`
sed -i "s/#vl $user $exp/#vl $user $exp4/g" /etc/xray/config.json
sed -i "s/#vlg $user $exp/#vlg $user $exp4/g" /etc/xray/config.json
sed -i "s/#vlup $user $exp/#vlup $user $exp4/g" /etc/xray/config.json
sed -i "s/#vlxh $user $exp/#vlxh $user $exp4/g" /etc/xray/config.json
clear
TEXT="
<code>◇━━━━━━━━━━━━━━◇</code>
<b>   XRAY VLESS RENEW</b>
<code>◇━━━━━━━━━━━━━━◇</code>
<b>DOMAIN   :</b> <code>${domain} </code>
<b>ISP      :</b> <code>$ISP $CITY </code>
<b>USERNAME :</b> <code>$user </code>
<b>EXPIRED  :</b> <code>$exp4 </code>
<code>◇━━━━━━━━━━━━━━◇</code>
"
curl -s --max-time $TIMES -d "chat_id=$CHATID&disable_web_page_preview=1&text=$TEXT&parse_mode=html" $URL >/dev/null
cd
if [ ! -e /etc/tele ]; then
echo -ne
else
echo "$TEXT" > /etc/notiftele
bash /etc/tele
fi
user2=$(echo "$user" | cut -c 1-3)
TIME2=$(date +'%Y-%m-%d %H:%M:%S')
TEXT2="
<code>◇━━━━━━━━━━━━━━◇</code>
<b>   PEMBELIAN VLESS SUCCES </b>
<code>◇━━━━━━━━━━━━━━◇</code>
<b>DOMAIN   :</b> <code>${domain} </code>
<b>ISP      :</b> <code>$ISP $CITY </code>
<b>DATE   :</b> <code>${TIME2} WIB </code>
<b>DETAIL   :</b> <code>Trx VLESS </code>
<b>USER :</b> <code>${user2}xxx </code>
<b>DURASI  :</b> <code>$masaaktif Hari </code>
<code>◇━━━━━━━━━━━━━━◇</code>
<i>Renew Account From Server..</i>
"
curl -s --max-time $TIMES -d "chat_id=$CHATID2&disable_web_page_preview=1&text=$TEXT2&parse_mode=html" $URL2 >/dev/null
clear
systemctl restart xray > /dev/null 2>&1
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo " VLESS Account Was Successfully Renewed"
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo " Client Name : $user"
echo " Expired On  : $exp4"
echo ""
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
read -n 1 -s -r -p "Press any key to back on menu"
m-vless
}
function del-vless(){
clear
NUMBER_OF_CLIENTS=$(grep -c -E "^#vl " "/etc/xray/config.json")
if [[ ${NUMBER_OF_CLIENTS} == '0' ]]; then
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "$COLOR1 ${NC}${COLBG1}    ${WH}⇱ Delete Vless Account ⇲     ${NC} $COLOR1 $NC"
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "You have no existing clients!"
echo ""
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
read -n 1 -s -r -p "Press any key to back on menu"
m-vless
fi
clear
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "$COLOR1 ${NC}${COLBG1}    ${WH}⇱ Delete Vless Account ⇲     ${NC} $COLOR1 $NC"
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo " Select the existing client you want to remove"
echo " ketik [0] kembali kemenu"
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "     No  User   Expired"
grep -E "^#vl " "/etc/xray/config.json" | cut -d ' ' -f 2-3 | nl -s ') '
until [[ ${CLIENT_NUMBER} -ge 1 && ${CLIENT_NUMBER} -le ${NUMBER_OF_CLIENTS} ]]; do
if [[ ${CLIENT_NUMBER} == '1' ]]; then
read -rp "Select one client [1]: " CLIENT_NUMBER
else
read -rp "Select one client [1-${NUMBER_OF_CLIENTS}]: " CLIENT_NUMBER
if [[ ${CLIENT_NUMBER} == '0' ]]; then
m-vless
fi
fi
done
user=$(grep -E "^#vl " "/etc/xray/config.json" | cut -d ' ' -f 2 | sed -n "${CLIENT_NUMBER}"p)
exp=$(grep -E "^#vl " "/etc/xray/config.json" | cut -d ' ' -f 3 | sed -n "${CLIENT_NUMBER}"p)
uuid=$(grep -E "^#vl " "/etc/xray/config.json" | cut -d ' ' -f 4 | sed -n "${CLIENT_NUMBER}"p)
if [ ! -e /etc/vless/akundelete ]; then
echo "" > /etc/vless/akundelete
fi
clear
echo "### $user $exp $uuid" >> /etc/vless/akundelete
sed -i "/^#vl $user $exp/,/^},{/d" /etc/xray/config.json
sed -i "/^#vlg $user $exp/,/^},{/d" /etc/xray/config.json
sed -i "/^#vlup $user $exp/,/^},{/d" /etc/xray/config.json
sed -i "/^#vlxh $user $exp/,/^},{/d" /etc/xray/config.json
clear
clear
rm /etc/vless/${user}IP >/dev/null 2>&1
rm /home/vps/public_html/vless-$user.txt >/dev/null 2>&1
rm /etc/vless/${user}login >/dev/null 2>&1
systemctl restart xray > /dev/null 2>&1
clear
TEXT="
<code>◇━━━━━━━━━━━━━━◇</code>
<b>  XRAY VLESS DELETE</b>
<code>◇━━━━━━━━━━━━━━◇</code>
<b>DOMAIN   :</b> <code>${domain} </code>
<b>ISP      :</b> <code>$ISP $CITY </code>
<b>USERNAME :</b> <code>$user </code>
<b>EXPIRED :</b> <code>$exp </code>
<code>◇━━━━━━━━━━━━━━◇</code>
<i>Succes Delete this Username...</i>
"
curl -s --max-time $TIMES -d "chat_id=$CHATID&disable_web_page_preview=1&text=$TEXT&parse_mode=html" $URL >/dev/null
cd
if [ ! -e /etc/tele ]; then
echo -ne
else
echo "$TEXT" > /etc/notiftele
bash /etc/tele
fi
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo " Vless Account Deleted Successfully"
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo " Client Name : $user"
echo " Expired On  : $exp"
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
read -n 1 -s -r -p "Press any key to back on menu"
m-vless
}
tim2sec() {
mult=1
arg="$1"
inu=0
while [ ${#arg} -gt 0 ]; do
prev="${arg%:*}"
if [ "$prev" = "$arg" ]; then
curr="${arg#0}"
prev=""
else
curr="${arg##*:}"
curr="${curr#0}"
fi
curr="${curr%.*}"
inu=$((inu + curr * mult))
mult=$((mult * 60))
arg="$prev"
done
echo "$inu"
}
function convert() {
local -i bytes=$1
if [[ $bytes -lt 1024 ]]; then
echo "${bytes} B"
elif [[ $bytes -lt 1048576 ]]; then
echo "$(((bytes + 1023) / 1024)) KB"
elif [[ $bytes -lt 1073741824 ]]; then
echo "$(((bytes + 1048575) / 1048576)) MB"
else
echo "$(((bytes + 1073741823) / 1073741824)) GB"
fi
}
function cek-vless() {
    clear
    
    # ANSI Color Codes
    COLOR_RESET="\e[0m"
    COLOR_GREEN="\e[32m"
    COLOR_RED="\e[31m"
    COLOR_YELLOW="\e[33m"
    COLOR_CYAN="\e[36m"
    COLOR_WHITE="\e[37m"

    # Restart Xray jika log kurang dari 5
    xrayy=$(cat /var/log/xray/access.log | wc -l)
    [[ $xrayy -le 5 ]] && systemctl restart xray

    xraylimit

    # Mendapatkan daftar semua pengguna vless
    vm=($(cat /etc/xray/config.json | grep "^#vlg" | awk '{print $2}' | sort -u))

    # Proses data dan tampilkan
    if [[ ${#vm[@]} -eq 0 ]]; then
        echo -e "${COLOR_WHITE}┌──────────────────────────────────────────────────────────┐${COLOR_RESET}"
        echo -e "${COLOR_WHITE}│                  Tidak ada pengguna VLESS                │${COLOR_RESET}"
        echo -e "${COLOR_WHITE}└──────────────────────────────────────────────────────────┘${COLOR_RESET}"
    else
        for user in "${vm[@]}"; do
            # Mendapatkan data penggunaan
            used_bytes=$(cat /etc/limit/vless/"${user}" 2>/dev/null || echo 0)
            limit_bytes=$(cat /etc/vless/"${user}" 2>/dev/null || echo 0)
            
            # Konversi bytes ke GB
            used_gb=$(awk "BEGIN {printf \"%.2f\", $used_bytes / 1024^3}")
            limit_gb=$(awk "BEGIN {printf \"%.2f\", $limit_bytes / 1024^3}")
            
            # Menghitung sisa kuota
            if [[ "$limit_bytes" -gt 0 ]]; then
                remaining_gb=$(awk "BEGIN {printf \"%.2f\", ($limit_bytes - $used_bytes) / 1024^3}")
            else
                remaining_gb="Unlimited"
            fi

            # Cek status online (logika yang lebih spesifik)
            # Periksa log 100 baris terakhir untuk aktivitas
            last_activity=$(grep -w "email: ${user}" /var/log/xray/access.log | tail -n 1)
            is_online=false
            if [[ -n "$last_activity" ]]; then
                # Dapatkan timestamp dari log
                timestamp_log=$(echo "$last_activity" | awk '{print $2}')
                
                # Konversi timestamp ke detik
                timestamp_sec=$(date -d "${timestamp_log}" +%s)
                
                # Waktu sekarang dalam detik
                now_sec=$(date +%s)
                
                # Jika aktivitas kurang dari 120 detik (2 menit) lalu
                if (( (now_sec - timestamp_sec) < 120 )); then
                    is_online=true
                fi
            fi

            # Tentukan status dan warna
            if $is_online; then
                status_symbol="${COLOR_GREEN}● Online${COLOR_RESET}"
            else
                status_symbol="${COLOR_RED}● Offline${COLOR_RESET}"
            fi

            # Dapatkan IP login
            login_ip_count=$(grep -w "email: ${user}" /var/log/xray/access.log | awk '{print $3}' | sed 's/tcp:\/\///g' | sort -u | wc -l)

            # Tampilkan output
            echo -e "${COLOR_WHITE}┌─${COLOR_CYAN}[ ${user} ${COLOR_WHITE}| Tipe: vless ]─┐${COLOR_RESET}"
            echo -e "${COLOR_WHITE}│${COLOR_RESET} 🚦 Status      : ${status_symbol}"
            echo -e "${COLOR_WHITE}│${COLOR_RESET} 📥 Terpakai    : ${COLOR_YELLOW}${used_gb}GB${COLOR_RESET}"
            echo -e "${COLOR_WHITE}│${COLOR_RESET} 📈 Batas Kuota : ${COLOR_GREEN}${limit_gb}GB${COLOR_RESET}"
            echo -e "${COLOR_WHITE}│${COLOR_RESET} 📊 Sisa Kuota  : ${COLOR_CYAN}${remaining_gb}GB${COLOR_RESET}"
            echo -e "${COLOR_WHITE}│${COLOR_RESET} 💻 Login IP    : ${COLOR_WHITE}${login_ip_count}${COLOR_RESET}"
            echo -e "${COLOR_WHITE}└───────────────────────────────────────────────┘${COLOR_RESET}"
            echo ""
        done
    fi
    
    read -n 1 -s -r -p "     Press any key to back on menu"
    m-vless
}
function list-vless(){
clear
NUMBER_OF_CLIENTS=$(grep -c -E "^#vl " "/etc/xray/config.json")
if [[ ${NUMBER_OF_CLIENTS} == '0' ]]; then
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "$COLOR1 ${NC}${COLBG1}    ${WH}⇱ Config Vless Account ⇲     ${NC} $COLOR1 $NC"
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "You have no existing clients!"
echo ""
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
read -n 1 -s -r -p "Press any key to back on menu"
m-vless
fi
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "$COLOR1 ${NC}${COLBG1}    ${WH}⇱ Config Vless Account ⇲     ${NC} $COLOR1 $NC"
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo " Select the existing client to view the config"
echo " ketik [0] kembali kemenu"
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

echo -e "     No  User                 Expired       Sisa Hari"
echo -e "     ──────────────────────────────────────────────────"
now_date=$(date +%Y-%m-%d)
d_now=$(date -d "$now_date" +%s)
num=1

while read -r _ user exp _; do
    d_exp=$(date -d "$exp" +%s 2>/dev/null || echo 0)
    if [[ $d_exp -gt 0 ]]; then
        sisa=$(( (d_exp - d_now) / 86400 ))
        if [[ $sisa -lt 0 ]]; then
            sisa_str="${RED}Expired${NC}"
        elif [[ $sisa -eq 0 ]]; then
            sisa_str="${YELLOW}Hari ini${NC}"
        else
            sisa_str="${GREEN}${sisa} Hari${NC}"
        fi
    else
        sisa_str="-"
    fi
    printf "     %2d) %-20s %-12s %b\n" "$num" "$user" "$exp" "$sisa_str"
    ((num++))
done < <(grep -E "^#vl " "/etc/xray/config.json")

until [[ ${CLIENT_NUMBER} -ge 1 && ${CLIENT_NUMBER} -le ${NUMBER_OF_CLIENTS} ]]; do
if [[ ${CLIENT_NUMBER} == '1' ]]; then
read -rp "Select one client [1]: " CLIENT_NUMBER
else
read -rp "Select one client [1-${NUMBER_OF_CLIENTS}]: " CLIENT_NUMBER
if [[ ${CLIENT_NUMBER} == '0' ]]; then
m-vless
fi
fi
done
clear
user=$(grep -E "^#vl " "/etc/xray/config.json" | cut -d ' ' -f 2 | sed -n "${CLIENT_NUMBER}"p)
cat /etc/vless/akun/log-create-${user}.log
cat /etc/vless/akun/log-create-${user}.log > /etc/notifakun
sed -i 's/\x1B\[1;37m//g' /etc/notifakun
sed -i 's/\x1B\[0;96m//g' /etc/notifakun
sed -i 's/\x1B\[0m//g' /etc/notifakun
TEXT=$(cat /etc/notifakun)
curl -s --max-time $TIMES -d "chat_id=$CHATID&disable_web_page_preview=1&text=$TEXT&parse_mode=html" $URL >/dev/null
cd
if [ ! -e /etc/tele ]; then
echo -ne
else
echo "$TEXT" > /etc/notiftele
bash /etc/tele
fi
read -n 1 -s -r -p "Press any key to back on menu"
m-vless
}
function login-vless(){
clear
echo -e "$COLOR1┌───────────────────────────────────────────────┐${NC}"
echo -e "$COLOR1│${NC}${COLBG1}           ${WH}• SETTING MULTI LOGIN •             ${NC}$COLOR1│ $NC"
echo -e "$COLOR1└───────────────────────────────────────────────┘${NC}"
echo -e "$COLOR1┌───────────────────────────────────────────────┐${NC}"
echo -e "${COLOR1}│ $NC SILAHKAN TULIS JUMLAH NOTIFIKASI UNTUK LOCK    ${NC}"
echo -e "${COLOR1}│ $NC AKUN USER YANG MULTI LOGIN     ${NC}"
echo -e "$COLOR1└───────────────────────────────────────────────┘${NC}"
read -rp "   Jika Mau 3x Notif baru kelock tulis 3, dst: " -e notif
cd /etc/vless
echo "$notif" > notif
clear
echo -e "$COLOR1┌───────────────────────────────────────────────┐${NC}"
echo -e "$COLOR1│${NC}${COLBG1}           ${WH}• SETTING MULTI LOGIN •             ${NC}$COLOR1│ $NC"
echo -e "$COLOR1└───────────────────────────────────────────────┘${NC}"
echo -e "$COLOR1┌───────────────────────────────────────────────┐${NC}"
echo -e "${COLOR1}│ $NC SUCCES GANTI NOTIF LOCK JADI $notif $NC "
echo -e "$COLOR1└───────────────────────────────────────────────┘${NC}"
m-vless
}
function lock-vless(){
cd
clear
if [ ! -e /etc/vless/listlock ]; then
echo "" > /etc/vless/listlock
fi
NUMBER_OF_CLIENTS=$(grep -c -E "^### " "/etc/vless/listlock")
if [[ ${NUMBER_OF_CLIENTS} == '0' ]]; then
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "$COLOR1 ${NC}${COLBG1}    ${WH}⇱ Unlock Vless Account ⇲     ${NC} $COLOR1 $NC"
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "You have no existing user Lock!"
echo ""
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
read -n 1 -s -r -p "Press any key to back on menu"
m-vless
fi
clear
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "$COLOR1 ${NC}${COLBG1}    ${WH}⇱ Unlock Vless Account ⇲     ${NC} $COLOR1 $NC"
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo " Select the existing client you want to Unlock"
echo " ketik [0] kembali kemenu"
echo " ketik [999] untuk delete semua Akun"
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "     No  User   Expired"
grep -E "^### " "/etc/vless/listlock" | cut -d ' ' -f 2-3 | nl -s ') '
until [[ ${CLIENT_NUMBER} -ge 1 && ${CLIENT_NUMBER} -le ${NUMBER_OF_CLIENTS} ]]; do
if [[ ${CLIENT_NUMBER} == '1' ]]; then
read -rp "Select one client [1]: " CLIENT_NUMBER
else
read -rp "Select one client [1-${NUMBER_OF_CLIENTS}] to Unlock: " CLIENT_NUMBER
if [[ ${CLIENT_NUMBER} == '0' ]]; then
m-vless
fi
if [[ ${CLIENT_NUMBER} == '999' ]]; then
rm /etc/vless/listlock
m-vless
fi
fi
done
user=$(grep -E "^### " "/etc/vless/listlock" | cut -d ' ' -f 2 | sed -n "${CLIENT_NUMBER}"p)
exp=$(grep -E "^### " "/etc/vless/listlock" | cut -d ' ' -f 3 | sed -n "${CLIENT_NUMBER}"p)
uuid=$(grep -E "^### " "/etc/vless/listlock" | cut -d ' ' -f 4 | sed -n "${CLIENT_NUMBER}"p)
sed -i '/#vless$/a\#vl '"$user $exp $uuid"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /etc/xray/config.json
sed -i '/#vlessgrpc$/a\#vlg '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /etc/xray/config.json
sed -i '/#vlessup$/a\#vlup '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /etc/xray/config.json
sed -i '/#vlessxhttp$/a\#vlxh '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /etc/xray/config.json
sed -i "/^### $user $exp $uuid/d" /etc/vless/listlock

systemctl restart xray
TEXT="
<code>◇━━━━━━━━━━━━━━◇</code>
<b>  XRAY VLESS UNLOCKED</b>
<code>◇━━━━━━━━━━━━━━◇</code>
<b>DOMAIN   :</b> <code>${domain} </code>
<b>ISP      :</b> <code>$ISP $CITY </code>
<b>USERNAME :</b> <code>$user </code>
<b>EXPIRED  :</b> <code>$exp </code>
<code>◇━━━━━━━━━━━━━━◇</code>
<i>Succes Unlocked This Akun...</i>
"
curl -s --max-time $TIMES -d "chat_id=$CHATID&disable_web_page_preview=1&text=$TEXT&parse_mode=html" $URL >/dev/null
cd
if [ ! -e /etc/tele ]; then
echo -ne
else
echo "$TEXT" > /etc/notiftele
bash /etc/tele
fi
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo " Vless Account Unlock Successfully"
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo " Client Name : $user"
echo " Status  : Unlocked"
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
read -n 1 -s -r -p "Press any key to back on menu"
m-vless
}
function res-user(){
clear
cd
if [ ! -e /etc/vless/akundelete ]; then
echo "" > /etc/vless/akundelete
fi
clear
NUMBER_OF_CLIENTS=$(grep -c -E "^### " "/etc/vless/akundelete")
if [[ ${NUMBER_OF_CLIENTS} == '0' ]]; then
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "$COLOR1 ${NC}${COLBG1}    ${WH}⇱ Restore Vless Account ⇲    ${NC} $COLOR1 $NC"
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "You have no existing user Expired!"
echo ""
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
read -n 1 -s -r -p "Press any key to back on menu"
m-vless
fi
clear
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "$COLOR1 ${NC}${COLBG1}    ${WH}⇱ Restore Vless Account ⇲    ${NC} $COLOR1 $NC"
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo " Select the existing client you want to Restore"
echo " ketik [0] kembali kemenu"
echo " ketik [999] untuk delete semua Akun"
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "     No  User   Expired"
grep -E "^### " "/etc/vless/akundelete" | cut -d ' ' -f 2-3 | nl -s ') '
until [[ ${CLIENT_NUMBER} -ge 1 && ${CLIENT_NUMBER} -le ${NUMBER_OF_CLIENTS} ]]; do
if [[ ${CLIENT_NUMBER} == '1' ]]; then
read -rp "Select one client [1]: " CLIENT_NUMBER
else
read -rp "Select one client [1-${NUMBER_OF_CLIENTS}] to Unlock: " CLIENT_NUMBER
if [[ ${CLIENT_NUMBER} == '0' ]]; then
m-vless
fi
if [[ ${CLIENT_NUMBER} == '999' ]]; then
rm /etc/vless/akundelete
m-vless
fi
fi
done
until [[ $masaaktif =~ ^[0-9]+$ ]]; do
read -p "Expired (days): " masaaktif
done
until [[ $iplim =~ ^[0-9]+$ ]]; do
read -p "Limit User (IP) or 0 Unlimited: " iplim
done
until [[ $Quota =~ ^[0-9]+$ ]]; do
read -p "Limit Quota (GB) or 0 Unlimited: " Quota
done
if [ ${iplim} = '0' ]; then
iplim="9999"
fi
if [ ${Quota} = '0' ]; then
Quota="9999"
fi
user=$(grep -E "^### " "/etc/vless/akundelete" | cut -d ' ' -f 2 | sed -n "${CLIENT_NUMBER}"p)
exp=`date -d "$masaaktif days" +"%Y-%m-%d"`
uuid=$(grep -E "^### " "/etc/vless/akundelete" | cut -d ' ' -f 4 | sed -n "${CLIENT_NUMBER}"p)
sed -i '/#vless$/a\#vl '"$user $exp $uuid"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /etc/xray/config.json
sed -i '/#vlessgrpc$/a\#vlg '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /etc/xray/config.json
sed -i '/#vlessup$/a\#vlup '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /etc/xray/config.json
sed -i '/#vlessxhttp$/a\#vlxh '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /etc/xray/config.json
echo "${iplim}" >/etc/vless/${user}IP
c=$(echo "${Quota}" | sed 's/[^0-9]*//g')
d=$((${c} * 1024 * 1024 * 1024))
if [[ ${c} != "0" ]]; then
echo "${d}" >/etc/vless/${user}
fi
sed -i "/^### ${user} ${exp} ${uuid}/d" /etc/vless/akundelete
systemctl restart xray
TEXT="
<code>◇━━━━━━━━━━━━━━◇</code>
<b>  XRAY VLESS RESTORE</b>
<code>◇━━━━━━━━━━━━━━◇</code>
<b>DOMAIN   :</b> <code>${domain} </code>
<b>ISP      :</b> <code>$ISP $CITY </code>
<b>USERNAME :</b> <code>$user </code>
<b>IP LIMIT  :</b> <code>$iplim IP </code>
<b>Quota LIMIT  :</b> <code>$Quota GB </code>
<b>EXPIRED  :</b> <code>$exp </code>
<code>◇━━━━━━━━━━━━━━◇</code>
<i>Succes Restore This Akun...</i>
"
curl -s --max-time $TIMES -d "chat_id=$CHATID&disable_web_page_preview=1&text=$TEXT&parse_mode=html" $URL >/dev/null
cd
if [ ! -e /etc/tele ]; then
echo -ne
else
echo "$TEXT" > /etc/notiftele
bash /etc/tele
fi
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo " Vless Account Restore Successfully"
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo " Client Name : $user"
echo " Expired  : $exp"
echo " Succes to Restore"
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
read -n 1 -s -r -p "Press any key to back on menu"
m-vless
}
function quota-user(){
cd
clear
if [ ! -e /etc/vless/userQuota ]; then
echo "" > /etc/vless/userQuota
fi
NUMBER_OF_CLIENTS=$(grep -c -E "^### " "/etc/vless/userQuota")
if [[ ${NUMBER_OF_CLIENTS} == '0' ]]; then
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "$COLOR1 ${NC}${COLBG1}    ${WH}⇱ Unlock Vless Account ⇲     ${NC} $COLOR1 $NC"
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "You have no existing user Lock!"
echo ""
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
read -n 1 -s -r -p "Press any key to back on menu"
m-vless
fi
clear
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "$COLOR1 ${NC}${COLBG1}    ${WH}⇱ Unlock Vless Account ⇲     ${NC} $COLOR1 $NC"
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo " Select the existing client you want to Unlock"
echo " ketik [0] kembali kemenu"
echo " ketik [999] untuk delete semua Akun"
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "     No  User   Expired"
grep -E "^### " "/etc/vless/userQuota" | cut -d ' ' -f 2-3 | nl -s ') '
until [[ ${CLIENT_NUMBER} -ge 1 && ${CLIENT_NUMBER} -le ${NUMBER_OF_CLIENTS} ]]; do
if [[ ${CLIENT_NUMBER} == '1' ]]; then
read -rp "Select one client [1]: " CLIENT_NUMBER
else
read -rp "Select one client [1-${NUMBER_OF_CLIENTS}] to Unlock: " CLIENT_NUMBER
if [[ ${CLIENT_NUMBER} == '0' ]]; then
m-vless
fi
if [[ ${CLIENT_NUMBER} == '999' ]]; then
rm /etc/vless/userQuota
m-vless
fi
fi
done
user=$(grep -E "^### " "/etc/vless/userQuota" | cut -d ' ' -f 2 | sed -n "${CLIENT_NUMBER}"p)
exp=$(grep -E "^### " "/etc/vless/userQuota" | cut -d ' ' -f 3 | sed -n "${CLIENT_NUMBER}"p)
uuid=$(grep -E "^### " "/etc/vless/userQuota" | cut -d ' ' -f 4 | sed -n "${CLIENT_NUMBER}"p)
sed -i '/#vless$/a\#vl '"$user $exp $uuid"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /etc/xray/config.json
sed -i '/#vlessgrpc$/a\#vlg '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /etc/xray/config.json
sed -i '/#vlessup$/a\#vlup '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /etc/xray/config.json
sed -i '/#vlessxhttp$/a\#vlxh '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /etc/xray/config.json
sed -i "/^### $user $exp $uuid/d" /etc/vless/userQuota
systemctl restart xray
TEXT="
<code>◇━━━━━━━━━━━━━━◇</code>
<b>  XRAY VLESS UNLOCKED</b>
<code>◇━━━━━━━━━━━━━━◇</code>
<b>DOMAIN   :</b> <code>${domain} </code>
<b>ISP      :</b> <code>$ISP $CITY </code>
<b>USERNAME :</b> <code>$user </code>
<b>EXPIRED  :</b> <code>$exp </code>
<code>◇━━━━━━━━━━━━━━◇</code>
<i>Succes Unlocked This Akun...</i>
"
curl -s --max-time $TIMES -d "chat_id=$CHATID&disable_web_page_preview=1&text=$TEXT&parse_mode=html" $URL >/dev/null
cd
if [ ! -e /etc/tele ]; then
echo -ne
else
echo "$TEXT" > /etc/notiftele
bash /etc/tele
fi
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo " Vless Account Unlock Successfully"
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo " Client Name : $user"
echo " Status  : Unlocked"
echo -e "$COLOR1━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
read -n 1 -s -r -p "Press any key to back on menu"
m-vless
}
clear
author=$(cat /etc/profil)
echo -e " $COLOR1╔════════════════════════════════════════════════════╗${NC}"
echo -e " $COLOR1║${NC}${COLBG1}             ${WH}• VLESS PANEL MENU •                   ${NC}$COLOR1║ $NC"
echo -e " $COLOR1╚════════════════════════════════════════════════════╝${NC}"
echo -e " $COLOR1╔════════════════════════════════════════════════════╗${NC}"
echo -e " $COLOR1║ $NC ${WH}[${COLOR1}01${WH}]${NC} ${COLOR1}• ${WH}ADD AKUN${NC}         ${WH}[${COLOR1}06${WH}]${NC} ${COLOR1}• ${WH}CEK USER CONFIG${NC}    $COLOR1║ $NC"
echo -e " $COLOR1║ $NC                                                  ${NC} $COLOR1║ $NC"
echo -e " $COLOR1║ $NC ${WH}[${COLOR1}02${WH}]${NC} ${COLOR1}• ${WH}TRIAL AKUN${NC}       ${WH}[${COLOR1}07${WH}]${NC} ${COLOR1}• ${WH}CHANGE USER LIMIT${NC}  $COLOR1║ $NC"
echo -e " $COLOR1║ $NC                                                  ${NC} $COLOR1║ $NC"
echo -e " $COLOR1║ $NC ${WH}[${COLOR1}03${WH}]${NC} ${COLOR1}• ${WH}RENEW AKUN${NC}       ${WH}[${COLOR1}08${WH}]${NC} ${COLOR1}• ${WH}SETTING LOCK LOGIN${NC} $COLOR1║ $NC"
echo -e " $COLOR1║ $NC                                                  ${NC} $COLOR1║ $NC"
echo -e " $COLOR1║ $NC ${WH}[${COLOR1}04${WH}]${NC} ${COLOR1}• ${WH}DELETE AKUN${NC}      ${WH}[${COLOR1}09${WH}]${NC} ${COLOR1}• ${WH}UNLOCK USER LOGIN${NC}  $COLOR1║ $NC"
echo -e " $COLOR1║ $NC                                                  ${NC} $COLOR1║ $NC"
echo -e " $COLOR1║ $NC ${WH}[${COLOR1}05${WH}]${NC} ${COLOR1}• ${WH}CEK USER LOGIN${NC}   ${WH}[${COLOR1}10${WH}]${NC} ${COLOR1}• ${WH}UNLOCK USER QUOTA ${NC} $COLOR1║ $NC"
echo -e " $COLOR1║ $NC                                                  ${NC} $COLOR1║ $NC"
echo -e " $COLOR1║ $NC ${WH}[${COLOR1}00${WH}]${NC} ${COLOR1}• ${WH}GO BACK${NC}          ${WH}[${COLOR1}11${WH}]${NC} ${COLOR1}• ${WH}RESTORE AKUN   ${NC}    $COLOR1║ $NC"
echo -e " $COLOR1╚════════════════════════════════════════════════════╝${NC}"
echo -e " $COLOR1╔═════════════════════════ ${WH}BY${NC} ${COLOR1}═══════════════════════╗ ${NC}"
echo -e "  $COLOR1${NC}           ${WH}   • BLACK MAGIC STORE •                $COLOR1 $NC"
echo -e " $COLOR1╚════════════════════════════════════════════════════╝${NC}"
echo -e ""
echo -ne " ${WH}Select menu ${COLOR1}: ${WH}"; read opt
case $opt in
1) clear ; add-vless  ;;
2) clear ; trial-vless  ;;
3) clear ; renew-vless  ;;
4) clear ; del-vless  ;;
5) clear ; cek-vless  ;;
6) clear ; list-vless  ;;
7) clear ; limit-vless  ;;
8) clear ; login-vless  ;;
9) clear ; lock-vless  ;;
10) clear ; quota-user  ;;
11) clear ; res-user  ;;
0) clear ; exec menu  ;;
x) exit ;;
*) echo "salah tekan " ; sleep 1 ; exec m-vless ;;
esac
