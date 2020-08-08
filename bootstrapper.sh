#!/bin/bash

eth0=$(TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"&>/dev/null` && curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4) &>/dev/null
eth0pub=$(TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"&>/dev/null` && curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4) &>/dev/null

echo Please start off by creating a Customer Gateway in your AWS account by using the IP address $eth0pub and setting an ASN different than the one you will use on your VGW or TGW. Then, create an AWS Site to Site VPN attached to either a VGW or TGW. Make sure take note of your CGW ASN, your TGW/VGW ASN, the gateway IPs created for your two tunnels as well as the local and remote inside IPs and finally the pre-shared keys for both tunnels. When you are ready to start, click enter.
read ignoreme

echo Local ASN:
read localasn

echo Remote ASN:
read remoteasn

echo AWS VPN Public IP 1:
read remoteoutside1

echo AWS VPN Public IP 2:
read remoteoutside2

echo Tunnel 1 Inside Local IP:
read tun1localip

echo Tunnel 1 Inside Remote IP:
read tun1remoteip

echo Tunnel 1 PSK:
read tun1psk

echo Tunnel 2 Inside Local IP:
read tun2localip

echo Tunnel 2 Inside Remote IP:
read tun2remoteip

echo Tunnel 2 PSK:
read tun2psk

printf "\n\n\n\n\n .... Please Wait .... Configuring ...."


sed -i "s/remoteinside1/$tun1remoteip/g" /etc/frr/bgpd.conf
sed -i "s/remoteinside2/$tun2remoteip/g" /etc/frr/bgpd.conf
sed -i "s/remoteas/$remoteasn/g" /etc/frr/bgpd.conf
sed -i "s/localas/$localasn/g" /etc/frr/bgpd.conf
sed -i "s/myhostname/$HOSTNAME/g" /etc/frr/bgpd.conf

sed -i "s/localinside1/$tun1localip/g" /etc/ipsec-vti.sh
sed -i "s/remoteinside1/$tun1remoteip/g" /etc/ipsec-vti.sh
sed -i "s/localinside2/$tun2localip/g" /etc/ipsec-vti.sh
sed -i "s/remoteinside2/$tun2remoteip/g" /etc/ipsec-vti.sh

sed -i "s/eth0inside/$eth0/g" /etc/strongswan/ipsec.conf
sed -i "s/eth0outside/$eth0pub/g" /etc/strongswan/ipsec.conf
sed -i "s/awsgw1/$remoteoutside1/g" /etc/strongswan/ipsec.conf
sed -i "s/awsgw2/$remoteoutside2/g" /etc/strongswan/ipsec.conf

printf "\n$eth0pub $remoteoutside1 : PSK \"$tun1psk\"\n$eth0pub $remoteoutside2 : PSK \"$tun2psk\"" >> /etc/strongswan/ipsec.secrets

systemctl start strongswan
sleep 10
ping -c 2 $tun1remoteip &>/dev/null
ping -c 2 $tun2remoteip &>/dev/null
systemctl start frr
