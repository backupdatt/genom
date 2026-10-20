#!/bin/bash
DF='\e[39m'
Bold='\e[1m'
Blink='\e[5m'
yell='\e[33m'
red='\e[31m'
green='\e[32m'
blue='\e[34m'
PURPLE='\e[35m'
cyan='\e[36m'
Lred='\e[91m'
Lyellow='\e[93m'
Lgreen='\e[92m'
NC='\e[0m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
LIGHT='\033[0;37m'
grenbo="\e[92;1m"
red() { echo -e "\\033[32;1m${*}\\033[0m"; }
# Getting
ipsaya=$(curl -sS ipv4.icanhazip.com)
data_server=$(curl -v --insecure --silent https://google.com/ 2>&1 | grep Date | sed -e 's/< Date: //')
date_list=$(date +"%Y-%m-%d" -d "$data_server")
# --- KONFIGURASI PRIVATE LICENSE HOST (isi sendiri) ---
GH_USER="GANTI_USERNAME_GITHUB_KAMU"
GH_REPO="GANTI_NAMA_REPO_PRIVATE_KAMU"
GH_TOKEN="GANTI_PERSONAL_ACCESS_TOKEN_KAMU"
GH_FILE="gnome"
[ -f /etc/xray/license.conf ] && source /etc/xray/license.conf
# --------------------------------------------------------
checking_sc() {
  useexp=$(curl -s --connect-timeout 10 \
    -H "Authorization: token $GH_TOKEN" \
    -H "Accept: application/vnd.github.v3.raw" \
    "https://api.github.com/repos/${GH_USER}/${GH_REPO}/contents/${GH_FILE}?ref=main" \
    | grep $ipsaya | awk '{print $3}')
  if [[ $date_list < $useexp ]]; then
    echo -ne
  else
    echo -e "\033[1;93m────────────────────────────────────────────\033[0m"
    echo -e "\033[42m          404 NOT FOUND AUTOSCRIPT          \033[0m"
    echo -e "\033[1;93m────────────────────────────────────────────\033[0m"
    echo -e ""
    echo -e "            ${RED}PERMISSION DENIED !${NC}"
    echo -e "   \033[0;33mYour VPS${NC} $ipsaya \033[0;33mHas been Banned${NC}"
    echo -e "     \033[0;33mBuy access permissions for scripts${NC}"
    echo -e "             \033[0;33mContact Admin :${NC}"
    echo -e "      ${GREEN}TELEGRAM${NC} https://github.com/backupdatt/genom"
	echo -e "      ${GREEN}WHATS APP ${NC} 087726917005"
    echo -e "\033[1;93m────────────────────────────────────────────\033[0m"
    exit 0
  fi
}
checking_sc
clear
MYIP=$(wget -qO- ipinfo.io/ip);
clear 
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "             • Backup Menu •         "
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "" 
echo -e " [\e[36m•1\e[0m] Backup VPS Data"
echo -e " [\e[36m•2\e[0m] Restore VPS Data"
echo -e " [\e[36m•3\e[0m] Jadwal Backup"
echo -e "" 
echo -e " [\e[31m•0\e[0m] \e[31mBack To Menu\033[0m"
echo -e "" 
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e ""
read -p " Select menu :  "  opt
echo -e   ""
case $opt in
01 | 1) clear ; backup ;;
02 | 2) clear ; restore ;;
02 | 3) clear ; atur-backup ;;
00 | 0) clear ; exec menu ;;
*) clear ; exec menu-backup ;;
esac
