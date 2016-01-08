#!/usr/bin/env python

import subprocess
import os
import socket
from tempfile import mkstemp
import shutil

strings = {

    'proxy'     : '"http://wwwcache.sanger.ac.uk',
    'port'      : ':3128";\n',
    'Acquire'   : 'Acquire::http::Proxy ',
    'Acquire_s' : 'Acquire::https::Proxy ',
    'exp'       : 'export http_proxy=',
    'exp_s'     : 'export https_proxy='
}

hosts = {

    'db'    :   '192.168.50.10',
    'icat'  :   '192.168.50.11',
}

paths = {

    'rhsm'      :   '/etc/rhsm/rhsm.conf',
    'apt'       :   '/etc/apt/apt.conf.d/99-sanger-webcache',
    'rc'        :   '/home/vagrant/.bashrc',
    'profile'   :   '/home/vagrant/.bash_profile'
}

def redhat_proxy():
    f, temp_file = mkstemp()
    with open(paths['rhsm'], "r") as conf, open(temp_file, "w") as tmp:
        for line in conf:
            if "proxy_hostname =" in line:
                tmp.write("proxy_hostname = wwwcache.sanger.ac.uk\n")
            elif "proxy_port =" in line:
                tmp.write("proxy_port = 3128\n")
            else:
                tmp.write(line)
    os.close(f)
    os.remove(paths['rhsm'])
    shutil.move(temp_file, paths['rhsm'])

def ubuntu_proxy():
    with open(paths['apt'], 'w+') as apt_proxy: 
        #Allow apt-get past the proxy
        for string in ('Acquire', 'Acquire_s'):
            apt_proxy.write(strings[string]+strings['proxy']+strings['port'])
        #set the proxy environment variables permanently
    with open(paths['rc'], 'w+') as bashrc, open(paths['profile'], 'w+') as bash_profile:
        for string in ('exp', 'exp_s'):
            for bash_file in (bashrc, bash_profile):
                bash_file.write(strings[string]+strings['proxy']+strings['port'])

    subprocess.call('/home/vagrant/.bashrc', shell='True')


if __name__ == "__main__":


    hostname = socket.gethostname()
    if 'ires' in hostname:
        print('reached ubuntu proxy as an ires server')
        ubuntu_proxy()
        search='*'
    elif'db' in hostname:
        search = 'db_os'
    else:
        search = 'icat_os'
            
    with open('/home/vagrant/settings/settings.cfg', 'r') as settings:
        for line in settings:
            if line.startswith(search):
                if 'redhat' in line.split('=')[1]:
                    redhat_proxy()
                elif 'ubuntu' in line.split('=')[1]:
                    ubuntu_proxy()
            elif line.startswith('ires_nodes'):
                nodes = line.split('=')[1]
                print(nodes)


    with open("/etc/hosts", "a") as h:
        for key, val in hosts.items():
            h.write('\n'+val+'\t'+key)

        for node in range(1,int(nodes)+1):
            h.write('\n'+'192.168.50.'+str(11+node)+'\t'+'ires'+str(node))
