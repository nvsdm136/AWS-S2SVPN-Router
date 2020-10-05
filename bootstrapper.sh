TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` && publicip=`curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/public-ipv4` && instanceid=`curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/instance-id` && localpvtip=`curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/local-ipv4`

echo Region:
read region

echo Local (CGW) ASN:
read localas

echo TGW ID:
read tgwid

cgw=`aws ec2 create-customer-gateway --bgp-asn $localas --public-ip $publicip --type ipsec.1  --tag-specification 'ResourceType=customer-gateway,Tags=[{Key=Name,Value='"$instanceid"'}]' --region $region | grep CustomerGatewayId | sed 's/\"CustomerGatewayId\": \"//' | sed 's/\",//'`
vpn=`aws ec2  create-vpn-connection --customer-gateway-id $cgw --type ipsec.1 --transit-gateway-id $tgwid --tag-specification 'ResourceType=vpn-connection,Tags=[{Key=Name,Value='"$instanceid"'}]' --region $region | grep VpnConnectionId | sed 's/\"VpnConnectionId\": \"//' | sed 's/\",//'`
aws ec2 describe-vpn-connections --vpn-connection-ids $vpn --region $region > output

cat output | sed -n 's:.*<customer_gateway_id>\(.*\)</ipsec_tunnel>.*:\1:p' > tunnel
cat tunnel | sed 's/<\/ipsec_tunnel>/\n/g' | sed -n 1,1p > tunnel1
cat tunnel | sed 's/<\/ipsec_tunnel>/\n/g' | sed -n 2,2p > tunnel2
vgw1outsideip=`cat tunnel1 | sed -n 's:.*<tunnel_outside_address>\(.*\)</tunnel_outside_address>.*:\1:p' | sed -n 's:.*<ip_address>\(.*\)</ip_address>.*:\1:p'`
vgw2outsideip=`cat tunnel2 | sed -n 's:.*<tunnel_outside_address>\(.*\)</tunnel_outside_address>.*:\1:p' | sed -n 's:.*<ip_address>\(.*\)</ip_address>.*:\1:p'`
cgw1insideip=`cat tunnel1 | sed -n 's:.*<customer_gateway>\(.*\)</customer_gateway>.*:\1:p' | sed -n 's:.*<tunnel_inside_address>\(.*\)</tunnel_inside_address>.*:\1:p' | sed -n 's:.*<ip_address>\(.*\)</ip_address>.*:\1:p'`
cgw2insideip=`cat tunnel2 | sed -n 's:.*<customer_gateway>\(.*\)</customer_gateway>.*:\1:p' | sed -n 's:.*<tunnel_inside_address>\(.*\)</tunnel_inside_address>.*:\1:p' | sed -n 's:.*<ip_address>\(.*\)</ip_address>.*:\1:p'`
cgw1psk=`cat tunnel1 | sed -n 's:.*<pre_shared_key>\(.*\)</pre_shared_key>.*:\1:p'`
cgw2psk=`cat tunnel2 | sed -n 's:.*<pre_shared_key>\(.*\)</pre_shared_key>.*:\1:p'`
vgw1insideip=`cat tunnel1 | sed -n 's:.*<vpn_gateway>\(.*\)</vpn_gateway>.*:\1:p' | sed -n 's:.*<tunnel_inside_address>\(.*\)</tunnel_inside_address>.*:\1:p' | sed -n 's:.*<ip_address>\(.*\)</ip_address>.*:\1:p'`
vgw2insideip=`cat tunnel2 | sed -n 's:.*<vpn_gateway>\(.*\)</vpn_gateway>.*:\1:p' | sed -n 's:.*<tunnel_inside_address>\(.*\)</tunnel_inside_address>.*:\1:p' | sed -n 's:.*<ip_address>\(.*\)</ip_address>.*:\1:p'`
vgwasn=`cat tunnel2 | sed -n 's:.*<vpn_gateway>\(.*\)</vpn_gateway>.*:\1:p' | sed -n 's:.*<asn>\(.*\)</asn>.*:\1:p'`
sed -i 's/localinside1/'"$cgw1insideip"'/' /etc/ipsec-vti.sh
sed -i 's/localinside2/'"$cgw2insideip"'/' /etc/ipsec-vti.sh
sed -i 's/remoteinside1/'"$vgw1insideip"'/' /etc/ipsec-vti.sh
sed -i 's/remoteinside2/'"$vgw2insideip"'/' /etc/ipsec-vti.sh
sed -i 's/eth0inside/'"$localpvtip"'/' /etc/strongswan/ipsec.conf
sed -i 's/eth0outside/'"$publicip"'/' /etc/strongswan/ipsec.conf
sed -i 's/awsgw1/'"$vgw1outsideip"'/' /etc/strongswan/ipsec.conf
sed -i 's/awsgw2/'"$vgw2outsideip"'/' /etc/strongswan/ipsec.conf
printf "\n$publicip $vgw1outsideip : PSK \"$cgw1psk\"" >> /etc/strongswan/ipsec.secrets
printf "\n$publicip $vgw2outsideip : PSK \"$cgw2psk\"" >> /etc/strongswan/ipsec.secrets
sed -i 's/myhostname/'"$HOSTNAME"'/' /etc/frr/bgpd.conf
sed -i 's/localas/'"$localas"'/' /etc/frr/bgpd.conf
sed -i 's/remoteinside1/'"$vgw1insideip"'/' /etc/frr/bgpd.conf
sed -i 's/remoteas/'"$vgwasn"'/' /etc/frr/bgpd.conf
sed -i 's/remoteinside2/'"$vgw2insideip"'/' /etc/frr/bgpd.conf
printf  "\n\n\n####################################################################################################################\n####################################################################################################################\n####                                                                                                            ####\n####   Giving AWS some time to setup the VPN Connection before we start the services and bring up the tunnels   ####\n####                                                                                                            ####\n####################################################################################################################\n####################################################################################################################\n\n\n"
sleep 300
systemctl start strongswan
systemctl start frr
