#!/usr/bin/perl -w
#
# script to mix samples to mimic a contamination
#
# by Jon Ahlinder

use warnings;

use List::Util qw(shuffle);

die "usage: pipeline_mix_reads.pl <working dir contamination> <no of contaminating samples> <no of reads per sample> <working dir rawwater> <no of rawwaters> <no of reads per rawwater> <save name> <replicates> <verbosity>\n" if ( $#ARGV != 8 );

chomp($cont_dir = $ARGV[0]);
chomp($no_cont = $ARGV[1]);
chomp($no_reads_cont = $ARGV[2]);
chomp($raw_dir = $ARGV[3]);
chomp($no_raw = $ARGV[4]);
chomp($no_reads_raw = $ARGV[5]);
chomp($save_dir = $ARGV[6]);
chomp($rep = $ARGV[7]);
chomp($verbosity = $ARGV[8]);

opendir(D,$cont_dir) || die "Can't open the directory $cont_dir: $!\n";
my @list = grep { (!/^\./) && -f "$cont_dir/$_" } readdir(D); 
closedir(D);

opendir(Dir,$raw_dir) || die "Can't open the directory $raw_dir: $!\n";
my @list2 = grep { (!/^\./) && -f "$raw_dir/$_" } readdir(Dir); 
closedir(Dir);

if($verbosity==1){ print "files available:\n"; }
foreach $f (@list2){
    if($verbosity==1){ print $f . " "; }
}
if($verbosity==1){ print "\n"; }


my $tmp_dir = $raw_dir . "/tmp";
my $command = "mkdir " . $tmp_dir;
if($verbosity==1){ print "command: $command\n"; }
system($command);
$tmp_dir = $cont_dir . "/tmp";
$command = "mkdir " . $tmp_dir;
if($verbosity==1){ print "command: $command\n"; }
system($command);
my $no_files = @list;

for ($k = 1; $k <= $rep; $k++){
    my $logfile = $save_dir . "_" . $k . ".log";
    open(FILE, ">$logfile" ) or die "Can't open $logfile : $!";  
    print FILE "*****************************\n\n";
    print FILE "Repetition: $k\n\n";
    print "*****************************\n\n";
    print "Repetition: $k\n\n";
    my %hash = ();
  
 
    if($verbosity==1){ print "The number of files: $no_files\n"; }
    # select x nr of samples to mix
    for($i = 0; $i < $no_cont; $i++){
	my $j = $i +1;
	if($verbosity==1){ print "fixing contamination nr: $j\n"; }
	print FILE "*****************************\n\n";
	print FILE "contamination no $j\n";
	my @list = shuffle(@list);    
	$current_file = $cont_dir . "/" . $list[0];
	if($verbosity==1){ print "infile: $current_file\n"; }
	print FILE "selected file: $current_file\nno of reads: $no_reads_cont\n";
	$command = "cat " . $current_file . " | cut -d' ' -f1 > " . $cont_dir . "/tmp_cont.fasta";
	$current_tmp_file = $cont_dir . "/tmp_cont.fasta";
	system($command);
	$outfile = $tmp_dir . "/cont_nr_" . $j . "_r_" . $no_reads_cont . ".fasta";
	# add current outfile to hash
	$files{$outfile} = $j;
	if($verbosity==1){ print "outfile: $outfile\n"; }
	$command = "o-subsample-fasta-file " . $current_tmp_file . " " . $no_reads_cont . " " . $outfile;
	if($verbosity==1){ print "command: $command\n"; }
	system($command);
	$command = "rm " . $current_tmp_file;
	system($command);
    }
    
      
    if($verbosity==1){ print "Subsample raw waters...\n"; }

    my $tmp_dir = $raw_dir . "/tmp";
    my $no_files = @list2;
   
    if($verbosity==1){   print "no of files in raw water directory: $no_files\n"; }
    for($i = 0; $i < $no_raw; $i++){
	my $j = $i +1;
	if($verbosity==1){ print "fixing raw water nr: $j\n"; }
	print FILE "*****************************\n\n";
	print FILE "raw water no $j\n";
	my @list2 = shuffle(@list2);    
	# my $nr=int(rand($no_files));
	$current_file = $raw_dir . "/" . $list2[0];
	if($verbosity==1){ print "infile: $current_file\n"; }
	$command = "cat " . $current_file . " | cut -d' ' -f1 > " . $raw_dir . "/tmp_raw.fasta";
	$current_tmp_file = $raw_dir . "/tmp_raw.fasta";
        if($verbosity==1){ print $command . "\n"; }
	system($command);
	$outfile = $tmp_dir . "/raw_nr_" . $j . "_r_" . $no_reads_cont . ".fasta";
	# add current outfile to hash
	$files{$outfile} = $j;
	print FILE "selected file: $current_file\nno of reads: $no_reads_raw\n";
	if($verbosity==1){ print "outfile: $outfile\n"; }
	$command = "o-subsample-fasta-file " . $current_tmp_file . " " . $no_reads_raw . " " . $outfile;
	if($verbosity==1){ print "command: $command\n"; }
	system($command);
	$command = "rm " . $current_tmp_file;
	system($command);
    }
    my $tmp;
    $j = 1;
    foreach $el (keys %files){
	if($j > 1){ $tmp = $tmp . " " . $el; }
	else{ 
	    $tmp = $el; 
	    $j = 2;
	}
    }
    $command = "cat " . $tmp . " > " . $save_dir . "_" . $k . ".fasta";
    system($command);
    if($verbosity==1){ print "remove tmp files...\n"; }
    $command = "rm " . $cont_dir . "/tmp/*";
    system($command);
    $command = "rm " . $raw_dir . "/tmp/*";
    system($command);
    close(FILE);
}
if($verbosity==1){ print "mixing done!\n"; }
$command = "rm -R " . $cont_dir . "/tmp";
system($command);
$command = "rm -R " . $raw_dir . "/tmp";
system($command);
