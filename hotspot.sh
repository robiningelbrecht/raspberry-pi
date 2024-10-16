#!/bin/bash
set -e

# Do not forget to run sudo "raspi-config" and set “Localisation Options” > “WLAN country”
# TODO; Check if wireguard.conf exists

COMMAND=$1

COLOR_ORANGE='\033[0;33m'
COLOR_RED='\033[0;31m'
NC='\033[0m' # No Color

source config.sh

if [[ -z ${SSID} ]];  then  
    echo -e "${COLOR_RED}Variable SSID not set, make sure you configured it in config.sh  ${NC}" 
    exit 1;
fi 

if [[ -z ${WIFI_PASSWORD} ]];  then  
    echo -e "${COLOR_RED}Variable WIFI_PASSWORD not set, make sure you configured it in config.sh  ${NC}" 
    exit 1;
fi 

if [[ -z ${WIREGUARD_CLIENT_NAME} ]];  then  
    echo -e "${COLOR_RED}Variable WIREGUARD_CLIENT_NAME not set, make sure you configured it in config.sh  ${NC}" 
    exit 1;
fi 

if [ "$EUID" -ne 0 ]; then
    echo -e "${COLOR_RED}Please run as root ${NC}"
    exit 1;
fi

if [ $# -lt 1 ]; then
    echo -e "${COLOR_RED}Provide a command ${NC}"
    exit 1;
fi

# MAIN FUNCTIONS
hotspot_status () {
  nmcli con show --active
  nmcli device wifi show-password
}

hotspot_up () {
  nmcli connection up hotspot
}

hotspot_down () {
  nmcli connection down hotspot
}

hotspot_setup () {
    nmcli con delete hotspot
    nmcli connection add type wifi ifname wlan0 con-name hotspot autoconnect yes ssid "${SSID}"
    nmcli connection modify hotspot 802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared
    nmcli connection modify hotspot wifi-sec.key-mgmt wpa-psk
    nmcli connection modify hotspot wifi-sec.psk ${WIFI_PASSWORD}
    nmcli connection modify hotspot connection.autoconnect yes
    nmcli connection up hotspot
}

vpn_enable () {
  # Install and configure WireGuard
  pivpn add -n ${WIREGUARD_CLIENT_NAME}
  mkdir -p /etc/wireguard
  chown root:root /etc/wireguard
  chmod 700 /etc/wireguard
  cat wireguard.conf > "${WIREGUARD_CLIENT_NAME}.conf"
  mv "${WIREGUARD_CLIENT_NAME}.conf" /etc/wireguard/
  wg-quick up ${WIREGUARD_CLIENT_NAME}
  # Autostart WireGuard in systemd
  systemctl enable wg-quick@${WIREGUARD_CLIENT_NAME}
  systemctl daemon-reload
}

vpn_disable () {
  pivpn remove ${WIREGUARD_CLIENT_NAME}
  # Remove WireGuard in systemd
  systemctl stop wg-quick@${WIREGUARD_CLIENT_NAME}
  systemctl disable wg-quick@${WIREGUARD_CLIENT_NAME}.service
  systemctl daemon-reload
  systemctl reset-failed
}

help () {
  echo "Syntax: hotspot.sh command"
  echo "options:"
  echo "setup          Setup the access point for anew."
  echo "up             Enable the access piont."
  echo "down           Disable the access point."
  echo "status         Print the status of all interfaces."
  echo "enable_vpn     Enable a secure VPN connecton."
  echo "diable_vpn     Disable active VPN connection."
  echo "gui            Open network managemlent GUI editor."
  echo "help           Print this help."
  echo
}

# COMMANDS
if [ "$COMMAND" == "setup" ]; then
    hotspot_setup
    hotspot_status
    exit
fi

if [ "$COMMAND" == "up" ]; then
  hotspot_up
  hotspot_status
  exit
fi

if [ "$COMMAND" == "down" ]; then
  hotspot_down
  nmcli con show --active
  exit
fi

if [ "$COMMAND" == "status" ]; then
  hotspot_status
  exit
fi

if [ "$COMMAND" == "enable_vpn" ]; then
  vpn_enable
  exit
fi

if [ "$COMMAND" == "disable_vpn" ]; then
  vpn_disable
  exit
fi

if [ "$COMMAND" == "gui" ]; then
  sudo nmtui
  exit
fi

if [ "$COMMAND" == "help" ]; then
  help
  exit
fi

help
exit 1;
