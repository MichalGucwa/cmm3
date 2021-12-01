
#----------------------------------------------------------------------
proc arpnavigator_prereq {} {
#----------------------------------------------------------------------
    if { [GetEnvPath warpbin 0] == "" } {
        return 0
    } else {
        return 1
    }
}

#--------------------------------------------------------------------
proc arpnavigator_run { arrayname } {
#--------------------------------------------------------------------

    upvar #0 $arrayname array

# First check if version 7 is installed
#
    set arpkey "0"
#
    set out_file [GetTmpFileName ]
    catch { exec [FileJoin [GetEnvPath warpbin] arp_warp ] -v ] > $out_file}
    #
    if { [ReadFile $out_file out_text] && \
            [ExtractTextLine $out_text  "73010312" 0 all line1 ] } {
        set arpkey [expr [lindex $line1 0] ]
    }

if { $arpkey != "73010312" } {
    WarningMessage "The version of ARP/wARP you have installed is not 7.3.0 or ARP/wARP could not be found at all. Make sure you have modified your .cshrc so as it contain the definition for warpbin and has the right path, or please get and install version 7.3.0 from http://www.arp-warp.org/"
    return 0
}
#

    return 0

}
#--------------------------------------------------------------------
proc arpnavigator_setup { typedefVar arrayname } {
#--------------------------------------------------------------------

    upvar #0 $arrayname array
    global env

    # Confirm that the user has sourced the arpwarp setup script
    if { [info exists env(warpbin)] == 0 } {
        WarningMessage "Please check your shell startup file does source ARP/wARP 7.3. Then open another terminal window and re-launch CCP4i."
        return 0
    }

    PleaseWait

    set workdir [GetDefaultDirPath]
    exec [FileJoin [GetEnvPath warpbin] arpnavigator] -use-project-path $workdir > /dev/null 2> /dev/null &
    return 0
}

#--------------------------------------------------------------------
proc arpnavigator_task_window { arrayname } {
#--------------------------------------------------------------------
# Dummy procedure required for startup only.
}
