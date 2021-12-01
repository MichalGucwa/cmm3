# $Id: indexing.tcl,v 1.9 2012/03/26 16:36:39 ccb Exp $
package provide indexing 2.0

# Setup spacegroup and lattice global arrays

set ::spacegroup(aP) [list P1]
set ::spacegroup(mP) [list P2 P21]
set ::spacegroup(mC) [list C2]
set ::spacegroup(mI) [list I2]
set ::spacegroup(oP) [list P222 P2221 P2122 P2212 P21212 P22121 P21221 \
                           P212121 ]
set ::spacegroup(oC) [list C222 C2221]
set ::spacegroup(oF) [list F222]
set ::spacegroup(oI) [list I222 I212121]
set ::spacegroup(tP) [list P4 P41 P42 P43 P422 P4212 \
			  P4122 P41212 P4222 P42212 \
			  P4322 P43212]
set ::spacegroup(tI) [list I4 I41 I422 I4122]
set ::spacegroup(hP) [list P3 P31 P32 P312 P321 P3112 P3121 \
			  P3212 P3221 P6 P61 P65 P62 P64 \
			  P63 P622 P6122 P6522 P6222 P6422 \
			  P6322]
set ::spacegroup(hR) [list h3 h32]
set ::spacegroup(cP) [list P23 P213 P432 P4232 P4332 P4132]
set ::spacegroup(cF) [list F23 F432 F4132]
set ::spacegroup(cI) [list I23 I213 I432 I4132]

set ::spacegroups {}
foreach i_lattice [array names ::spacegroup] {
    eval lappend ::spacegroups $::spacegroup($i_lattice)
}
set ::spacegroups [lsort -unique $::spacegroups]

set ::lattice(aP) "Primitive triclinic"
set ::lattice(mP) "Primitive monoclinic"
set ::lattice(mC) "C-centred monoclinic"
set ::lattice(mI) "Body-centred monoclinic"
set ::lattice(oP) "Primitve orthorhombic"
set ::lattice(oC) "C-centred orthorhombic"
set ::lattice(oF) "Face-centred orthorhombic"
set ::lattice(oI) "Body-centred orthorhombic"
set ::lattice(tP) "Primitive tetragonal"
set ::lattice(tI) "Body-centred tetragonal"
set ::lattice(hP) "Primitve hexagonal"
set ::lattice(hR) "Rhombohedral"
set ::lattice(cP) "Primitive cubic"
set ::lattice(cF) "Face-centred cubic"
set ::lattice(cI) "Body-centred cubic"



class Solution {
    protected variable number ""
    protected variable type ""
    protected variable penalty ""
    protected variable lattice ""
    protected variable cell ""
    protected variable matrix ""
    protected variable spacegroup ""
    
    protected variable image_files {}

    public method getNumber
    public method getType
    public method getLattice
    public method getSpacegroup
    public method getPenalty
    public method getCell
    public method getMatrix
    
    public method getImageFiles
    public method getImages
    
    public method copyFrom
    protected method parseSolution

    public method serialize
    protected method unserialize

    constructor { a_method args } { }

}

body Solution::constructor { a_method args } {
    set cell [namespace current]::[Cell \#auto "cell" "blank"]
    set matrix [namespace current]::[Matrix \#auto "blank" "Unnamed"]
    if {$a_method == "xml"} {
	unserialize $args
    } elseif {$a_method == "build"} {
	set type [lindex $args 0]
	foreach i_image [lindex $args 1] {
	    lappend image_files [$i_image getFullPathName]
	}
	# Derive matrix name from image file
	$matrix setName [file tail [file rootname [lindex $image_files 0]]]
	eval parseSolution [lindex $args 2]
    } elseif {$a_method == "copy"} {
	copyFrom $args
    } elseif {$a_method == "parent_class"} {
	# Do nothing
    } else {
	error "Unknown Solution construction method $a_method"
    }
}

body Solution::getNumber { } {
    return $number
}

body Solution::getType { } {
    return $type
}

body Solution::getPenalty { } {
    return $penalty
}

body Solution::getLattice { } {
    return $lattice
}

body Solution::getSpacegroup { } {
    return $spacegroup
}

body Solution::getCell { } {
    return $cell
}

body Solution::getMatrix { } {
    return $matrix
}

body Solution::getImageFiles { } {
    return $image_files
}

body Solution::getImages { } {
    set l_images {}
    foreach i_image_file $image_files {
	lappend l_images [Image::getImageByPath $i_image_file]
    }
    return $l_images
}

body Solution::copyFrom { a_solution } {
    $cell copyFrom [$a_solution getCell]
    $matrix copyFrom [$a_solution getMatrix]
    set number [$a_solution getNumber]
    set type [$a_solution getType]
    set penalty [$a_solution getPenalty]
    set lattice [$a_solution getLattice]
    set spacegroup [$a_solution getSpacegroup]
    set image_files [$a_solution getImageFiles]
}

body Solution::parseSolution { a_node } {
    set number [$a_node selectNodes {normalize-space(number)}]
    set penalty [$a_node selectNodes {normalize-space(penalty)}]
    set lattice [$a_node selectNodes {normalize-space(lattice)}]
    set spacegroup [lindex $::spacegroup($lattice) 0]

    if {$type == "raw"} {
	set a [$a_node selectNodes {normalize-space(cell/a)}]
	set b [$a_node selectNodes {normalize-space(cell/b)}]
	set c [$a_node selectNodes {normalize-space(cell/c)}]
	set alpha [$a_node selectNodes {normalize-space(cell/alpha)}]
	set beta [$a_node selectNodes {normalize-space(cell/beta)}]
	set gamma [$a_node selectNodes {normalize-space(cell/gamma)}]
    } elseif {$type == "reg"} {
	set a [$a_node selectNodes {normalize-space(regularised_cell/reg_a)}]
	set b [$a_node selectNodes {normalize-space(regularised_cell/reg_b)}]
	set c [$a_node selectNodes {normalize-space(regularised_cell/reg_c)}]
	set alpha [$a_node selectNodes {normalize-space(regularised_cell/reg_alpha)}]
	set beta [$a_node selectNodes {normalize-space(regularised_cell/reg_beta)}]
	set gamma [$a_node selectNodes {normalize-space(regularised_cell/reg_gamma)}]
    } else {
	error "Unknown solution type"
    }
    $cell setCell $a $b $c $alpha $beta $gamma

    set a11 [$a_node selectNodes {normalize-space(a_matrix/a11)}]
    set a12 [$a_node selectNodes {normalize-space(a_matrix/a12)}]
    set a13 [$a_node selectNodes {normalize-space(a_matrix/a13)}]
    set a21 [$a_node selectNodes {normalize-space(a_matrix/a21)}]
    set a22 [$a_node selectNodes {normalize-space(a_matrix/a22)}]
    set a23 [$a_node selectNodes {normalize-space(a_matrix/a23)}]
    set a31 [$a_node selectNodes {normalize-space(a_matrix/a31)}]
    set a32 [$a_node selectNodes {normalize-space(a_matrix/a32)}]
    set a33 [$a_node selectNodes {normalize-space(a_matrix/a33)}]
    $matrix setMatrix $a11 $a12 $a13 $a21 $a22 $a23 $a31 $a32 $a33 
}

body Solution::serialize { } {
    return "<solution type=\"$type\" number=\"$number\" penalty=\"$penalty\" lattice=\"$lattice\" spacegroup=\"$spacegroup\" image_files=\"$image_files\">[$cell serialize][$matrix serialize]</solution>"
}

body Solution::unserialize { a_node } {
    set type [$a_node getAttribute type]
    set number [$a_node getAttribute number]
    set penalty [$a_node getAttribute penalty]
    set lattice [$a_node getAttribute lattice]
    set spacegroup [$a_node getAttribute spacegroup]
    set image_files [split [$a_node getAttribute image_files]]
    $cell parseDom [$a_node selectNodes {cell}]
    $matrix parseDom [$a_node selectNodes {matrix}]
}

# ####################################################

class RefinedSolution {
    inherit Solution

    private variable spot_deviation_pos ""
    private variable spot_deviation_phi ""
    private variable beam_x ""
    private variable beam_y ""
    private variable beam_shift_abs ""
    private variable beam_shift_rel ""
    private variable reflections_used ""

    public method getBeam
    public method getSpotDevPos
    public method getSpotDevPhi
    public method getBeamShiftAbs
    public method getBeamShiftRel
    public method getReflectionsUsed

    public method copyFrom
    private method parseRefinement

    public method serialize
    private method unserialize

    constructor { a_method args } {
	Solution::constructor "parent_class"
    } {
	set type "ref"
	if {$a_method == "xml"} {
	    unserialize $args
	} elseif {$a_method == "build"} {
	    set l_solution [lindex $args 0]
	    Solution::copyFrom $l_solution
	    parseRefinement [lindex $args 1]
	} elseif { $a_method == "copy" } {
	    copyFrom $args
	} else {
	    error "Unknown method for building a RefinedSolution"
	}
    }

}

body RefinedSolution::getSpotDevPos { } {
    return $spot_deviation_pos
}

body RefinedSolution::getSpotDevPhi { } {
    return $spot_deviation_phi
}

body RefinedSolution::getBeamShiftAbs { } {
    return $beam_shift_abs
}

body RefinedSolution::getBeamShiftRel { } {
    return $beam_shift_rel
}

body RefinedSolution::getReflectionsUsed { } {
    return $reflections_used
}

body RefinedSolution::getBeam { { a_formatted 0 } } {
    if {$a_formatted == "1"} {
	set l_beam "[format %.2f $beam_x], [format %.2f $beam_y]"
    } else {
	set l_beam [list $beam_x $beam_y]
    }
    return $l_beam
}

body RefinedSolution::copyFrom { a_refined_solution } {
    Solution::copyFrom $a_refined_solution
    set spot_deviation_pos [$a_refined_solution getSpotDevPos] 
    set spot_deviation_phi  [$a_refined_solution getSpotDevPhi] 
    foreach { beam_x beam_y } [$a_refined_solution getBeam] break  
    set beam_shift_abs  [$a_refined_solution getBeamShiftAbs] 
    set beam_shift_rel  [$a_refined_solution getBeamShiftRel] 
    set reflections_used  [$a_refined_solution getReflectionsUsed] 
}

body RefinedSolution::parseRefinement { a_dom } {
    set spot_deviation_pos [$a_dom selectNodes normalize-space(//spot_deviation_pos)]
    set spot_deviation_phi [$a_dom selectNodes normalize-space(//spot_deviation_phi)]
    set beam_x [$a_dom selectNodes normalize-space(//beam_x)]
    set beam_y [$a_dom selectNodes normalize-space(//beam_y)]
    set beam_shift_abs [$a_dom selectNodes normalize-space(//beam_shift_abs)]
    set beam_shift_rel [$a_dom selectNodes normalize-space(//beam_shift_rel)]
    set reflections_used [$a_dom selectNodes normalize-space(//reflections_used)]

    set a [$a_dom selectNodes {normalize-space(//a)}]
    set b [$a_dom selectNodes {normalize-space(//b)}]
    set c [$a_dom selectNodes {normalize-space(//c)}]
    set alpha [$a_dom selectNodes {normalize-space(//alpha)}]
    set beta [$a_dom selectNodes {normalize-space(//beta)}]
    set gamma [$a_dom selectNodes {normalize-space(//gamma)}]
    $cell setCell $a $b $c $alpha $beta $gamma

    set a11 [$a_dom selectNodes normalize-space(//a11)]
    set a12 [$a_dom selectNodes normalize-space(//a12)]
    set a13 [$a_dom selectNodes normalize-space(//a13)]
    set a21 [$a_dom selectNodes normalize-space(//a21)]
    set a22 [$a_dom selectNodes normalize-space(//a22)]
    set a23 [$a_dom selectNodes normalize-space(//a23)]
    set a31 [$a_dom selectNodes normalize-space(//a31)]
    set a32 [$a_dom selectNodes normalize-space(//a32)]
    set a33 [$a_dom selectNodes normalize-space(//a33)]
    $matrix setMatrix $a11 $a12 $a13 $a21 $a22 $a23 $a31 $a32 $a33 
}

body RefinedSolution::serialize { } {
    return "<refined_solution type=\"$type\" number=\"$number\" penalty=\"$penalty\" lattice=\"$lattice\" spacegroup=\"$spacegroup\" spot_deviation_pos=\"$spot_deviation_pos\" spot_deviation_phi=\"$spot_deviation_phi\" beam_x=\"$beam_x\" beam_y=\"$beam_y\" beam_shift_abs=\"$beam_shift_abs\" beam_shift_rel=\"$beam_shift_rel\" reflections_used=\"$reflections_used\" image_files=\"$image_files\">[$cell serialize][$matrix serialize]</refined_solution>"
}

body RefinedSolution::unserialize { a_node } {
    set spot_deviation_pos [$a_node getAttribute spot_deviation_pos]
    set spot_deviation_phi [$a_node getAttribute spot_deviation_phi]
    set beam_x [$a_node getAttribute beam_x]
    set beam_y [$a_node getAttribute beam_y]
    set beam_shift_abs [$a_node getAttribute beam_shift_abs]
    set beam_shift_rel [$a_node getAttribute beam_shift_rel]
    set reflections_used [$a_node getAttribute reflections_used]
    Solution::unserialize $a_node
}

