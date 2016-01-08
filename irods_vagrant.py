#!/usr/bin/env python
"""
This script is the user interface to an automated infrastructure management
platform that produces an iRODS dynamic infrastructure. use vagrant.py -h
for further details of the command line options.
"""
from __future__ import print_function
import subprocess
import sys
from tempfile import mkstemp
import argparse
import getpass
import shutil
import os
from jinja2 import FileSystemLoader, Environment



box_names = {
    'db_base' : '"http://it-admin2.internal.sanger.ac.uk/boxes/package.box"',
    "db_postgres_ubuntu12" : "",
    "db_postgres_ubuntu14" : "",
    'redhat7': 'thussain/rhel7',
    'centos7.1': 'https://github.com/CommanderK5/packer-centos-template/releases/download/0.7.1/vagrant-centos-7.1.box',
    'pty':  'true',
    'ubuntu14': 'ubuntu/trusty64',
    'ubuntu12': 'hashicorp/precise64'
}

def file_check():
    """
    This function checks that all the files required to use
    oracle have been placed in the correct directory
    """
    f_required = ["instantclient-basic", "instantclient-sqlplus", "oracle-xe"]
    f_actual = []
    for zips in os.listdir("./files"):
        for file_type in f_required:
            if zips.startswith(file_type):
                if zips.endswith(".zip"):
                    f_actual.append(file_type)
                else:
                    print("The "+file_type+"is not a zip file")
    for zips in f_required:
        if zips not in f_actual:
            print("The "+zips+" zip file is not in the files folder")
            exit()

def config_man(args):
    """
    This function creates the config files for all three types of
    vm(db,icat,ires) in the form of text files. It gets the
    configuration from either the command
    line or the command line defaults
    """

    file_check()
    f_cfg, cfg_tmp = mkstemp()

    with open(cfg_tmp, 'w') as cfg:
        cfg.write(
            "database="+args.db+'\n'
            +"db_os="+args.db_os+'\n'
            +"rel="+args.rel+'\n'
            +"icat_os="+args.cat_os+'\n'
            +"ires_os="+args.res_os+'\n'
            +"box_mode="+args.box+'\n'
            +"ires_nodes="+args.nodes+'\n'
        )
        credentials = 0

        #if a redhat box is needed
        if ('redhat7' in args.db_os) or ('redhat7' in args.cat_os):
            if os.path.isfile('./settings/settings.cfg'):
                with open('./settings/settings.cfg', 'r') as settings:
                    for line in settings:
                        if 'username' in line or 'password' in line:
                            cfg.write(line)
                            credentials = credentials + 1
            if credentials != 2:
                cfg.write(
                    "rh_username="+raw_input('Enter your RedHat username: ')+'\n'
                    +"rh_password="+getpass.getpass()+'\n'
                )

    shutil.move(cfg_tmp, './settings/settings.cfg')



    os.close(f_cfg)

def gen_vagrantfile(args):
    """
    This function is used to create the appropriate
    strings that will be included in the Vagrantfile
    """
    template_env = Environment(loader=FileSystemLoader(searchpath="."))
    template = template_env.get_template("./settings/Vagrantfile.jinja")
    #create dictionary containing all the variables required for the Vagrantfile
    vag_vars = dict()

    if 'oracle' in args.db:
        vag_vars['db_box'] = box_names[args.db_os]
        vag_vars['db_pty'] = box_names['pty']

    vag_vars['icat_box'] = box_names[args.cat_os]
    if 'redhat7' in args.cat_os:
        vag_vars['icat_pty'] = 'true'
    else:
        vag_vars['icat_pty'] = 'false'

    vag_vars['ires_box'] = box_names[args.res_os]

    if args.interface:
        vag_vars['interface'] = ', bridge: "en0: Wi-Fi (AirPort)"'
    else:
        vag_vars['interface'] = ''

    if args.logging:
        vag_vars['log_type'] = '| tee'
    else:
        vag_vars['log_type'] = '&>'

    vag_vars['num_nodes'] = args.nodes

    with open('Vagrantfile', 'w+') as vagrantfile:
        vagrantfile.write(template.render(vag_vars))

def argument_parser():
    """
    This function gathers the command line argument_parser
    """
    class CustomFormatter(argparse.ArgumentDefaultsHelpFormatter,
                          argparse.RawTextHelpFormatter):
        """
        Allows addtional help text formatting
        """
        pass
    parser = argparse.ArgumentParser(
        description="""This script creates the necessary config file and
            Vagrantfile to create an iRODS dynamic infrastructure consisting of
            four virtual machines, one database server, one iCAT server and
            two iRES servers. 
            The database server can either contain an oracle or a postgres database.
            If the database is oracle then the db server and iCAT 
            server are using red hat 7.1.
            If the database is postgres then the db server and the icat server 
            can be either ubuntu12 or ubuntu14.
            For either configuration the ires servers can be ubuntu12 or ubuntu14.
            The iRODS versions that are currently supported are 3.3.1, 4.1.4 and 4.1.5.
            There is also the option to use these scripts to create purpose build base
            boxes, however THIS STILL NEEDS SOME WORK""",
        formatter_class=CustomFormatter
        )
    parser.add_argument(
        '-d', '--db', dest='db',
        default='oracle', choices=['oracle', 'postgres'],
        help='''Sets whether to use an oracle or postgres
        database on the database server'''
    )
    parser.add_argument(
        '-os-r', '--os-res', dest='res_os',
        default='ubuntu12', choices=['ubuntu12', 'ubuntu14'],
        help='''Sets the operating system for the iRES servers
    and if the database is postgres also the icat 
    and database servers. '''
    )
    parser.add_argument(
        '-os-c', '--os-cat', dest='cat_os',
        default='ubuntu12', choices=['ubuntu12', 'ubuntu14', 'redhat7'],
        help='''Sets the operating system for the iCAT server'''
        )
    parser.add_argument(
        '-os-d', '--os-db', dest='db_os',
        default='redhat7', choices=['centos7.1', 'redhat7'],
        help='''Sets the operating system for the iCAT server'''
        )
    parser.add_argument(
        '-r', '--rel', dest='rel',
        default='4.1.7',
        help='''Sets the iRODS release that will be installed.'''
    )
    parser.add_argument(
        '-b', '--box', dest='box',
        default='c', choices=['c', 'v',],
        help=
        '''Sets whether these scripts will be used to:
        1)  Create a complete irods testing platform from scratch (o)
        2)  Create the virtual machines to be used for the irods
        testing platform but do not provision them (v)
        '''
    )
    parser.add_argument(
        '-v', '--vm', dest='vm',
        default=['db', 'icat'], nargs='*',
        help='''Sets the virtual machines that will be built.'''
        )
    parser.add_argument(
        '-i', '--interface', dest='interface',
        action='store_true',
        help='''Sets the interface to bridge to, if set then the
        wireless is used.'''
        )
    parser.add_argument(
        '-t', '--tee', dest='logging',
        action='store_true',
        help='''Sets the logging to output to the terminal window
        as well as to the log files.'''
        )
    parser.add_argument(
        '-n', '--nodes', dest='nodes',
        default='2',
        help='''number of ires nodes'''
        )
    return parser.parse_args()

def argument_checker(args):
    """
    This function checks for incompatible input arguments and if found exits the script
    after printing an appropriate error message
    """
    valid = ['3.3.1', '4.1.7', '4.1.8']

    if args.rel not in valid:
        if "ubuntu" in args.cat_os:
            print("Invalid combination, "+ args.cat_os +" is not valid with "+args.rel)
            sys.exit()


def main():
    """
    """

    args = argument_parser()
    
    argument_checker(args)
    
    #change to the irods_auto directory
    os.chdir(os.path.dirname(os.path.abspath(__file__)))

    config_man(args)

    gen_vagrantfile(args)

    #create full list of servers from command line
    if args.nodes == '0':
        servers = args.vm
    else:
        servers = args.vm + ['ires'+str(res) for res in range(1, int(args.nodes)+1)]


    for server in servers:
        try:
            subprocess.check_call(['vagrant', 'up', server])
        except subprocess.CalledProcessError:
            print("vagrant up failed on"+server)
        except OSError:
            print("Vagrant is not installed")



if __name__ == "__main__":
    main()
