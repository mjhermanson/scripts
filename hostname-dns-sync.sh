#!/bin/bash
# A simple script to make DNS authoritive for hostnames on RHEL 5/6. Meant to be run from cron. 
# It does:
#	1. check if the current hostname matches DNS
#	2. Updates the local hostname to whatever is in DNS
if host $(hostname); then
    DNS_record=$(host $(hostname -I) | awk -F ' ' '{ print $NF }' | awk -F '.' '{ print $1 }')
    if [ $(hostname| awk -F . '{ print $1 }') == $DNS_record ] ; then
        echo 'hostname matches DNS'
        exit 0
    else
        platform=$(uname)
        if [ "$platform" = Linux ];then
			#TODO: Update this to use hostnamectl on RHEL 7
            hostname $DNS_record
            sed '/HOSTNAME=/d' /etc/sysconfig/network
            echo "HOSTNAME=$DNS_record" >> /etc/sysconfig/network
        fi
        if [ "$platform" = SunOS ]; then
            echo 'Solaris is untested'
#            hostname $DNS_record
#            sed '/HOSTNAME=/d' /etc/hostname
#            echo "HOSTNAME=$DNS_record" >> /etc/hostname
        fi
    fi
fi
