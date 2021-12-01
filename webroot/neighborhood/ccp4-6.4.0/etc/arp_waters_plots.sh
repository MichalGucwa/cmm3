#!/bin/sh -f
logf=$1 
ncyc=`grep NCYC $logf | awk '{print $4}' | head -1`
nrestr=1 
let ncyc++

if test `grep -c 'CGRAD' ${logf}` != 0 ; then
        let ncyc=$ncyc+1
        let nrestr=$ncyc-1
fi

if test `grep -c 'CDIR' ${logf}` != 0 ; then
        let ncyc=$ncyc+1
        let nrestr=$ncyc-1
fi

if test `grep -c 'CCP PROGRAM SUITE: PROTIN' ${logf}` != 0 ; then
	let nrestr=$ncyc-1 
fi


# echo $ncyc
# echo $nrestr
echo Producing file for xloggraph ...

grep 'all_FOM' ${logf} |head -1|nawk '{print 0,$2}' >t1.log
grep 'all_FOM' ${logf} |nawk -v nc=$nrestr '(NR%nc==0){print NR/nc,$2}' >>t1.log

grep 'all_R' ${logf} |head -1|nawk '{print $2}' >t2.log
grep 'all_R' ${logf} |nawk -v nc=$ncyc '(NR%nc==0){print $2}' >>t2.log

grep '_Correlation_coefficients_Fo_to_Fc' ${logf} |head -1 |nawk '{print $2}' >t3.log
grep '_Correlation_coefficients_Fo_to_Fc' ${logf} |nawk -v nc=$ncyc '(NR%nc==0){print $2}' >>t3.log

grep 'free_FOM' ${logf} |head -1|nawk '{print $2}' >t11.log
grep 'free_FOM' ${logf} |nawk -v nc=$nrestr '(NR%nc==0){print $2}' >>t11.log

grep '_refine_free_R_factor' ${logf} |head -1|nawk '{print $2}' >t12.log
grep '_refine_free_R_factor' ${logf} |nawk -v nc=$ncyc '(NR%nc==0){print $2}' >>t12.log

grep '_Free_correlation_coeff_Fo_to_Fc' ${logf} |head -1 |nawk '{print $2}' >t13.log
grep '_Free_correlation_coeff_Fo_to_Fc' ${logf} |nawk -v nc=$ncyc '(NR%nc==0){print $2}' >>t13.log

if test `grep -c '_Free_correlation_coeff_Fo_to_Fc' ${logf} ` = 0 ; then
    cp t11.log t12.log
    cp t11.log t13.log
fi

grep 'New atoms found' ${logf}  |head -1|nawk '{print $2}' >t21.log
grep 'New atoms found' ${logf}  |nawk '{print $2}' >>t21.log

grep 'Number of atoms will be removed' ${logf}  |head -1|nawk '{print $7}' >t22.log
grep 'Number of atoms will be removed' ${logf} |nawk '{print $7}' >>t22.log

grep 'Number of atoms included in refinement' ${logf}  |head -1|nawk '{print $8}' >t23.log
grep 'Number of atoms included in refinement' ${logf}  |nawk '{print $8}' >>t23.log

nawk '/TYPE  WGT NUMBER   DIST   DELTA   SIGMA/,/  ------ TYPE CODE ------/' ${logf} >t30.log

grep '  1  ' t30.log |head -1|awk '{print $5}' >t31.log
grep '  1  ' t30.log |awk -v nc=$nrestr '(NR%nc==0){print $5}' >>t31.log

grep '  2  ' t30.log |head -1|awk '{print $5}' >t32.log
grep '  2  ' t30.log |awk -v nc=$nrestr '(NR%nc==0){print $5}' >>t32.log



paste t1.log t2.log t3.log t11.log t12.log t13.log t21.log t22.log t23.log t31.log t32.log >t0.log

/bin/rm t1.log t2.log t3.log
/bin/rm t11.log t12.log t13.log
/bin/rm t21.log t22.log t23.log
/bin/rm t30.log t31.log t32.log

echo ' $TABLE: Refinement statistics  :' >summary.log

echo ' $GRAPHS:R,FOM and Fo Fc Correlation v. cycle :N:1,2,3,4:'  >>summary.log
echo ' :FREE R,FOM and Fo Fc Correlation v. cycle :N:1,5,6,7:'  >>summary.log
echo ' :R and free R  v. cycle :N:1,3,6:'  >>summary.log
echo ' :Atoms update  v. cycle :N:1,8,9:'  >>summary.log
echo ' :Total Atoms  v. cycle :N:1,10:'  >>summary.log
echo ' :Geometry  v. cycle :N:1,11,12:'  >>summary.log
echo ' $$'  >>summary.log
echo ' Cycle  FOM Rfactor Fo_Fc_Cor Free_FOM Free_R Free_Cor New_atom Removed_atoms Total_atoms rms_distances rms_angles $$'  >>summary.log
echo ' $$'  >>summary.log


cat t0.log >>summary.log

echo ' $$'  >>summary.log
echo
xloggraph summary.log

echo




