This is a wrapper for fio, the IO tester under Linux. Fiox support
variables in the \*.fio configuration files. Please check ./fiox.pl --help
for more information.

To distinguish fiox config file with fio origin ones, I defined to use
\*.fiox for fiox config files, and fiox.pl will generate \*.fio config
files using this \*.fiox file. 

needed libraries:
- Carp::Assert
- JSON::Parse

Please install these libraries first. I would like to suggest to use
'cpanm' to do it. :)
