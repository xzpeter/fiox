needed libraries:
- Carp::Assert
- JSON::Parse

Please install these libraries first. I would like to suggest to use
'cpanm' to do it. :)

--------------------------------------

Usage: ./fiox.pl fiox_conf_file

fiox_conf_file:     configure file (*.fiox)

fiox.pl is a wrapper for fio to parse more powerful '*.fiox' conf files.
'*.fiox' files support benchmark with multiple configurations in one
shot, like: 

====================================================
; $bs = [512 4k 64k]
; $iodepth = [1 2 4 8]
; $direct = [0 1]

[global]
rw=randread
direct=$direct
ioengine=libaio
iodepth=$iodepth
numjobs=1
bs=$bs

;[sdb]
;filename=/dev/sdb

[test]
size=8M
directory=/home/xz/tmp/

====================================================

This config file will run fio for 3x4x2=24 times (cases), with different bs
values from 512,4k,64K, and iodepth from 1,2,4,8, with buffered or not.

Script will create a temporary directory under the working dir, and all
the results will be put under that. 

