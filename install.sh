#!/bin/bash

cat /etc/system-release


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

#setting up some options
cos7="CentOS Linux release 7"
aml2="Amazon"
rhelrelease="/etc/system-release"

#checking OS version and executing correct install script
if [[ ! -z $(grep "$aml2" "$rhelrelease") ]]
    then . ./aml2.sh -v $version
	elif [[ ! -z $(grep "$cos7" "$rhelrelease") ]]
		then . ./cos7.sh -v $version
    else echo "You are not running this on a supported operating system. Please check the documentation on Github or if you feel this is an error, open an issue on Github."; EXIT
fi


