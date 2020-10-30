TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
publicip=`curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/public-ipv4`
instanceid=`curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/instance-id`
localpvtip=`curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/local-ipv4`

if [[ ${#publicip} -ge 5 ]]
        then echo Your public IP is $publicip
        else publicip=`curl http://checkip.amazonaws.com/`
fi

if [[ ${#instanceid} -ge 5 ]]
        then echo Your instance ID is $instanceid
        else instanceid=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 17 | head -n 1)
fi

if [[ ${#localpvtip} -ge 5 ]]
        then echo Your Private IP is $localpvtip
        else printf "Please specify the IP bound to the interface you want the VPN to originate from (that is associated with the Public IP we listed above):" && read localpvtip
fi

while getopts ":r:a:t:v:e:" opt; do
  case ${opt} in
    r ) region=$OPTARG
      ;;
    a ) localas=$OPTARG
      ;;
    t ) tgwid=$OPTARG
      ;;
    v ) vgwid=$OPTARG
      ;;
	e ) vpn=$OPTARG
	  ;;
    \? ) echo "Usage: cmd [-r REGION] [-a LOCAL ASN] [-t TGW ID]"
      exit 1
      ;;
  esac
done

if [[ ${#region} -ge  9 ]]
        then echo Your region is $region
        else echo Region: && read region
fi

if [[ ${#localas} -ge 5 || ${#vpn} -ge 15 ]]
        then echo Your local ASN is $localas
        else printf "Local (CGW) ASN:" && read localas
fi

if [[ ${#tgwid} -ge 15 || ${#vpn} -ge 15 ]]
        then echo Your TGW ID is $tgwid; gw="TRUE"
        else echo no TGW set
fi

if [[ ${#vgwid} -ge 15 || ${#vpn} -ge 15 ]]
        then echo Your VGW ID is $vgwid; gw="TRUE"
        else echo no VGW set
fi


if [[ $gw == TRUE ]]
        then echo "gw is set"
        else printf "Please select VGW or TGW [VGW TGW]:" && read gwtype
fi

if [[ $gwtype == TGW ]]
        then echo TGW ID: && read tgwid
        else echo ""
fi

if [[ $gwtype == VGW ]]
        then echo VGW ID: && read vgwid
        else echo ""
fi

if [[ ${#vpn} -lt 15 ]]
	then cgw=`aws ec2 create-customer-gateway --bgp-asn $localas --public-ip $publicip --type ipsec.1  --tag-specification 'ResourceType=customer-gateway,Tags=[{Key=Name,Value='"$instanceid"'}]' --region $region | grep CustomerGatewayId | sed 's/\"CustomerGatewayId\": \"//' | sed 's/\",//'`
	else printf "Pre-configured VPN"; presetvpn="TRUE"
fi

if [[ ${#tgwid} -ge 15 ]]
        then vpn=`aws ec2  create-vpn-connection --customer-gateway-id $cgw --type ipsec.1 --transit-gateway-id $tgwid --tag-specification 'ResourceType=vpn-connection,Tags=[{Key=Name,Value='"$instanceid"'}]' --region $region | grep VpnConnectionId | sed 's/\"VpnConnectionId\": \"//' | sed 's/\",//'`
        elif [[ ${#vgwid} -ge 15 ]]
		then vpn=`aws ec2  create-vpn-connection --customer-gateway-id $cgw --type ipsec.1 --vpn-gateway-id $vgwid --tag-specification 'ResourceType=vpn-connection,Tags=[{Key=Name,Value='"$instanceid"'}]' --region $region | grep VpnConnectionId | sed 's/\"VpnConnectionId\": \"//' | sed 's/\",//'`
		else echo No GW set
fi
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
localas=`cat tunnel2 | sed -n 's:.*<customer_gateway>\(.*\)</customer_gateway>.*:\1:p' | sed -n 's:.*<asn>\(.*\)</asn>.*:\1:p'`



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
printf  "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n####################################################################################################################\n####################################################################################################################\n####                                                                                                            ####\n####   Giving AWS some time to setup the VPN Connection before we start the services and bring up the tunnels   ####\n####                                                                                                            ####\n####################################################################################################################\n####################################################################################################################\n\n\n"


if [[ ${#presetvpn} -ge 3 ]]
	then sleep 300
	else sleep 1
fi


systemctl start strongswan
systemctl start frr