#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
# ======================================================================
# ncsref.tcl --
#
# Run Mapmask to generate mask for one ncs unit and then use
# DM  to get ncs phases
#
# CCP4Interface 
#
# =======================================================================


#--------------------------------------------------------------------
proc ncsref_setup { typedefVar arrayname } {
#--------------------------------------------------------------------
  upvar #0 $typedefVar typedef

set typedef(_refmac_nonx_code)  { menu { "tight" \
                                        "tight main chain & medium side chain" \
                                        "tight main chain & loose side chain" \
                                        "medium" \
                                        "medium main chain & loose side chain" \
                                        "loose" }
                                        { 1 2 3 4 5 6 } }


  return 1

}


#--------------------------------------------------------------------
proc ncsref_run { arrayname } {
#--------------------------------------------------------------------
  upvar #0 $arrayname array

  # Check that the solvent fraction is valid
  set solvent_warning 0
  if { [string trim $array(SOLVENT_FRAC)] == "" } {
    set solvent_warning 1
  } elseif { ![string is double $array(SOLVENT_FRAC)] } {
    set solvent_warning 1
  } elseif { $array(SOLVENT_FRAC) < 0.0 || \
	  $array(SOLVENT_FRAC) > 1.0 } {
    set solvent_warning 1
  }
  if { $solvent_warning } {  
    WarningMessage "You need to enter a valid value for the solvent
fraction (in the \"Required Parameters\" folder).

This should be a decimal fraction between 0.0
(indicating all protein) and 1.0 (all solvent)."
    return 0
  }

  return 1
}

#---------------------------------------------------------------------
proc NcsrefUnits { arrayname counter } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  SetProgramHelpFile lsqkab

  CreateLine line \
    message "Define chain for NCS unit" \
    label "NCS unit $counter is chain" \
    help match \
    widget CHAIN \
    label "residue range" \
    widget CHAIN_RES_1 \
    label to \
    widget CHAIN_RES_2

}

#------------------------------------------------------------------------
proc RefmacNonX { arrayname c1 } {
#------------------------------------------------------------------------

  CreateExtendingFrame N_NONX_CHN RefmacNonXChain \
        "Specify chains restrained by non-crystallographic symmetry" \
        "Add chain" \
      [list  NONX_CHN ] \
        -counter $c1

  CreateExtendingFrame N_NONX_SPANS RefmacNonXSpans \
        "Specify range of residues restrained by non-crystallographic symmetry" \
        "Add residue range" \
      [list  NONX_SPANS_RES1 \
                NONX_SPANS_RES2 \
                NONX_SPANS_CODE ] \
               -counter $c1

}
#------------------------------------------------------------------------
proc RefmacNonXChain { arrayname c1 c2 } {
#------------------------------------------------------------------------
  if { $c1 == 1 } {
    CreateLine line \
      label "Restrain together chain" \
      widget NONX_CHN
  } else {
    CreateLine line \
      label "and" \
      widget NONX_CHN
  }

}
 
#------------------------------------------------------------------------
proc RefmacNonXSpans { arrayname c1 c2 } {
#------------------------------------------------------------------------

  CreateLine line \
    label "Restrain residue range" \
    widget NONX_SPANS_RES1 \
    label "to" \
    widget NONX_SPANS_RES2 \
    label "with" \
    widget NONX_SPANS_CODE \
    label "restraints"
}

#-------------------------------------------------------------------
proc NcsrefReadPdb { arrayname } {
#-------------------------------------------------------------------
  upvar #0 $arrayname array

  source  [SearchPath TOP utils pdb_utils.tcl]

  if { [PdbGetChains [GetFullFileName0 $arrayname XYZIN]  chains chain_res] 
      && [llength $chains] > 0  } {
    set increment [expr [llength $chains] - $array(NCHAINS) ]
    update_extendingframe NcsrefUnits 0 $arrayname NCHAINS \
                $array(NCHAINS) $increment 1
    for { set n 1 } { $n <= $array(NCHAINS) } { incr n } {
       set array(CHAIN,$n) [lindex $chains [expr $n -1] ]
       set array(CHAIN_RES_1,$n) [lindex [lindex $chain_res [expr $n -1] ] 0]
       set array(CHAIN_RES_2,$n) [lindex [lindex $chain_res [expr $n -1] ] 1]
    }
  }
}


#--------------------------------------------------------------------
proc ncsref_task_window {arrayname} {
#--------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow  $arrayname \
 	"NCSref - NCS Phased Refinement" NCSRef \
        [list "NCS Units"  \
	"Required Parameters" \
	"Detailed Parameters" ] ] == 0 } return

  SetDefaultMapFormat $arrayname MAPOUT_FORMAT

  SetProgramHelpFile refmac


#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
    message "By default initial phases calculated by Refmac" \
    widget INIT_PHASE \
    label "Input initial phases"

  CreateLine line \
        message "Generate weighted mFo-DFcalc and 2mFo-DFcalc maps & averaged maps" \
        widget IF_MAPOUT \
	  -toggleon \
        label "Generate weighted difference maps files in" \
        widget MAPOUT_FORMAT \
        label "format"


#=FILES================================================================

  OpenFolder file 

    CreateInputFileLine line \
        "Enter input coordinate file (XYZIN)" \
	"Coords in" \
	XYZIN DIR_XYZIN \
	-command "NcsrefReadPdb $arrayname" \
	-fileout XYZOUT DIR_XYZOUT "_ncsref"

  CreateOutputFileLine line \
      "Enter name of output coordinate file (XYZOUT)" \
      "Coords out" \
      XYZOUT DIR_XYZOUT


  CreateInputFileLine line \
	"Enter input MTZ file name (HKLIN)" \
	"MTZ in" \
	HKLIN DIR_HKLIN \
	-setlabin FREE [list FREE FreeR FreeR_flag] \
	-fileout HKLOUT DIR_HKLOUT "_ncsref" \
	-fileout MASKOUT DIR_MASKOUT "_ncsref"

  CreateLabinLine line \
    "Choose amplitude (FP) and essential sigma (SIGFP)" \
     HKLIN "FP"  FP  {} \
     -sigma "SIGFP" SIGFP  {}

  CreateLabinLine line \
    "Choose phase (PHIO) and essential weighting factor (FOMO)" \
     HKLIN "PHIO" PHIO  {} \
     -sigma "Weight" FOMO  {} \
     -toggle_display INIT_PHASE open 1

  CreateLabinLine line \
    "Choose COMPULSORY Free R column (FREE)" \
     HKLIN FreeR FREE {}

       
  CreateOutputFileLine line \
      "Enter name of output MTZ file (HKLOUT)" \
      "MTZ out" \
      HKLOUT DIR_HKLOUT

  CreateOutputFileLine line \
      "Enter name of output mask file (MASKOUT)" \
      "Mask out" \
      MASKOUT DIR_MASKOUT


#=PARAMETERS==========================================================

  OpenFolder 1

#  CreateToggleFrame  N_NONX  RefmacNonX \
#                "Open another non-xtallographic symmetry restraint" \
#                "Non-xtallographic symmetry restraint" \
#                "Add non-X restraint" \
#             [list   N_NONX_CHN \
#                N_NONX_SPANS ] \
#                -child RefmacNonXChain \
#                -child RefmacNonXSpans

  CreateExtendingFrame NCHAINS NcsrefUnits \
        "Add/remove line to define NCS unit" \
        "Add NCS unit" \
        [ list CHAIN \
        CHAIN_RES_1 \
        CHAIN_RES_2 ] 


#-------------------------------------------------------------------------
  OpenFolder 2

  SetProgramHelpFile refmac

  CreateLine line \
        message "Number of cycles of refinement (NCYC) for each Refmac run" \
        help refi_ncyc \
        widget NCYCLES \
          -width 3 \
        label "cycles of refinement in each Refmac run and" \
        message "Number of cycles of running Refmac & DM" \
        widget EXTERNAL_NCYCLES \
           -width 3 \
        label "cycle(s) of external refinement"  \


  SetProgramHelpFile dm

  CreateLine line \
        message "Fraction of unit cell which is solvent (SOLC) as a fraction between 0.0 and 1.0" \
	help solc \
	label "Fraction solvent content" \
	widget SOLVENT_FRAC -oblig

#-------------------------------------------------------------------------detailed parameters

  OpenFolder 3 closed

  SetProgramHelpFile ncsmask

  CreateLine line \
	message "Atom radius used in generating mask (RADIUS)" \
	label "Atom radius used in generating mask" \
	widget RADIUS

  SetProgramHelpFile refmac

  CreateLine line \
    message "Blurring factors for input phases (REFI PHASE SCBLUR BBLUR)" \
    label "Blurring factors for input phase FOM SC" \
    help refi_phas_scbl \
    widget PHASE_SCBLUR \
    label "B" \
    widget PHASE_BBLUR

  CreateLine line \
        message "For structures with non-robust Wilson plot fix <B> (SCALE FIXB)"  \
        help "scal_lssc_fixb" \
        widget SCALING_IF_FIXB \
          -toggleon \
        label "Fix overall scales and Bvalues for bulk to" \
        widget SCALING_FIXB_BBULK \
        label "and solvent/protein density ratio" \
        widget SCALING_FIXB_SCBULK

}
