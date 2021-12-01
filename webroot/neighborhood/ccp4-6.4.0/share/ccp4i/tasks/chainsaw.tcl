#
#     Copyright (C) 2005 Martyn Winn
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
# ======================================================================
# chainsaw.tcl --
#
# CCP4Interface 
# Created Sep05 by Martyn Winn
#
# =======================================================================

# Source file containing sequence utilities, e.g. format checking
source [SearchPath TOP utils seq_utils.tcl]

#------------------------------------------------------------------------
proc chainsaw_check_clust { arrayname }  {
#------------------------------------------------------------------------
  upvar #0 $arrayname array

  return [CheckFormatClustalw [GetFullFileName0 $arrayname CLUSTIN]]

}

#------------------------------------------------------------------------
proc chainsaw_check_msf { arrayname }  {
#------------------------------------------------------------------------
  upvar #0 $arrayname array

  return [CheckFormatMSF [GetFullFileName0 $arrayname MSFIN]]

}

#------------------------------------------------------------------------
proc chainsaw_check_phylip { arrayname }  {
#------------------------------------------------------------------------
  upvar #0 $arrayname array

  return [CheckFormatPhylip [GetFullFileName0 $arrayname PHYLIPIN]]

}

#------------------------------------------------------------------------
proc chainsaw_check_blast { arrayname }  {
#------------------------------------------------------------------------
  upvar #0 $arrayname array

  return [CheckFormatBlast [GetFullFileName0 $arrayname BLASTIN]]

}

#------------------------------------------------------------------------
proc chainsaw_check_oca { arrayname }  {
#------------------------------------------------------------------------
  upvar #0 $arrayname array

  return [CheckFormatOCA [GetFullFileName0 $arrayname OCAIN]]

}

#------------------------------------------------------------------------
proc chainsaw_check_pir { arrayname }  {
#------------------------------------------------------------------------
  upvar #0 $arrayname array

  return [CheckFormatPIR [GetFullFileName0 $arrayname PIRIN]]

}

#------------------------------------------------------------------------
proc chainsaw_check_fasta { arrayname }  {
#------------------------------------------------------------------------
  upvar #0 $arrayname array

  return [CheckFormatFasta [GetFullFileName0 $arrayname FASTAIN]]

}

#------------------------------------------------------------------------
proc chainsaw_setup { typedefname arrayname }  {
#------------------------------------------------------------------------

  upvar #0 $typedefname typedef

  set typedef(_chainsaw_input_format)	{ menu	{ "ALN/Clustalw" \
						  "MSF/GCG" \
						  "Phylip" \
						  "Blast" \
						  "PIR" \
						  "Fasta" \
                                                  "OCA" \
						  "Other"  } \
	{ CLUST MSF PHYLIP BLAST PIR FASTA OCA OTHER } }

  set typedef(_chainsaw_input_mode)	{ menu	{ "gamma atom" \
						  "beta atom" \
						  "last common atom" } \
	{ MIXS MIXA MAXI } }

  set typedef(_chainsaw_task_mode)	{ menu	{ "using Chainsaw" \
						  "as polyALA model" } \
	{ CHAINSAW POLYALA } }


  return 1

}


#---------------------------------------------------------------------
proc chainsaw_run { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  switch [GetValue $arrayname INPUT_FORMAT] \
  PIR {
    set array(ALIGNIN) $array(PIRIN)
    set array(DIR_ALIGNIN) $array(DIR_PIRIN)
  } CLUST {
    set array(ALIGNIN) $array(CLUSTIN)
    set array(DIR_ALIGNIN) $array(DIR_CLUSTIN)
  } MSF {
    set array(ALIGNIN) $array(MSFIN)
    set array(DIR_ALIGNIN) $array(DIR_MSFIN)
  } PHYLIP {
    set array(ALIGNIN) $array(PHYLIPIN)
    set array(DIR_ALIGNIN) $array(DIR_PHYLIPIN)
  } BLAST {
    set array(ALIGNIN) $array(BLASTIN)
    set array(DIR_ALIGNIN) $array(DIR_BLASTIN)
  } OCA {
    set array(ALIGNIN) $array(OCAIN)
    set array(DIR_ALIGNIN) $array(DIR_OCAIN)
  } FASTA {
    set array(ALIGNIN) $array(FASTAIN)
    set array(DIR_ALIGNIN) $array(DIR_FASTAIN)
  } OTHER {
    set array(ALIGNIN) $array(ANYIN)
    set array(DIR_ALIGNIN) $array(DIR_ANYIN)
  } default {
    set array(ALIGNIN) $array(ANYIN)
    set array(DIR_ALIGNIN) $array(DIR_ANYIN)
  }

  if { [StringSame [GetValue $arrayname TASK_MODE] CHAINSAW] } {
    append array(INPUT_FILES) " ALIGNIN"
  }

  return 1
}


#-----------------------------------------------------------------------
proc chainsaw_task_window { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
	"Chainsaw - create MR search model" "Chainsaw" \
	[list "Parameters" ]] == 0 } return

  SetProgramHelpFile "chainsaw"

#=PROTOCOL==============================================================
# Choose format of file to be read

  OpenFolder protocol

  CreateTitleLine line TITLE

  CreateLine line  \
	message "Choose Chainsaw or polyALA using PDBSET "	\
	label "Create search model " \
	widget TASK_MODE

  CreateLine line  \
	message "Choose how far non-conserved residues are truncated "	\
        help mode \
	label "Prune non-conserved residues to " \
	widget INPUT_MODE \
        toggle_display TASK_MODE open CHAINSAW

#=FILES================================================================

  OpenFolder file

  CreateInputFileLine line \
      "Enter input template file name (XYZIN)" \
        "PDB in" \
       XYZIN DIR_XYZIN \
     -fileout XYZOUT DIR_XYZOUT "_chainsaw" 

  OpenSubFrame frame -toggle_display TASK_MODE open CHAINSAW

  CreateLine line  \
	message "Choose input sequence alignment file format "	\
        help files-alignin \
	label "Input sequence alignment file in " \
	widget INPUT_FORMAT \
	label " format"

  CreateInputFileLine line \
      "Enter input alignment file name (ALIGNIN)" \
        "Alignment in" \
       CLUSTIN DIR_CLUSTIN \
	-command "chainsaw_check_clust $arrayname" \
        -toggle_display INPUT_FORMAT open CLUST

  CreateInputFileLine line \
      "Enter input alignment file name (ALIGNIN)" \
        "Alignment in" \
       MSFIN DIR_MSFIN \
	-command "chainsaw_check_msf $arrayname" \
        -toggle_display INPUT_FORMAT open MSF

  CreateInputFileLine line \
      "Enter input alignment file name (ALIGNIN)" \
        "Alignment in" \
       PHYLIPIN DIR_PHYLIPIN \
	-command "chainsaw_check_phylip $arrayname" \
        -toggle_display INPUT_FORMAT open PHYLIP

  CreateInputFileLine line \
      "Enter input alignment file name (ALIGNIN)" \
        "Alignment in" \
       BLASTIN DIR_BLASTIN \
	-command "chainsaw_check_blast $arrayname" \
        -toggle_display INPUT_FORMAT open BLAST

  CreateInputFileLine line \
      "Enter input alignment file name (ALIGNIN)" \
        "Alignment in" \
       PIRIN DIR_PIRIN \
	-command "chainsaw_check_pir $arrayname" \
        -toggle_display INPUT_FORMAT open PIR
        
  CreateInputFileLine line \
      "Enter input alignment file name (ALIGNIN)" \
        "Alignment in" \
       FASTAIN DIR_FASTAIN \
	-command "chainsaw_check_fasta $arrayname" \
        -toggle_display INPUT_FORMAT open FASTA

  CreateInputFileLine line \
      "Enter input alignment file name (ALIGNIN)" \
        "Alignment in" \
       OCAIN DIR_OCAIN \
	-command "chainsaw_check_oca $arrayname" \
        -toggle_display INPUT_FORMAT open OCA

  CreateInputFileLine line \
      "Enter input alignment file name (ALIGNIN)" \
        "Alignment in" \
       ANYIN DIR_ANYIN \
        -toggle_display INPUT_FORMAT open OTHER

  CloseSubFrame

  CreateOutputFileLine line \
      "Enter output search model file name (XYZOUT)" \
       "PDB out" \
       XYZOUT DIR_XYZOUT \

#=PARAMETERS==========================================================

  OpenFolder 1 hide

}

