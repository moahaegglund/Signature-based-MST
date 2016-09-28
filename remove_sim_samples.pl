#!/usr/bin/perl -w
#
# script to remove samples used in simulation
#
# by Jon Ahlinder

use warnings;

die "usage: remove_sim_samples.pl <filename> <log file>\n" if ( $#ARGV != 1 );

chomp($file = $ARGV[0]);
chomp($log = $ARGV[1]);

open(FILE, "<$log" ) or die "Can't open $log : $!";
chomp(@LIST = <FILE>);
close(FILE);

my %selfiles=();

foreach my $line (@LIST){

    if($line=~m/selected file/){
	@tmp = split('\/',$line);
        $el = scalar @tmp;
        $tmp[$el-1] =~ s/\.fasta$//;
	$selfiles{$tmp[$el-1]} = 1;
    }
}

open(FILE, "<$file" ) or die "Can't open $file : $!";
chomp(@LIST = <FILE>);
close(FILE);

foreach my $line (@LIST){
    if(!exists($selfiles{$line})){ print $line . "\n"; }
}
