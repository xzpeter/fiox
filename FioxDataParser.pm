package FioxDataParser;

use strict;
use warnings;
use FioParser;
use Data::Dumper;
use JSON::Parse qw/json_to_perl/;
use constant DEF_FIO_PARSE_FORMAT => "json";

sub _parse_normal_output ($) {
	return FioParser::parse_output(shift);
}

sub _parse_json_output ($) {
	my $filename = shift;
	open my $file, "<$filename" or die "Cannot open file $filename: $!";
	my @vals = <$file>;
	close $file;
	my $hash = json_to_perl(join "", @vals);
	my $job = $hash->{jobs}[0];
	my $res = {};
	$res->{$_} = $job->{$_} foreach (qw/usr_cpu sys_cpu error/);
	foreach my $dir (qw/read write/) {
		$res->{"${dir}_".$_} = $job->{$dir}{$_} foreach (qw/bw iops io_bytes runtime/);
		$res->{"${dir}_".$_} = $job->{$dir}{$_}{mean} foreach (qw/slat clat/);
	}
	return $res;
}

my %format_list = (
	"normal" => \&_parse_normal_output,
	"json" => \&_parse_json_output,
);

sub parse_dir($@) {
	# this dir should be the root dir of fiox results
	my ($dir, $format) = @_;
	my @subdirs = `cd $dir; ls -l | grep ^d | awk '{print \$9}'`;
	my @vars = ();
	my @results = ();

	$format = DEF_FIO_PARSE_FORMAT if not defined $format;
	my $output_parser = $format_list{lc $format} or die "Don't support format: $format!";

	my $cnt = 0;
	# open summary data file for write
	my $out_file = "$dir/summary_output.csv";
	open my $out, ">$out_file" or die "cannot open file $out_file: $!";

	foreach (@subdirs) {
		# get param list using the dir name
		chomp;
		my %pairs = grep /^.+$/, split /_+/;

		# get output file name, and benchmark results
		my $output_dir = $dir."/".$_;
		my $output_file = $output_dir."/".`cd $output_dir; ls result*.txt`;
		my $res = &$output_parser($output_file);

		# if the first one, generate header of csv
		if (not @vars) {
			push (@vars, $_) foreach (keys %pairs);
			print $out join ",", @vars;
			# this (double commas: ",,") is the seperator of VARS and RESULTS!
			print $out ",,";
			push (@results, $_) foreach (keys %$res);
			print $out join ",", @results;
			print $out "\n";
		}

		# print "dir:$_,cnt:$cnt,".Dumper($res)."\n"; $cnt++;
		# generate shortened data string
		my $datastr = join ",", map {$pairs{$_}} @vars;
		$datastr .= ",," . join ",", map {$res->{$_}} @results;
		print $out $datastr."\n";
	}
	close $out;
}

sub test () {
	# my $res = _parse_json_output("/home/xz/git-repo/fiox/result_sas-15k_130214_230234/_iodepth_16_bs_1M/result__iodepth_16_bs_1M.txt");
	# print Dumper $res;
	parse_dir("/home/xz/git-repo/fiox/result_sas-15k_130214_230234");
}

1;
