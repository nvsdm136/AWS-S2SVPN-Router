# AWS Site-To-Site VPN Router

Install and configure StrongSwan and Free Range Routing to connect to AWS Site-to-Site VPN with BGP Peering.


Run run.sh as a sudoer. This was designed for Amazon Linux 2 on Amazon EC2 instances, including both x86 and ARM (Graviton). 

to run attended :

```
git clone https://github.com/nvsquirrel/AWS-S2SVPN-Router.git; cd AWS-S2SVPN-Router; sh run.sh; chmod +x bootstrapper.sh; ./bootstrapper.sh
```

to run unattended (bootstrap script) run the following. make sure to replace <region> with the region (such as us-east-1) <local ASN> with the ASN you want to use on the instance and <TGW ID> with the TGW ID you wish to attach to:

```
#!/bin/bash
yum -y install updates
yum -y install git
git clone https://github.com/nvsquirrel/AWS-S2SVPN-Router.git; cd AWS-S2SVPN-Router; sh run.sh; chmod +x bootstrapper.sh; ./bootstrapper.sh -r <region> -a <local ASN> -t <TGW ID>
```

Additionally, you can configure all VPN and BGP parameters via the bootstrapper script (or edit ipsec-vti.sh, ipsec.conf, ipsec.secrets and bgpd.conf manually). To run the bootstrapper (note: bootstrapper only supports new TGW attachments right now):

```
chmod +x bootstrapper.sh
sudo ./bootstrapper.sh
```
