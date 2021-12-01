#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
1 INCLUDE
1 SET  ATOM_FILES_DIRECTORY = '$ATOM_FILES_DIRECTORY'
1 SET KNOWNS   = '$KNOWNS_LIST'
1 SET SEQUENCE = '$MODEL_NAME'
1 SET ALNFILE  = '$ALNFILE'
IF { [StringSame $INPUT_MODE SEQ] }
  1 SET SEGFILE =  '$SEGFILE'
  1 CALL ROUTINE = 'align_strs_seq'
ENDIF
CASE $REFINE_MODE 
CASEMATCH NO
  1 SET MODEL = $MODEL_NAME.ini
#  1 CALL ROUTINE = 'transfer_xyz'
  1 READ_ALIGNMENT FILE = ALNFILE, ALIGN_CODES = SEQUENCE
  1 READ_TOPOLOGY   FILE = TOPLIB
  1 READ_PARAMETERS FILE = PARLIB
  1 CALL ROUTINE = 'create_topology'
  1 TRANSFER_XYZ CLUSTER_CUT = -1.0
  1 BUILD_MODEL INITIALIZE_XYZ = OFF, BUILD_METHOD = INTERNAL_COORDINATES
  1 WRITE_MODEL FILE = MODEL
CASEMATCH FAST
  1 CALL ROUTINE = 'very_fast'
  1 CALL ROUTINE = 'model'
CASEMATCH FULL
  1 SET STARTING_MODEL= 1
  1 SET ENDING_MODEL  = $NMODELS
  1 CALL ROUTINE = 'model'
ENDCASE

