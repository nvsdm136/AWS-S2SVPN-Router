# AWS Site-To-Site VPN Router

Install and configure StrongSwan and Free Range Routing to connect to AWS Site-to-Site VPN with BGP Peering.


Run install.sh as a sudoer. This was designed for Amazon Linux 2 on Amazon EC2 instances, including both x86 and ARM (Graviton). 

to run attended :

```
git clone https://github.com/nvsquirrel/AWS-S2SVPN-Router.git; cd AWS-S2SVPN-Router; sh install.sh; ./bootstrapper.sh
```

to run unattended (bootstrap script) and attach to a TGW run the following. `make sure to replace <region> with the region (such as us-east-1) <local ASN> with the ASN you want to use on the instance and <TGW ID> with the TGW ID you wish to attach to`:

```
#!/bin/bash
yum -y update
yum -y install git
git clone https://github.com/nvsquirrel/AWS-S2SVPN-Router.git; cd AWS-S2SVPN-Router; sh install.sh; ./bootstrapper.sh -r <region> -a <local ASN> -t <TGW ID>
```

Additionally, you can configure all VPN and BGP parameters via the bootstrapper script (or edit ipsec-vti.sh, ipsec.conf, ipsec.secrets and bgpd.conf manually). To run the bootstrapper (note: bootstrapper only supports new TGW attachments right now):

```
chmod +x bootstrapper.sh
sudo ./bootstrapper.sh
```


Bootstrap command switches:

* -r  Region  ex. us-east-1
* -a  Local ASN   (64512-65534)  ex. 64512
* -t  TGW ID    ex. tgw-1234567890abcdefg
* -v  VGW ID    ex. vgw-1234567890abcdefg
* -e Existing VPN ID    ex. vpn-1234567890abcdefg


NOTE: If you specify both TGW and VGW the TGW will take precedence. 

PERMISSIONS: The bootstrapper makes use of the AWS CLI, you must allow create-customer-gateway, create-vpn-connection and describe-vpn-connections to be called on the instance via CLI. You can find an example of the IAM Policy JSON document in IAMPolicy.json

