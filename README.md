# AWS Site-To-Site VPN Router

Install and configure StrongSwan and Free Range Routing to connect to AWS Site-to-Site VPN with BGP Peering.


Run run.sh as a sudoer. This was designed for Amazon Linux 2 on Amazon EC2 instances, including both x86 and ARM (Graviton). 

to run attended :

```
git clone https://github.com/nvsquirrel/AWS-S2SVPN-Router.git; cd AWS-S2SVPN-Router; sh run.sh; chmod +x bootstrapper.sh; ./bootstrapper.sh
```

to run unattended (bootstrap script) run the following. `make sure to replace <region> with the region (such as us-east-1) <local ASN> with the ASN you want to use on the instance and <TGW ID> with the TGW ID you wish to attach to`:

```
#!/bin/bash
yum -y update
yum -y install git
git clone https://github.com/nvsquirrel/AWS-S2SVPN-Router.git; cd AWS-S2SVPN-Router; sh run.sh; chmod +x bootstrapper.sh; ./bootstrapper.sh -r <region> -a <local ASN> -t <TGW ID>
```

command options for bootstrapper.sh

-  -r  region; eg. us-east-1
-  -a  Local ASN;  any 1 byte or 4 byte ASN between 1-2147483647
-  -t  Transite Gateway ID; eg.  tgw-1234abcd5678efgh9
-  -e  Existing VPN ID; eg. vpn-1234abcd5678efgh9

