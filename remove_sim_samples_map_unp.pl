#!/usr/bin/perl -w
#
# script to remove samples used in simulation, part 2: mapping file
#
# by Jon Ahlinder

use warnings;

die "usage: remove_sim_samples_map.pl <mapping filename> <log file> <name of sim sample>\n" if ( $#ARGV != 2 );

chomp($file = $ARGV[0]);
chomp($log = $ARGV[1]);
chomp($sim = $ARGV[2]);

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
my $hit1 = 0;
foreach my $line (@LIST){
    my $hit = 0;
  
    foreach my $el (sort keys %selfiles){
	if($line=~/$el/){ $hit = 1; }
    }
    if($hit==0){
	if(($line =~ m/natural/ || $line =~ m/background/ || $line =~ m/raw_water/) && $hit1 == 0){
	    print $line . "\n";
            @tmp = split('\t',$line);
	    $line =~ s/$tmp[0]/$sim/g;
	    $line =~ s/Source/Sink/g; 
	    $line =~ s/source/sink/g; 
	    $line =~ s/natural/simulated/g;
	    $line =~ s/raw_water/simulated/g;
	    $line =~ s/background/simulated/g;
	    print $line . "\n";
            $hit1 = 1;
	}
	else { 
	    print $line . "\n"; 

	} 
    }
}
