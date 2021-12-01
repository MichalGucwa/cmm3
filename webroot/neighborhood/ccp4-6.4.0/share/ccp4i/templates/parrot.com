#
#     Copyright (C) 2008  Kevin Cowtan
#     Parrot script template
#

1 title $TITLE
1 pdbin-ref $XYZINref 
1 mtzin-ref $HKLINref 
1 colin-ref-fo /*/*/\\\[$FPref,$SIGFPref\\\]
1 colin-ref-hl /*/*/\\\[$HLAref,$HLBref,$HLCref,$HLDref\\\]
$USESEQINwrk seqin-wrk $SEQINwrk
1 mtzin-wrk $HKLINwrk
1 colin-wrk-fo /*/*/\\\[$FPwrk,$SIGFPwrk\\\]
{ $USEPHIW != 1 } colin-wrk-hl /*/*/\\\[$HLAwrk,$HLBwrk,$HLCwrk,$HLDwrk\\\]
{ $USEPHIW == 1 } colin-wrk-phifom /*/*/\\\[$PHIwrk,$FOMwrk\\\]
$USEFMAP colin-wrk-fc     /*/*/\\\[$FMAPwrk,$PMAPwrk\\\]
$USEFREE colin-wrk-free   /*/*/\\\[$FREEwrk\\\]
$USEXYZIN_ha  pdbin-wrk-ha $XYZIN_ha
$USEXYZIN_mr  pdbin-wrk-mr $XYZIN_mr

1 mtzout $HKLOUT
1 colout $COLOUT

$DOSOLV solvent-flatten
$DOHIST histogram-match
$DONCSA ncs-average

$DOANIS anisotropy-correction

1 cycles $NCYCLE

1 resolution $RESOLUTION_MAX

1 ncs-mask-filter-radius $NCSRAD

{ $USESEQINwrk != 1 } solvent-content $SOLC

LOOP I 1 $N_KEYS
	1	$KEYS($I)
ENDLOOP
