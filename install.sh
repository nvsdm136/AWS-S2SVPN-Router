yum -y install git gcc cmake pcre pcre-devel python3 python3-devel autoconf automake libtool make readline-devel texinfo net-snmp-devel groff pkgconfig json-c-devel pam-devel bison flex pytest c-ares-devel python-devel systemd-devel python-sphinx libcap-devel
cd ~
git clone https://github.com/CESNET/libyang.git
cd libyang
mkdir build; cd build
cmake -DENABLE_LYD_PRIV=ON -DCMAKE_INSTALL_PREFIX:PATH=/usr \
      -D CMAKE_BUILD_TYPE:String="Release" ..
make
sudo make install
sudo groupadd -g 92 frr
sudo groupadd -r -g 85 frrvty
sudo useradd -u 92 -g 92 -M -r -G frrvty -s /sbin/nologin \
  -c "FRR FRRouting suite" -d /var/run/frr frr
cd ~
git clone https://github.com/frrouting/frr.git frr
cd frr
./bootstrap.sh
./configure \
    --bindir=/usr/bin \
    --sbindir=/usr/lib/frr \
    --sysconfdir=/etc/frr \
    --libdir=/usr/lib/frr \
    --libexecdir=/usr/lib/frr \
    --localstatedir=/var/run/frr \
    --with-moduledir=/usr/lib/frr/modules \
    --enable-snmp=agentx \
    --enable-multipath=64 \
    --enable-user=frr \
    --enable-group=frr \
    --enable-vty-group=frrvty \
    --enable-systemd=yes \
    --disable-exampledir \
    --disable-ldpd \
    --enable-fpm \
    --with-pkg-git-version \
    --with-pkg-extra-version=-MyOwnFRRVersion \
    SPHINXBUILD=/usr/bin/sphinx-build
make
make check
sudo make install
sudo mkdir /var/log/frr
sudo mkdir /etc/frr
sudo touch /etc/frr/zebra.conf
sudo touch /etc/frr/bgpd.conf
sudo touch /etc/frr/ospfd.conf
sudo touch /etc/frr/ospf6d.conf
sudo touch /etc/frr/isisd.conf
sudo touch /etc/frr/ripd.conf
sudo touch /etc/frr/ripngd.conf
sudo touch /etc/frr/pimd.conf
sudo touch /etc/frr/nhrpd.conf
sudo touch /etc/frr/eigrpd.conf
sudo touch /etc/frr/babeld.conf
sudo chown -R frr:frr /etc/frr/
sudo touch /etc/frr/vtysh.conf
sudo chown frr:frrvty /etc/frr/vtysh.conf
sudo chmod 640 /etc/frr/*.conf
sudo install -p -m 644 tools/etc/frr/daemons /etc/frr/
sudo chown frr:frr /etc/frr/daemons
sed -i "s/bgpd=.*/bgpd=yes/g" /etc/frr/daemons
printf "# Sysctl for routing\n#\n# Routing: We need to forward packets\nnet.ipv4.conf.all.forwarding=1\nnet.ipv6.conf.all.forwarding=1" > /etc/sysctl.d/90-routing-sysctl.conf
sudo sysctl -p /etc/sysctl.d/90-routing-sysctl.conf
sudo install -p -m 644 tools/frr.service /usr/lib/systemd/system/frr.service
sudo systemctl preset frr.service
sudo systemctl enable frr
sudo systemctl start frr
cd ~