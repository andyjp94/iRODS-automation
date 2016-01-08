#!/bin/bash

source /home/vagrant/settings/settings.cfg

HOSTNAME=$( hostname )

if [ "$HOSTNAME" == "db" ] || [ "$HOSTNAME" == "icat" ]; then
	VAR="$HOSTNAME"_os""
	if [ ${!VAR} == "redhat" ]; then
		subscription-manager unregister
	fi
elif [[ "$HOSTNAME" == *"ires"* ]]; then
	VAR="ires_os"
	if [ ${!VAR} == "redhat" ]; then
		subscription-manager unregister
	fi
fi
