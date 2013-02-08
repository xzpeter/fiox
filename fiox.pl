#!/usr/bin/perl -w

# This is totally free and use it at your own risk. Enjoy!
# mail: xzpeter@gmail.com

#######################################################
# package MultiConf
#######################################################
package MultiConf;

use strict;
use warnings;
use Carp;
use Carp::Assert;
use Data::Dumper;

# $SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

sub _do_read ($) {
	open my $file, "<", $_[0] or die "Failed to open $_[0]: $!";
	my $data = [];
	@$data = <$file>;
	close $file;
	return $data;
}

# arg1: key name
# arg2: array ref that points to an array containing all
# the possible cases for this key
# arg3: array ref of current cases, should be: [{}, {},...], each case is a hash ref
sub _generate_cases ($$$) {
	my ($key, $choices, $cases) = @_;
	assert(ref $choices eq "ARRAY");
	assert(ref $cases eq "ARRAY");
	my $new_cases = [];
	foreach my $case (@$cases) {
		foreach my $choose (@$choices) {
			my $new;
			%$new = %$case;
			$new->{$key} = $choose;
			push @$new_cases, $new;
		}
	}
	return $new_cases;
}

sub _do_parse ($) {
	my $data = shift;
	my $table = {};
	foreach (@$data) {
		# parse things like:
		# ; $bs = [512 1k 2k 4k 8k 16k]
		if (/^;+\s+(\$\w+)\s*=\s*\[([^]]+)\]\s*$/) {
			my $list = [];
			@$list = split /\s/, $2;
			$table->{$1} = $list;
		}
	}
	die "This is not a SUPER fio config file! Just run it directly with fio!"
		if not scalar keys %$table;
	return $table;
}

# generate all possible cases from the variable table
sub _do_generate_cases ($) {
	my $table = shift;
	my $cases = [{}];
	foreach my $key (keys %$table) {
		$cases = _generate_cases($key, $table->{$key}, $cases);
	}
	return $cases;
}

sub new () {
	my ($class, $self) = @_;
	assert(defined $self->{file});
	my $data = _do_read($self->{file});
	my $table = _do_parse($data);
	my $cases = _do_generate_cases($table);
	die "No case found! " if not scalar @$cases;
	$self->{data} = $data;
	$self->{table} = $table;
	$self->{current} = shift @$cases;
	$self->{cases} = $cases;
	return bless($self, $class);
}

sub get_current_conf () {
	my $this = shift;
	my $case = $this->{current};
	return undef if not defined $case;
	my $conf;
	@$conf = @{$this->{data}};
	foreach my $line (@$conf) {
		next if $line =~ /^;/;
		foreach my $key (keys %$case) {
			$line =~ s/\Q$key/$case->{$key}/g;
		}
	}
	return $conf;
}

sub get_current_case () {
	return shift->{current};
}

sub next () {
	my $this = shift;
	$this->{current} = shift @{$this->{cases}};
	return $this->{current};
}

sub test () {
	my $conf = new MultiConf({file => 'test.fio'});
	do {
		print "===case===\n";
		print Dumper $conf->get_current_case();
		<>;
		print "===conf===\n";
		print @{$conf->get_current_conf()};
		<>;
	} while ($conf->next());
}

package main;

use strict;
use warnings;
use Data::Dumper;
# use MultiConf;
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
	
	my $log_file = "$casedir/result_${hash_str}.txt";
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
