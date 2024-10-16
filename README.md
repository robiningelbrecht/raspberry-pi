# Configure PI as an Access Point over VPN

## Prerequisites

* Install git to pull and update this script

```bash
> sudo apt install git-all
```

* Make sure `config.sh` and `hotspot.sh` are in your home directory
* Fill out the variables in `config.sh`
* Navigate to https://account.proton.me/u/0/vpn/WireGuard and generate a WireGuard config
* Copy the contents in a new file  `wireguard.conf`
* Make sure `hotspot.sh` is executable, run

```bash
>  chmod +x hotspot.sh
```

## Configure an access point

```bash
>  sudo ./hotspot.sh setup
```
At this point the hotspot should be available for devices to connect to.

## Install PiVPN 

* Run `ifconfig` on your Raspberry Pi and copy the MAC address from `eth0` interface
* Log in into Mobile Vikings and add a new DHCP-RESERVERING.
  * Use the MAC address you copied
  * Set the IP address to `192.168.129.10`
* Reboot your Raspberry Pi
* Run `ifconfig` again and verify the router issues the configured IP address to your Pi
* To install PiVPN, run
```bash
>  curl -L https://install.pivpn.io | bash
```

* If prompted to choose an interface, select `eth0`

## Configure PiVPN

* After install, run

```bash
>  sudo ./hotspot.sh enable_vpn
```

* if you get an error saying something about `openresolv` , run `sudo apt install openresolv`
* Run `sudo wg` to check status

## Maintaining Your System

```bash
>  sudo crontab -e
> 0 3 * * * apt-get autoremove -y && apt-get autoclean -y
```
