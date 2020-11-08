sed -i -e 's/\r$//' install.sh
sed -i -e 's/\r$//' aml2.sh
sed -i -e 's/\r$//' bootstrapper.sh
chmod +x install.sh
./install.sh
