package FioxDataParser;

use strict;
use warnings;
use FioParser;
use Data::Dumper;

sub parse_dir($) {
	# this dir should be the root dir of fiox results
	my $dir = shift;
	my @subdirs = `cd $dir; ls -l | grep ^d | awk '{print \$9}'`;
	my @vars = ();
	my @results = ();

	my $cnt = 0;
	# open summary data file for write
	my $out_file = "$dir/summary_output.csv";
	open my $out, ">$out_file" or die "cannot open file $out_file: $!";

	foreach (@subdirs) {
		# get param list using the dir name
		chomp;
		my %pairs = grep /^.+$/, split /_+/;

		# get output file name
		my $output_dir = $dir."/".$_;
		my $output_file = $output_dir."/".`cd $output_dir; ls result*.txt`;
		# get result list using FioParser
		my $res = FioParser::parse_output($output_file);

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
		$datastr .= ",,";
		$datastr .= join ",", map {$res->{$_}} @results;
		print $out $datastr."\n";
	}
	close $out;
}

sub test () {
	parse_dir("/home/xz/org/result/result_sas-15k_130208_201321");
}

1;
