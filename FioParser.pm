package FioParser;

use strict;
use warnings;
use Data::Dumper;

sub _assert ($) {
	shift or die "Assert failed!";
}

sub _do_parse_output($) {
	my $data = shift;
	my $ret = {};
	_assert(ref $data eq "ARRAY");
	foreach (@$data) {
		my @res;
		@res = /io=.*bw=([^,]+), iops=(\d+), runt=\s*(\d+m?sec)$/;
		if (@res) {
			$ret->{bw} = $res[0];
			$ret->{iops} = $res[1];
			$ret->{runt} = $res[2];
			next;
		}
		@res = /clat \((\w+)\).*avg= *([\d.]+),/;
		if (@res) {
			$ret->{clat} = $res[1].$res[0];
			next;
		}
		@res = /slat \((\w+)\).*avg= *([\d.]+),/;
		if (@res) {
			$ret->{slat} = $res[1].$res[0];
			next;
		}
	}
	return $ret;
}

sub parse_output ($) {
	my $output_file = shift;
	open my $file, "<$output_file" or die "cannot open file $output_file: $!";
	my @data = <$file>;
	close $file;
	return _do_parse_output(\@data);
}

sub test() {
	my @data = <DATA>;
	my $result = _do_parse_output(\@data);
	print Dumper $result;
}

1;

__DATA__
sdb: (g=0): rw=randread, bs=4K-4K/4K-4K, ioengine=libaio, iodepth=1
Starting 1 process

sdb: (groupid=0, jobs=1): err= 0: pid=15861
  read : io=1024KB, bw=5753KB/s, iops=1438, runt=   178msec
    slat (usec): min=21, max=132, avg=36.83, stdev=13.46
    clat (usec): min=179, max=42587, avg=649.07, stdev=3097.95
  cpu          : usr=0.00%, sys=9.04%, ctx=256, majf=0, minf=27
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued r/w: total=256/0, short=0/0
     lat (usec): 250=60.94%, 500=33.20%, 750=1.17%, 1000=0.78%
     lat (msec): 2=1.17%, 4=0.78%, 10=0.39%, 20=1.17%, 50=0.39%

Run status group 0 (all jobs):
   READ: io=1024KB, aggrb=5752KB/s, minb=5890KB/s, maxb=5890KB/s, mint=178msec, maxt=178msec

Disk stats (read/write):
  sda: ios=206/0, merge=0/0, ticks=144/0, in_queue=144, util=57.83%
