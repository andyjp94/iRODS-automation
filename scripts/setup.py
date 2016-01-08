#!/usr/bin/env python
"""This script creates a text file which will be be used
as the input to the irods_setup command.
This script works for all configurations.
"""
from socket import gethostname

#contains all values that need to be prompted for any configuration,
#only missing keys are oracle_client and oracle_access which are added
#whilst the program is running due to the fact that they rely on variables
#s == server
settings = {
    's_zone_name'                   :   'tempZone',
    's_port'                        :   '1247',
    'port_range_begin'              :   '20000',
    'port_range_end'                :   '20199',
    'Vault_dir':   '/var/lib/irods/iRODS/Vault',
    's_zone_key'                    :   '',
    's_negotiation_key'             :   '',
    'Plane_port'                    :   '1248',
    'Control_plane_key'             :   '',
    'Schema_Validation_Base_URI'    :   '',
    's_admin_username'              :   'irods',
    's_admin_password'              :   'rods',
    'confirm_settings'              :   'yes',
    'Database_s_port'               :   '',
    'Database_name'                 :   'ICAT',
    'Database_username'             :   'irods',
    'Database_password'             :   'rods'
}

def prompter(prompt_list):
    """stores the chosen values in setup_options.txt"""
    with open('/home/vagrant/setup_options.txt', 'w+') as options:
        for prompt in prompt_list:
            options.write(settings[prompt]+'\n')

if 'icat' in gethostname():
    prompts = ['s_zone_name', 's_port',
        'port_range_begin', 'port_range_end',
        'Vault_dir', 's_zone_key',
        's_negotiation_key', 'Plane_port',
        'Control_plane_key', 'Schema_Validation_Base_URI',
        's_admin_username', 's_admin_password',
        'confirm_settings']

    settings['Database_s_hostname'] = 'db'
    with open('/home/vagrant/settings/settings.cfg', 'r') as s:
        for line in s:
            if line.startswith('database'):
                if 'oracle' in line.split('=')[1]:     
                    settings['oracle_client'] = '/opt/oracle/instantclient_11_2'
                    settings['oracle_access'] = \
                        settings['Database_username']+'@' +\
                        settings['Database_s_hostname']+':'+\
                        settings['Database_s_port']

                    db_prompts = [
                        'oracle_client', 'oracle_access', 'Database_password',
                        'confirm_settings']
                else:
                    db_prompts = [
                        'Database_s_hostname', 'Database_s_port',
                        'Database_name', 'Database_username', 'Database_password',
                        'confirm_settings']

                prompts = prompts + db_prompts
                break
else:
    settings['Database_s_hostname'] = 'icat'

    prompts = ['s_port', 'port_range_begin',
            'port_range_begin', 'Vault_dir',
            's_zone_key', 's_negotiation_key',
            'Plane_port', 'Control_plane_key',
            'Schema_Validation_Base_URI', 's_admin_username',
            'confirm_settings', 'Database_s_hostname',
            's_zone_name', 'confirm_settings',
            'Database_password']

prompter(prompts)



