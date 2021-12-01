#!/bin/sh -f


# check to see if $CCP4 has been setup.
if test -z $CCP4 ; then
  echo ' The CCP4 setup script has not been sourced or has a problem' 1>&2
  exit 1
fi



# make man and cat1 directories
test -d ${CCP4}/man || mkdir -p ${CCP4}/man
test -d ${CCP4}/man/cat1 || mkdir -p ${CCP4}/man/cat1

# setup links in in cat1 directory so that `man` will operate 

for i in `ls ${CCP4}/doc/` ; do
case $i in
 *.doc)
  basenam=`basename ${i} .doc`
  rm -f ${CCP4}/man/cat1/${basenam}.* &> /dev/null
  ln -f -s ${CCP4}/doc/${i} ${CCP4}/man/cat1/${basenam}.1
;;
esac
done


#copy the whatis file to the man directory so that man -k will work.
cp ${CCP4}/html/whatis ${CCP4}/man/.


exit 0
