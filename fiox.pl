#!/usr/bin/perl -w

# This is totally free and use it at your own risk. Enjoy!
# mail: xzpeter@gmail.com

use strict;
use warnings;
use Data::Dumper;
use MultiConf;
use Term::ANSIColor;
use File::Basename;

my @sample_conf = <DATA>;

sub usage () {
	print "
Usage: " . __FILE__ . " fiox_conf_file

fiox_conf_file:     configure file (*.fiox)

fiox.pl is a wrapper for fio to parse more powerful '*.fiox' conf files.
'*.fiox' files support benchmark with multiple configurations in one
shot, like: 

====================================================
" . join("", @sample_conf) . "
====================================================

This config file will run fio for 3x4x2=24 times (cases), with different bs
values from 512,4k,64K, and iodepth from 1,2,4,8, with buffered or not.

Script will create a temporary directory under the working dir, and all
the results will be put under that. 

";

	exit (0);
}

sub _date () {
	my $str = 'date +%y%m%d_%H%M%S';
	my $val = `$str`;
	chomp $val;
	return $val;
}

sub check_fio () {
	`which fio`;
	die "You need to install fio first! " if $?;
}

sub disp ($@) {
	my ($words, $type) = @_;
	$words = colored($words, $type) if $type;
	print _date() . ": $words\n";
}

sub hash_to_str ($) {
	my $hash = shift;
	return join ", ", map {"$_=$hash->{$_}"} keys %$hash;
}

sub run ($) {
	my $cmd = shift;
	disp "running command: $cmd";
	`$cmd`;
	die "run command '$cmd' failed: $!" if $?;
}

usage() if scalar @ARGV != 1;
check_fio();

my $conf_file = $ARGV[0];
my $taskname = basename $conf_file;
$taskname =~ s/\.[^.]+$//;

my $mconf = new MultiConf({file => $ARGV[0]});
my $cnt = 0;

disp "Benchmark task '$taskname' started...", "red bold";
my $dirname = "result_" . $taskname . "_" . _date();
run "mkdir $dirname";

do {
	++$cnt;
	my $case = $mconf->get_current_case();
	my $hash_str = hash_to_str($case);
	disp "Starting testcase $cnt with param: " . $hash_str, "green bold";

	# make case directory
	$hash_str =~ s/[=, \$]+/_/g;
	my $casedir = "$dirname/" . $hash_str;
	run "mkdir -p $casedir";

	# make case config file for fio
	my $conf_fname = "$casedir/config_${hash_str}.fio";
	open my $conf_fd, ">", $conf_fname or die "Failed to open conf file $conf_file: $!";
	my $conf_data = $mconf->get_current_conf();
	print $conf_fd "; " . hash_to_str($case) . "\n";
	print $conf_fd @$conf_data;
	close $conf_fd;
	
	my $log_file = "$casedir/result.txt";
	run "fio --output $log_file $conf_fname";
} while ($mconf->next());

disp "Benchmark all done!", "red bold";

__END__
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
