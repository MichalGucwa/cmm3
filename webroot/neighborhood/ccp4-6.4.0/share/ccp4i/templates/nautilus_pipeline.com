#
#     Copyright (C) 2012 Kevin Cowtan
#     nautilus script template for ccp4i_pipeline_python
#


1		title  $TITLE

$REFUSER	pdbin-ref $XYZINref

1 		seqin $SEQINwrk

1 		mtzin $HKLINwrk
1 		colin-fo $FPwrk,$SIGFPwrk
$USEFREE 	colin-free $FREEwrk
{$USEPHIW!=1}	colin-hl $HLAwrk,$HLBwrk,$HLCwrk,$HLDwrk
{$USEPHIW==1}	colin-phifom $PHIwrk,$FOMwrk
$USEFMAP	colin-fc $FMAPwrk,$PMAPwrk

$USEXYZIN	pdbin $XYZINwrk

1		pdbout $XYZOUT

1		cycles $NCYCLE

$DOANIS		nautilus-anisotropy-correction

1		nautilus-resolution $NAU_RESOLN_MAX

1		refmac-mlhl $REF_MLHL
1               refmac-twin $REF_TWIN
{!$REF_MXAUTO}	refmac-weight $REF_MXWGHT
$REF_HLCOLS	refmac-colin-hl $REF_HLAwrk,$REF_HLBwrk,$REF_HLCwrk,$REF_HLDwrk

LOOP I 1 $N_NAU_KEYS
	1	nautilus-keyword $NAU_KEYS($I)
ENDLOOP
LOOP I 1 $N_REF_KEYS
	1	refmac-keyword $REF_KEYS($I)
ENDLOOP

1		prefix $prefix
