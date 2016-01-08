#!/bin/bash -x	
#setup postgres database
cat << `EOT` | su - postgres -c psql -
CREATE USER irods WITH PASSWORD 'rods';
CREATE DATABASE "ICAT";
GRANT ALL PRIVILEGES ON DATABASE "ICAT" TO irods;
`EOT`

cat >> /etc/postgresql/9.1/main/pg_hba.conf << `EOF`
host    all             all             192.168.50.11/32        md5
host    all             all             192.168.50.12/32        md5
host    all             all             192.168.50.13/32        md5
`EOF`

cat >> /etc/postgresql/9.1/main/postgresql.conf << `EOF`
listen_addresses = '*'
`EOF`

#set ssl to false in postgresql.conf
STORE=$(grep -n 'ssl =' /etc/postgresql/9.1/main/postgresql.conf | cut -c-2)
VAR='d'
sed -i".bak" $STORE$VAR /etc/postgresql/9.1/main/postgresql.conf
I="i"
SEARCH=" ssl = false"
sed -i "$STORE$I$SEARCH"  /etc/postgresql/9.1/main/postgresql.conf

#restart postgresql to allow the file changes to take effect 
cat << `EOT` | su - postgres 
/etc/init.d/postgresql restart
`EOT`
