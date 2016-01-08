#!/bin/bash -x

source /home/vagrant/settings/settings.cfg


if [ "$rel" == "3.3.1" ]; then
	cd /usr/local/iRODS/
	if [ "$(hostname)" == "icat" ]; then 	
		if [ -f /usr/local/iRODS/config/irods.config ]; then
			su vagrant <<'EOF'
		    cd /usr/local/iRODS/
			yes | ./irodssetup
			./irodsctl start

			export PATH=$PATH:/usr/local/iRODS/clients/icommands/bin
EOF
		else
			echo "config file failed to configure" 
		fi
	else
		export PERL5LIB=$PERL5LIB:/usr/local/iRODS/config/irods.config
		su vagrant <<'EOF'
		cd /usr/local/iRODS
		yes | ./irodssetup
		./irodsctl start
		export PATH=$PATH:/usr/local/iRODS/clients/icommands/bin
EOF
	fi	
	cd ~
	git clone https://github.com/sstephenson/bats.git
	git clone https://github.com/wtsi-ssg/irods_testing.git	
	/home/vagrant/bats/install.sh /usr/local/
	
else 
	#This needs modifying to allow for continuous integration
	chmod +x /home/vagrant/scripts/setup.py
	bash -c "cat >> /etc/irods/service_account.config" << `EOF`
	IRODS_SERVICE_ACCOUNT_NAME=irods
	IRODS_SERVICE_GROUP_NAME=irods
`EOF`
	yes | adduser irods 
	chown irods -R /etc/irods/
	chown irods -R /var/lib/irods/
	chown :irods -R /etc/irods
	chown :irods -R /var/lib/irods/
	/home/vagrant/scripts/setup.py

	cat >> /etc/profile.d/oracle.sh << `EOF`
	export ORACLE_HOME=/opt/oracle/instantclient_11_2
	export ORACLE_SID=XE
	export LD_LIBRARY_PATH=/opt/oracle/instantclient_11_2/:$LD_LIBRARY_PATH
	export PATH=$ORACLE_HOME:$PATH
`EOF`

	cat >> /etc/environment << `EOF`
	ORACLE_HOME=/opt/oracle/instantclient_11_2
`EOF`
		
	/var/lib/irods/packaging/setup_irods.sh < /home/vagrant/setup_options.txt
	cd /var/lib/irods/
	su - irods -c "git clone https://github.com/sstephenson/bats.git"
	su - irods -c "git clone https://github.com/wtsi-ssg/irods_testing.git"	
	/var/lib/irods/bats/install.sh /usr/local/

fi

echo "irods   ALL=(ALL)       NOPASSWD:ALL" >> /etc/sudoers
