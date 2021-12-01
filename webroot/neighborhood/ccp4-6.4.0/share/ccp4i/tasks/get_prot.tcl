#
#     Copyright (C) 1999-2004  Pryank Patel
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
# ======================================================================
# get_prot.tcl --
#
# Import protein sequence from database and edit if necessary
#
# CCP4Interface 
#
# =======================================================================

#==========================================================================
#==_setup==initialisations, defining local menus===========================
#==========================================================================

proc get_prot_setup { typedefname arrayname } {

    upvar #0 $typedefname typedef
    
    set typedef(_get_prot_input) { menu { "EBI/other Database" "CCP4 Database" } { FASTA CCP4_DATABASE } }
    set typedef(_get_prot_saving) { menu { "All Sequences" "Last Sequence"} { SAVEALL SAVELAST } }
#DEFINE MENUS
    

    set typedef(_any_file) { file ANY "*"  "All"  "" ""}

    return 1
    
}

#==========================================================================
#==_task_window==core procedure. all commands to define graphical interface
#==========================================================================

proc get_prot_task_window { arrayname } {

    global get_prot_var
#VARIABLE TO KEEP TRACK OF THE NUMBER OF SEQUENCES OPENED IN A SESSION
    global configure

    upvar #0 $arrayname array

    set get_prot_var(RUN_COUNT) 0
    
    if { [CreateTaskWindow $arrayname \
	      "Import/Edit Protein Sequence" "Get_Prot" [list "Input from CCP4 Database" "Input from EBI/other Database" "View Full Sequence Entry" "Sequence Only" "Editing" "Other Information"] \
	      {} \
	      -action_buttons [ list quit ] ] == 0 } return
    
# Add extra customised button for saving sequence
CreateButton $array(WINDOW) save "Save Sequence" "get_prot_save $arrayname" \
      -message "save current sequence in ccp4i database"


# Add extra customised button for loading sequence
#CreateButton $array(WINDOW) load "Import Sequence" "run_command interactive get_prot $arrayname" \
 #     -message "load chosen sequence into interface"

#==========================================================================
#==PROTOCOL==TITLE AND KEY DECISIONS=======================================
#==========================================================================
    
    OpenFolder protocol
    
    CreateTitleLine line TITLE
    
    CreateLine line \
	label "Select database " \
        message "Location of desired sequence (external Db can be set in Configure interface - default is EBI)" \
        widget INPUT 

    
#WIDGET CREATED GIVING USER CHOICE BETWEEN OPENING FILE FROM LOCAL DATABASE OR DOWNLOADING FILE FROM SWISSPROT

#=========================================================================
#==FOLDER 1==Input and Output Declaration if choosing local file==========
#=========================================================================

    
    OpenFolder 1 INPUT open CCP4_DATABASE hide
    
    CreateLine line label "Opening file from..."

    CreateInputFileLine test "Open from" Sequence SEQIN DIR_SEQIN
    CreateLine line
    button $line.import2 -text "Import Sequence Now!" -command "run_command interactive get_prot $arrayname"
    $line.import2 configure -background $configure(COLOUR_PALE)
    SetMessage $arrayname $line.import2 "Import Sequence"
    pack $line.import2 -side left

    CreateLine line label "\n"

    CreateLine line label "Save" \
       message "Save to disk either last sequence imported or all sequences" \
       widget SAVING label "into..."
#Added widget to give user option of saving either the last imported sequence or all sequences in text widget
    CreateOutputFileLine test_output \
       "Give name of file to save sequence in and click on Save Sequence below" \
       File SEQOUT DIR_SEQOUT

#ABOVE PROCEDURE CARRIED OUT IF USER CHOOSES TO OPEN FILE FROM LOCAL DATABASE

#===========================================================================
#==FOLDER 2==Accession code query and Output file declaration if downloading from EBI
#===========================================================================

    OpenFolder 2 INPUT open FASTA hide

    CreateLine line label "Type Protein Code:" \
       message "Give SwissProt code and hit Import Sequence Now" \
       widget CODE -oblig

    CreateLine line
    button $line.import -text "Import Sequence Now!" -command "run_command interactive get_prot $arrayname"
    $line.import configure -background $configure(COLOUR_PALE)
    SetMessage $arrayname $line.import "Import Sequence"
    pack $line.import -side left

    CreateLine line label "\n"

    CreateLine line label "Save" widget SAVING label "into..."
#Added widget to give user option of saving either the last imported sequence or all sequences in text widget

    CreateOutputFileLine test_output "Name of file to save sequence in" "File   " \
       SEQOUT DIR_SEQOUT

#ABOVE PROCEDURE CARRIED OUT IF USER CHOOSES TO DOWNLOAD NEW FILE FROM SWISSPROT


#===========================================================================
#==FOLDER 3==TEXT WINDOWN TO SHOW WHOLE FILE================================
#===========================================================================

    OpenFolder 3 closed

    CreateLine line label "Full Details"

    CreateText textframe_full " " -scroll

    set array(TEXTFRAME_FULL) $textframe_full

#===========================================================================
#==FOLDER 4==First Text Window to show sequence=============================
#===========================================================================

    OpenFolder 4 open
    
    CreateText textframe " " -scroll

    set array(TEXTFRAME) $textframe
#CREATES TEXTFRAME TO HOLD SEQUENCE, WITH SELECTIONS AND EDITING

    CreateLine line 
#button that clears the entire contents of the text widget
    button $line.clearall -text "Clear All Contents" -command "get_prot_clear $arrayname"
    $line.clearall configure -background $configure(COLOUR_PALE)
    SetMessage $arrayname $line.clearall "Clear All Contents"
    pack $line.clearall -side left

#button that calculates the molecular weight of the last protein shown, in Daltons
    button $line.calcweight -text "Calculate Molecular Weight" -command "get_prot_calculate_weight $arrayname"
    $line.calcweight configure -background $configure(COLOUR_PALE)
    SetMessage $arrayname $line.calcweight "Calculate the molecular weight of the last protein shown"
    pack $line.calcweight -side left



#==========================================================================
#==FOLDER 5==Folder containing Editing Facilities==========================
#==========================================================================
    
    OpenFolder 5 closed
    
    CreateLine line label "Editing facilities\n" 

    CreateLine line message "search for sequence of amino acids in full sequence" \
       button "Search For..." -command "get_prot_search $arrayname" widget SEARCH \
       message "delete highlighted sequence" button Delete \
       -command "get_prot_delete $arrayname" 

    CreateLine line message "mutate highlighted sequence" button "Mutate Into..." \
       -command "get_prot_mutate $arrayname" widget MUTATE

    CreateLine line message "insert after highlighted sequence" button "Insert" \
       -command "get_prot_insert $arrayname" widget INSERT -expand  

    CreateLine line message "Undo last editing" button "Undo" \
       -command "get_prot_undo $arrayname" 
#CREATES BUTTONS TO CARRY OUT EDITING FUNCTIONS


#==FOLDER 6==Miscellaneous Information=====================================

    OpenFolder 6 open

    CreateText textframe_edit " " -scroll
    
    set array(TEXTFRAME_EDIT) $textframe_edit
#CREATES TEXTFRAME TO SHOW ALL CHANGES MADE TO SEQUENCE

}

#==========================================================================
#==_run==executed when user hits IMPORT SEQUENCE NOW.======================
#==========================================================================

proc get_prot_run { arrayname } {
    
    global get_prot_var
    global configure
    global output_text

# Source file containing DownloadSequence
    source [SearchPath TOP utils seq_utils.tcl]

    upvar #0 $arrayname array

    if { [ElementExists configure WGET_SEQUENCE] && $configure(WGET_SEQUENCE) != "" } {
      set array(WGET_COMMAND) $configure(WGET_SEQUENCE)
    }
    
    set get_prot_var(FINAL_SEQUENCE) ""

    set get_prot_var(RUN_COUNT) [expr $get_prot_var(RUN_COUNT) + 2]
 
# Set log file, and write header information
    set array(LOGFILE) [GetTmpFileName]
    set logheader [WriteIdentifier {} "LOG get_prot" \
	SCRATCH [GetEnvPath CCP4_SCR] \
	HOSTNAME [GetHostname] \
	PID [GetPid] ]
    WriteFile $array(LOGFILE) $logheader
    WriteFile $array(LOGFILE) "\n \#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#"
    WriteFile $array(LOGFILE)   " \#\#\#\#\#\#\#   GET_PROT INTERACTIVE TASK    \#\#\#\#\#\#\#\#\#\#\#\#\#\#\#"
    WriteFile $array(LOGFILE)   " \#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#"

#TMP FILE DEFINED TO HOLD THE ORIGINAL SWISS-PROT ENTRY
    set get_prot_var(ENTRYFILE) [GetTmpFileName]
#TMP FILE DEFINED TO HOLD THE CHANGES TO THE PROTEIN SEQUENCE 
    set get_prot_var(CHANGES_FILE) [GetTmpFileName]

    set database $array(INPUT)
#DATABASE ASSIGNED ACCORDING TO SOURCE OF PROTEIN SEQUENCE
    
    if { $database == "EBI/other Database" } {
	set code $array(CODE)
#CODE IS THE ACCESSION CODE OF THE PROTEIN FROM SWISSPROT
	if { $code == "" } {
	    PleaseWait
 	    WarningMessage "No code entered"
 	    return 0
#WARNING MESSAGE IF CODE IS LEFT BLANK - THEREFORE NO FILE TO DOWNLOAD FROM SWISSPROT
	} 
        WriteFile $array(LOGFILE) "\nRetrieving sequence from remote database ... \n\n"
	PleaseWait "Trying to connect..."
	WriteFile $array(LOGFILE) "\nTemp EntryFile containing sequence: $get_prot_var(ENTRYFILE)\n"
	WriteFile $array(LOGFILE) "\nChanges File: $get_prot_var(CHANGES_FILE)\n"
	WriteFile $array(LOGFILE) "\nURL: $configure(DATABASE_URL)$code\n"

        DownloadSequence $get_prot_var(ENTRYFILE) $array(LOGFILE) "www.ebi.ac.uk/cgi-bin/swissfetch" $code

# retrieve sequence from temporary file
	if { [ReadFile "$get_prot_var(ENTRYFILE)" sequence_text]} {
	    set output_text "$sequence_text"
	}
	PleaseWait

	if { $sequence_text != "" } {
           WriteFile $array(LOGFILE) "\nDownload successful\n"
	} else {
           WriteFile $array(LOGFILE) "\nFailed to download sequence from remote database.\n"
           WriteFile $array(LOGFILE) "Check settings in Configure Interface for Proxy Server and External Protein Sequence Database.\n"
 	   WarningMessage "Download failed! Check the log file for the get_prot job."
	}
    } 
    if { $database == "CCP4 Database" } {

	WriteFile $array(LOGFILE) "\nRetrieving sequence from local database...\n\n"
	WriteFile $array(LOGFILE) "Sequence FileName $array(SEQIN)"

 	set file [GetFullFileName [FileRootName $array(SEQIN)] $array(DIR_SEQIN)].seq
	set code ""
#CODE IS BLANK BECAUSE FILE UPLOADED IS FROM LOCAL DATABASE

	if {[ReadFile $file sequence_text]} {
 	    set output_text "$sequence_text"
#READS THE CONTENTS OF THE FILE INTO THE output_text VARIABLE
 	} else {
  	    PleaseWait
 	    WarningMessage "File not present or cannot be read"
 	    return 0
#IF FILE NOT PRESENT, WARNING MESSAGE RETURNED

 	}
    }

    set get_prot_var(CODELINE_ACC) [regexp "AC   " $output_text]

    set get_prot_var(NUMLINES) [regsub -all \n $output_text {} ignore]
    
    set get_prot_var(FINAL_SEQUENCE) ""
   
    if { $get_prot_var(CODELINE_ACC) == 1 } {

	set get_prot_var(CODELINE_ACC) [ExtractFromText $output_text "AC   " 0 all]
	regsub "AC   " $get_prot_var(CODELINE_ACC) ">" get_prot_var(CODELINE_ACC)

	set get_prot_var(CODELINE) [ExtractFromText $output_text "DE   " 0 all]
	regsub "DE   " $get_prot_var(CODELINE) "" get_prot_var(CODELINE)

	AppendTextWindow $array(TEXTFRAME) "$get_prot_var(CODELINE_ACC) $get_prot_var(CODELINE)"

	set sequence_line [regexp SQ $output_text]

	for {set y 1} {$y < $get_prot_var(NUMLINES)} {incr y} {

	    set line [ExtractFromText $output_text "SQ " $y all]

	    if  { $line == "//" } {

		break
	    }

	    append get_prot_var(FINAL_SEQUENCE) $line
	    set get_prot_var(FINAL_SEQUENCE)

	}

	regsub -all " " $get_prot_var(FINAL_SEQUENCE) "" get_prot_var(FINAL_SEQUENCE)

    AppendTextWindow $array(TEXTFRAME_FULL) "$output_text"


    } elseif { $get_prot_var(CODELINE_ACC) == 0 } {

	set get_prot_var(CODELINE) [ExtractFromText $output_text $code 0 all]
	AppendTextWindow $array(TEXTFRAME) "$get_prot_var(CODELINE)"

	for {set x 1} {$x < $get_prot_var(NUMLINES)} {incr x} {
	    set sequence [ExtractFromText $output_text "$code" $x all]	
	    append get_prot_var(FINAL_SEQUENCE) $sequence
	    set get_prot_var(FINAL_SEQUENCE)
	}

    }
    AppendTextWindow $array(TEXTFRAME) "$get_prot_var(FINAL_SEQUENCE)" 
    $array(TEXTFRAME) yview [expr $get_prot_var(RUN_COUNT)-1].0

    set get_prot_var(SEARCH) $array(SEARCH)
    set get_prot_var(SEARCH_POS_COUNT) 0	

    $array(TEXTFRAME) configure -state normal
    $array(TEXTFRAME) mark set get_prot_var(SEARCHPOINT) $get_prot_var(RUN_COUNT).0
    $array(TEXTFRAME) configure -state disabled

    return 1

}

#===========================================================================
#==get_prot_search Procedure==Searches Protein for Query====================
#===========================================================================

proc get_prot_search { arrayname  } {

    global get_prot_var
    global tmp    
    global cnt

    upvar #0 $arrayname array

    set search_backup [string toupper $get_prot_var(SEARCH)]
    set get_prot_var(SEARCH) [string toupper $array(SEARCH)]
    set search_length [string length $get_prot_var(SEARCH)]
    set t_edit $array(TEXTFRAME_EDIT)

#    puts "search : $get_prot_var(SEARCH)"
#    puts "search backup : $search_backup"

    $array(TEXTFRAME) configure -state normal

    if { $get_prot_var(SEARCH) == "" } {
	WarningMessage "No Search String Entered"
    }
#OLD PRYANK SAYING: "YOU CANNOT FIND SOMETHING IF YOU DO NOT KNOW WHAT YOU ARE LOOKING FOR"

    if {$search_backup != $get_prot_var(SEARCH)} {
	set get_prot_var(SEARCH_POS_COUNT) 0
	$array(TEXTFRAME) mark set get_prot_var(SEARCHPOINT) $get_prot_var(RUN_COUNT).0
    }
#IF THE SEARCH QUERY CHANGES, THEN RESET SEARCH MARK TO BEGINNING OF PROTEIN SEQUENCE

    $array(TEXTFRAME) mark set front $get_prot_var(RUN_COUNT).0
    set tmp [$array(TEXTFRAME) search -count cnt $get_prot_var(SEARCH) get_prot_var(SEARCHPOINT) end]

#RETURNS THE INDEX OF THE START OF THE PATTERN MATCH IN tmp

    if {$tmp == "" } {
 	WarningMessage "None/No More Found"
	$array(TEXTFRAME) mark set get_prot_var(SEARCHPOINT) $get_prot_var(RUN_COUNT).0
	$array(TEXTFRAME) tag delete get_prot_var(MYSEL)

#WHEN THE WHOLE OF THE PROTEIN SEQUENCE IS SEARCHED AND THERE ARE EITHER NO EXAMPLES OF THE SEARCH STRING, OR NO MORE ARE FOUND, THE MESSAGE IS PRODUCED ON THE SCREEN.

    } elseif {$cnt == 0} {

	$array(TEXTFRAME) mark set get_prot_var(SEARCHPOINT) $get_prot_var(RUN_COUNT).0
	set tmp [$array(TEXTFRAME) search -count cnt $get_prot_var(SEARCH) get_prot_var(SEARCHPOINT) end]
	
    } elseif {$cnt > 0} {
	$array(TEXTFRAME) mark unset get_prot_var(SEARCHPOINT)
	$array(TEXTFRAME) mark set get_prot_var(SEARCHPOINT) "$tmp + $cnt chars"
	$array(TEXTFRAME) tag delete get_prot_var(MYSEL)
	$array(TEXTFRAME) tag configure get_prot_var(MYSEL) -background red
	$array(TEXTFRAME) tag add get_prot_var(MYSEL) $tmp "$tmp + $cnt chars"
	$array(TEXTFRAME) yview "$tmp - 300 chars"
#IF A SEARCH STRING IS FOUND WITHIN THE PROTEIN SEQUENCE, THAT STRING IS HIGHLIGHTED IN RED. ALSO, IF THE PROTEIN SEQUENCE DOES NOT FIT INSIDE THE VIEWING WINDOW, THE SCREEN SHIFTS TO VIEW THE 300 AMINO ACIDS BEFORE THE HIGHLIGHTED SECTION.

    } 
    
    $array(TEXTFRAME) configure -state disabled

}


#===========================================================================
#==get_prot_insert Procedure==Inserts string after Search Query Found=======
#===========================================================================

proc get_prot_insert { arrayname } {
    
    global get_prot_var
    global tmp
    
    upvar #0 $arrayname array

    set get_prot_var(INSERT) $array(INSERT)

    set insert_length [string length $get_prot_var(INSERT)]
    set search_length [string length $get_prot_var(SEARCH)]

    if { $get_prot_var(SEARCH) == "" || $get_prot_var(INSERT) == "" || $tmp == ""} {
	WarningMessage "No Search String Entered/Highlighted OR No Insertion String Entered"

    } else {

	set get_prot_var(INSERT) [string toupper $get_prot_var(INSERT)]

	$array(TEXTFRAME) configure -state normal
	
	$array(TEXTFRAME) insert "$tmp + $search_length chars" $get_prot_var(INSERT)
#INSERT WITHIN THE PROTEIN SEQUENCE THE STRING LOADED IN THE INSERT BOX
	
	set insert_position [$array(TEXTFRAME) get $get_prot_var(RUN_COUNT).0 "$tmp + $search_length chars + $insert_length chars" ]

	set get_prot_var(INSERT_POS_INDEX) [string length $insert_position]
#RETURNS THE POSITION WITHIN THE PROTEIN SEQUENCE WHERE INSERTION TOOK PLACE.
	
	$array(TEXTFRAME) configure -state disabled
	
	AppendTextWindow $array(TEXTFRAME_EDIT) "$get_prot_var(INSERT) inserted at position: $get_prot_var(INSERT_POS_INDEX)"
	
	WriteFile $get_prot_var(CHANGES_FILE) "$get_prot_var(INSERT) inserted at position: $get_prot_var(INSERT_POS_INDEX)"
	
	set get_prot_var(LAST_EDIT) 1

    }
}

#===========================================================================
#==get_prot_delete Procedure==Deletes Search Query==========================
#===========================================================================

proc get_prot_delete { arrayname } {

    global get_prot_var
    global tmp
    
    upvar #0 $arrayname array

    set search_length [string length $get_prot_var(SEARCH)]

    if { $get_prot_var(SEARCH) == "" || $tmp == ""} {
	WarningMessage "No Search String Entered/Highlighted"

    } else {

	$array(TEXTFRAME) configure -state normal
	
	$array(TEXTFRAME) delete $tmp "$tmp + $search_length chars"
#DELETES FROM THE PROTEIN SEQUENCE THE SEARCH STRING 

	set delete_position [$array(TEXTFRAME) get $get_prot_var(RUN_COUNT).0 "$tmp" ]

	set get_prot_var(DELETE_POS_INDEX) [string length $delete_position]
#RETURNS THE POSITION WITHIN THE PROTEIN SEQUENCE OF THE LAST DELETION

	$array(TEXTFRAME) configure -state disabled
	
	AppendTextWindow $array(TEXTFRAME_EDIT) "$get_prot_var(SEARCH) deleted at position: [expr $get_prot_var(DELETE_POS_INDEX)+1]"
	
	WriteFile $get_prot_var(CHANGES_FILE) "$get_prot_var(SEARCH) deleted at position: [expr $get_prot_var(DELETE_POS_INDEX)+1]"
	
	set get_prot_var(LAST_EDIT) 2

    }
}

#===========================================================================
#==get_prot_mutate Procedure==Carries out mutation on Protein sequence======
#===========================================================================

proc get_prot_mutate { arrayname } {

    global get_prot_var
    global tmp

    upvar #0 $arrayname array

    set mutate [string toupper $array(MUTATE)]

    set mutate_length [string length $mutate]
    set search_length [string length $get_prot_var(SEARCH)]

    if { $get_prot_var(SEARCH) == "" || $mutate == "" || $tmp == ""} {
	WarningMessage "No Search String Entered/Highlighted OR No Mutation String Entered"
    
    } else {

	$array(TEXTFRAME) configure -state normal
	
	$array(TEXTFRAME) delete $tmp "$tmp + $search_length chars"

	$array(TEXTFRAME) insert $tmp $mutate
#MUTATES THE SELECTED RESIDUES BY FIRST DELETING THE SELECTED RESIDUES AND THEN REPLACING THEM WITH THE STRING IN THE MUTATE BOX.
  
	set mutate_position [$array(TEXTFRAME) get $get_prot_var(RUN_COUNT).0 "$tmp" ]
	
	set mutate_pos_index [string length $mutate_position]
#RETURNS THE POSITION WITHIN THE PROTEIN SEQUENCE OF THE LAST MUTATION.

	$array(TEXTFRAME) configure -state disabled

        regsub $get_prot_var(SEARCH) $get_prot_var(FINAL_SEQUENCE) $mutate get_prot_var(FINAL_SEQUENCE)
	AppendTextWindow $array(TEXTFRAME_EDIT) "$get_prot_var(SEARCH) mutated into $mutate at position: [expr $mutate_pos_index+1]"
	
	WriteFile $get_prot_var(CHANGES_FILE) "$get_prot_var(SEARCH) mutated into $mutate at position: [expr $mutate_pos_index+1]"
	
	set get_prot_var(LAST_EDIT) 3

    }
}

#===========================================================================
#==get_prot_undo Procedure==To undo last editing procedure carried out======
#===========================================================================

proc get_prot_undo { arrayname } {

    global get_prot_var
    global tmp

    upvar #0 $arrayname array

    set search_length [string length $get_prot_var(SEARCH)]

    if { $get_prot_var(LAST_EDIT) == 1 && $tmp !="" } {
	$array(TEXTFRAME) configure -state normal
	$array(TEXTFRAME) delete "$tmp + $search_length chars" "$tmp + $search_length chars + $search_length chars"
	$array(TEXTFRAME) configure -state disabled
	WriteFile $get_prot_var(CHANGES_FILE) "UNDONE"
	AppendTextWindow $array(TEXTFRAME_EDIT) "UNDONE"
	set get_prot_var(LAST_EDIT) 0
    } 
#IF THE LAST EDITING FUNCTION CARRIED OUT WAS INSERTION, THEN UNDO INSERTION

    if { $get_prot_var(LAST_EDIT) == 2 && $tmp != "" } {
	$array(TEXTFRAME) configure -state normal
	$array(TEXTFRAME) insert $tmp $get_prot_var(SEARCH)
	$array(TEXTFRAME) configure -state disabled
	WriteFile $get_prot_var(CHANGES_FILE) "UNDONE"
	AppendTextWindow $array(TEXTFRAME_EDIT) "UNDONE"
	set get_prot_var(LAST_EDIT) 0
    }
#IF THE LAST EDITING FUNCTION CARRIED OUT WAS DELETION, THEN UNDO DELETION

    if { $get_prot_var(LAST_EDIT) == 3 && $tmp != "" } {
	$array(TEXTFRAME) configure -state normal
	$array(TEXTFRAME) delete $tmp "$tmp + $search_length chars"
	$array(TEXTFRAME) insert $tmp $get_prot_var(SEARCH)	
	$array(TEXTFRAME) configure -state disabled
	WriteFile $get_prot_var(CHANGES_FILE) "UNDONE"
	AppendTextWindow $array(TEXTFRAME_EDIT) "UNDONE"
	set get_prot_var(LAST_EDIT) 0
    }
#IF THE LAST EDITING FUNCTION CARRIED OUT WAS MUTATION, THEN UNDO MUTATION

    if { $tmp == "" } {
	WarningMessage "Previous search string highlighted"
    }

}

#===========================================================================
#==get_prot_save Procedure==Saves changed protein sequence in specified file
#===========================================================================

proc get_prot_save { arrayname } {
    
    global get_prot_var

    upvar #0 $arrayname array

    if { $array(SEQOUT) == "" || $array(DIR_SEQOUT) == ""} {
	WarningMessage "No Output File Name Specified"
 	return 0
    }

# following are names of permanent files created on Save
    set output_file [GetFullFileName [FileRootName $array(SEQOUT)] $array(DIR_SEQOUT)].seq
    set entry_file [file root $output_file].ent
    set changes_file [file root $output_file].chg

    $array(TEXTFRAME) configure -state normal
    
    if { $array(SAVING) == "Last Sequence" } {
	set whole [$array(TEXTFRAME) get [expr $get_prot_var(RUN_COUNT)-1].0 $get_prot_var(RUN_COUNT).end]
    } elseif { $array(SAVING) == "All Sequences" } {
	set whole [$array(TEXTFRAME) get 1.0 $get_prot_var(RUN_COUNT).end]
    }
    
    $array(TEXTFRAME) configure -state disabled
    
    WriteFile $output_file $whole -overwrite
    #SELECT, FROM THE TEXT WINDOW, THE CHANGED SEQUENCE AND WRITE SEQUENCE TO SPECIFIED OUTPUT FILE
    if { [file exists $get_prot_var(ENTRYFILE)] } {
      CopyFile $get_prot_var(ENTRYFILE) $entry_file -overwrite
    }
    if { [file exists $get_prot_var(CHANGES_FILE)] } {
      CopyFile $get_prot_var(CHANGES_FILE) $changes_file -overwrite
    }

    AppendTextWindow $array(TEXTFRAME_EDIT) "SEQUENCE SAVED"
}


proc get_prot_clear { arrayname } {
    upvar #0 $arrayname array
    $array(TEXTFRAME) configure -state normal
    $array(TEXTFRAME) delete 1.0 end
    $array(TEXTFRAME) configure -state disabled
}

proc get_prot_calculate_weight { arrayname } {
    upvar #0 $arrayname array
    global get_prot_var

    set query_sequence [$array(TEXTFRAME) get [expr $get_prot_var(RUN_COUNT)].0 $get_prot_var(RUN_COUNT).end]

    set protein_weight [get_prot_calculate_stats $arrayname $query_sequence]
    AppendTextWindow $array(TEXTFRAME_EDIT) "Molecular Weight $protein_weight Daltons"
    WriteFile $array(GET_PROT_LOGFILE) "Molecular Weight $protein_weight Daltons\n\n"
}


proc get_prot_calculate_stats { arrayname sequence } {
#Function to calculate the molecular weight of a protein ($sequence), in Daltons, and the percentage composition of the protein according to residues. Returns $final_weight which is the mass of the protein

    upvar #0 $arrayname array

    set amino_acid(A) 0
    set amino_acid(R) 0
    set amino_acid(N) 0
    set amino_acid(D) 0
    set amino_acid(C) 0
    set amino_acid(E) 0
    set amino_acid(Q) 0
    set amino_acid(G) 0
    set amino_acid(H) 0
    set amino_acid(I) 0
    set amino_acid(L) 0
    set amino_acid(K) 0
    set amino_acid(M) 0
    set amino_acid(F) 0
    set amino_acid(P) 0
    set amino_acid(S) 0
    set amino_acid(T) 0
    set amino_acid(W) 0
    set amino_acid(Y) 0
    set amino_acid(V) 0
    set amino_acid(B) 0
    set amino_acid(Z) 0
    set amino_acid(X) 0
#Array to count the number of occurences of each amino acid in '$sequence'

    set amino_acid_mass(A) 71.0788
    set amino_acid_mass(R) 156.1875
    set amino_acid_mass(N) 114.1038
    set amino_acid_mass(D) 115.0886
    set amino_acid_mass(C) 103.1388
    set amino_acid_mass(E) 129.1155
    set amino_acid_mass(Q) 128.1307
    set amino_acid_mass(G) 57.0519
    set amino_acid_mass(H) 137.1411
    set amino_acid_mass(I) 113.1594
    set amino_acid_mass(L) 113.1594
    set amino_acid_mass(K) 128.1741
    set amino_acid_mass(M) 131.1926
    set amino_acid_mass(F) 147.1766
    set amino_acid_mass(P) 97.1167
    set amino_acid_mass(S) 87.0782
    set amino_acid_mass(T) 101.1051
    set amino_acid_mass(W) 186.2132
    set amino_acid_mass(Y) 163.1760
    set amino_acid_mass(V) 99.1326
    set amino_acid_mass(B) 0.0000
    set amino_acid_mass(Z) 0.0000
    set amino_acid_mass(X) 0.0000

    set final_weight 18.0152
    #Array declaring the peptide mass of each amino acid residue in chain. The variable 'final_weight' is the total weight of the protein. It is initially set to 18.0152 to add HOH.
 
    set sequence [string toupper $sequence]
    set sequence [string trimright $sequence]

    set proteinLength [string length $sequence]
    for {set i 0} {$i < $proteinLength} {incr i} {
	incr amino_acid([string index $sequence $i])
    }

#    puts "\nStatistics:"
#    WriteFile $array(LOGFILE) "Statistics"
    set dirpath [GetDefaultDirPath [GetCurrentProject]]
    set array(GET_PROT_LOGFILE) [FileJoin $dirpath [DbGetJobFileRoot [DbGetJobData 0 NJOBS]].log]
    
    WriteFile $array(GET_PROT_LOGFILE) "Protein Length = $proteinLength residues"
    set proteinLength "$proteinLength.0"
    WriteFile $array(GET_PROT_LOGFILE) "Amino Acid Composition:"
    foreach Amino_Acid { A R N D C E Q G H I L K M F P S T W Y V B Z X } {
	set percent 0.000
	set percent [expr $amino_acid($Amino_Acid) / $proteinLength * 100]
	if {$percent > 0.0} {
	    WriteFile $array(GET_PROT_LOGFILE) "      ($Amino_Acid) = $percent %"
	}
	#only print to shell percentage of amino acids present. ie will not show amino acids with a composition of 0.0%
	set total_acid_weight [ expr $amino_acid($Amino_Acid) * $amino_acid_mass($Amino_Acid) ]
	set final_weight [ expr $total_acid_weight + $final_weight]
    }

    return $final_weight

}






