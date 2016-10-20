#!/usr/bin/perl -w
#
# script to rename simulated samples
#
# by Jon Ahlinder

use warnings;

die "usage: rename_sim_samples.pl <filename>\n" if ( $#ARGV != 0 );

chomp($file = $ARGV[0]);
my $name = ();
my @tmp = split('\.',$file);

if($tmp[0]=~'/'){
    @tmp1 = split('/',$tmp[0]);
    my $nel = scalar @tmp1 - 1;
    $name = $tmp1[$nel];

}
else{ $name = $tmp[0]; }

open(FILE, "<$file" ) or die "Can't open $file : $!";
chomp(@LIST = <FILE>);
close(FILE);

foreach my $line (@LIST){
    if($line=~'>'){
	@tmp = split('_',$line);
	$line = '>' . $name . '_' . $tmp[1];
    }
    print $line . "\n";
}
