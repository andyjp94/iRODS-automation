# iRODS_auto

TODO: This project aims to create a testing platform for iRODS. This testing platform currently supports version 3.3.1, 4.1.[4..7] with 4.1.8 coming soon! 

## Installation

To install this project you must first install virtualbox and vagrant. The tested version of these are virtualbox 5.0.10 and vagrant 1.7.4, the vagrant plugins required are vagrant-triggers. You will also require the jinja2 python module. To install the project itself simply clone this repo.

## Usage

To build an oracle database server, an icat server and two ires servers on 4.1.7 simply use the command "irods_vagrant.py"
There are many configurations settings one can choose. For now refer to the confluence page at https://ssg-confluence.internal.sanger.ac.uk/display/ISG/iRODS+Vagrant, however this page will be updated over time to explain the options 

## Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request :D

## History

We needed a system to reproducibly create irods systems for testing an upgrade from iRODS 3.3.1 to iRODS 4.1.x, over time the functionality and requirements shifted and expanded to what we have today. If you would like a more in-depth history then you should read my best selling book "Vagrant and I" currently retailing on Amazon and Audible. (In talks with Netflix at the minute but don't want to get too hopeful) 

## Credits

TODO: Write the credits 

## License

TODO: Write license
