while getopts ":h:v:" opt; do
  case ${opt} in
	h ) echo "help menu"
		exit 0
	  ;;
    v ) version=$OPTARG
      ;;
    \? ) echo "Usage: cmd [-v version] "
      exit 1
      ;;
  esac
done

#install epel

yum -y install epel-release

#Updating YUM repos

yum -y update

#installing prereqs available in YUM as well as Strongswan

yum -y install git gcc cmake pcre pcre-devel python3 python3-devel autoconf automake libtool make readline-devel texinfo net-snmp-devel groff pkgconfig json-c-devel pam-devel bison flex pytest c-ares-devel python-devel systemd-devel python-sphinx libcap-devel strongswan unzip net-tools

#checking if AWS CLI is installed

if [[ $(aws --version) != *"aws-cli/2"* ]]
then
    cli=FALSE; echo "AWS CLI is missing. Attempting to install now"
    else cli=TRUE; echo "AWS CLI Found"
fi

#IF AWS CLI is not installed, checking proc architecture and installing the right package

if [[ $(arch) == "x86_64" && $cli == "FALSE" ]]
        then echo "x86_64 architecture detected"; curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"; unzip awscliv2.zip; sudo ./aws/install
        elif [[ $(arch) == "aarch64" ]]
                then echo "ARM64 architecture detected"; curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"; unzip awscliv2.zip; sudo ./aws/install
		elif [[ $cli == "TRUE" ]]
                then echo ""
        else echo "Unsupported proc architecture"; exit 1
fi

#confirming the install of AWS CLI

if [[ $(aws --version) != *"aws-cli/2"* ]]
then
    echo "AWS CLI could not be successfully installed. Please install manually and run the script again."; exit 1
    elif [[ $cli == "FALSE" ]]
	then echo "AWS CLI was successfully installed."
	else echo ""
fi

printf "##############################################\n####  Pre-requisites have been installed  ####\n##############################################\n"


#installing Libyang

if [[ $(whereis libyang) == *"libyang.so"* ]]
	then echo "Libyang has already been installed"
	else git clone https://github.com/CESNET/libyang.git
		cd libyang
		mkdir build; 
		cd build
		cmake -DENABLE_LYD_PRIV=ON -DCMAKE_INSTALL_PREFIX:PATH=/usr -D CMAKE_BUILD_TYPE:String="Release" ..
		make
		make install
		cd ../../
fi

#confirming Libyang install

if [[ $(whereis libyang) == *"libyang.so"* ]]
	then printf "######################################\n####  libyang has been installed  ####\n######################################\n"
	else echo "Libyang failed to install. Please resolve the error and try again."; exit 1
fi

#installing FRR

if [[ $(vtysh -c "show version" --dryrun) == *"FRRouting"* ]]
	then echo "Free Range Routing has already been installed"
	else groupadd -g 92 frr
		groupadd -r -g 85 frrvty
		useradd -u 92 -g 92 -M -r -G frrvty -s /sbin/nologin -c "FRR FRRouting suite" -d /var/run/frr frr
		if [[ $version == "74" ]]
			then printf "Pulling FRR 7.4-stable\n"; git clone --branch "stable/7.4" https://github.com/frrouting/frr.git frr
			elif [[ $version == "73" ]]
			then printf "Pulling FRR 7.3-stable\n";git clone --branch "stable/7.3" https://github.com/frrouting/frr.git frr
			elif [[ $version == "72" ]]
			then printf "Pulling FRR 7.2-stable\n";git clone --branch "stable/7.2" https://github.com/frrouting/frr.git frr
			elif [[ $version == "71" ]]
			then printf "Pulling FRR 7.1-stable\n";git clone --branch "stable/7.1" https://github.com/frrouting/frr.git frr
			elif [[ $version == "70" ]]
			then printf "Pulling FRR 7.0-stable\n";git clone --branch "stable/7.0" https://github.com/frrouting/frr.git frr
			elif [[ $version == "60" ]]
			then printf "Pulling FRR 6.0-stable\n";git clone --branch "stable/7.0" https://github.com/frrouting/frr.git frr
			else printf "Pulling default FRR 7.3-stable\n";git clone --branch "stable/7.3" https://github.com/frrouting/frr.git frr
		fi
		cd frr/
		sed -i '/^AC_CONFIG_MACRO_DIR*/a AC_CONFIG_AUX_DIR([.])' configure.ac
		. ./bootstrap.sh
		sh configure --bindir=/usr/bin --sbindir=/usr/lib/frr --sysconfdir=/etc/frr --libdir=/usr/lib/frr --libexecdir=/usr/lib/frr --localstatedir=/var/run/frr --with-moduledir=/usr/lib/frr/modules --enable-snmp=agentx --enable-multipath=64 --enable-user=frr --enable-group=frr --enable-vty-group=frrvty --enable-systemd=yes --disable-exampledir --disable-ldpd --enable-fpm --with-pkg-git-version --with-pkg-extra-version=-MyOwnFRRVersion SPHINXBUILD=/usr/bin/sphinx-build
		make
		make check
		make install
		mkdir /var/log/frr
		mkdir /etc/frr
		touch /etc/frr/zebra.conf
		touch /etc/frr/bgpd.conf
		touch /etc/frr/ospfd.conf
		touch /etc/frr/ospf6d.conf
		touch /etc/frr/isisd.conf
		touch /etc/frr/ripd.conf
		touch /etc/frr/ripngd.conf
		touch /etc/frr/pimd.conf
		touch /etc/frr/nhrpd.conf
		touch /etc/frr/eigrpd.conf
		touch /etc/frr/babeld.conf
		chown -R frr:frr /etc/frr/
		touch /etc/frr/vtysh.conf
		chown frr:frrvty /etc/frr/vtysh.conf
		chmod 640 /etc/frr/*.conf
		install -p -m 644 tools/etc/frr/daemons /etc/frr/
		chown frr:frr /etc/frr/daemons
		install -p -m 644 tools/frr.service /usr/lib/systemd/system/frr.service
		cd ../
fi

#confirming FRR install

if [[ $(vtysh -c "show version" --dryrun) == *"FRRouting"* ]]
	then printf "########################################\n####  FRR Installation is Complete  ####\n########################################\n"
	else echo "FRR failed to install. Please resolve the error and try again."; exit 1
fi

#enabling the BGPD daemon

sed -i "s/bgpd=.*/bgpd=yes/g" /etc/frr/daemons

#setting linux to allow IPv4&6 forwarding

if [[ $(cat /etc/sysctl.d/90-routing-sysctl.conf) == *"net.ipv4.conf.all.forwarding=1"* && $(cat /etc/sysctl.d/90-routing-sysctl.conf) == *"net.ipv6.conf.all.forwarding=1"* ]]
	then printf "sysctl is set"
	else printf "net.ipv4.conf.all.forwarding=1\nnet.ipv6.conf.all.forwarding=1" > /etc/sysctl.d/90-routing-sysctl.conf; sysctl -p /etc/sysctl.d/90-routing-sysctl.conf
fi

#enabling FRR and strongswan to start on bootup

systemctl preset frr.service
systemctl enable frr
systemctl enable strongswan

#placing bootstrap config files

cat bgpd.conf > /etc/frr/bgpd.conf
cat ipsec-vti.sh > /etc/ipsec-vti.sh
cat ipsec.conf > /etc/strongswan/ipsec.conf

#updating final permissions

chmod +x /etc/ipsec-vti.sh
chown frr:frr /etc/frr/bgpd.conf
chmod 600 /etc/frr/bgpd.conf


printf "#######################################################################################################################################################\n#######################################################################################################################################################\n#####                                                                                                                                             #####\n#####     AWS CLI, FRR and Strongswan have been installed successfully. Now run bootstrap.sh to configure an AWS Site-to-Site VPN connection.     #####\n#####                                                                                                                                             #####\n#######################################################################################################################################################\n#######################################################################################################################################################\n"