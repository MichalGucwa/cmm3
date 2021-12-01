::! \bin\sh

:: Accessible surface area and volume calculation.

surface xyzin1 %TOXD%\toxd.pdb xyzout %TEMPRES%\toxd.surface < %SCRIPTWIN%\surf-vol-calc1.dat 

:: Nb XtalView also has a program called volume
:: Specifically use the version in the CCP4 bin directory

volume xyzin %TEMPRES%\toxd.surface xyzout %TEMPRES%\calc_shell.vol shellfile %TEMPRES%\toxd.shell < %SCRIPTWIN%\surf-vol-calc2.dat

volume xyzin %TEMPRES%\toxd.surface xyzout %TEMPRES%\with_shell.vol shellfile %TEMPRES%\toxd.shell <  %SCRIPTWIN%\surf-vol-calc3.dat

:: find awk executable
::for myawk in nawk gawk awk
::do
::  test -f $myawk && break
::done

::$myawk <%TEMPRES%\with_shell.vol  '
::BEGIN {first = 1;}
::\^ BEGIN\ {
::    started = 1;
::    print "\nResidue, number, volume (>1000 probably indicates ignored atom)\n";
::    next;
::}
::\^ TOTAL\ {exit;}
::{
::    if (!started) { next; }
::    seqnum = substr ($0, 29, 5);
::    volume = substr ($0, 68, 8);
::    res3 = substr ($0, 23, 6);
::    if (old_seqnum == seqnum) {
::      volume_sum += volume ;
::    } else if (first) {
::      volume_sum = volume;
::      old_seqnum = seqnum ;
::      old_res3 = res3;
::      first = 0;
::    } else {
::      printf "%6s%5d %8.3f\n", old_res3,old_seqnum,volume_sum;
::      old_res3 = res3;
::      volume_sum = volume;
::      old_seqnum = seqnum ;
::    }      
::}
::'

