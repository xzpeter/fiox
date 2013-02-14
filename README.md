needed libraries:
- Carp::Assert
- JSON::Parse

Please install these libraries first. I would like to suggest to use
'cpanm' to do it. :)

fiox.pl is a wrapper for fio to parse more powerful '*.fiox' conf files.
'*.fiox' files support benchmark with multiple configurations in one
shot. For example, I want to see how my SAS 15K disk perform with various
block size/iodepth/iopattern, I may 

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

[sdb]
filename=/dev/sdb

This config file will run fio for 3x4x2=24 times (cases), with different bs
values from 512,4k,64K, and iodepth from 1,2,4,8, with buffered or not.

Script will create a temporary directory under the working dir, and all
the results will be put under that. 

