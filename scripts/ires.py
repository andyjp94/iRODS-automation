#!/usr/bin/env python
"""
Builds an iRES server using an pre-existing irods.config file,
 changing variable to be specific to the zone its installing to
 ap21 & jc18
"""

import argparse
import socket
import os
import sys
import shutil
from tempfile import mkstemp

parser = argparse.ArgumentParser(description="configures ires servers")
parser.add_argument('-i', dest='icat_host')
parser.add_argument('-z', dest='zone')
parser.add_argument('-p', dest='password')
args = parser.parse_args()

resource_name = "demo" + socket.gethostname()
if resource_name == "demo":
    print("Could not retrieve the hostname")
    sys.exit()

fd, temporary_file = mkstemp()


config_map = {

	"$IRODS_HOME"              : "/usr/local/iRODS",
	"$IRODS_PORT"              : "1247",
	"$SVR_PORT_RANGE_START"    : "20000",
	"$SVR_PORT_RANGE_END"      : "20199",
	"$IRODS_ADMIN_NAME"        : "irods",
	"$IRODS_ADMIN_PASSWORD"    : "rods",
	"$IRODS_ICAT_HOST"         : 'icat',
	"$DB_NAME"                 : "ICAT",
	"$RESOURCE_NAME"           : "demoResc2",
	"$RESOURCE_DIR"            : "/usr/local/iRODS/Vault",
	"$ZONE_NAME"               : "tempZone",
	"$DB_KEY"  	               : "123",
	"$GSI_AUTH"                : "0",
	"$KRB_AUTH"	               : "0",
	"$AUDIT_EXT"               : "1",
	"$UNICODE" 		           : "1"
	

}


rods_config = '/usr/local/iRODS/config/irods.config.template'
with open(rods_config, 'r') as config_file, open(temporary_file, 'w') as tmp:
    for line in config_file:
        if line.startswith('#'):
            if "$CCFLAGS =" in line:
                tmp.write('$CCFLAGS = "-fPIC";\n')
            else:
                tmp.write(line)
        else:
            line = line.strip()
            if line:
                key = line.split()[0]
                if key in config_map:
                    tmp.write(
                        "{key} = '{value}';\n".format(
                            key=key, 
                            value=config_map[key]
                            )
                        )
                else:
                    tmp.write(line)


os.close(fd)
shutil.copyfile(temporary_file, "/usr/local/iRODS/config/irods.config")
os.remove(temporary_file)

