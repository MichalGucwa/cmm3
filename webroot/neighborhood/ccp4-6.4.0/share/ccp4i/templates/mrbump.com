#
#
#     Copyright (C) 2005 Ronan Keegan
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#
##################################################
# MrBUMP: COMMAND SCRIPT
##################################################

IF {[StringSame $MRBUMP_MODE FULLMR] || [StringSame $MRBUMP_MODE MRONLY]} 
  1 LABIN F=$F SIGF=$SIGF FreeR_flag=$FreeR_flag
  {[IfSet $MR_PROGRAM_LIST]} MRPROGRAMS $MR_PROGRAM_LIST
  1 TRYALL $TRYALL 
  1 CLEAN $CLEAN 
  1 LITE $LITE 
  1 USEACORN $USEACORN 
  1 ACORNRES $ACORNRES 
  1 ENANT $USEENANT 
  1 PACK $PACK
  1 PJOBS $PJOBS
  1 NCYC $NCYC
  1 REFTWIN $REFTWIN
  1 BUCCANEER $BUCCANEER
  1 BCYC $BCYC
  1 ARPWARP $ARPWARP
  1 ACYC $ACYC
  1 SHELXE $SHELXE
  1 SCYC $SCYC
  LOOP I 1 $NPKEY
	1	PKEYWORD $PKEYWORD($I)
  ENDLOOP
ENDIF

1 JOBID $job_params(JOB_ID) 
1 ROOTDIR $ROOTDIR
1 RESHTML $ROOTDIR/results_$job_params(JOB_ID).html 
1 MRNUM $MRNUM
1 ENSNUM $ENSNUM
1 ENSMODNUM $ENSMODNUM
1 MAPROGRAM $MAPROGRAM
1 DEBUG $DEBUG
1 SCOPSEARCH $SCOPSEARCH
1 SSMSEARCH $SSMSEARCH
1 PQSSEARCH $PQSSEARCH
1 MDLU $MDLU
1 MDLD $MDLD
1 MDLM $MDLM
1 MDLC $MDLC
1 MDLS $MDLS
1 MDLP $MDLP
1 FASTALOCAL $FASTALOCAL
1 UPDATE $UPDATE
1 DOFASTA $DOFASTA
1 EVALUE $EVALUE
1 NMASU $NMASU
1 IGNORE $IGNORE 
1 INCLUDE $INCLUDE 
1 HTMLOUT $HTMLOUT 
1 DBOUT $DBOUT 
1 DBVIEW $DBVIEW 
1 CHECK $CHECK 
1 CLUSTER $CLUSTER 
LOOP N 1 $NLOCAL
   IF {[StringSame $LOC_CHAINID($N) ""]}
      IF { $LOC_RMS($N) > 0 }
         1 LOCALFILE $XYZIN($N) CHAIN "A" RMS $LOC_RMS($N) 
      ELSE
         1 LOCALFILE $XYZIN($N) CHAIN "A" 
      ENDIF
   ELSE
      IF { $LOC_RMS($N) > 0 }
         1 LOCALFILE $XYZIN($N) CHAIN $LOC_CHAINID($N) RMS $LOC_RMS($N)
      ELSE
         1 LOCALFILE $XYZIN($N) CHAIN $LOC_CHAINID($N)
      ENDIF
   ENDIF
ENDLOOP
LOOP N 1 $NFIXED
   1 FIXED_XYZIN $FIXED_XYZIN($N) IDEN $FIDEN($N)
ENDLOOP
IF { ![StringSame $PROXYSERVER ""] }
   1 PROXYSERVER $PROXYSERVER 
ENDIF

IF {[StringSame $MRBUMP_MODE FULLMR] || [StringSame $MRBUMP_MODE MODELS]} 
   IF { ![StringSame $PDBDIR ""] }
      1 PDBDIR $PDBDIR
   ENDIF
   IF { ![StringSame $PDBLOCAL ""] }
      1 PDBLOCAL $PDBLOCAL
   ENDIF
ENDIF

1 END