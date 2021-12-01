#!/usr/bin/perl -w

# Prints out statistics for a single residue from EDSTATS output files.

if(@ARGV<2)
{ use File::Basename;
  die "Usage: ${\basename($0)}  a:nnnnx  edstats-1.out  ...\n";
}

($c,$r)=split(/ +|:/,$ARGV[0]);
if($r=~/^(\d+)(\D)$/) {($r,$i)=($1,$2)}
else {$i=' '}
$r=sprintf '%s %4s',$c,$r;
print "\nResidue: '$r$i'\n";
shift;

print "\n";
for $a(@ARGV)
{ print "$a\n" if @ARGV>1;
  open IN,$a or die "ERROR opening $a,";
  $l=(length($_=<IN>)-11)/3;
  ($_=substr($_,11,$l))=~s/m\b/ /g;
  print " $_\n";
  $o1=11+$l;
  $o2=$o1+$l;
  while(<IN>)
  { if(substr($_,4,6) eq $r && substr($_,10,1) eq $i)
    { print substr($_,11,$l),"\n",substr($_,$o1,$l),"\n",
        substr($_,$o2),"\n";
      last;
    }
  }
  close IN;
}
