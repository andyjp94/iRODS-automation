
#!/bin/bash -x

source /home/vagrant/settings/settings.cfg

os(){
case "$1" in
	"ubuntu12")
		apt-get -y update
		apt-get -y install postgresql libjson-perl python-psutil python-requests unixodbc odbc-postgresql super		
	
		sudo bash
		export http_proxy=http://wwwcache.sanger.ac.uk:3128
		export https_proxy=http://wwwcache.sanger.ac.uk:3128
		wget https://bootstrap.pypa.io/get-pip.py
		python get-pip.py
		pip install jsonschema
		su vagrant 

	;;
	"ubuntu14")
		apt-get -y update
		apt-get -y install postgresql libjson-perl python-psutil python-requests unixodbc odbc-postgresql super python-jsonschema
	;;
	"centos7.1")
		cp /home/vagrant/settings/db_bash .bashrc
		. .bashrc
		yum -y update
		yum -y install bc unzip glibc.x86_64 make.x86_64 binutils.x86_64 gcc.x86_64 libaio.x86_64 

		echo "packages updated and installed"

	;;
	"redhat7")
		echo "subscribing"
		subscription-manager register --username "$rh_username" --password "$rh_password" --auto-attach --force
		echo "subscribed"

		cp /home/vagrant/settings/db_bash .bashrc
		. .bashrc
		yum -y update
		yum -y install bc unzip glibc.x86_64 make.x86_64 binutils.x86_64 gcc.x86_64 libaio.x86_64 

		echo "packages updated and installed"
	;;
esac
}
	

oracle(){
	cp /home/vagrant/files/oracle-xe-11.2.0-1.0.x86_64.rpm.zip /home/vagrant/
	unzip /home/vagrant/oracle-xe-11.2.0-1.0.x86_64.rpm.zip
	echo "unzipped oracle database folder"
	sleep 2m 
	dd if=/dev/zero of=/swapfile bs=2048 count=1048576  
	mkswap /swapfile
	swapon /swapfile
	cp /etc/fstab /etc/fstab.orig
	echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
	swapon -a ; swapon -s

	echo "enlarged swap"

	rm -rf /dev/shm
	mkdir /dev/shm
	mount -t tmpfs shmfs -o size=2048m /dev/shm

	mv Disk1/* ./ 
	rm -r Disk1


	rpm -ivh  /home/vagrant/oracle-xe-11.2.0-1.0.x86_64.rpm 

	 
	/etc/init.d/oracle-xe configure responseFile=/home/vagrant/settings/xe.rsp > /home/vagrant/logs/XEsilentinstall.log

	/etc/init.d/oracle-xe start

	cd /u01
	export PATH=$PATH:/u01/app/oracle/product/11.2.0/xe/bin/
	cd /home/vagrant/
	. oracle_env.sh

	sqlplus system/rods <<`EOF`
	create user irods identified by rods;
	grant all privileges to irods;
	GRANT CREATE SESSION TO irods WITH ADMIN OPTION;
	exit
`EOF`

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


##
if [ "$database" == "oracle" ]; then
	OS=$db_os
else
	OS=$ires_os
fi

os $OS
if [ "$OS" == "ubuntu12" ] || [ "$OS" == "ubuntu14" ]; then
	postgres
else
	oracle
fi


