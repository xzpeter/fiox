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

1;

__END__
; $bs = [512 4k 16k]
; $iodepth = [1 2 4 8]

[global]
rw=randread
direct=1
ioengine=libaio
iodepth=1
numjobs=1
bs=$bs

;[sdb]
;filename=/dev/sdb

[test]
size=8M
directory=/home/xz/tmp/
