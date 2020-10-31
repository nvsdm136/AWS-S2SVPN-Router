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

if grep Amazon /etc/system-release 1> /dev/null
    then . ./aml2.sh -v $version
    else echo "not AML"; EXIT
fi


