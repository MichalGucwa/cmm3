#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
#==========================================================================
#==_task_window==core procedure. all commands to define graphical interface
#==========================================================================

#------------------------------------------------------------------------------
proc clustalw_prereq { } {
#------------------------------------------------------------------------------
  if { ![file exists [FindExecutable clustalw2]] } {
    return 0
  }
  return 1
}

proc clustalw_setup { typedefname arrayname } {

    upvar #0 $typedefname typedef

   set typedef(_clustalw_exptype) { menu { \
	    "  DNA   Pairwise Alignment" \
	    "  DNA   Multiple Alignment" \
	    "Protein Pairwise Alignment" \
	    "Protein Multiple Alignment" } { DNAFAST DNAFULL PROTEINFAST PROTEINFULL } }
    set typedef(_clustalw_outputtype) { menu { "ALN" "GCG" "GDE" "Phylip" "PIR" } { ALN GCG GDE PHYLIP PIR } }
    set typedef(_clustalw_outorder) { menu { "Input" "Aligned" } { INPUT ALIGNED } }
    set typedef(_clustalw_score) { menu { "Percent" "Absolute" } { PERCENT ABSOLUTE } }
    set typedef(_clustalw_pwmatrixn) { menu { "BLOSUM" "PAM" "GONNET" "ID" } { BLOSUM PAM GONNET ID } }
    set typedef(_clustalw_pwdnamatrixn) { menu { "IUB" "CLUSTALW" } { IUB CLUSTALW } }
    set typedef(_clustalw_matrixn) { menu { "BLOSUM" "PAM" "GONNET" "ID" } { BLOSUM PAM GONNET ID} }
    set typedef(_clustalw_dnamatrixn) { menu { "IUB" "CLUSTALW" } { IUB CLUSTALW } }
    set typedef(_clustalw_outputtreen) { menu { "NJ" "Phylip" "Dist" "Nexus" } { NJ PHYLIP DIST NEXUS } }
    set typedef(_clustalw_bootlabelsn) { menu { "NODE" "BRANCH" } { NODE BRANCH } }




    # Check that the CLUSTALW program is available
    PleaseWait "Looking for the ClustalW program"
    if { [clustalw_find_program clustalw2] } {
    # Start the interface
	return 1
    }


    # Set URL for CLUSTALW homepage
    set clustalw_url "http://www.ebi.ac.uk/clustalw/"
    # Make sure we get rid of waiting message
    PleaseWait
    
    set action [ChooseOptionDialog "ClustalW Interface" "ClustalW" \
	    "The ClustalW program doesn't appear to be available. Without it
    this interface cannot run.
    
    This may be because ClustalW is not on your path, or because the
    program has not been installed.
    
    If you already have ClustalW then you can configure the interface to
    find it using the options under the \"System Administration\" menu.
    Otherwise you can download the latest version of ClustalW from
    $clustalw_url" \
	    { "Go to website" Dismiss } -default 1 ]
    
    # Go to the ClustalW website
    if ![regexp Dismiss $action] {
	open_url $clustalw_url -remote
    }
    return 0


    return 1
}

proc clustalw_task_window { arrayname } {
    global clustalw_var
    global configure

    upvar #0 $arrayname array

    if { [CreateTaskWindow $arrayname \
               "Clustalw Interface" "Clustalw"  [list "DNA Pairwise Alignment" "DNA Multiple Alignment" "Protein Pairwise Alignment" "Protein Multiple Alignment"  "Other Options - Structure Alignments" "Other Options - Phylogenetic Trees" "Output" ]] == 0 } return

    OpenFolder protocol
    CreateTitleLine line TITLE

    CreateLine line label "Conduct" widget EXPTYPE -command "clustalw_set_align $arrayname"

    CreateLine line \
	    label "Opening File From... " \
    
    CreateInputFileLine blastin "Select Clustalw Input File 'NO SPACE!'" File INFILE DIR_INFILE    
    
    CreateLine line \
	    label "Save File Into..." \

    CreateOutputFileLine clustalout "Declare Clustalw Output File 'NO SPACE!'" File OUTFILE DIR_OUTFILE

    CreateLine line label "Set Output Type" widget OUTPUTTYPE label "and" widget OUTORDER label "with score type" widget SCORE

    OpenFolder 1 EXPTYPE closed DNAFAST hide
    CreateLine line widget PWDNAMATRIX label "Set DNA Weight Matrix" widget PWDNAMATRIXN
    CreateLine line widget KTUPLE      label "Set K-TUPLE value" widget KTUPLEN
    CreateLine line widget TOPDIAGS    label "Set number of best diagrams" widget TOPDIAGSN
    CreateLine line widget PAIRGAP     label "Set Gap Penalty" widget PAIRGAPN
    CreateLine line widget PWGAPOPEN   label "Set Gap Opening Penalty" widget PWGAPOPENF
    CreateLine line widget PWGAPEXT    label "Set Gap Extension Penalty" widget PWGAPEXTF

    OpenFolder 2 EXPTYPE closed DNAFULL hide
    CreateLine line widget DNAMATRIX label "Set DNA Weight Matrix" widget DNAMATRIXN
    CreateLine line widget GAPOPEN label "Set Gap opening Penalty" widget GAPOPENF
    CreateLine line widget GAPEXT label "Set Gap Extension Penalty" widget GAPEXTF
    CreateLine line widget ENDGAPS label "No End Gap Separation Penalty"
    CreateLine line widget GAPDIST label "Set Gap Separation Penalty Range" widget GAPDISTN
    CreateLine line widget NOPGAP label "No residue-specific gaps"
    CreateLine line widget NOHGAP label "No Hydrophilic gaps"
    CreateLine line widget HGAPRESIDUES label "List Hydrophilic Residues"
    CreateLine line widget TRANSWEIGHT label "Set Transitions Weighting" widget TRANSWEIGHTF

    OpenFolder 3 EXPTYPE closed PROTEINFAST hide
    CreateLine line widget PWMATRIX label "Set Protein Weight Matrix" widget PWMATRIXN
    CreateLine line widget KTUPLE      label "Set K-TUPLE value" widget KTUPLEN
    CreateLine line widget TOPDIAGS    label "Set number of best diagrams" widget TOPDIAGSN
    CreateLine line widget PAIRGAP     label "Set Gap Penalty" widget PAIRGAPN
    CreateLine line widget PWGAPOPEN   label "Set Gap Opening Penalty" widget PWGAPOPENF
    CreateLine line widget PWGAPEXT    label "Set Gap Extension Penalty" widget PWGAPEXTF

    OpenFolder 4 EXPTYPE closed PROTEINFULL hide
    CreateLine line widget MATRIX label "Set Protein Weight Matrix" widget MATRIXN
    CreateLine line widget GAPOPEN label "Set Gap opening Penalty" widget GAPOPENF
    CreateLine line widget GAPEXT label "Set Gap Extension Penalty" widget GAPEXTF
    CreateLine line widget ENDGAPS label "No End Gap Separation Penalty"
    CreateLine line widget GAPDIST label "Set Gap Separation Penalty Range" widget GAPDISTN
    CreateLine line widget NOPGAP label "No residue-specific gaps"
    CreateLine line widget NOHGAP label "No Hydrophilic gaps"
    CreateLine line widget HGAPRESIDUES label "List Hydrophilic Residues"
    CreateLine line widget TRANSWEIGHT label "Set Transitions Weighting" widget TRANSWEIGHTF

    OpenFolder 5 closed
    CreateLine line widget HELIXGAP label "Set gap penalty for helix core residues" label "n=" widget HELIXGAPN
    CreateLine line widget STRANDGAP label "Set gap penalty for strand core residues" label "n=" widget STRANDGAPN
    CreateLine line widget LOOPGAP label "Set gap penalty for loop regions" label "n=" widget LOOPGAPN
    CreateLine line widget TERMINALGAP label "Set gap penalty for structure termini" label "n=" widget TERMINALGAPN
    CreateLine line widget HELIXENDIN label "Set number of residues inside helix treated as termini" widget HELIXENDINN
    CreateLine line widget HELIXENDOUT label "Set number of residues outside helix treated as termini" widget HELIXENDOUTN
    CreateLine line widget STRANDENDIN label "Set number of residues inside strand treated as termini" widget STRANDENDINN
    CreateLine line widget STRANDENDOUT label "Set number of residues outside strand treated as termini" widget STRANDENDOUTN

    OpenFolder 6 closed
    CreateLine line widget OUTPUTTREE label "Output Phylogenetic Tree in" widget OUTPUTTREEN label "Format"
    CreateLine line widget SEED label "Set seed number for bootstraps" widget SEEDN
    CreateLine line widget KIMURA label "Use Kimura's Correction"
    CreateLine line widget TOSSGAPS label "Ignore positions with gaps"
    CreateLine line widget BOOTLABELS label "Set position of bootstrap values in tree display" widget BOOTLABELSN

    OpenFolder 7 open
    CreateText outputaln " " -scroll
    set array(OUTPUTALN) $outputaln

}

proc clustalw_set_align { arrayname } {
    upvar #0 $arrayname array
    if { $array(EXPTYPE) == "Protein Multiple Alignment" } {
	set array(ALIGN) 1
	set array(TYPE) "PROTEIN"
    } 
    if { $array(EXPTYPE) == "  DNA   Multiple Alignment" } {
	set array(ALIGN) 1
	set array(TYPE) "DNA"
    } 
    if { $array(EXPTYPE) == "Protein Pairwise Alignment" } {
	set array(ALIGN) 0
	set array(TYPE) "PROTEIN"
    }
    if { $array(EXPTYPE) == "  DNA   Pairwise Alignment" } {
	set array(ALIGN) 0
	set array(TYPE) "DNA"
    }
    return 1
}

proc clustalw_run { arrayname } {

    upvar #0 $arrayname array

    set align $array(ALIGN)
    set infile [GetFullFileName [FileRootName $array(INFILE)] $array(DIR_INFILE)]
    set outfile [GetFullFileName [FileRootName $array(OUTFILE)] $array(DIR_OUTFILE)]
    return 1

}

proc clustalw_review { arrayname job_id } {
    
    upvar #0 $arrayname array
    
    if { [ReadFile [GetFullFileName0 $arrayname OUTFILE] alignment] } {
      AppendTextWindow $array(OUTPUTALN) $alignment
    } else {
      AppendTextWindow $array(OUTPUTALN) "Program failed! Check log file."
    }
}

#-----------------------------------------------------------------------
proc clustalw_find_program { program } {
#-----------------------------------------------------------------------
# Search for the clustalw executable, to make sure that the program
# will run

  if { ![file exists [FindExecutable $program]] } {
    return 0
  }
  return 1

}
