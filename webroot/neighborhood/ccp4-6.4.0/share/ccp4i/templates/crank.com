#CCP4I SCRIPT TEMPLATE crank

#
# crank.com
#

1 <?xml version="1.0" standalone="yes"?>
1 <crank>
#
#
1 <parameters>
1    <description>$TITLE</description>
1    <version>$VERSION</version>
1    <code>crank</code>
1    <solvent_content>$SOLVENT_CONTENT</solvent_content>
1    <residues>$NRESIDUES</residues>
IF { $NUCLEOTIDES_PRESENT }
1    <nucleotides>$NNUCLEOTIDES</nucleotides>
ELSE
1    <nucleotides>0</nucleotides>
ENDIF
1    <nmonomers>$NMONOMERS</nmonomers>
1    <bfactor>$BFACTOR</bfactor>
1    <ref_crystal>$REF_CRYSTAL</ref_crystal>
1    <ref_dataset>$REF_DATASET</ref_dataset>
1    <input_spacegroup>
1       <name>$SPACE_GROUP_NAME</name>
1       <number>$SPACE_GROUP_NUMBER</number>
1    </input_spacegroup>
IF { $DOCK_SEQUENCE }
1    <sequence>
1    $SEQUENCE
1    </sequence>
ENDIF
1    <input_intensity>$INPUT_INTENSITY</input_intensity>
LOOP K 1 $N_CRYSTALS
1    <crystal id="$K">
1       <cell>
1          <cell_a>$CELL_A($K)</cell_a>
1          <cell_b>$CELL_B($K)</cell_b>
1          <cell_c>$CELL_C($K)</cell_c>
1          <cell_alpha>$CELL_ALPHA($K)</cell_alpha>
1          <cell_beta>$CELL_BETA($K)</cell_beta>
1          <cell_gamma>$CELL_GAMMA($K)</cell_gamma>
1       </cell>
IF { $CRYSTAL_NATIVE($K) } 
1       <native>1</native>
1       <data id="1">
1          <type>NATIVE</type>
1          <anomalous>0</anomalous>
1          <bfactor>$BFACTOR</bfactor>
1       </data>
ELSE
1       <native>0</native>
1       <substructure>
1          <atom_name>$CRYSTAL_ATOM_NAME($K)</atom_name>
1          {<natoms>[ expr $CRYSTAL_N_ATOMS($K)*$NMONOMERS ]</natoms>}
1          <input>$CRYSTAL_INPUT_SUBSTRUCTURE($K)</input>
IF { $CRYSTAL_INPUT_SUBSTRUCTURE($K) && [StringSame $CRYSTAL_INPUT_SUBSTRUCTURE_TYPE($K) Manual ]  }
1          <coordinate_format>$COORDINATE_FORMAT($K)</coordinate_format>
LOOP M 1 $N_ATOMS($K)
1          <atom id="$M">
1             <name>$ATOM_ID($K,$M)</name>
1             <x>$ATOM_X($K,$M)</x>
1             <y>$ATOM_Y($K,$M)</y>
1             <z>$ATOM_Z($K,$M)</z>
1             <noref_x>$ATOM_X_NOREF($K,$M)</noref_x>
1             <noref_y>$ATOM_Y_NOREF($K,$M)</noref_y>
1             <noref_z>$ATOM_Z_NOREF($K,$M)</noref_z>
1             <occ>$ATOM_OCCU($K,$M)</occ>
1             <bfac>$ATOM_BISO($K,$M)</bfac>
1             <noref_occ>$ATOM_OCCU_NOREF($K,$M)</noref_occ>
1             <noref_bfac>$ATOM_BISO_NOREF($K,$M)</noref_bfac>
1          </atom>
ENDLOOP
ENDIF
1       </substructure>
LOOP M 1 $N_DATA($K)
1       <data id="$M">
1          <type>$DATA_TYPE($K,$M)</type>
1          <anomalous>$DATA_ANOMALOUS($K,$M)</anomalous>
1          <wavelength>$DATA_WAVELENGTH($K,$M)</wavelength>
1          <bfactor>$BFACTOR</bfactor>
IF { $N_WATOMS($K) > 0 } 
1          <atom id="1">
1             <name>$ATOM_WAVE_ID1($K,$M)</name>
1             <fprime>$DATA_FPRIME1($K,$M)</fprime>
1             <fprimeprime>$DATA_FPRIMEPRIME1($K,$M)</fprimeprime>
1          </atom>
IF { $N_WATOMS($K) > 1 } 
1          <atom id="2">
1             <name>$ATOM_WAVE_ID2($K,$M)</name>
1             <fprime>$DATA_FPRIME2($K,$M)</fprime>
1             <fprimeprime>$DATA_FPRIMEPRIME2($K,$M)</fprimeprime>
1          </atom>
IF { $N_WATOMS($K) > 2 } 
1          <atom id="3">
1             <name>$ATOM_WAVE_ID3($K,$M)</name>
1             <fprime>$DATA_FPRIME3($K,$M)</fprime>
1             <fprimeprime>$DATA_FPRIMEPRIME3($K,$M)</fprimeprime>
1          </atom>
IF { $N_WATOMS($K) > 3 } 
1          <atom id="4">
1             <name>$ATOM_WAVE_ID4($K,$M)</name>
1             <fprime>$DATA_FPRIME4($K,$M)</fprime>
1             <fprimeprime>$DATA_FPRIMEPRIME4($K,$M)</fprimeprime>
1          </atom>
IF { $N_WATOMS($K) > 4 } 
1          <atom id="5">
1             <name>$ATOM_WAVE_ID5($K,$M)</name>
1             <fprime>$DATA_FPRIME5($K,$M)</fprime>
1             <fprimeprime>$DATA_FPRIMEPRIME5($K,$M)</fprimeprime>
1          </atom>
IF { $N_WATOMS($K) > 5 } 
1          <atom id="6">
1             <name>$ATOM_WAVE_ID6($K,$M)</name>
1             <fprime>$DATA_FPRIME6($K,$M)</fprime>
1             <fprimeprime>$DATA_FPRIMEPRIME6($K,$M)</fprimeprime>
1          </atom>
ENDIF
ENDIF
ENDIF
ENDIF
ENDIF
ENDIF
1       </data>
ENDLOOP
ENDIF
1    </crystal>
ENDLOOP
1 </parameters>
1
#
#
1 <input_files>
1    <file id="1">
1       <type>$REFL_TYPE</type>
1       <label>IN</label>
IF { $ONE_MTZ } 
1 	<name>$HKLIN</name>
ENDIF
LOOP K 1 $N_CRYSTALS
1         <crystal id="$K">
IF $CRYSTAL_NATIVE($K)
1            <data id="1">
IF { ! $ONE_MTZ && [StringSame $REFL_TYPE MTZ ] } 
1 	        <name>$MTZIN($K,1)</name>
ELSE IF { [StringSame $REFL_TYPE SCA ] }
1 	        <name>$SCAIN($K,1)</name>
ENDIF
IF $INPUT_INTENSITY
1               <i>$DATA_I($K)</i>
1               <sigi>$DATA_SIGI($K)</sigi>
ELSE
1               <f>$DATA_F($K)</f>
1               <sigf>$DATA_SIGF($K)</sigf>
ENDIF
1            </data>
ELSE
LOOP M 1 $N_DATA($K)
1            <data id="$M">
IF { ! $ONE_MTZ && [StringSame $REFL_TYPE MTZ ] } 
1 	        <name>$MTZIN($K,$M)</name>
ELSE IF { [StringSame $REFL_TYPE SCA ] }
1 	        <name>$SCAIN($K,$M)</name>
ENDIF
IF $INPUT_INTENSITY
1               <i_plus>$DATA_I_PLUS($K,$M)</i_plus>
1               <sigi_plus>$DATA_SIGI_PLUS($K,$M)</sigi_plus>
1               <i_minus>$DATA_I_MINUS($K,$M)</i_minus>
1               <sigi_minus>$DATA_SIGI_MINUS($K,$M)</sigi_minus>
ELSE
1               <f_plus>$DATA_F_PLUS($K,$M)</f_plus>
1               <sigf_plus>$DATA_SIGF_PLUS($K,$M)</sigf_plus>
1               <f_minus>$DATA_F_MINUS($K,$M)</f_minus>
1               <sigf_minus>$DATA_SIGF_MINUS($K,$M)</sigf_minus>
ENDIF
IF { [StringSame $M 1] && [StringSame $K 1] && [IFSet HLA]   }
1               <hl_columns>
1               <hla>$HLA</hla>
1               <hlb>$HLB</hlb>
1               <hlc>$HLC</hlc>
1               <hld>$HLD</hld>
1               </hl_columns>
ENDIF
1            </data>
ENDLOOP
ENDIF
1         </crystal>
ENDLOOP
1    </file>
IF { $CRYSTAL_INPUT_SUBSTRUCTURE($K) && [StringSame $CRYSTAL_INPUT_SUBSTRUCTURE_TYPE($K) Pdb ] }
1    <file id="2">
1       <type>SUBSTRUCTURE</type>
1       <xtal>$K</xtal>
1       <label>IN</label>
1 	<name>$SUBSTRUCTURE_INPUT_COORDSIN($K)</name>
1    </file>
ENDIF
1 </input_files>
#
1 <output_files>
1    <mtz_out>
1       <name>$HKLOUT</name>
1    </mtz_out>
1    <pdb_out>
1       <name>$XYZOUT</name>
1    </pdb_out>
1 </output_files>
1
#
1 <soap>
1    <run>
1       <directory>$rundir</directory>
#
LOOP I 1 $N_PROGRAMS
1
1	<step id="$I">$PROGRAM_NAME($I)
1   	<name>$PROGRAM_NAME($I)</name>
1	<tag>$PROGRAM_TAG($I)</tag>
1       <step>$PROGRAM_STEP($I)</step>
AT { [FileJoin [GetEnvPath CRANK] plugins $PROGRAM_COM($I) ] }
1       </step>
1
ENDLOOP

1    </run>
1 </soap>
1 </crank>
1
