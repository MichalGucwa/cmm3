0 title =$TITLE
1 <?xml version="1.0" encoding="UTF-8"?>
1    <arp-warp>
1      <loop>

1 <SuppressCopyright> yes </SuppressCopyright>

# For the CConfig class:
1 <MessageFilename>  $MESSAGE_FILENAME </MessageFilename>
1 <XMLOutputFilename>  $XML_MESSAGE_FILENAME </XMLOutputFilename>
1 <AbortLevel>  $ABORT_LEVEL </AbortLevel>
1 <MessageLevel>  $MESSAGE_LEVEL </MessageLevel>
1 <ProgramName>  loopy </ProgramName>


# For CDictionary:
1 <DictionaryFilename> {[ file native "[GetEnvPath warpbin]/AAbis.XYZ" ]}  </DictionaryFilename>

# For CFitTarget :
1 <UniformAtomBFactor> $B_FACTOR </UniformAtomBFactor> 
1 <UniformAtomRadius> $ATOM_RADIUS </UniformAtomRadius> 
1 <AntiBumpFactor> $REMOVAL_FACTOR </AntiBumpFactor> 

# For CCrystalInfo:
1 <SymmetryFilename> {[ file native "[GetEnvPath warpbin]/syminfo.lib" ]} </SymmetryFilename> 

# PSP :
1 <SpaceGroup> $SPACEGROUP_NUMBER </SpaceGroup> 
1 <XtalCell>  $CELL_1 $CELL_2 $CELL_3 $CELL_4 $CELL_5 $CELL_6  </XtalCell> 

1 <KeepSideChain> 1 </KeepSideChain> 
1 <KeepFragmentLongerThan> 0 </KeepFragmentLongerThan> 
1 <UseCDummyResidue> 1 </UseCDummyResidue> 

#For CStructure
#Use a different lookup table for the angle-dihedral angle combination
1 <StructureFilenameToC> {[ file native $STRUCTURE_TO_C ]} </StructureFilenameToC> 
1 <StructureFilenameToN> {[ file native $STRUCTURE_TO_N ]} </StructureFilenameToN> 

#Alternative ramachandran plot for non-GLY and non-PRO
1 <GeneralRamaFile> {[file native "[GetEnvPath warpbin]/loopRamachandran.tab"]} </GeneralRamaFile>

# For CGrid
#Distance between 2 CAs
1 <CADistance> $CA_DISTANCE </CADistance> 
#Standard deviation in distance between 2 CAs.. for random grid only
$GRID_TYPE <CADistanceError> $CA_DISTANCE_ERROR </> 
#Use randomly generated positions in a sphere shell (1), or a regular grid on a sphere (0)
1 <RandomGrid> $GRID_TYPE </RandomGrid> 
#Thickness of generated random grid with uniform distribution
$GRID_TYPE <ShellThickness> $SHELL_THICKNESS </ShellThickness> 
#Number of points to be generated, for a regular grid the closest Fibonacci number is used
1 <GridNumber> $GRID_NUMBER </GridNumber> 
#Disregard generated points at negative electron density for computation
1 <DisregardNegativeDensity> 1 </DisregardNegativeDensity> 
#Keep CAs with negative density halfway between successive CAs
1 <KeepNegDensityHalfway> $KEEP_NEG_DENS_HALFWAY </KeepNegDensityHalfway> 

#Normalize density
1 <NormalizeDensity> 1 </NormalizeDensity> 

#B factor for side chain atoms
1 <BFactorForBuildSideChain> $B_FACTOR_SIDE_CHAIN </BFactorForBuildSideChain> 

1 <LikelihoodThreshold> $LIKELIHOOD_THRESHOLD </LikelihoodThreshold> 
#Weight for the log(density likelihood)
1 <WeightDensityLLH> $WEIGHT_DENSITY </WeightDensityLLH> 
#Weight for the log(distance likelihood)
1 <WeightDistanceLLH> $WEIGHT_DISTANCE </WeightDistanceLLH> 
#Weight for the log(structural likelihood)
1 <WeightStructuralLLH> $WEIGHT_STRUCTURE </WeightStructuralLLH> 

1 <CheckDistanceDuringBuild>yes</CheckDistanceDuringBuild>
1 <MaxDistanceBetweenAnchors> $MAX_DISTANCE_BETWEEN_ANCHORS </MaxDistanceBetweenAnchors>

1 <OldComputation> 0 </OldComputation> 
#Check whether first angle Ca-N/C-Ca is correct
1 <CheckFirstAngle> $CHECK_FIRST_ANGLE </CheckFirstAngle> 

#Using CFitTargetSE if OldComputation=0, NOTE: update UniformAtomRadius!!
1 <UseCubicFitTarget> $USE_CUBIC_FITTARGET </UseCubicFitTarget> 
1 <OverlapRejectionThreshold> $OVERLAP_REMOVAL_THRESHOLD </OverlapRejectionThreshold> 
1 <DummyRejectionThreshold> $DUMMY_REMOVAL_THRESHOLD </DummyRejectionThreshold> 

1 <LoopBuildAll> $MODE_LOOPY </LoopBuildAll> 
$MODE_LOOPY <ExtendGapSmallerThan> $EXTEND_GAP_SMALLER_THAN </ExtendGapSmallerThan> 
1 <LoopBothWays> $LOOP_BOTH_WAYS </LoopBothWays> 
1 <LoopToC> $LOOP_TO_C </LoopToC> 
$MODE_LOOPY <LoopLength> $MAX_LOOP_LENGTH </LoopLength> 
1 <LoopOverlap> 0 </LoopOverlap> 
1 <LoopDensityCutoffNo> $LOOP_DENSITY_CUTOFF_NO </LoopDensityCutoffNo> 


#Minimal distance between points found
1 <MinimalDistance> $MINIMAL_DISTANCE </MinimalDistance> 

$USER_SETTING_MAX_NO_CAS <MaxNoCAsKept> $MAX_NO_CAS_KEPT </MaxNoCAsKept> 
1 <ForceMinCAsKept> $FORCE_MIN_CAS_KEPT </ForceMinCAsKept> 
1 <LoopRMS> $LOOP_RMS </LoopRMS> 
1 <LoopStructureThreshold> $LOOP_STRUCTURE_THRESHOLD </LoopStructureThreshold> 
1 <LoopStructureCutoffNo> $LOOP_STRUCTURE_CUTOFF_NO </LoopStructureCutoffNo> 
1 <LoopStructureMinNo> $LOOP_STRUCTURE_MIN_NO </LoopStructureMinNo> 
1 <MaxLoopsAfterMCplane> $MAX_LOOPS_AFTER_MC_PLANE </MaxLoopsAfterMCplane>
1 <LoopMainChainDensNo> $LOOP_MAIN_CHAIN_DENS_NO </LoopMainChainDensNo> 

1 <LoopsToBuild> $LOOPS_TO_BUILD </LoopsToBuild> 

1 <InputPDB> $PDB_INPUT_FILENAME </InputPDB> 

IF { $USE_PIR_FILE }
	1 <UseLoopSequence> 0 </UseLoopSequence> 
	1 <NumberOfSequences> $NSEQFILES </NumberOfSequences>
	LOOP I 1 $NSEQFILES
	1 <SequenceFilename$I> $SEQIN($I) </SequenceFilename$I>
	1 <SequenceMultiplicty$I> $NMOL($I) </SequenceMultiplicty$I>
	1 <MethionineIsSeleno$I>$MET_IS_SEL($I)</MethionineIsSeleno$I>
	ENDLOOP
	1 <MinCScore>2</MinCScore>
ELSE
	1 <UseLoopSequence> 1 </UseLoopSequence> 
	1 <LoopSequence> $LOOP_SEQUENCE </LoopSequence> 
ENDIF
!$INCLUDE_ALL <IncludeChains>$INCLUDE_CHAINS</IncludeChains> 
{[StringSame $MAP_INPUT_MODE MAP ]} <InputMap> $MAP_FILENAME </InputMap> 
{[StringSame $MAP_INPUT_MODE MAP ]} <OutputExtendedMap> $EXT_MAP_FILENAME </OutputExtendedMap> 
{[StringSame $MAP_INPUT_MODE MTZ ]} <InputMTZ> $MTZ_FILENAME </InputMTZ> 
{[StringSame $MAP_INPUT_MODE MTZ ]} <OutputExtendedMap> $MAP_FROM_MTZ </OutputExtendedMap> 
{[StringSame $MAP_INPUT_MODE MTZ ]} <FWTLabel> $F1 </FWTLabel> 
{[StringSame $MAP_INPUT_MODE MTZ ]} <PHIWTLabel> $PHI </PHIWTLabel> 

1 <SaveResult> $MODE_LOOPY </SaveResult> 
IF { $MODE_LOOPY }
1 <SaveBestLoopSets> 0 </SaveBestLoopSets>
1 <PDBOutputFilename> $OUTPUT_PDB </PDBOutputFilename>
ELSE
1 <SaveBestLoopSets> 1 </SaveBestLoopSets> 
1 <SaveBestNumber> $SAVE_BEST_NUMBER </SaveBestNumber> 
1 <SaveLoopsDir> $SAVE_LOOP_DIR </SaveLoopsDir> 
1 <SaveLoopsBasename> $SAVE_LOOP_BASENAME </SaveLoopsBasename> 
1 <SaveProposedPDBDir> $SAVE_LOOP_PROP_DIR </SaveProposedPDBDir> 
1 <SaveProposedPDBBasename> $SAVE_LOOP_PROP_BASE </SaveProposedPDBBasename> 
ENDIF
1 <SaveUseLoopDef> 0 </SaveUseLoopDef> 

1 <WeightMainChain> 0.5 </WeightMainChain> 
1 <WeightSideChain> 0.5 </WeightSideChain> 

#newer variables
1 <SevenPointPlane> 1 </SevenPointPlane>
#default target
1 <CFitTarget>
1 <Type>linear</Type>
1 </CFitTarget>
#other targets
1 <BuildMainChainTarget>
1     <CFitTarget>
1       <Type>cubic</Type>
1     </CFitTarget>
1 </BuildMainChainTarget>
1 <FitSideChainTarget>
1	  <CFitTarget>
1	    <Type>accelerated</Type>
1         </CFitTarget>
1 </FitSideChainTarget>
1 <RefineSideChainTarget>
1	  <CFitTarget>
1	    <Type>accelerated</Type>
1         </CFitTarget>
1 </RefineSideChainTarget>
1 <ScoringTarget>
1	  <CFitTarget>
IF { $FITTARGET }
1	    <Type>correlation</Type>
1	    <MaskRadius>2.0</MaskRadius>
1	    <UseObservedDensityAroundAtoms></UseObservedDensityAroundAtoms>
ELSE
1	    <Type>accelerated</Type>
ENDIF
1         </CFitTarget>
1 </ScoringTarget>
1 <FancySideBuilding> 1 </FancySideBuilding>
IF { $REFINEMENT }
1	<Loopfit>
1		<UseDefaultLoopfit>false</UseDefaultLoopfit>
1		<ExtendRefinementRegion>$EXTEND_REFINEMENT</ExtendRefinementRegion>
1		<LoopfitExe>$LOOPFIT_EXE_FILENAME</LoopfitExe>
1		<LoopfitLog>$LOOPFIT_LOG_FILENAME</LoopfitLog>
1		<TmpOutputPDB>$PRELOOPFIT_PDB</TmpOutputPDB>
1	</Loopfit>
ENDIF
1        <IgnoreAllHeavies>true</IgnoreAllHeavies>
1       </loop>
1     </arp-warp>
