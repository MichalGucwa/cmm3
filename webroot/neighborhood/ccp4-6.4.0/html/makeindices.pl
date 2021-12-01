#!/usr/bin/perl

# CVS Id $Id$
#
#    Martyn Winn   February 1998
#
# Make an html menu of the contents of $CCP4/html based
# on (1) supported, etc. and (2) functionality groups
# Also produce whatis file for apropos command
#
# **** Not intended for public release ****
#

##### variables to be edited as desired

$indexfile = "INDEX.html";
$functionfile = "FUNCTION.html";
$whatisfile = "whatis";
$index_code = INDEX_INFO;       # identifying tag in program docs.

#####

# open output files

open(INDEX,">$indexfile") || die "Cannot open $indexfile for output!\n";
open(FUNCTION,">$functionfile") || die "Cannot open $functionfile for output!\n";
open(WHATIS,">$whatisfile") || die "Cannot open $whatisfile for output!\n";

#########################
#
# Print headers
#
#########################

# common header

$header = <<EOF;          
<!doctype html system "html.dtd">
<html>
<head><title>CCP4 Program Documentation</title></head>
<body  BGCOLOR="#FFFFFF">
<FONT COLOR="#FF0000"><H1>CCP4 v6.4.0 Program Documentation</H1></FONT>
<P><B><U><FONT SIZE="3">Reference:</FONT></U></B><BR>
Collaborative Computational Project, Number 4. 1994.<BR>
 &quot;The CCP4 Suite: Programs for Protein Crystallography&quot;. Acta Cryst. D50,
760-763 </P>
<p>
There is a partial list of <a href="REFERENCES.html">program references</a>
extracted from the individual program documentation.
<HR>

<P><B><U><FONT SIZE="3">Changes:</FONT></U></B><BR>
List of the <a href="CHANGESinV6_4.html">major program changes</a>
since the previous release.
<HR>
EOF

# print header to index file

print INDEX $header;
print INDEX <<EOF;

This list can also be seen in <a href="$functionfile">function grouping.</a>

EOF

# print header to function file

print FUNCTION $header;
print FUNCTION <<EOF;

This list can also be seen in <a href="$indexfile">alphabetical order.</a>

EOF

#########################
#
# Loop through all files in argument list, and extract
# necessary info
#
#########################

FILE: foreach $infile (@ARGV) {
  open(INFILE,"<$infile") || do {
	print STDERR "Can't open $infile: $!\n";
	next;
  };
  next if -d INFILE;    # ignore directories
  next if -B INFILE;    # ignore binary files
  while (<INFILE>) {
	if (m/$index_code/) {
# found relevant line, so parse it
          &parseindexline($_);
# associative array of filename for link
          $filename{$progname} = $infile;  
# associative array of program/description
          $progs{$progname} = $description;  
# associative array of program/comment
          $comments{$progname} = "(".$comment.")" if $comment; 
# associative array of index category / program list
          $indcats{$indcatname} .= $progname . "," if $indcatname;
# associative array of function category / program list
          for ($count = 0; $count < $numfuncat; $count++) {
            $funcats{$funcatname[$count]} .= $progname . "," if $funcatname[$count];
          }
          close(INFILE);
          next FILE;
	}
  };
  close(INFILE);
};

#########################
#
# Print indices to files
#
#########################

# Make an explicit list of our categories
# The categories will be indexed in the order that they appear in the list
# NB if new categories are added to the documentation then
# they must also be added here
@categories = ("BASIC", "GENERAL", "SUPPORTED", "UNSUPPORTED", "DEPRECATED", "LIBRARY",
               "FILE FORMATS");

# print program listing in supported, etc. categories

foreach $category (@categories) {
  chop($indcats{$category});
print INDEX <<EOF;                   # function category heading
<p>
<FONT COLOR="#FF0000"><H2>$category</H2></FONT>
<ul>
EOF
  foreach $prog (sort split(",",$indcats{$category})) {
print INDEX <<EOF;                   # prog. name + desc.
<li><a href=\"$filename{$prog}\">$prog</a> - $progs{$prog} </li> 
EOF
  }
print INDEX <<EOF;                
</ul>
EOF
}

# print program listing in functionality categories

foreach $category (sort keys(%funcats)) {
  chop($funcats{$category});
print FUNCTION <<EOF;                   # function category heading
<p>
<FONT COLOR="#FF0000"><H2>$category</H2></FONT>
<ul>
EOF
  foreach $prog (split(",",$funcats{$category})) {
print FUNCTION <<EOF;                   # prog. name + desc.
<li><a href=\"$filename{$prog}\">$prog</a> - $progs{$prog} $comments{$prog} </li> 
EOF
  }
print FUNCTION <<EOF;                
</ul>
EOF
}

# print whatis file

foreach $prog (sort keys(%progs)) {
  printf WHATIS "%-24s%s\n", $prog." (CCP4)", "- ".$progs{$prog};
}

exit 0;

####################################
#
#   SUBROUTINES
#
####################################

# Parse html comment line and extract fields

sub parseindexline {
	  local(@line) = split(/::/,$_[0]);

          shift @line until $line[0] eq $index_code;  # start from index codeword

          ($progname = $line[1]) =~ tr/A-Z/a-z/;      # lower case
          $progname = &tidystart($progname);          # remove leading blanks
          $progname = &tidyend($progname);            # remove trailing blanks
          $progname = "mtzMADmod" if ($progname eq "mtzmadmod");  # horrible fudge!!

          ($indcatname = $line[2]) =~ tr/a-z/A-Z/;    # upper case
          $indcatname = &tidystart($indcatname);      # remove leading blanks
          $indcatname = &tidyend($indcatname);        # remove trailing blanks

          ($funcatname = $line[3]) =~ tr/a-z/A-Z/;    # upper case
          @funcatname = split(/,/,$funcatname);
          $numfuncat = @funcatname;
          for ($count = 0; $count < $numfuncat; $count++) {
            $funcatname[$count] = &tidystart($funcatname[$count]);
            $funcatname[$count] = &tidyend($funcatname[$count]);
          };

          $description = $line[4];
          $comment = $line[5];
	}

# Use recursion to remove trailing blanks

sub tidyend {
  local($string) = $_[0];

  local($tmpstring) = $string;
  if (chop($tmpstring) eq ' ') {
    &tidyend($tmpstring);
  } else {
    $string;
  }
}

# Use recursion to remove leading blanks

sub tidystart {
  local($string) = $_[0];

  if (substr($string,0,1) eq ' ') {
    substr($string,0,1) = '';
    &tidystart($string);
  } else {
    $string;
  }
}


