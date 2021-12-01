#!/bin/csh -f


# check to see if $CCP4 has been setup.
if (${?CCP4} == 0) then
  echo ' The CCP4 setup script has not been sourced or has a problem' 1>&2
  exit 1
endif 



# make man and cat1 directories
if -d ${CCP4}/man == 0 then
  mkdir ${CCP4}/man
endif

if -d ${CCP4}/man/cat1 == 0 then
  mkdir ${CCP4}/man/cat1
endif


# setup links in in cat1 directory so that `man` will operate 

foreach i (`ls ${CDOC}/*.doc`)

  set basenam = `basename ${i} .doc`
  rm -f ${CCP4}/man/cat1/${basenam}.* >& /dev/null
  ln -f -s ${i} ${CCP4}/man/cat1/${basenam}.1

end


#copy the whatis file to the man directory so that man -k will work.
cp ${CHTML}/whatis ${CCP4}/man/.


exit 0
