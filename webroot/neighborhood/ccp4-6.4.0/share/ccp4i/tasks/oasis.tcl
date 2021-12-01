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
# oasis.tcl --
#
# CCP4Interface 
#
# =======================================================================

#-----------------------------------------------------------------------
proc oasis_run { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  # If DM is going to run then check for a valid solvent content
    if { $array(DM) } {
	if { $array(solc) <= 0.0 || $array(solc) >= 1.0 } {
	    WarningMessage "You have specified an invalid solvent fraction"
	    return 0
	}
    }

    set array(INPUT_FILES) "HKLIN"
    set array(OUTPUT_FILES) "HKLOUT"

    if { [GetValue $arrayname MOD] == 1 } {
	append array(INPUT_FILES) " M_HKLIN"
    }

    if { [GetValue $arrayname DM] == 1  } {
	set NAME [split $array(HKLOUT) .]
	set HKL_T [lindex $NAME 0]
	append HKL_T "_dm.mtz"
	set array(DM_HKLOUT) $HKL_T
	set array(DIR_DM_HKLOUT) $array(DIR_HKLOUT)
	append array(OUTPUT_FILES) " DM_HKLOUT"

    }

    if { [GetValue $arrayname PAR] == 1 && [GetValue $arrayname PAR_MODE] == "P_PDB" } {
	append array(INPUT_FILES) " PAR_PDB_FILE"
    }


    if { [GetValue $arrayname PAR] == 1 && [GetValue $arrayname PAR_MODE] == "P_OAS" } {
	append array(INPUT_FILES) " PAR_OAS_FILE"
    }

    if { [GetValue $arrayname HA] == "HA_PDB" && [GetValue $arrayname OASIS_MODE] != "DMR" }  {
	append array(INPUT_FILES) " HA_FILE_PDB"
    }

    if { [GetValue $arrayname HA] == "HA_OAS" && [GetValue $arrayname OASIS_MODE] != "DMR" }  {
	append array(INPUT_FILES) " HA_FILE_OAS"
    }

    if { [GetValue $arrayname CELL_CON] == "FILE" } {
	append array(INPUT_FILES) " SEQIN"
    }



    if { [GetValue $arrayname HA] == "HA_EN" && [GetValue $arrayname OASIS_MODE] != "DMR" }  {
		  set n 0
              for {set i 1} { $i <= $array(HA_T_NUM)} {incr i} {
                      for {set j 1} { $j <= $array(HA_NUM_P,$i) } {incr j} {
				incr n

			set array(HA_TYPE,$n) $array(HA_T_TYPE,$i)
			set array(HA_X,$n) $array([Indxv HA_X_T $i $j])
			set array(HA_Y,$n) $array([Indxv HA_Y_T $i $j])
			set array(HA_Z,$n) $array([Indxv HA_Z_T $i $j])
			set array(HA_OCC,$n) $array([Indxv HA_OCC_T $i $j])
			set array(HA_B,$n) $array([Indxv HA_B_T $i $j])
}
}
			set array(HA_NUM) $n
    }


      ha_up  $arrayname
 	ha_c_p $arrayname
	c_up $arrayname



 return 1
}


#---------------------------------------------------------------------
proc oasis_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
  upvar #0  $typedefVar typedef
  upvar #0 $arrayname array

    DefineMenu _oasis_mode [list "SAD --- direct phasing and/or fragment extension" \
	                         "SIR --- direct phasing and/or fragment extension"\
                                 "MR --- model completion"] \
	                     [list SAD SIR DMR]


    DefineMenu _cell_con [list "number of residues in asymmetric unit" "from sequence file (*.pir/*.seq)" ] \
	                        [list NUM FILE ]

    DefineMenu _oasis_ha_entry [list "enter below" "from PDB file" "from Oasis file"] \
	    [list HA_EN HA_PDB HA_OAS ]

    DefineMenu _oasis_xray [list "xray-wavelength" "input f''" ] \
	    [list X_WL X_F ]

 DefineMenu _par_mode [list "From PDB file" " From Oasis file" ] \
	    [list P_PDB P_OAS  ]

 DefineMenu _modify_mode [list  "merge" "Change FOMs" ] \
	    [list M_MER M_FOM  ]

  return 1
}

# procedure to draw task window
#---------------------------------------------------------------------
proc oasis_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array


  if { [CreateTaskWindow $arrayname  \
        "Direct methods of SAD/SIR phasing and MR-model completion" "OASIS" \
        [ list "Heavy-atom substructure" \
               "Controlling parameters for MR-model completion"\
               "*** Cell Contents for calculating E values in direct-method phasing" \
               "Controlling parameters for direct-method phasing"   \
	] ] == 0 } return


# Set the name of the CCP4 program help file to use
  SetProgramHelpFile "oasis"

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
	  message "Select one of the available actions to perform" \
	  label "                        Action       " \
	  widget OASIS_MODE \
        -command "mode_p $arrayname"



#=FILES================================================================ 

  OpenFolder file

  # Input MTZ
  CreateInputFileLine line \
        "Enter name of input mtz file" \
        "MTZ in  " \
        HKLIN DIR_HKLIN  -command "in_p $arrayname"\
	-setfileparam SPACE_GROUP_NAME SPACEGROUP \
	-setfileparam CELL_1 CELL_A \
	-setfileparam CELL_2 CELL_B \
	-setfileparam CELL_3 CELL_C \
	-setfileparam CELL_4 CELL_ALPHA \
	-setfileparam CELL_5 CELL_BETA \
	-setfileparam CELL_6 CELL_GAMMA \
	-setlabin FOMM [list FOMDM FOM FOMM ] \
	-fileout HKLOUT DIR_HKLOUT "_oasis_"

  CreateLabinLine line \
	"Assign structure factor amplitude and its sigma" \
	HKLIN "         Fp" FP {NULL} \
	-sigma "    SigFp" SIGFP {NULL}\
      -toggle_display OASIS_MODE open [list DMR]
 

#   Input labels for SAD
OpenSubFrame frame -toggledisplay OASIS_MODE open [list SAD]


          CreateLine line \
                label "       SAD data format  :"\
		widget MAP_FM  label  "Fmean, Dano       "  -command "map_p1 $arrayname"\
		widget MAP_FP  label "F+, F -" -command "map_p2 $arrayname" 


OpenSubFrame frame -toggledisplay MAP_FM open 1

  CreateLabinLine line \
	"Assign the mean of |F(+)| and |F( - )| and the corresponding sigma" \
	HKLIN "     Fmean" FP {NULL} \
	-sigma "SigFmean" SIGFP {NULL}\

  CreateLabinLine line \
	"Assign anomalous difference, |F(+)| - |F( - )|, and its sigma" \
	HKLIN "     Dano" DANO {NULL} \
	-sigma "SigDano" SIGDANO {NULL}\


CloseSubFrame

OpenSubFrame frame -toggledisplay MAP_FP open 1

  CreateLabinLine line \
	"Assign structure factor amplitude |F(+)| and its sigma" \
	HKLIN "      F+" FP {NULL} \
	-sigma "     SigF+" SIGFP {NULL}\

  CreateLabinLine line \
	"Assign structure factor amplitude |F( - )| and its sigma" \
	HKLIN "      F -" DANO {NULL} \
	-sigma "     SigF -" SIGDANO {NULL}\


CloseSubFrame

CloseSubFrame


# Input labels for SIR

  OpenSubFrame frame -toggledisplay OASIS_MODE open [list SIR]

   CreateLabinLine line \
	"For SIR: assign native structure factor amplitude and sigma" \
	HKLIN "     Fnative" FP {NULL} \
	-sigma "SigFnative" SIGFP {NULL}

  CreateLabinLine line \
	"For SIR: assign isomorphous difference and sigma" \
	HKLIN "      Fderiv" FPH {NULL} \
	-sigma "SigFderiv" SIGFPH {NULL} \

 CloseSubFrame

  # Input phases for comparison



  # Output MTZ
  CreateOutputFileLine line \
	"Enter name of output mtz file" \
       "MTZ out" \
	HKLOUT DIR_HKLOUT

  CreateLine line \
	  message "Set low- and high-resolution limits to diffraction data (RES keyword)" \
	  widget RES \
	  label "Resolution range from" \
	  widget RES_L \
	  label " to " \
	  widget RES_H \
	  label " Angstroms" 


  CreateLine line \
	  message "Compare resultant phases with those provided in input Mtz file (PHI keyword)" \
	  widget COMPARE_PHI \
	  label "Perform comparison with known phases from input file    "\
     
     CreateLabinLine line \
	  "Known phases for comparison with those resulted from OASIS" \
	  HKLIN "     PHIC" PHIC {NULL} \
	  -toggle_display COMPARE_PHI open [list 1]


CreateLine line \
	  message "Known structure fragment(s) to be extended" \
	  widget PAR \
	  label "Partial structure" 

OpenSubFrame frame -toggle_display PAR open 1

CreateLine line \
	    label "     " widget PAR_MODE

CreateInputFileLine line \
	    "FRA" \
	    "       PDB input" \
	    PAR_PDB_FILE DIR_PAR_PDB_FILE \
	    -toggle_display PAR_MODE open [list P_PDB]

CreateInputFileLine line \
	    "FRA" \
	    "       File input" \
	    PAR_OAS_FILE DIR_PAR_OAS_FILE \
	    -toggle_display PAR_MODE open [list P_OAS]

CloseSubFrame 

#  CreateLine line \
#	  widget MOD \
#	  label "Modify output phases"\

#OpenSubFrame frame -toggle_display MOD open 1
#    CreateLine line \
	   label "     " widget MOD_MOD

#OpenSubFrame frame -toggle_display MOD_MOD open M_MER

#  CreateInputFileLine line \
        "Enter name of input mtz file" \
        "       using the file" \
         M_HKLIN DIR_M_HKLIN

#  CreateLabinLine line \
	" " \
	M_HKLIN "       phase" M_PHIC {NULL} \
	-sigma "           FOM" M_FOM {NULL}

#    CreateLine line \
	   label "    "  widget  KEEP_MOD  label "keep unmodified MTZ file"

#CloseSubFrame 


#OpenSubFrame frame -toggle_display MOD_MOD open M_FOM

#  CreateInputFileLine line \
        "Enter name of input mtz file" \
        "       using the file" \
         M_HKLIN DIR_M_HKLIN

#    CreateLine line \
	   label "    "  widget  KEEP_MOD  label "keep unmodified MTZ file"

#CloseSubFrame 
#CloseSubFrame 



    CreateLine line \
	    widget DM  label "Run DM after OASIS" -command "dm_fom $arrayname" 

OpenSubFrame frame -toggle_display DM open 1

     CreateLine line \
            label "       Fractional solvent content"\
            widget solc
    CloseSubFrame 





#-----------------------------------------------------------------------------------------
 OpenFolder 1 OASIS_MODE hide [list DMR] closed  [list SIR] open  [list SAD]



       CreateLine line \
       label "     "\
	 widget HA -command "ha_p_c $arrayname"

      CreateInputFileLine line \
        "Enter name of input pdb file" \
        "       PDB in " \
        HA_FILE_PDB DIR_HA_FILE_PDB  \
         -command "ha_pdb $arrayname" \
       -toggle_display HA open [list HA_PDB]

      CreateInputFileLine line \
        "Enter name of input pdb file" \
        "       OAS in " \
        HA_FILE_OAS DIR_HA_FILE_OAS \
         -command "ha_oas $arrayname" \
      -toggle_display HA open [list HA_OAS]

    OpenSubFrame frame -toggle_display HA open HA_EN

    CreateExtendingFrame HA_T_NUM ha_num \
	   "Click to add an atom type and the number of independent atoms of that type"  \
	   "Add type"  \
	    [ list HA_T_TYPE HA_T_TYPE_NUM X_F HA_NUM_P ] \
         -child ha_p

    CloseSubFrame



       CreateLine line \
       help ano \
       label "       X-ray wavelength"\
	 widget X_WLENGTH \ 

    OpenSubFrame frame -toggle_display INIT hide 0
    OpenSubFrame frame -toggle_display HA hide [list HA_EN]
    OpenSubFrame frame -toggle_display HA_T_NUM open [list 1 2 3 4]
    CreateLine line \
    label "Type " widget HA_T_TYPE,1  \
    label " f'' "  widget   X_F,1 	\
    label " Number "  widget  HA_T_TYPE_NUM,1 \  
    CloseSubFrame

    OpenSubFrame frame -toggle_display HA_T_NUM open [list 2 3 4]
    CreateLine line \
    label "Type " widget HA_T_TYPE,2 \
    label " f'' "  widget   X_F,2 	\
    label " Number "  widget   HA_T_TYPE_NUM,2 \
    CloseSubFrame

    OpenSubFrame frame -toggle_display HA_T_NUM open [list 3 4]
    CreateLine line \
    label "Type " widget HA_T_TYPE,3 \
    label " f'' "  widget   X_F,3 	\
    label " Number "  widget   HA_T_TYPE_NUM,3  \
	
    CloseSubFrame

    OpenSubFrame frame -toggle_display HA_T_NUM open [list 4]
    CreateLine line \
    label "Type " widget HA_T_TYPE,4 \
    label " f'' "  widget   X_F,4 	\
    label " Number "  widget   HA_T_TYPE_NUM,4 \  
     CloseSubFrame
     CloseSubFrame
      CloseSubFrame

#-------------------------------------------------------------------------------------------
 OpenFolder 2  OASIS_MODE hide [list SAD SIR] closed 



#               CreateLine line \
#               label "    " widget MR_SAD  \
#               label "simulating SAD phasing            " -command "mr_mode_p1 $arrayname" \
#               widget MR_SIR  \
#               label "simulating SIR phasing"  -command "mr_mode_p2 $arrayname"\


          CreateLine line \
	      message "Number of heavy atoms and SEED" \
	      label "       percentage of artificial heavy atoms" \
	      widget NHA\
            label "%              seed of random-number generator"\
            widget SED\



#-----------------------------------------------------------------------------------------

 OpenFolder 3
   
    OpenSubFrame frame -toggle_display CELL_CON open [list NUM]

       CreateLine line \
       help ano \
	 widget CELL_CON \
       label "   "   \
       widget CELL_CON_NUM \

    CreateExtendingFrame C_NUM C_other \
	    "Atoms not included in the heavy-atom substructure and other than C, N, O and H" \
	    "Other atoms" \
	    [ list C_TYPE C_TYPE_NUM ]


    CloseSubFrame

    OpenSubFrame frame -toggle_display CELL_CON open [list FILE]

       CreateLine line \
       help ano \
	 widget CELL_CON \ 

      CreateInputFileLine line \
        "Enter name of input pir file" \
        "Sequence in" \
        SEQIN DIR_SEQIN \

    CloseSubFrame





#-----------------------------------------------------------------------------------------

 OpenFolder 4 closed

CreateLine line \
	    help kmi \
	    message "Kappa minimum (KMI) for direct-method phase derivation" \
	    label "       Kappa minimum" \
	    widget KMI\
	    message "Number of cycles for phase iteration (CYC keyword, 2 cycles recommended for SAD)" \
	    label "     number of cycles for phase iteration" \
	    widget CYC



CreateLine line \
	    help cos \
	    message "Forcing cos(deltaPhi)'s to uniform distribution is for dealing with large experimental errors" \
     	    label "    " widget COS \
	    label "not forcing cos(deltaPhi)'s to follow uniform distribution"\

CreateLine line \
            message "Forcing output FOM's to uniform distribution is for dealing with large experimental errors" \
	    label "    " widget FOM \
	    label "not forcing output FOM's to follow uniform distribution"









}
#--------------------------------------------------------------------
proc mode_p { arrayname } {
#--------------------------------------------------------------------


    upvar #0 $arrayname array

    if { [GetValue $arrayname OASIS_MODE] == "SAD" } {
            set array(TITLE) "SAD phasing"
		set array(KMI) 0.03
		set array(FOM) 0
		set array(COS) 0
             set array(PAR) 0
         }

    if { [GetValue $arrayname OASIS_MODE] == "SIR" } {
            set array(TITLE) "SIR phasing"
		set array(KMI) 0.03
		set array(FOM) 0
		set array(COS) 0
             set array(PAR) 0
         }

    if { [GetValue $arrayname OASIS_MODE] == "DMR" } {
            set array(TITLE) "MR-model completion"
		set array(KMI) 0.05
		set array(FOM) 1
		set array(COS) 1
             set array(PAR) 1
         }

}



#--------------------------------------------------------------------
proc ha_p { arrayname counter c4 } {
#--------------------------------------------------------------------
# Add another line to extending frame to enter details for heavy atom
# sites

    upvar #0 $arrayname array

    CreateLine line \
	    message "X, Y, Z - fractional coordinates" \
	    label "       X"    widget HA_X_T \
	    label "Y"    widget HA_Y_T \
	    label "Z"    widget HA_Z_T \
	    label "Occ"      widget HA_OCC_T\
	    label "B"        widget HA_B_T\


}

#--------------------------------------------------------------------
proc ha_c_p { arrayname } {
#--------------------------------------------------------------------


    upvar #0 $arrayname array

if { [GetValue $arrayname HA] == "HA_EN" } {
set array(HA_T_NUM) 0
 
     for {set i 1} { $i <= $array(HA_NUM) } {incr i} {
		set sig 0
           for {set j 1} { $j <= $array(HA_T_NUM) } {incr j} {
		if { $array(HA_T_TYPE,$j) == $array(HA_TYPE,$i) } {
			set sig $j
			break
}

}		
		if { $sig == 0}  {
		incr array(HA_T_NUM)
		set array(HA_T_TYPE,$array(HA_T_NUM)) $array(HA_TYPE,$i)  
		set array(HA_T_TYPE_NUM,$array(HA_T_NUM)) 1
} else {
		incr array(HA_T_TYPE_NUM,$sig) 
}		

}

}
}



#--------------------------------------------------------------------
proc ha_num { arrayname counter } {
#--------------------------------------------------------------------


    upvar #0 $arrayname array

    CreateLine line \
	    label "       Type " widget HA_T_TYPE \
	    label " Number"  widget  HA_T_TYPE_NUM  \
	    label "f''"   widget  X_F	    

   CreateExtendingFrame HA_NUM_P ha_p \
	   "Click to add independent heavy atoms one by one"  \
	   "Add parameters"  \
	    [ list HA_X_T HA_Y_T HA_Z_T HA_OCC_T HA_B_T] \
          -counter $counter
}



#--------------------------------------------------------------------
proc C_other { arrayname counter } {
#--------------------------------------------------------------------


    upvar #0 $arrayname array

    CreateLine line \
	    label "       Type" widget C_TYPE \
	    label "       Number"  widget  C_TYPE_NUM 	    

}

#--------------------------------------------------------------------
proc merge_p { arrayname } {
#--------------------------------------------------------------------


    upvar #0 $arrayname array

    if {[GetValue $arrayname MER] == 1 } {
	set array(C_FOM) 0
}

}


#--------------------------------------------------------------------
proc fom_p { arrayname } {
#--------------------------------------------------------------------


    upvar #0 $arrayname array

    if {[GetValue $arrayname C_FOM] == 1 } {
	set array(MER) 0
}

}



#--------------------------------------------------------------------
proc map_p1 { arrayname } {
#--------------------------------------------------------------------


    upvar #0 $arrayname array

    if {[GetValue $arrayname MAP_FM] == 1 } {
	set array(MAP_FP) 0
} else {
        set array(MAP_FM) 1
}


}


#--------------------------------------------------------------------
proc map_p2 { arrayname } {
#--------------------------------------------------------------------


    upvar #0 $arrayname array

    if {[GetValue $arrayname MAP_FP] == 1 } {
	set array(MAP_FM) 0
} else {
        set array(MAP_FP) 1
}

}

#--------------------------------------------------------------------
proc mr_mode_p1 { arrayname } {
#--------------------------------------------------------------------


    upvar #0 $arrayname array

    if {[GetValue $arrayname MR_SAD] == 1 } {
	set array(MR_SIR) 0
} else {
        set array(MR_SIR) 1
}


}


#--------------------------------------------------------------------
proc mr_mode_p2 { arrayname } {
#--------------------------------------------------------------------


    upvar #0 $arrayname array

    if {[GetValue $arrayname MR_SIR] == 1 } {
	set array(MR_SAD) 0
} else {
        set array(MR_SAD) 1
}


}

#--------------------------------------------------------------------
proc ha_up { arrayname } {
#------------------------------------------------------------------

    upvar #0 $arrayname array

       for {set i 1} { $i <= $array(HA_NUM) } {incr i } {
       set array(HA_TYPE,$i) [string toupper $array(HA_TYPE,$i)]
}
       for {set i 1} { $i <= $array(HA_T_NUM) } {incr i } {
       set array(HA_T_TYPE,$i) [string toupper $array(HA_T_TYPE,$i)]
}

}


#--------------------------------------------------------------------
proc ha_pdb { arrayname } {
#------------------------------------------------------------------

upvar #0 $arrayname array

set array(INIT) 1
set array(HA_T_NUM) 0
set DIR_TMP [GetCurrentProjectDir $array(DIR_HA_FILE_PDB)]
append DIR_TMP "/$array(HA_FILE_PDB)"

if { ![ReadFile $DIR_TMP file_list] } {
  set DIR_TMP [GetCurrentProjectDir $array(DIR_HA_FILE_PDB)]
  append DIR_TMP "$array(HA_FILE_PDB)"
}
   
           if { [ReadFile $DIR_TMP file_list -split ] }  {


              foreach line0 $file_list {
     	        set line [string trim $line0]
              set title  [lindex $line 0]

		if { $title == "ATOM" || $title == "HETATM" }  {
             set HA_TYPE   [lindex $line 2]

		set sig 0
              for {set j 1} { $j <= $array(HA_T_NUM) } {incr j} {
		 if { $HA_TYPE == $array(HA_T_TYPE,$j) } {
			set sig $j
			break
}
}		
		 if { $sig == 0}  {
		 incr array(HA_T_NUM)
		 set array(HA_T_TYPE,$array(HA_T_NUM)) $HA_TYPE  
		 set array(HA_T_TYPE_NUM,$array(HA_T_NUM)) 1
} else {
		 incr array(HA_T_TYPE_NUM,$sig) 
}
}
}
}
}

#--------------------------------------------------------------------
proc ha_oas { arrayname } {
#------------------------------------------------------------------

upvar #0 $arrayname array
set array(INIT) 1
set array(HA_T_NUM) 0
set DIR_TMP [GetCurrentProjectDir $array(DIR_HA_FILE_OAS)]
append DIR_TMP "/$array(HA_FILE_OAS)"

           if { [ReadFile $DIR_TMP file_list -split ] }  {

              foreach line0 $file_list {
      	        set line [string trim $line0]
              set HA_TYPE   [lindex $line 0]

		if { $HA_TYPE == "" } {
		continue
}
		  set sig 0

              for {set j 1} { $j <= $array(HA_T_NUM) } {incr j} {
		 if { $HA_TYPE == $array(HA_T_TYPE,$j) } {
			set sig $j
			break
}
}		
		 if { $sig == 0}  {
		 incr array(HA_T_NUM)
		 set array(HA_T_TYPE,$array(HA_T_NUM)) $HA_TYPE  
		 set array(HA_T_TYPE_NUM,$array(HA_T_NUM)) 1
} else {
		 incr array(HA_T_TYPE_NUM,$sig) 
}
}
}
}

#--------------------------------------------------------------------
proc ha_p_c { arrayname } {
#--------------------------------------------------------------------
# Add another line to extending frame to enter details for heavy atom
# sites

    upvar #0 $arrayname array
       for {set i 1} { $i <= $array(HA_T_NUM) } {incr i } {
       set array(HA_T_TYPE,$i) ""
       set array(HA_T_TYPE_NUM,$i) 0
}
if { [GetValue $arrayname HA ] != "HA_EN" } {
set array(INIT) 0
}
set array(HA_FILE_PDB) ""
set array(HA_FILE_OAS) ""

}
#-----------------------------------------------------------------------
proc c_up { arrayname } {
#------------------------------------------------------------------------
    upvar #0 $arrayname array

       for {set i 1} { $i <= $array(C_NUM) } {incr i } {
       set array(C_TYPE,$i) [string toupper $array(C_TYPE,$i)]
}
}
#-----------------------------------------------------------------------
proc dm_fom { arrayname } {
#------------------------------------------------------------------------
    upvar #0 $arrayname array

	if { $array(DM) == 1 && [GetValue $arrayname OASIS_MODE] == "DMR" } {
		if { $array(MOD) == 0 } {
			set array(MOD) 1
			SetValue $arrayname MOD_MOD "M_FOM"
			if { $array(M_HKLIN) == "" } {
			set array(M_HKLIN) $array(HKLIN)
			set array(DIR_M_HKLIN) $array(DIR_HKLIN)
}
}
}
}

#-----------------------------------------------------------------------
proc in_p { arrayname } {
#------------------------------------------------------------------------
    upvar #0 $arrayname array

			set array(M_HKLIN) $array(HKLIN)
			set array(DIR_M_HKLIN) $array(DIR_HKLIN)



}

