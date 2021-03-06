#!/usr/bin/perl -w
use strict;
use warnings;
my $BEGIN_TIME=time();
use Getopt::Long;
my ($fqlist,$outdir,$method,$step,$stop,$sample,$start,$popmap);
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
my $version="2.1.0";
GetOptions(
	"help|?" =>\&USAGE,
	"fqlist:s"=>\$fqlist,
	"outdir:s"=>\$outdir,
	"method:s"=>\$method,
	"sample:s"=>\$sample,
	"gro:s"=>\$popmap,
	"step:s"=>\$step,
	"stop:s"=>\$stop,
	"start:s"=>\$start,
			) or &USAGE;
&USAGE unless ($fqlist and $outdir and $popmap);
$method||="RAD";
$start||=0;
mkdir $outdir if (!-d $outdir);
$fqlist=ABSOLUTE_DIR($fqlist);
$outdir=ABSOLUTE_DIR($outdir);
$popmap=ABSOLUTE_DIR($popmap);

mkdir "$outdir/work_sh" if (!-d "$outdir/work_sh");
$step||=1;
$stop||=-1;
open LOG,">$outdir/work_sh/STACKS.$BEGIN_TIME.log";
if ($step == 1) {
	print LOG "########################################\n";
	print LOG "fastq qc\n"; my $time=time();
	print LOG "########################################\n";
	my $job="perl $Bin/bin/step01.fastqqc.pl -fqlist $fqlist -outdir $outdir/01.fastq-qc -dsh $outdir/work_sh -proc 20";
	print LOG "$job\n";
	`$job`;
	print LOG "$job\tdone!\n";
	print LOG "########################################\n";
	print LOG "Done and elapsed time : ",time()-$time,"s\n";
	print LOG "########################################\n";
	$step++ if ($step ne $stop);
}
if ($step == 2) {
	print LOG "########################################\n";
	print LOG "fastq uniform\n"; my $time=time();
	print LOG "########################################\n";
	my $job="perl $Bin/bin/step02.uniform.pl -fqlist $fqlist -out $outdir/02.uniform -method $method -dsh $outdir/work_sh  -proc 20";
	print LOG "$job\n";
	`$job`;
	print LOG "$job\tdone!\n";
	print LOG "########################################\n";
	print LOG "Done and elapsed time : ",time()-$time,"s\n";
	print LOG "########################################\n";
	$step++ if ($step ne $stop);
}
if ($step == 3) {
	print LOG "########################################\n";
	print LOG "ustacks\n"; my $time=time();
	print LOG "########################################\n";
	my $fqlist=ABSOLUTE_DIR("$outdir/02.uniform/fq.list");
	my $total_sample = `wc -l $outdir/02.uniform/fq.list`;
	chomp $total_sample;
	$total_sample=(split(/\s+/,$total_sample))[0];
	my $check_sample = `ls $outdir/02.uniform/\*.check|wc -l`;
	chomp $check_sample;
	$check_sample = (split(/\s+/,$check_sample))[0];
	if ($total_sample ne $check_sample){
		print "There are some wrong in step02.uniform,please check!";die;
	}
	my $job="perl $Bin/bin/step03.ustacks.pl -fqlist $fqlist -out $outdir/03.ustacks -dsh $outdir/work_sh  -proc 20 -start $start";
	print LOG "$job\n";
	`$job`;
	print LOG "$job\tdone!\n";
	print LOG "########################################\n";
	print LOG "Done and elapsed time : ",time()-$time,"s\n";
	print LOG "########################################\n";
	$step++ if ($step ne $stop);
}
if ($step == 4) {
	print LOG "########################################\n";
	print LOG "cstacks\n"; my $time=time();
	print LOG "########################################\n";
	my $ustacks=ABSOLUTE_DIR("$outdir/03.ustacks");
	my $total_sample = `wc -l $outdir/03.ustacks/ustacks.list`;
	chomp $total_sample;
	$total_sample=(split(/\s+/,$total_sample))[0];
	my $check_sample = `ls $outdir/03.ustacks/\*.check|wc -l`;
	chomp $check_sample;
	$check_sample = (split(/\s+/,$check_sample))[0];
	if ($total_sample ne $check_sample){
		print "There are some wrong in step03.ustacks,please check!";die;
	}
	my $job="perl $Bin/bin/step04.cstacks.pl -ulist $ustacks -out $outdir/04.cstacks -dsh $outdir/work_sh ";
	$job.="-sample $sample" if($sample);
	print LOG "$job\n";
	`$job`;
	print LOG "$job\tdone!\n";
	print LOG "########################################\n";
	print LOG "Done and elapsed time : ",time()-$time,"s\n";
	print LOG "########################################\n";
	$step++ if ($step ne $stop);
}
if ($step == 5) {
	print LOG "########################################\n";
	print LOG "sstacks\n"; my $time=time();
	print LOG "########################################\n";
	my $cstacks=ABSOLUTE_DIR("$outdir/04.cstacks");
	my $ustacks=ABSOLUTE_DIR("$outdir/03.ustacks/ustacks.list");
	my $check_sample = `wc -l $outdir/04.cstacks/sample.list`;
	chomp $check_sample;
	$check_sample = (split(/\s+/,$check_sample))[0];
	my $check_log = `ls $outdir/04.cstacks/\*.log|wc -l`;
	chomp $check_log;
	$check_log = (split(/\s+/,$check_log))[0];
	if ($check_sample ne $check_log) {
		print "There is some wrong in step04.cstacks ,please check!";die;
	}
	my $job="perl $Bin/bin/step05.sstacks.pl -ulist $ustacks -clist $cstacks -out $outdir/05.sstacks -dsh $outdir/work_sh -proc 20";
	print LOG "$job\n";
	`$job`;
	print LOG "$job\tdone!\n";
	print LOG "########################################\n";
	print LOG "Done and elapsed time : ",time()-$time,"s\n";
	print LOG "########################################\n";
	$step++ if ($step ne $stop);
}

if ($step == 6) {
	print LOG "########################################\n";
	print LOG "genotype\n"; my $time=time();
	print LOG "########################################\n";
	my $ustacks=ABSOLUTE_DIR("$outdir/03.ustacks/ustacks.list");
	my $cstacks=ABSOLUTE_DIR("$outdir/04.cstacks/cstacks.list");
	my $sstacks=ABSOLUTE_DIR("$outdir/05.sstacks");
	my $check_sample = `wc -l $outdir/05.sstacks/sstacks.list`;
	chomp $check_sample;
	$check_sample = (split(/\s+/,$check_sample))[0];
	my $check_log = `ls $outdir/05.sstacks/\*.check|wc -l`;
	chomp $check_log;
	$check_log = (split(/\s+/,$check_log))[0];
	if ($check_sample ne $check_log) {
		print "There is some wrong in step05.sstacks ,please check!";die;
	}
	my $job="perl $Bin/bin/step06.genotype.pl -ulist $ustacks -clist $cstacks -slist $sstacks -gro $popmap -out $outdir/06.genotype -dsh $outdir/work_sh ";
	print LOG "$job\n";
	`$job`;
	print LOG "$job\tdone!\n";
	print LOG "########################################\n";
	print LOG "Done and elapsed time : ",time()-$time,"s\n";
	print LOG "########################################\n";
	$step++ if ($step ne $stop);
}
if ($step == 7) {
	print LOG "########################################\n";
	print LOG "stacks stat\n"; my $time=time();
	print LOG "########################################\n";
	my $stacks=ABSOLUTE_DIR("$outdir/03.ustacks/ustacks.list");
	my $vcf=ABSOLUTE_DIR("$outdir/06.genotype/populations.snps.vcf");
	my $job="perl $Bin/bin/step07.stackstat.pl -ulist $stacks -vcf $vcf -out $outdir/07.stacksstat -dsh $outdir/work_sh ";
	print LOG "$job\n";
	`$job`;
	print LOG "$job\tdone!\n";
	print LOG "########################################\n";
	print LOG "Done and elapsed time : ",time()-$time,"s\n";
	print LOG "########################################\n";
	$step++ if ($step ne $stop);
}
if ($step == 8) {
	print LOG "########################################\n";
	print LOG "stacks stat\n"; my $time=time();
	print LOG "########################################\n";
	my $stacks=ABSOLUTE_DIR("$outdir/07.stacksstat/");
	my $vcf=ABSOLUTE_DIR("$outdir/06.genotype/");
	my $fastqc=ABSOLUTE_DIR("$outdir/01.fastq-qc/");
	my $job="perl $Bin/bin/step08.report.pl -statdir $stacks -vcfdir $vcf -fastqc $fastqc -out $outdir/08.report -dsh $outdir/work_sh ";
	print LOG "$job\n";
	`$job`;
	print LOG "$job\tdone!\n";
	print LOG "########################################\n";
	print LOG "Done and elapsed time : ",time()-$time,"s\n";
	print LOG "########################################\n";
	$step++ if ($step ne $stop);
}

close LOG;
#######################################################################################
print STDOUT "\nDone. Total elapsed time : ",time()-$BEGIN_TIME,"s\n";
#######################################################################################
sub ABSOLUTE_DIR #$pavfile=&ABSOLUTE_DIR($pavfile);
{
	my $cur_dir=`pwd`;chomp($cur_dir);
	my ($in)=@_;
	my $return="";
	if(-f $in){
		my $dir=dirname($in);
		my $file=basename($in);
		chdir $dir;$dir=`pwd`;chomp $dir;
		$return="$dir/$file";
	}elsif(-d $in){
		chdir $in;$return=`pwd`;chomp $return;
	}else{
		warn "Warning just for file and dir \n$in";
		exit;
	}
	chdir $cur_dir;
	return $return;
}


sub USAGE {#
        my $usage=<<"USAGE";
Contact:        minghao.zhang\@majorbio.com;
Script:			$Script
Description:
	fq thanslate to fa format
	eg:
	perl $Script -i -o -k -c

Usage:
  Options:
	"fqlist:s"=>\$fqlist,  input fastq.list
	"outdir:s"=>\$outdir,  output dir
	"method:s"=>\$method,  RAD or GBS
	"sample:s"=>\$sample,  input sample.list for cstacks
	"gro:s"=>\$popmap,	input group.list
	"step:s"=>\$step,	pipeline control for start 

          01 fastq qc
          02 fastq uniform lenth
          03 ustacks
          04 cstacks
          05 sstacks
          06 genotype
          07 stat
		  08 report

	"stop:s"=>\$stop,   pipeline control for stop
	"start:s"=>\$start,  loci of analysied data ,default 1
  -h         Help

USAGE
        print $usage;
        exit;
}
