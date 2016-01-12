#!/bin/bash -x

source /home/vagrant/settings/settings.cfg
#Read values from config file
REPOSITORY_3="https://gitlab.internal.sanger.ac.uk/jc18/irods_legacy.git"
PROXY="TRUE"

#read icat values 
HOST=$( hostname )
if [ "$(hostname)" == "icat" ]; then
	OS=$icat_os
else
	OS=$ires_os
fi


release(){
 	if 	[ "$rel" == "3.3.1" ]; then
		R_3_3_1
	elif  	[ "$rel" == "4.1.4" ]; then
		R_4_1_4
	elif  	[ "$rel" == "4.1.5" ]; then
		R_4_1_5
	#assume at this point that this is a new release, so pray that the configuration is identical to the last releases configuration
	else 	
		#This will run the latest release function, the release functions naming syntax must stay the same in order for this to work!
		
		CALL=$(grep "^R" $0 | grep "()"| sort | tail -1 )
		CALL="${CALL/{}"
		CALL="${CALL/(}"
		CALL="${CALL/)}"

		eval $CALL
	fi

}

R_3_3_1(){
	if [ "$OS" == "ubuntu12" ] || [ "$OS" == "ubuntu14" ]; then
		apt-get -y update
	
	elif [ "$OS" == "redhat" ]; then	
		subscription-manager register --username $rh_username --password $rh_password --auto-attach --force
	    yum -y update
	fi
	if [ "$box_mode" == "c" ]; then	
		
		if [ "$OS" == "ubuntu12" ] || [ "$OS" == "ubuntu14" ]; then
			apt-get -y install make g++ git unzip libaio-dev
		elif [ "$OS" == "redhat" ]; then	
			yum -y install make gcc-c++ git	perl-JSON.noarch perl-JSON-PP.noarch unzip python-devel lsof 	
		fi
		
		if [ "$(hostname)" == "icat" ]; then
			cp /home/vagrant/settings/icat_bash_3 /home/vagrant/.bashrc
			cp /home/vagrant/settings/icat_bash_3 /home/vagrant/.bash_profile
			. .bashrc	
		else
    		cp /home/vagrant/settings/ires_bash /home/vagrant/.bashrc
    		cp /home/vagrant/settings/ires_bash /home/vagrant/.bash_profile
			. .bashrc
    	fi


	
    	cd /usr/local/
    	git -c http.sslVerify=false  clone $REPOSITORY_3

    	cp -R ./irods_legacy/iRODS/ iRODS

    	chmod go-r /usr/local/iRODS/config/irods.config

    	if [ "$(hostname)" == "icat" ]; then

	    	mkdir /opt/oracle/
		    for FILE in /home/vagrant/files/instantclient*.zip; do 
			    cp $FILE /opt/oracle
		    done
		    cd /opt/oracle/
		    for FILE in /opt/oracle/*; do
			    unzip $FILE 
			    rm $FILE
		    done
		
		    cd instantclient_11_2
		    mkdir bin
		    cp * bin
		    cp /opt/oracle/instantclient_11_2/sdk/include/* /usr/local/iRODS/server/icat/include/
		    chown vagrant /usr/local/iRODS/server/icat/include/*
		    cd /usr/local/iRODS/server/bin/
		    ln -s /opt/oracle/instantclient_11_2/lib/libclntsh.so.11.1 libclntsh.so
		    cd /opt/oracle/instantclient_11_2/
		    mkdir lib
		    cp * lib
		    cd lib 
		    ln -s /opt/oracle/instantclient_11_2/lib/libclntsh.so.11.1 libclntsh.so
		    ln -s /opt/oracle/instantclient_11_2/lib/libocci.so.11.1 libocci.so


    		python /home/vagrant/scripts/icat.py	
    	else
    		python /home/vagrant/scripts/ires.py	
    	fi

    	chown vagrant /usr/local/iRODS/config/irods.config

    	chown -R vagrant /usr/local/iRODS


    	chown vagrant /usr/local/iRODS/config/irods.config



	fi
	
	
}

R_4_1_5(){
	if [ "$box_mode" == "c" ]; then
		os
		if [ "$(hostname)" == "icat" ]; then
			icat
		else
			ires
		fi 
	fi
}


R_4_1_4(){
	if [ "$box_mode" == "c" ]; then
		os
		if [ "$(hostname)" == "icat" ]; then
			icat
		else
			ires
		fi 
	fi
}

icat(){
	
	if [ "$database" == "postgres" ]; then
		export http_proxy=http://wwwcache.sanger.ac.uk:3128
		export https_proxy=http://wwwcache.sanger.ac.uk:3128
		bash postgres.sh
		if [ "$rel" == "4.1.4" ]; then
			VERSION="1.5"
		else
			VERSION="1.6"
		fi
		wget ftp://ftp.renci.org/pub/irods/releases/$rel/$OS/irods-icat-$rel-$OS-x86_64.deb -O icat.deb
		wget ftp://ftp.renci.org/pub/irods/releases/$rel/$OS/irods-database-plugin-postgres-$VERSION-$OS-x86_64.deb -O db.deb

		sudo -i
		export http_proxy=http://wwwcache.sanger.ac.uk:3128
		export https_proxy=http://wwwcache.sanger.ac.uk:3128
		su vagrant
		dpkg -i icat.deb db.deb
		
	elif [ "$database" == "oracle" ]; then 
		oracle
	fi
	
	
	
}

ires(){
	if [ "$rel" == "4.1.8" ]; then
		wget ftp://ftp.renci.org/pub/irods/preview/4.1.8-001-3863d0f89667a19ffd7f89d11ecff76df8978543/ubuntu12/irods-resource-4.1.8-64bit.deb -O res.deb
	else
	wget ftp://ftp.renci.org/pub/irods/releases/$rel/$OS/irods-resource-$rel-$OS-x86_64.deb -O res.deb		
	fi
	dpkg -i res.deb
}

os(){
	case "$OS" in
		"ubuntu12")
			apt-get -y update
			apt-get -y install postgresql libjson-perl python-psutil python-requests unixodbc odbc-postgresql super git unzip libaio-dev		
		
			sudo bash
			export http_proxy=http://wwwcache.sanger.ac.uk:3128
			export https_proxy=http://wwwcache.sanger.ac.uk:3128
			wget https://bootstrap.pypa.io/get-pip.py
			python get-pip.py
			pip install jsonschema
			su vagrant 

			cp /home/vagrant/settings/icat_bash .bashrc
			cp /home/vagrant/settings/icat_bash /tmp/icat_bash
		

		;;
		"ubuntu14")
			apt-get -y update
			apt-get -y install postgresql libjson-perl python-psutil python-requests unixodbc odbc-postgresql super python-jsonschema git unzip libaio-dev	
		;;
		"redhat")
			cp /home/vagrant/settings/icat_bash .bashrc
			cp /home/vagrant/settings/icat_bash /tmp/icat_bash
	
			. .bashrc		
			subscription-manager register --username $rh_username --password $rh_password --auto-attach --force
			echo "subscribed"
			yum -y update
			yum -y install perl-JSON.noarch perl-JSON-PP.noarch
			yum -y install unzip python-devel lsof git
			su -s
			. .bashrc

			wget https://bootstrap.pypa.io/get-pip.py
			python get-pip.py
			pip install psutil
			pip install jsonschema
			pip install requests
	
		;;
	esac
}



oracle(){
		
	

	
	if [ "$rel" == "4.1.4" ]; then
		VERSION="1.5"
	elif [ "$rel" == "4.1.5" ] || [ "$rel" == "4.1.6" ]; then
		VERSION="1.6"
	elif [ "$rel" == "4.1.7" ]; then
		VERSION="1.7"
	fi

	if [ "$OS" == "ubuntu12" ] || [ "$OS" == "ubuntu14" ]; then
		OS_DIR=$OS
		EXTENSION=deb
	else
		OS_DIR=centos7
		EXTENSION=rpm
	fi

	if [ "$rel" == "4.1.8" ]; then
		wget ftp://ftp.renci.org/pub/irods/preview/4.1.8-001-3863d0f89667a19ffd7f89d11ecff76df8978543/ubuntu12/irods-database-plugin-oracle-1.7.deb -O db.$EXTENSION
		wget ftp://ftp.renci.org/pub/irods/preview/4.1.8-001-3863d0f89667a19ffd7f89d11ecff76df8978543/ubuntu12/irods-icat-4.1.8-64bit.deb -O icat.$EXTENSION
	else
		wget ftp://ftp.renci.org/pub/irods/releases/$rel/$OS_DIR/irods-icat-$rel-$OS_DIR-x86_64.$EXTENSION -O icat.$EXTENSION
		wget ftp://ftp.renci.org/pub/irods/releases/$rel/$OS_DIR/irods-database-plugin-oracle-$VERSION-$OS_DIR-x86_64.$EXTENSION -O db.$EXTENSION
	fi

	
	mkdir /opt/oracle/
	for FILE in /home/vagrant/files/instantclient*.zip; do 
		cp $FILE /opt/oracle
	done
	cd /opt/oracle/
	for FILE in /opt/oracle/*; do
		unzip $FILE 
		rm $FILE
	done
	cd instantclient_11_2

	ln -s libclntsh.so.11.2 libclntsh.so
	ln -s libocci.so.11.2 libocci.so
	if [ "$OS" == "ubuntu12" ] || [ "$OS" == "ubuntu14" ]; then
		dpkg -i --force-depends /home/vagrant/icat.deb /home/vagrant/db.deb
	else 
		rpm -i --nodeps /home/vagrant/icat.rpm /home/vagrant/db.rpm 
	fi
	
		
}
guest_additions(){
wget http://download.virtualbox.org/virtualbox/4.3.30/VBoxGuestAdditions_4.3.30.iso
sudo mkdir /media/VBoxGuestAdditions
sudo mount -o loop,ro VBoxGuestAdditions_4.3.30.iso /media/VBoxGuestAdditions
sudo sh /media/VBoxGuestAdditions/VBoxLinuxAdditions.run
rm VBoxGuestAdditions_4.3.30.iso
sudo umount /media/VBoxGuestAdditions
sudo rmdir /media/VBoxGuestAdditions
}

release
if [ "$box_mode" == "c" ]; then
	bash /home/vagrant/scripts/build.sh
	echo "finished"
fi
