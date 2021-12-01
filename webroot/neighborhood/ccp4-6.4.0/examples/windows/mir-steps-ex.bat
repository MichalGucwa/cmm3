::!\bin\sh

:: ============================================================
::       Outline of Heavy atom refinement and Phasing tutorial 
::            ( E.J.Dodson)
:: ============================================================
::        Example based on MIR solution of Dendrotoxin from green mamba
::        Protein of 425 residues 
::        cell 73.58   38.73   23.19   90.00   90.00   90.00
::        Spacegroup  P212121
::    Two derivatives; Au I

:: Steps after solving patterson for 1 site.
::    Use FFT, PEAKMAX  HAVECS, Int Tab etc..
::========================
:: step 1.
::========================
::   Refine Au Site 1 using Centric differences only
::  Phasing cycle ( the last) will calculate SIR phases for all reflections.
::  Alternative:  Use a direct methods program to find a consistent set of Hg 
::     sites and go straight to Step 3.
::
:: Step 2.
::========================
::   Difference Fourier to find more sites. Contour and
::   note pertubation in map about first site.
::   Check patterson peaks are consistent with 2nd site. ( do not worry 
::   too much if they are not... (gets round alternate origin problem)
::
:: Step 3.
::========================
::   Refine 2 Au Sites  using Centric differences only
::  Phasing cycle ( the last) will calculate SIR phases for all reflections
::
:: Step 4.
::========================
::   Difference fouriers to look for I sites.
::
:: Step 5.
::========================
::  Refinement of both derivatives together.
::
:: Step 6.
::========================
::  Refinement of both derivatives together including anomalous data
::    If hand correct, and there are TWO independent derivatives; 
::    anomalous occupancies will be positive if hand correct;
::                                   negative if hand incorrect.
::       If so - change positions to -x,-y,-z, ( spacegroup to 
::        enantiomorph if necessary) and go on..
::
::========================
::   Next steps not in this example:
::
:: Step 7.
::========================
::  Check I pattersons.
::  Now should repeat procedure, using I phases to find Au.
::  Calculate isomorphous map...
::
:: Step 8.
::========================
::  Calculate isomorphous map...
::
:: Step 9.
::========================
:: Do density modification. (dm\Wang procedures)
::  Calculate new map...
::
:: Step 10.
::========================
:: Build structure.
::
::
::::::   Command procedures  to carry out this procedure. 
::    ==================================================
::                          STEP 1
::    ==================================================
:: step 1.
::   Refine Au Site 1 using Centric differences only
::  Phasing cycle ( the last) will calculate SIR phases for all reflections.
::----------------------------------------------------
::----------------------------------------------------
::    step1_mir_steps
::----------------------------------------------------
::----------------------------------------------------

IF NOT EXIST %TEMPRES%\toxd_sc.mtz (echo '! run scaleit-ex first' 1>&2 && GOTO :EOF)

mlphare HKLIN %TEMPRES%\toxd_sc.mtz HKLOUT   %TEMPRES%\toxd_step1.mtz < %SCRIPTWIN%\mir-steps1.dat

::   ==================================================
::                         STEP 2
::   ==================================================
::
:: Step 2.
::   Difference Fourier to find more sites. Contour and
::   note pertubation in map about first site.
::   Check patterson peaks are consistent with 2nd.. sites.  (do not worry 
::   too much if they are not...)
::   (If you add FH=FH1 PHIH=PHIH1 you will generate a double difference map 
::      - may be clearer..)
::----------------------------------------------------
::----------------------------------------------------
::    step2_mir_steps
::----------------------------------------------------
::----------------------------------------------------
::

fft HKLIN %TEMPRES%\toxd_step1.mtz MAPOUT %TEMPRES%\toxd_step2.map abcoeffs %TEMPRES%\fftkw.abcoeffs < %SCRIPTWIN%\mir-steps2.dat

:: Find 100 peaks above 5*rms, 
:: output to PDB file "occupancy"= peak height, " Btemp"=   height\sigma
:: orthogonalization code (normal)
:: positive peaks only

peakmax mapin %TEMPRES%\toxd_step2.map xyzout %TEMPRES%\toxd_step2.frc  < %SCRIPTWIN%\mir-steps3.dat

::   ==================================================
::                         STEP 2A
::   ==================================================
::
::  Get PDB file of coordinates and vectors.
::  Alternative inputs - PDB,fractional or phare_ml

:: 1)   Input fractional sites 
::   Free format:   Occup   x y z b (sites.frc - typed in)
::
:: 2)  Input PHARE fractional sites 
::ATOM   Au    0.026  0.000  0.287 19.75 25.74 BFAC   13.887
::
:: 3) Input PDB file - usual sort of stuff CRYSTAL\SCALEi coordinates.
::

havecs XYZIN %DATA%\sites.frc XYZOUT %TEMPRES%\sites.pdb UVWOUT %TEMPRES%\sitesuvw.pdb	< %SCRIPTWIN%\mir-steps4.dat

::   Plot map with Au sites marked.  Choose sensible contour levels
::
::!\bin\csh -f

npo MAPIN %TEMPRES%\toxd_step2.map XYZIN1 %TEMPRES%\sites.pdb PLOT %TEMPRES%\step2.plot < %SCRIPTWIN%\mir-steps5.dat

::   ==================================================
::                         STEP 3
::   ==================================================
::
:: Step 3.
::========================
::   Refine 2 Au Sites  using Centric differences only
::  Phasing cycle ( the last) will calculate SIR phases for all reflections
::
::----------------------------------------------------
::----------------------------------------------------
::    step3_mir_steps 
::----------------------------------------------------
::----------------------------------------------------
::

mlphare HKLIN %TEMPRES%\toxd_sc.mtz HKLOUT %TEMPRES%\toxd_step3.mtz DATOUT test.dat	< %SCRIPTWIN%\mir-steps6.dat

::==================================================
::                         STEP 4
::==================================================
::
:: Step 4.
::========================
::   Difference fouriers to look for I sites and Hg sites

::----------------------------------------------------
::    step4a_mir_steps
::----------------------------------------------------
::----------------------------------------------------
::    In this case it was important to EXCLUDE ridiculous differences.
::
::!\bin\csh -f

fft HKLIN %TEMPRES%\toxd_step3.mtz MAPOUT %TEMPRES%\step4.map abcoeffs %TEMPRES%\fftkw.abcoeffs < %SCRIPTWIN%\mir-steps7.dat

peakmax MAPIN %TEMPRES%\step4.map XYZOUT %TEMPRES%\siteI.frc < %SCRIPTWIN%\mir-steps8.dat

::----------------------------------------------------
::----------------------------------------------------
::    step4b_mir_steps
::----------------------------------------------------
::----------------------------------------------------
::
::
::!\bin\csh -f

fft HKLIN %TEMPRES%\toxd_step3.mtz MAPOUT %TEMPRES%\step4b.map abcoeffs %TEMPRES%\fftkw.abcoeffs < %SCRIPTWIN%\mir-steps9.dat

peakmax MAPIN %TEMPRES%\step4b.map XYZOUT %TEMPRES%\siteHg.frc < %SCRIPTWIN%\mir-steps10.dat

::==================================================
::                         STEP 5
::==================================================
::
:: Step 5.
::========================
::  Refinement of all derivatives together.
::  Include refinement of anomalous occupancies.
::----------------------------------------------------
::----------------------------------------------------
::    step5_mir_steps
::----------------------------------------------------
::----------------------------------------------------

mlphare HKLIN %TEMPRES%\toxd_sc.mtz HKLOUT %TEMPRES%\toxd_step5.mtz DATOUT %TEMPRES%\test.dat < %SCRIPTWIN%\mir-steps11.dat

::   ==================================================
::                         STEP 6
::   ==================================================
::  Refinement of both derivatives together.
::  Include refinement of anomalous occupancies on both hands.
::----------------------------------------------------
::----------------------------------------------------
::    step6_mir_steps
::----------------------------------------------------
::----------------------------------------------------

mlphare HKLIN %TEMPRES%\toxd_sc.mtz HKLOUT %TEMPRES%\toxd_step6.mtz DATOUT %TEMPRES%\test.dat < %SCRIPTWIN%\mir-steps12.dat

::----------------------------------------------------
::----------------------------------------------------
::       step6a_mlphare.com
::----------------------------------------------------
::----------------------------------------------------

:: only necessary for certain spacegroups -- dummy step here

mtzutils HKLIN1 %TEMPRES%\toxd_sc.mtz HKLOUT %TEMPRES%\scaled.mtz < %SCRIPTWIN%\mir-steps13.dat

mlphare HKLIN %TEMPRES%\scaled.mtz HKLOUT %TEMPRES%\toxd_step6.mtz DATOUT %TEMPRES%\test.dat < %SCRIPTWIN%\mir-steps14.dat
