#
#     Copyright (C) 2009 Kevin Cowtan
#     buccaneer script template for ccp4i_pipeline_python
#


1		title  $TITLE

1 		pdbin-ref $XYZINref
1 		mtzin-ref $HKLINref
1 		colin-ref-fo $FPref,$SIGFPref
1 		colin-ref-hl $HLAref,$HLBref,$HLCref,$HLDref

1 		seqin $SEQINwrk

1 		mtzin $HKLINwrk
1 		colin-fo $FPwrk,$SIGFPwrk
$USEFREE 	colin-free $FREEwrk
{$USEPHIW!=1}	colin-hl $HLAwrk,$HLBwrk,$HLCwrk,$HLDwrk
{$USEPHIW==1}	colin-phifom $PHIwrk,$FOMwrk
$USEFMAP	colin-fc $FMAPwrk,$PMAPwrk

$USEXYZIN	pdbin $XYZINwrk
$USEXYZSQ	pdbin-sequence-prior $XYZINseq
$USEXYZMR	pdbin-mr $XYZINmr

1		pdbout $XYZOUT

1		cycles $NCYCLE

$DOANIS		buccaneer-anisotropy-correction
$DOSEMET	buccaneer-build-semet
{$USEXYZIN && $DOFIXPOS}	buccaneer-fix-position
$DOFAST		buccaneer-fast

1		buccaneer-1st-cycles $BUC_NCYCLE_0
1		buccaneer-1st-sequence-reliability $BUC_SEQREL_0
$BUC_USECORR_0	buccaneer-1st-correlation-mode

1		buccaneer-nth-cycles $BUC_NCYCLE_N
1		buccaneer-nth-sequence-reliability $BUC_SEQREL_N
$BUC_USECORR_N	buccaneer-nth-correlation-mode

1		buccaneer-new-residue-name $BUC_NEWRESNM
1		buccaneer-resolution $BUC_RESOLN_MAX
$USEKNOWN       buccaneer-keyword known-structure $BUC_KNOWN_ID:$BUC_KNOWN_RAD

$USEJOBS	jobs $NJOBS

1		refmac-mlhl $REF_MLHL
1               refmac-twin $REF_TWIN
{!$REF_MXAUTO}	refmac-weight $REF_MXWGHT
$REF_HLCOLS	refmac-colin-hl $REF_HLAwrk,$REF_HLBwrk,$REF_HLCwrk,$REF_HLDwrk

LOOP I 1 $N_BUC_KEYS
	1	buccaneer-keyword $BUC_KEYS($I)
ENDLOOP
LOOP I 1 $N_REF_KEYS
	1	refmac-keyword $REF_KEYS($I)
ENDLOOP

1		prefix $prefix
