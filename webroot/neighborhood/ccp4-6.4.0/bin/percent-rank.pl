#!/usr/bin/perl -w

# Sort EDSTATS overall statistics in 'pdb-edstats.out' (see table below)
# obtained from a set of ~ 600 structures from PDB_REDO with > 100
# protein residues and Rfree <= 0.175.  Extract corresponding data from
# EDSTATS standard outputs specified on the command line and print out
# per-cent ranks for each item.

#  1:  High res.
#  2:  Mean B.
#  3:  QQZ-
#  4:  QQZ+
#  5:  % RSZD- < -3 sigma
#  6:  % RSZD+ >  3 sigma

open IN,'pdb-edstats.out' or $ENV{PDB_EDSTATS} &&
  open IN,$ENV{PDB_EDSTATS} or
  die "\nERROR: pdb-edstats.out statistical data not found,";

# Read the statistics table, omitting overflows (+-99.99).
while(<IN>)
{ @s=split;
  push @qqzns,-$s[2] if $s[2]>-99.99;
  push @qqzps,$s[3] if $s[3]<99.99;
  push @pzdns,$s[4];
  push @pzdps,$s[5];
}

# Sort the arrays in decreasing order of score, so that the "worst"
# value (highest numerical score) is ranked 0% and the "best" (lowest)
# score is ranked 100%.

@qqzns=sort{$b<=>$a} @qqzns;

@qqzps=sort{$b<=>$a} @qqzps;

@pzdns=sort{$b<=>$a} @pzdns;

@pzdps=sort{$b<=>$a} @pzdps;

# Read the EDSTATS log file(s).
$n=0;
for $log(@ARGV)
{ open IN,$log or die "\nERROR: log file $log not found,";

  $rh=$ba=$qqzn=$qqzp=$pzdn=$pzdp='';

# Extract the relevant data.
  $i=0;
  while(<IN>)
  { if(/\s*RESHI\s*=\s*(\S+)/) {$rh=$1}
    elsif(/^Overall mean B.*:\s*(\S+)/) {$ba=$1}
    elsif(/^Q-Q plot Z.+:\s+(\S+)\s+(\S+)/)
      {($qqzn,$qqzp)=($1,$2)}
    elsif(/^RSZ\S+ /) {++$i}
    elsif(/^\s*-?(\d)\.0\s+\d+\s+\S+\s+\d+\s+\S+\s+\d+\s+(\S+)/)
    { if($i==1 && $1==3) {$pzdn=$2}
      elsif($i==2 && $1==3) {$pzdp=$2}
    }
  }

  close IN;

# Calculate & print the per-cent ranks.
  print "\n      Statistic          value   rank%\n\n" if !$n++;
  print "$log:\n" if @ARGV>1;

  pcrank('      Q-Q plot ZD-    ',\@qqzns,-1,-$qqzn);

  pcrank('      Q-Q plot ZD+    ',\@qqzps,1,$qqzp);

  pcrank('    % RSZD- < -3 sigma',\@pzdns,1,$pzdn);

  pcrank('    % RSZD+ >  3 sigma',\@pzdps,1,$pzdp);
  print "\n";
}


# Calculate & print the per-cent rank.
sub pcrank
{ my($s,$a,$k,$x)=@_;
  my $y;

  if($x>$$a[0])
  { $y=0;
#    printf "\n  0  $$a[0]  %6.1f\n",$y;
  }
  elsif($x<$$a[-1])
  { $y=100;
#    printf "\n  $#$a  $$a[-1]  %6.1f\n",$y;
  }
  else
  { for($i=$#$a;$i>=0;--$i)
    { if($x<=$$a[$i])
      { if($i==$#$a)
        { $y=100;
#	  printf "\n  $i  $$a[$i]  %6.1f\n",$y;
	}

# Interpolate in the table.
	else
        { $j=$i+1;
	  $y=100*($$a[$i]*$j-$$a[$j]*$i-$x)/(@$a*($$a[$i]-$$a[$j]));
#	  $y=($$a[$i]*$j-$$a[$j]*$i-$x)/($$a[$i]-$$a[$j]);
#	  printf "\n$i  $$a[$i]  $j  $$a[$j]  %6.1f\n",$y;
#	  $y*=100/@$a;
	}
	last;
      }
    }
  }

  printf "%-20s  %6.1f  %5.1f%%\n",$s,$k*$x,$y;
}
