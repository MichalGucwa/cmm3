#ifndef _H_MAIN
#define _H_MAIN

#include "util.h"
#include "csymlib.h"

/* EntityWide fields */
#define EntityFileNameLen       255
#define EntityPDBIDLen          4
#define EntityDateLen           10
#define EntityHeaderLen         40
#define EntityTitleLen          255
typedef char EntityFileName[EntityFileNameLen+1];
typedef char EntityPDBID[EntityPDBIDLen+1];
typedef char EntityDate[EntityDateLen+1];
typedef char EntityHeader[EntityHeaderLen+1];
typedef char EntityTitle[EntityTitleLen+1];
/* ComponentWide fields */
#define GeneOntologyEvidenceLen 3
#define GeneOntologyLongNameLen 18
#define ComponentNameLen        255
#define OrganismNameLen         255
#define TemporaryFieldLen       99999   // a very long field for buffering the reading of header
typedef char GeneOntologyEvidence[GeneOntologyEvidenceLen+1];
typedef char GeneOntologyLongName[GeneOntologyLongNameLen+1];
typedef char ComponentName[ComponentNameLen+1];
typedef char OrganismName[OrganismNameLen+1];
typedef char TemporaryField[TemporaryFieldLen+1];
/* ResidueWide fields */
#define SegmentIdLen            4
#define ResidueNameLen          3
#define ResidueIdLen            4
typedef char SegmentId[SegmentIdLen+1];
typedef char ResidueName[ResidueNameLen+1];
typedef char ResidueId[ResidueIdLen+1];
/* AtomWide fields */
#define AtomNameLen             4
#define AtomElemLen             4
#define ElemNameLen             13
typedef char AtomName[AtomNameLen+1];
typedef char AtomElem[AtomElemLen+1];
typedef char ElemName[ElemNameLen+1];
/* InteractionWide fields */
#define MolprobityIndexLen      35      // 16 chars each atom, with 3 extra delimiters in the format of ([1],[2])
typedef char MolprobityIndex[MolprobityIndexLen+1];


/* The following macros are processed as integers, but will be output as binary string */
/* When it will get import into neighborhood database, it will be stored as bit-string */

#define ASSEMBLY_UNDEF          0
#define ASSEMBLY_SMALLER        1
#define ASSEMBLY_EQUAL          10
#define ASSEMBLY_OVERLAP        11
#define ASSEMBLY_BIGGER         100

#define CHAIN_TYPE2_UNDEF       0
#define CHAIN_TYPE2_WATER       1
#define CHAIN_TYPE2_LIGAND      10
#define CHAIN_TYPE2_DNARNA      100
#define CHAIN_TYPE2_PROTEIN     1000

#define CHAIN_CLUSTER_UNDEF     0
#define CHAIN_CLUSTER_SHORT     1
#define CHAIN_CLUSTER_CLUSTERED 10
#define CHAIN_CLUST90_REPRESENT 11
#define CHAIN_CLUST50_REPRESENT 100

#define RESIDUE_LOCATE_UNDEF    0
#define RESIDUE_LOCATE_BURIED   1
#define RESIDUE_LOCATE_SURFACE  10
#define RESIDUE_LOCATE_CAVITY   11
#define RESIDUE_LOCATE_SDCAVITY 100

#define ATOM_LOCATE_UNDEF       0
#define ATOM_LOCATE_BURIED      1
#define ATOM_LOCATE_SURFACE     10
#define ATOM_LOCATE_CAVITY      11
#define ATOM_LOCATE_SDCAVITY    100

#define COMPONENT_AMINOACID     0
#define COMPONENT_NUCLEOTIDE    1
#define COMPONENT_WATER         10
#define COMPONENT_OTHER         11

#define CONTACT_INTRA_RESIDUE   0
#define CONTACT_INTER_RESIDUE   1
#define CONTACT_INTER_MOLEC     10
#define CONTACT_INTER_BU        100
#define CONTACT_INTER_AU        1000
#define CONTACT_CUTOFF_6A       10000

#define GEOM_FREE                 0
#define GEOM_LINEAR               1     // full weight 120, Class II popularity,  CN=2
#define GEOM_TRIANGLE             2     // full weight 120, Class II popularity,  CN=3
#define GEOM_SQUARE_PLANAR        3     // full weight 150, Class II-III popularity, CN=4
#define GEOM_TETRAHEDRAL          4     // full weight 180, Class III popularity, CN=4
#define GEOM_TRIGONAL_BIPYRAMID   5     // full weight 120, Class II popularity,  CN=5
#define GEOM_OCTAHEDRAL           6     // full weight 180, Class III popularity, CN=6
#define GEOM_TRIGONAL_BIPRISM     7     // full weight  60, Class I popularity
#define GEOM_TRIGONAL_ANTIPRISM   8     // full weight  60, Class I popularity
#define GEOM_CAP_TRIGONAL_BIPRISM 9     // full weight  60, Class I popularity
#define GEOM_PENTAGONAL_BIPYRAMID 10    // full weight  60, Class I popularity
#define GEOM_CUBIC                11    // full weight  60, Class I popularity
#define GEOM_SQUARE_ANTIPRISM     12    // full weight  60, Class I popularity
#define GEOM_DODECAHEDRAL         13    // full weight  60, Class I popularity
#define GEOM_IRREGULAR            14    // not used
#define GEOM_UNDERFLOW            15
#define GEOM_OVERFLOW             16
#define GEOM_MAX                  17

#define ILR_INNERSPHERE           1
#define ILR_DIRECT_OUTERSPHERE    2
#define ILR_HYBRID_INNER_OUTER    3
#define ILR_INDIRECT_OUTERSPHERE  4

#define ISOFORM_UNDEF            -1
#define ISOFORM_DR_OP_TERMINAL    0
#define ISOFORM_SC_O_CARBOXYL     1
#define ISOFORM_SC_N_HIS          2
#define ISOFORM_SC_S_CYS          3
#define ISOFORM_SC_O_AMIDE        4
#define ISOFORM_SC_O_HYDROXYL     5
#define ISOFORM_MC_O              6
#define ISOFORM_DR_N_BASE         7
#define ISOFORM_DR_O_BASE         8
#define ISOFORM_DR_O_RIBOSE       9
#define ISOFORM_LIGAND_O          10
#define ISOFORM_LIGAND_N          11
#define ISOFORM_LIGAND_X          12
#define ISOFORM_DEFAULT_O         13
#define ISOFORM_DEFAULT_N         14
#define ISOFORM_DEFAULT_X         15
#define ISOFORM_WATER_OP          16
#define ISOFORM_WATER_CARBOXYL    17
#define ISOFORM_MOBILE            18
#define ISOFORM_MAX               19


/********* DEFINITION OF DIRECTION FOR NEIGHBOR PAIR *********
 * Between categories, direction from low -> high numerically
 *      according to type #define number
 * Within categories, direction from low -> high alphabetically
 *      according to residue->resn in case of residue,
 *      or according to atom->name in case of atom
 * For TABLE neighbors, only residue order is guaranteed,
 *      order by neighbortype, atomneighbortype random
 * For TABLE atomneighbors, only atom order is guaranteed,
 *      order by atomneighbortype, neighbortype random */
#define RESIDUE_UNDEF           0
#define RESIDUE_GLY             1
#define RESIDUE_ALA             3
#define RESIDUE_VAL             5
#define RESIDUE_LEU             7
#define RESIDUE_ILE             9

#define RESIDUE_SER             11
#define RESIDUE_THR             13
#define RESIDUE_CYS             15
#define RESIDUE_MET             17
#define RESIDUE_PRO             19

#define RESIDUE_ASP             21
#define RESIDUE_ASN             23
#define RESIDUE_GLU             25
#define RESIDUE_GLN             27
#define RESIDUE_LYS             29
#define RESIDUE_ARG             31
#define RESIDUE_HIS             33

#define RESIDUE_PHE             35
#define RESIDUE_TYR             37
#define RESIDUE_TRP             39
#define RESIDUE_NSAA_BASE       1
/* even numbers -- Non-standard amino acid residues */

#define RESIDUE_AMINOACID       41
#define RESIDUE_DNA_PURINE      42
#define RESIDUE_DNA_PYRIMIDINE  43
#define RESIDUE_RNA_PURINE      44
#define RESIDUE_RNA_PYRIMIDINE  45
#define RESIDUE_PNA_PURINE      46 // Peptide nucleic acid
#define RESIDUE_PNA_PYRIMIDINE  47 // Peptide nucleic acid
#define RESIDUE_ANA_PURINE      48 // Arabinose nucleic acid
#define RESIDUE_ANA_PYRIMIDINE  49 // Arabinose nucleic acid
#define RESIDUE_DNARNA          50
#define RESIDUE_SUGAR           51

#define RESIDUE_WATER           52
#define RESIDUE_ALKALI          53
#define RESIDUE_ALKALINE        54
#define RESIDUE_CATION          55
#define RESIDUE_ANION           56
#define RESIDUE_SOLVENT         57
#define RESIDUE_PORPHYRIN       58
#define RESIDUE_COFACTOR        59
#define RESIDUE_HEAVY           60
#define RESIDUE_LIGAND          61
#define RESIDUE_MAX             62

/* Moiety type */
#define MOIETY_UNDEF            0
#define MOIETY_MC               1
#define MOIETY_SC_HYDROPHOBIC   2
#define MOIETY_SC_HYDROPHILIC   3
#define MOIETY_SC_ACIDIC        4
#define MOIETY_SC_BASIC         5
#define MOIETY_PHOSPHATE        6
#define MOIETY_RIBOSE           7
#define MOIETY_BASE             8
#define MOIETY_CARBOHYDRATE     9
#define MOIETY_WATER            10
#define MOIETY_CATION           11
#define MOIETY_ANION            12
#define MOIETY_LIGAND           13
#define MOIETY_MAX              14

/* Atom type description in detail, description given by maks
1  - main chain N
2  - main chain CA
3  - main chain C
4  - main chain O
5  - side chain, carbon atom
6  - side chain of ARG, nitrogen atom from guanidine group
7  - side chain, oxygen atom from amide group, present in ASN & GLN
8  - side chain, nitrogen atom from amide group, present in ASN & GLN
9  - side chain, oxygen atom from carboxylic groups of ASP & GLU
10 - side chain, sulphur atom from CYS
11 - side chain, carbon atom from aromatic ring (HIS, PHE, TYR, TRP)
12 - side chain, nitrogen atom from aromatic ring (HIS & TRP)
13 - side chain, nitrogen atom from LYS
14 - side chain, sulphur or selenium atom from MET or MSE
15 - side chain, oxygen atom from hydroxyl group (SER, THR)
16 - side chain, oxygen atom from phenol group (TYR)  */
#define ATOM_UNDEF              0       // amino acids
#define ATOM_MC_N               1
#define ATOM_MC_CA              2
#define ATOM_MC_C               3
#define ATOM_MC_O               4
#define ATOM_SC_CB              5
#define ATOM_SC_C               6
#define ATOM_SC_N_ARG           7
#define ATOM_SC_O_AMIDE         8
#define ATOM_SC_N_AMIDE         9
#define ATOM_SC_O_CARBOXYL      10
#define ATOM_SC_S_CYS           11
#define ATOM_SC_C_RING          12
#define ATOM_SC_N_HIS           13
#define ATOM_SC_N_LYS           14
#define ATOM_SC_N_TRP           15
#define ATOM_SC_S_MET           16
#define ATOM_SC_O_HYDROXYL      17
#define ATOM_SC_O_PHENOL        18
#define ATOM_SC_SE              19

#define ATOM_SC_O_HETERO        20
#define ATOM_SC_N_HETERO        21
#define ATOM_SC_S_HETERO        22
#define ATOM_SC_X_HETERO        23

#define ATOM_NA_C_BASE          24      // nucleotides
#define ATOM_NA_C_RIBOSE        25
#define ATOM_NA_C_BRIDGE        26
#define ATOM_NA_N_BASE_RIBOSE   27
#define ATOM_NA_N_BASE_ENDO     28
#define ATOM_NA_NH_BASE_ENDO    29
#define ATOM_NA_N_BASE_AMIDE    30
#define ATOM_NA_O_BASE          31
#define ATOM_NA_O2_RIBOSE       32
#define ATOM_NA_O4_RIBOSE       33
#define ATOM_NA_OP_BRIDGE       34
#define ATOM_NA_OP_TERMINAL     35
#define ATOM_NA_P               36

#define ATOM_GC_C               37      // glycans
#define ATOM_GC_O               38
#define ATOM_GC_N               39
#define ATOM_GC_X               40
#define ATOM_WT_O               41
#define ATOM_HYDROGEN           42

#define ATOM_LG_C               43
#define ATOM_LG_N               44
#define ATOM_LG_O               45
#define ATOM_LG_P               46
#define ATOM_LG_S               47
#define ATOM_LG_H               48
#define ATOM_ALKALI             49
#define ATOM_ALKALINE           50
#define ATOM_HALOGEN            51
#define ATOM_LIGHT              52
#define ATOM_HEAVY              53
#define ATOM_OTHER              54
#define ATOM_MAX                55

/* ID for tables in the database */
/* table type 0 */
#define TABLE_TABLES                            0
#define TABLE_NEIGHBORHOOD                      1
#define TABLE_IDENTITIES                        2
#define TABLE_BROWSERS                          3
#define TABLE_VISITORS                          4
#define TABLE_STALKERS                          5
#define TABLE_USAGES                            6
#define TABLE_COMMENTS                          7

/* table type 1 */
#define TABLE_GENEONTOLOGY_DICTIONARY           8
#define TABLE_GENEONTOLOGY_RELATIONSHIP         9
#define TABLE_GENEONTOLOGY_REFERENCE            10
#define TABLE_EC_DICTIONARY                     11
#define TABLE_CATH_DICTIONARY                   12
#define TABLE_AMINOACID_DICTIONARY              13
#define TABLE_HETDICTIONARY                     14

/* table type 2 */
#define TABLE_PDBFILES                          15
#define TABLE_CCDINFO                           16
#define TABLE_GENEONTOLOGIES                    17
#define TABLE_ASSEMBLIES                        18
#define TABLE_CAVITIES                          19
#define TABLE_COMPONENTS                        20
#define TABLE_FUNCTIONS                         21
#define TABLE_KEYWORDS                          22

/* table type 3 */
#define TABLE_CDHIT_CHAINS                      23
#define TABLE_SYMOP_CHAINS                      24
#define TABLE_MOLECULES                         25
#define TABLE_DOMAINS                           26
#define TABLE_RESIDUES                          27
#define TABLE_ATOMS                             28

/* table type 4 */
#define TABLE_NEIGHBORS                         29
#define TABLE_ATOMNEIGHBORS                     30
#define TABLE_MOLPROBITIES                      31
#define TABLE_PEPTIDEBONDS                      32
#define TABLE_NUCLEOTIDEBONDS                   33
#define TABLE_NEIGHBORVECTORS                   34
#define TABLE_LIGAND_BONDANGLES                 35

/* table type 5 */
#define TABLE_ION_BONDVALENCES                  36
#define TABLE_WATER_BONDVALENCES                37
#define TABLE_ION_BINDINGSITES                  38
#define TABLE_ION_BINDINGSITE_PROFILES          39
#define TABLE_ION_BINDINGSITE_LIGRESIDUES       40
#define TABLE_ION_BINDINGSITE_LIGMOIETIES       41
#define TABLE_ION_BINDINGSITE_LIGATOMS          42
#define TABLE_ION_BINDINGSITE_LIGNEIGHBORS      43
#define TABLE_ION_BINDINGSITE_LIGATOMNEIGHBORS  44
#define TABLE_WATER_BINDINGSITES                45
#define TABLE_MAX                               46

typedef struct ResidueDict {
  ResidueName nsa;
  ResidueName aa;
  int         type;
} ResidueDict;

typedef struct ElementDict {
  AtomElem      elem;
  int           protons;
  int           period;
  int           group;
  ElemName      element;
} ElementDict;

typedef struct BondValenceDict {
  int           record_index;
  int           cation_protons;
  AtomElem      cation_elem;
  int           oxidation_state;
  float         bv_r0_oxygen,   bv_r0_sulfur,    bv_r0_selenium, bv_r0_tellurium;
  float         bv_r0_fluorine, bv_r0_chlorine,  bv_r0_bromine,  bv_r0_iodine;
  float         bv_r0_nitrogen, bv_r0_phosphorus,bv_r0_arsenic,  bv_r0_hydrogen;
  int           next_record_index;      // field to indicate if there is multiple oxidation states
} BondValenceDict;

// types of atoms to be considered for generously allowed inner-sphere
// A flag of 0 indicates ligands not allowed in inner-sphere,
// A flag of 1 inidcates ligands allowed in inner-sphere, but will only be searched with deviation of 0.5A
// A flag of 2 indicates ligands allowed and favored in inner-sphere, will be searched with deviation of 1.0A
typedef int InnerSphereDict[ATOM_MAX+1][12];

typedef struct GeometryDict {
  int           index;
  int           coord_number;
  int           geometry_pseudo;
  int           geometry_type;
  int           angle_number;
  int           rmsd_geom_weight;       // 60 * class * (1 - missing_vertex_percentage) [0,180], divide this value by 10 as acceptable RMSD for each geometry
                                        // Assign as IRREGULAR if no geometry is selected, compare observed_rmsd/acceptable_rmsd_10, smaller RMSD will be accepted
  double        angle[28];              // Support maximal coord_number=8, with trailing -1
} GeometryDict;

static GeometryDict geometry_dictionary[] = {
{ 0,1,1,GEOM_UNDERFLOW,           0,  0, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f},
{ 1,2,0,GEOM_LINEAR,              1,120,180.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f},
{ 2,2,1,GEOM_TRIANGLE,            1, 80,120.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f},
{ 3,2,2,GEOM_TETRAHEDRAL,         1, 90,109.47, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f},
{ 4,2,2,GEOM_SQUARE_PLANAR,       1, 90, 90.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f},
{ 5,3,0,GEOM_TRIANGLE,            3,120,120.0f,120.0f,120.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f},
{ 6,3,1,GEOM_TETRAHEDRAL,         3,135,109.47,109.47,109.47, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f},
{ 7,3,1,GEOM_SQUARE_PLANAR,       3,135, 90.0f, 90.0f,180.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f},
{ 8,3,2,GEOM_TRIGONAL_BIPYRAMID,  3, 72, 90.0f, 90.0f,120.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f},
{ 9,3,3,GEOM_OCTAHEDRAL,          3, 90, 90.0f, 90.0f, 90.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f},
{10,4,0,GEOM_TETRAHEDRAL,         6,180,109.47,109.47,109.47,109.47,109.47,109.47, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f},
{11,4,0,GEOM_SQUARE_PLANAR,       6,150, 90.0f, 90.0f, 90.0f, 90.0f,180.0f,180.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f},
{12,4,1,GEOM_TRIGONAL_BIPYRAMID,  6, 96, 90.0f, 90.0f, 90.0f,120.0f,120.0f,120.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f},
{13,4,1,GEOM_TRIGONAL_BIPYRAMID,  6, 96, 90.0f, 90.0f, 90.0f, 90.0f,120.0f,180.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f},
{14,4,2,GEOM_OCTAHEDRAL,          6,120, 90.0f, 90.0f, 90.0f, 90.0f, 90.0f,180.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f},
{15,5,0,GEOM_TRIGONAL_BIPYRAMID, 10,120, 90.0f, 90.0f, 90.0f, 90.0f, 90.0f, 90.0f,120.0f,120.0f,120.0f,180.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f},
{16,5,1,GEOM_OCTAHEDRAL,         10,150, 90.0f, 90.0f, 90.0f, 90.0f, 90.0f, 90.0f, 90.0f, 90.0f,180.0f,180.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f},
{17,6,0,GEOM_OCTAHEDRAL,         15,180, 90.0f, 90.0f, 90.0f, 90.0f, 90.0f, 90.0f, 90.0f, 90.0f, 90.0f, 90.0f, 90.0f, 90.0f,180.0f,180.0f,180.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f},
{18,6,0,GEOM_TRIGONAL_BIPRISM,    15,60,66.422,66.422,66.422,66.422,66.422,66.422,101.54,101.54,101.54,143.13,143.13,143.13,143.13,143.13,143.13, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f},
{19,6,0,GEOM_TRIGONAL_ANTIPRISM,  15,60, 70.0f, 70.0f, 70.0f, 70.0f, 70.0f, 70.0f,110.0f,110.0f,110.0f,110.0f,110.0f,110.0f,180.0f,180.0f,180.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f},
{20,7,0,GEOM_CAP_TRIGONAL_BIPRISM,21,60,66.422,66.422,66.422,66.422,66.422,66.422,71.565,71.565,71.565,71.565,101.54,101.54,101.54,129.23,129.23,143.13,143.13,143.13,143.13,143.13,143.13, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f},
{21,7,0,GEOM_PENTAGONAL_BIPYRAMID,21,60, 72.0f, 72.0f, 72.0f, 72.0f, 72.0f, 90.0f, 90.0f, 90.0f, 90.0f, 90.0f, 90.0f, 90.0f, 90.0f, 90.0f, 90.0f,144.0f,144.0f,144.0f,144.0f,144.0f,180.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f},
{22,8,0,GEOM_CUBIC,               28,60,70.53f,70.53f,70.53f,70.53f,70.53f,70.53f,70.53f,70.53f,70.53f,70.53f,70.53f,70.53f,109.47,109.47,109.47,109.47,109.47,109.47,109.47,109.47,109.47,109.47,109.47,109.47,180.0f,180.0f,180.0f,180.0f},
{23,8,0,GEOM_SQUARE_ANTIPRISM,    28,60,74.86f,74.86f,74.86f,74.86f,74.86f,74.86f,74.86f,74.86f,74.86f,74.86f,74.86f,74.86f,74.86f,74.86f,74.86f,74.86f,118.53,118.53,118.53,118.53,141.59,141.59,141.59,141.59,141.59,141.59,141.59,141.59},
{24,8,0,GEOM_DODECAHEDRAL,        28,60,73.693,73.693,73.693,73.693,73.693,73.693,73.693,73.693,73.693,73.693,73.693,73.693,73.693,73.693,73.693,73.693,73.693,73.693,73.693,73.693,138.92,138.92,138.92,138.92,147.39,147.39,147.39,147.39},
{25,9,0,GEOM_OVERFLOW,            99, 0, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f},
};

typedef struct ObjAssemblyInfo {
  int                   index;
  int                   assembly_number;
  int                   type;
  float                 total_asa,polar_asa,positive_asa,negative_asa,total_bb_asa,polar_bb_asa;
  float                 total_msa,polar_msa,positive_msa,negative_msa,total_bb_msa,polar_bb_msa;
  int                   numChain;       // obsolete, all chains go to symchain now
  int                   numSymChain;
  int                   numCavity;      // obsolete, from surflex-dock, only the top 1 cavity is recorded now
  int                   numSurfraceAtom;
  struct ObjCavityInfo  *CavityInfo;
  struct ObjSymChainInfo*SymChainInfo;
} ObjAssemblyInfo;

typedef struct ObjCavityInfo {
  int                   index;
  int                   assembly_index;
  struct ObjAssemblyInfo*AssemblyInfo;
  int                   numResidue;
  int                   *residue_indices;
  int                   numAtom;        // obsolete, only numResidue will be recorded now
  int                   volume;
} ObjCavityInfo;

typedef struct ObjFunctionInfo {
  int                   index;
  int                   ec_primary;
  int                   ec_3rd_level;
  int                   ec_4th_level;
  struct ObjComponentInfo *ComponentInfo;
} ObjFunctionInfo;

typedef struct ObjKeywordInfo {
  int                   index;
  ComponentName         keyword;
  struct ObjComponentInfo *ComponentInfo;
} ObjKeywordInfo;

typedef struct ObjComponentInfo {
  int                   index;
  int                   componentnum;
  int                   numChain;
  ComponentName         component_name;
  int                   numKeyword;
  struct ObjKeywordInfo *KeywordInfo;
  int                   numFunction;
  struct ObjFunctionInfo*FunctionInfo;
  int                   engineered, mutation, synthetic;
  int                   organism_id;
  OrganismName          organism_name;
  int                   expression_id;
  OrganismName          expression_name;
  TemporaryField        temp_field;
} ObjComponentInfo;

typedef struct ObjGeneOntologyInfo {
  int                   index;
  char                  chain;
  char                  go_type;
  int                   go_id;
  int                   qualifier;
  GeneOntologyEvidence  evidence;
  GeneOntologyLongName  xref_db_name;
  GeneOntologyLongName  xref_db_id;
  int                   organism_id;
  EntityDate            creation_date;
  GeneOntologyLongName  created_by;
  char                  ref_db_name;
  int                   ref_db_id;
} ObjGeneOntologyInfo;

typedef struct ObjChainInfo {
  int                   index;
  char                  chainid;
  int                   assembly_index;
  struct ObjAssemblyInfo*AssemblyInfo;
  struct ObjComponentInfo*ComponentInfo;
  int                   numWaterRes,numLigandRes,numDnarnaRes,numProteinRes;
  int                   type2;  // being named so for consistency with mypdb2 table pdbchains
  int                   clusterstatus;
  int                   cluster50_id,represent50_id,cluster90_id,represent90_id;
  int                   numGeneOntology,numBiolProcess,numMoleFunction,numCellComponent;
  struct ObjGeneOntologyInfo*BiolProcessInfo;
  struct ObjGeneOntologyInfo*MoleFunctionInfo;
  struct ObjGeneOntologyInfo*CellComponentInfo;
  int                   numMolecule;    // new field Nov-2009
  struct ObjMoleculeInfo*MoleculeInfo;  // new field Nov-2009
  int                   numDomain;      // new field Oct-2010, number of real domains
  int                   numFragment;    // new field Oct-2010, number of fragments with at the border or linkage of domains
  struct ObjDomainInfo  *DomainInfo;
  int                   numResidue;
  int                   numAtom;
  int                   claimed;
  Vector3f              Center;
} ObjChainInfo;

typedef struct ObjSymChainInfo {
  int                   index;
  int                   model_number;
  char                  cdhit_chainid;
  char                  symop_chainid;
  int                   assembly_index;
  struct ObjAssemblyInfo*AssemblyInfo;
} ObjSymChainInfo;

typedef struct ObjMoleculeInfo {        // new data type Nov-2009
  int                   index;
  int                   type;
  int                   assembly_index;
  struct ObjAssemblyInfo*AssemblyInfo;
  char                  chain;          // in case of water, chain = ' '
  struct ObjChainInfo   *ChainInfo;
  int                   numResidue;
} ObjMoleculeInfo;

typedef struct ObjDomainInfo {
  int                   index;
  char                  chain;
  int                   residueid_begin, residueid_end;
  int                   is_fragment;
  int                   domainnum;
  int                   cath_primary, cath_topology, cath_superfamily;
  int                   cath_s35, cath_s60, cath_s95, cath_s100;
  int                   cath_uniqueid;
  int                   numResidue;
} ObjDomainInfo;

typedef struct ObjResidueInfo {
  int                   index;
  int                   type;
  int                   prev_index;     // if in a polypeptide/polynucleotide/polysaccharide chain, index of previous residue
  int                   next_index;     // if in a polypeptide/polynucleotide/polysaccharide chain, index of next residue
  int                   branch_index;   // if in a branch covalent glycans, index of branch out residue
  int                   branch2_index;  // if in 4-way branch covalent glycans, index of branch out residue
  AtomName              prev_atomname;
  AtomName              next_atomname;
  AtomName              branch_atomname;
  AtomName              branch2_atomname;
  int                   assembly_index;
  struct ObjAssemblyInfo*AssemblyInfo;
  int                   cavity_index;
  struct ObjCavityInfo  *CavityInfo;
  char                  chain;  // PDB ATOM record 22
  struct ObjChainInfo   *ChainInfo;
  int                   molecule_index; // new field Nov-2009
  struct ObjMoleculeInfo*MoleculeInfo;  // new field Nov-2009
  int                   domain_index;   // new field Oct-2010
  struct ObjDomainInfo  *DomainInfo;    // new field Oct-2010
  ResidueName           resn;   // PDB ATOM record 18-20
  ResidueId             resi;   // PDB ATOM record 23-27, text
  int                   resid;  // PDB ATOM record 23-27, numeric
  char                  resi2;  // PDB ATOM record 28, patched residue
  int                   numAtom;
  int                   isSingle;       // indicate whether residue contains more than one non-hydrogen atom, 2 indicates water
  int                   containsMetal;  // indicate whether residue contains any atoms that is not H,C,N,O,P,S,Se,Halogen or Noble gas
  int                   location;       // buried, surface, or within cavity
  float                 asa,msa,curvature;
  struct ObjAtomInfo    *AtomInfo;
  Vector3f              Center;
  float                 center_displacement; // distance to center of chain
  int                   frozen;         // temporary field to check if a sugar residue has been attached to protein yet
  int                   maxResNeighbor; // maximal allocated residue neighbors, will get extended double allocation if not enough
  int                   numResNeighbor;
  int                   *ResNeighborIndex;
} ObjResidueInfo;

typedef struct ObjAtomInfo {
  int                   index;
  int                   residue_index;
  int                   cavity_index;
  struct ObjResidueInfo *ResidueInfo;
  struct ObjCavityInfo  *CavityInfo;
  /* atom specific fields */
  int                   moiety_type;
  int                   type;
  signed char           hetatm; // PDB ATOM record 1-6
  int                   id;     // PDB ATOM record 7-11
  AtomName              realname;//PDB ATOM record 13-16
  AtomName              name;   // PDB ATOM record 13-16, whithout whitespace
  char                  alt;    // PDB ATOM record 17
  int                   numAltLoc;
  char                  AltLocStr[16]; // Handle only up to 16 different alternative conformation
  AtomElem              elem;   // PDB ATOM record 77-78
  float                 occup,b,sigma_2fofc,q,vdw;      /* atom properties */
                                // PDB ATOM record (55-60)occup (61-66)b (79-80)q (elem->)vdw
  int                   location;
  float                 asa,msa,curvature;
  int                   hydrogen,protons,period,group;
  int                   oxidation_state;
  int                   bv_index,numCovalentBond;
  int                   isMetal;// indicate whether atoms is H,C,N,O,P,S,Se,Halogen or Noble gas
//int                   hydrogen,donor,acceptor;/* hb related properties */
//float                 bohr,q2;
  int                   numAtmNeighbor;
  int                   indAtmNeighbor;
  int                   *AtmNeighborIndex;
  float                 center_displacement; // distance to center of chain
} ObjAtomInfo;

typedef struct ObjNeighborInfo {
  int                   index;          // unique bond index
  int                   atom_index[2];  // unique pair for atom index
  int                   residue_index[2];
//ObjResidueInfo        *res1,*res2;
//ObjAtomInfo           *atm1,*atm2;
  char                  bond_type;      // Jan-2012, crystal contact by contact: enum:('0'=undefined, '1'=weak hydrogen bond, '3'=strong hydrogen bond)
  // or in AU type by molprobity: enum:('u'=undefined, 'h'=hydrogen bond, 'w'=wide contact, 'c'=close contact, 's'=small overlap, 'b'=bad overlap)
  float                 score_probe;
  float                 score_hb, score_wc, score_cc, score_so, score_bo;
  int                   contact_flag;   // new field Nov-2009
  double                distance;
  double                bfactor_correlation;    // if B1>B2, (B1-B2)*(B1/B2), or vice versa
  struct ObjNeighborVectorInfo*vec_fwd;
  struct ObjNeighborVectorInfo*vec_rev;
  int                   vector_index[2];
} ObjNeighborInfo;

typedef struct ObjNeighborVectorInfo {  // New object Nov-2011, to separate foward vector from backward vector
  int                   index;          // Special index, 0 points to an invalid value, n and -n points to the same value and opposite direction
  int                   icell,isym;     // new field Feb-2011, to identify which cell and AU the 2nd vertex is relatively to the 1st vertex, default is 555,000
//int                   rcell,rsym;     // new field Feb-2011, to identify which cell and AU the 1st vertex is relatively to the 2nd vertex, default is 555,000
  Vector3f              direction;      // new field Feb-2011, the direction of the vector, (x2,y2,z2)-(x1,y1,z1)
} ObjNeighborVectorInfo;

typedef struct MolprobityMapping {
  int                   index;
  MolprobityIndex       molprobity_index;
  int                   neighbor_index;
} MolprobityMapping;

typedef struct ObjMolprobityInfo {
  int                   index;          // unique bond index
  int                   neighbor_index; // the neighbor_index
  AtomName              name_a;         // PDB ATOM record 13-16, whithout whitespace
  AtomName              name_b;         // PDB ATOM record 13-16, whithout whitespace
  char                  bond_type;      // Jan-2012, in AU interaction type by molprobity
  int                   num_dots, num_dots_fwd, num_dots_rev;
  float                 score, mingap, gap, spike_len;
} ObjMolprobityInfo;

typedef struct ObjAngleInfo {
  int                   index;
  int                   atom_index[3];
  int                   residue_index[3];
  int                   atomneighbor_index[2];
  float                 distance[3];
  double                angle;
  int                   numDistance;
  int                   indDistance;
  float                 *DistanceList;
} ObjAngleInfo;

typedef struct ObjIonBondValenceInfo {
  int                   index;
  ObjNeighborInfo       *ni;
  int                   reverse;        // reverse==0: ni->atom_index[0] is for ligand, ni->atom_index[1] is for ion
                                        // reverse==1: ni->atom_index[1] is for ligand, ni->atom_index[0] is for ion
  int                   inner_sphere_flag; // This field will be 0 if it is too far to be in inner-sphere by any standard
                                           // 1 if it is included in inner-sphere in the first step, 2 if it is included as inner-sphere from second step
  ObjResidueInfo        *ri_lig;
  ObjResidueInfo        *ri_ion;
  ObjAtomInfo           *ai_lig;
  ObjAtomInfo           *ai_ion;
  int                   valid;
  float                 valid_lig_occup;
  double                bondvalence,bv_sodium,bv_magnesium,bv_potassium,bv_calcium;
  double                bv_manganese,bv_iron,bv_cobalt,bv_nickel,bv_copper,bv_zinc;
  Vector3f              direction;
  Vector3f              bv_direction;
  double                bv_direction_len;
  int                   bidentate_flag; // indicate if it belongs to amino acid side chain bidentate
} ObjIonBondValenceInfo;

typedef struct ObjIonLigResidueInfo {          // New object 02-May-2012
  int                   local_index;
  int                   bindingsite_index;
  int                   type;           // indicate if it is first or second coordination sphere
  int                   priority;       // indicate its priority in isoform (cis-/trans-) determination
                                        // OP(RNA) 14, Glu/Asp 13, His 12, Cys 11, O_amide 10, O_hydroxyl 9, O_MC 8,
                                        // OBase(RNA) 7, NBase(RNA) 6, ORibose(RNA) 5, O_Ligand 4, NS_Ligand 3,
                                        // O_default 2, default 1, Mobile 0     -- refer to ISOFORM_ set of constants
  int                   residue_index;
  float                 distance[2];
  int                   atom_index[2];  // atom_index[1] has different meaning dependent on 1st or 2nd coordination sphere
  // For first coordination sphere, atom_index[1] stores bidentate information
  // For second coordination sphere, atom_index[1] stores the first coordination sphere atom on the path towards the metal center
//int                   numNeighbor;
//int                   *AtmNeighborIndex;
  /* The following four fields are not needed because they can be retrieved from the corresponding I->AtmNeighborInfo record
  int                   *SelfAtmIndex;
  int                   *ExternalResIndex;
  int                   *ExternalAtmIndex;
  int                   *bond_type */
} ObjIonLigResidueInfo;

typedef struct ObjIonLigMoietyInfo {
  int                   local_index;
  int                   bindingsite_index;
//int                   valid;          // Only a single case will be invalid: O3'/O5' with OP1/OP2 and without O2'/O4'
  int                   type;           // indicate if it is first or second coordination sphere
  int                   moiety_type;
  int                   residue_index;
  int                   residue_symop;
  int                   num_inner_links, num_outer_links;
} ObjIonLigMoietyInfo;

typedef struct ObjIonLigAtomInfo {  // New object 08-May-2012
  int                   local_index;
  int                   bindingsite_index;
  int                   priority;       // indicate its priority in isoform (cis-/trans-) determination
  ObjIonLigResidueInfo *IonLigResidueInfo;
  int                   protons;
  int                   atom_index;
  ObjIonBondValenceInfo*IonBondValenceInfo;
  double                distance,bondvalence;
  Vector3f              bv_direction;
  int                   isoform_considered;
} ObjIonLigAtomInfo;

typedef struct ObjIonLigNeighborInfo {  // New object 02-May-2012
  int                   index;
  int                   bindingsite_index;
  int                   type;
  int                   dresseq;
  ObjIonLigResidueInfo *IonLigResidueInfo_a;
  ObjIonLigResidueInfo *IonLigResidueInfo_b;
  int                   residue_index[2];
  int                   atom_index[4];
  int                   neighbor_index;
  int                   atomneighbor_index;
} ObjIonLigNeighborInfo;

typedef struct ObjIonLigAtomNeighborInfo {  // New object 08-May-2012
  int                   local_index;
  int                   bindingsite_index;
  int                   priority_type;
  double                angle;
  double                bvproduct_cos_angle;
  int                   dresseq;
  ObjIonLigAtomInfo    *IonLigAtomInfo_a;
  ObjIonLigAtomInfo    *IonLigAtomInfo_b;
  int                   atom_index[2];
  int                   residue_index[2];
} ObjIonLigAtomNeighborInfo;

typedef struct ObjBidentateInfo {
  ObjIonBondValenceInfo*bv1;
  ObjIonBondValenceInfo*bv2;
  double                distance;
  double                bondvalence, calcium_bondvalence;
  Vector3f              bv_direction;
} ObjBidentateInfo;

typedef struct ObjIonBindingSiteInfo {
  int    index,                 residueid_ion,          atomid_ion;
  float  bfactor_env_avg,       occupancy_env_avg;
  int    coord_number_3a,       coord_number_geom,      coord_number_4a;
  float  rmsd_geom_angle;
  int    rmsd_geom_weight;
  int    geometry_type,         geometry_bidentate,     geometry_pseudo,        geometry_distort;
  int    num_bidentate_all,     num_bidentate_oo,       num_bidentate_on,       num_bidentate_nn;
  float  distance_avg,          distance_min,           distance_max;
  int    num_metal_4a;
  double valence_3a,    vecsum_3a,      valence_4a,     vecsum_4a;
  double bvs_sodium,    bvs_magnesium,  bvs_potassium,  bvs_calcium;
  double bvs_manganese, bvs_iron,       bvs_cobalt,     bvs_nickel,     bvs_copper,     bvs_zinc;
// which_metal is repetitive field to (I->AtomInfo+atomid_ion)->protons
  int    atomid_cluster,  size_cluster,    homosize_cluster;
  int    which_metal,     which_geotype,   which_ligtype,    which_XHCXX,     which_OOO,   which_wOOO2,
         which_PPP,       which_BNR,       which_wBNR2,      which_mBRP2,     which_isoform,   which_mobile;
  double quality_valence, quality_complete,quality_experiment,quality_complete_nw;
  int    num_oxygen,      num_nitrogen,    num_sulfur,       num_phosphorus,  num_carbon,  num_others;
  int    n04_o_mc,        n08_o_amide,     n10_o_carboxyl,   n17_o_hydroxyl,  n18_o_phenol,
         n30_o_base,      n31_o_ribose,    n32_op_bridge,    n33_op_terminal, n39_o_water, n43_o_others;
  int    n01_n_mc,        n07_n_arginine,  n09_n_amide,      n13_n_histidine, n14_n_lysine,
         n15_n_tryptophan,n27_n_base_ring, n28_n_base_ribose,n29_n_base_amide,n42_n_others;
  int    n11_s_cysteine,  n16_s_methionine,n45_s_others,     n19_selenium,    n53_others;
} ObjIonBindingSiteInfo;

typedef struct ObjEntityMolecule {
  EntityFileName        filename;
  EntityPDBID           pdbid;
  int                   pdbfileid;
  int                   intra_residue_flag;
  int                   shortest_only_flag;
  int                   numAssembly;
  int                   numComponent;           // new field Oct-2010
  int                   numKeyword;
  int                   numChain;
  int                   numMolecule;            // new field Nov-2009
  int                   numDomain;              // new field Oct-2010, number of total sum of both domains and fragments
  int                   numResidue;
  int                   numAtom;
  int                   numResNeighbor;
  int                   numAtmNeighbor;
  int                   numNeighborVector;
  int                   numMolprobity;
  int                   numAngle;
  int                   numWaterBondValence;
  int                   numIonBondValence;
  int                   numIonBindingSite;      // new field Aug-2010
  int                   numIonLigResidue;       // new field May-2012
  int                   numIonLigMoiety;        // new field Nov-2012
  int                   numIonLigAtom;          // new field May-2012
  int                   numIonLigNeighbor;      // new field May-2012
  int                   numIonLigAtomNeighbor;  // new field May-2012
  int                   numWaterBindingSite;    // new field May-2012
  ObjAssemblyInfo       *AssemblyInfo;
  ObjComponentInfo      *ComponentInfo;         // new field Oct-2010
  ObjKeywordInfo        *KeywordInfo;           // new field Oct-2010
  ObjChainInfo          *ChainInfo;
  ObjMoleculeInfo       *MoleculeInfo;          // new field Nov-2009
  ObjDomainInfo         *DomainInfo;            // new field Oct-2010
  ObjResidueInfo        *ResidueInfo;
  ObjAtomInfo           *AtomInfo;
  ObjNeighborInfo       *ResNeighborInfo;
  ObjNeighborInfo       *AtmNeighborInfo;
  ObjNeighborVectorInfo *NeighborVectorInfo;
  ObjMolprobityInfo     *MolprobityInfo;
  ObjAngleInfo          *AngleInfo;
  ObjIonBondValenceInfo *WaterBondValenceInfo;
  ObjIonBondValenceInfo *IonBondValenceInfo;
  ObjIonBindingSiteInfo *IonBindingSiteInfo;        // new field Aug-2010
  ObjIonLigResidueInfo  *IonLigResidueInfo;         // new field May-2012
  ObjIonLigMoietyInfo   *IonLigMoietyInfo;
  ObjIonLigAtomInfo     *IonLigAtomInfo;            // new field May-2012
  ObjIonLigNeighborInfo *IonLigNeighborInfo;        // new field May-2012
  ObjIonLigAtomNeighborInfo *IonLigAtomNeighborInfo;// new field May-2012
  ObjIonBindingSiteInfo *WaterBindingSiteInfo;      // new field May-2012
  /* below from old struct Coordset */
  float                 *Coord;
  Vector3f              Max,Min,Center;
  /* field recorded information from PDB header */
  /* fields for basic methodology information */
  CCP4SPG               *space_group;
  SGrpName              space_group_name;
  int                   space_group_number;
  float                 cell_a, cell_b, cell_c, cell_alpha, cell_beta, cell_gamma;
  int                   z_value;
  float                 resolution;
  EntityDate            deposition_date;
  int                   symop_status;           // 0: no symop read in yet, 1-n: in the process of symop reading, -1: reading is done
  ccp4_symop            *symop;
  int                   nsymop;
  ccp4_symop            *origx_matrix;
  ccp4_symop            *scale_matrix;
  int                   origx_done, scale_done; // whether or not the specified matrix has been read
  int                   compnd_done, source_done; // whether or not the specified COMPND or SOURCE record has been read
  int                   compnd_wait, source_wait; // whether or not the specified COMPND or SOURCE record is waiting for more input
  int                   exp_method;
  EntityHeader          header;
  EntityTitle           title;
  /* fields for functional classification */
  int                   organism_id;
  int                   ec_primary;
  int                   ec_3rd_level;
  int                   ec_4th_level;
  int                   ec_complex;
  /* fields for structural classification */
  int                   cluster50_id;
  int                   cluster90_id;
  int                   go_process,go_function,go_component;
  int                   cath_primary;
  int                   cath_topology;
  int                   cath_superfamily;
  int                   temp_index;
  TemporaryField        temp_field;
  int                   tables[TABLE_MAX];
} ObjEntityMolecule;

int  ReadAminoAcidDictionary(ResidueDict *aminoacid_dictionary, char *file_aadict);
ObjEntityMolecule *EntityMoleculeNew();
void EntityMoleculeFree(ObjEntityMolecule *I);
void ObjGeneOntologyInit(ObjGeneOntologyInfo *goi, char go_type, int index);
int  ObjGeneOntologyMinimalID(ObjGeneOntologyInfo *goinfo, int numGO);
void ObjComponentInit(ObjComponentInfo *comi);
void ObjFunctionInit(ObjFunctionInfo *funi);
void ObjKeywordInit(ObjKeywordInfo *keyi);
void ObjChainInit(ObjChainInfo *ci);
void ObjChainFree(ObjChainInfo *ci);
void ObjMoleculeInit(ObjMoleculeInfo *mi);
void ObjDomainInit(ObjDomainInfo *di);
void ObjResidueInit(ObjResidueInfo *ri);
void ObjIonBindingSiteInit(ObjIonBindingSiteInfo *ibsi, ObjAtomInfo *ai_ion);
void ObjResidueAssignResname(ObjResidueInfo *ri,char* q);
void ObjResidueAssignAltLoc(ObjResidueInfo *ri);
void ObjResidueAssignType(ObjResidueInfo *ri, ResidueDict *aminoacid_dictionary);
void EntityMoleculeAssignType(ObjEntityMolecule *I);
void EntityMoleculeAssignCenterDisplacement(ObjEntityMolecule *I);
void EntityMoleculeReadPDBStr(ObjEntityMolecule *I, char *buffer, ResidueDict *aminoacid_dictionary);
void EntityMoleculeReadClusterStr(ObjEntityMolecule *I, char *buffer);
void EntityMoleculeReadAssemblyStr(ObjEntityMolecule *I, char *buffer_buheader, char *data_dir);
void EntityMoleculeReadAssemblyStrOld(ObjEntityMolecule *I, char *buffer_surface, char *data_dir);
void EntityAssemblyReadSurfaceStr(ObjAssemblyInfo *assi, char *buffer, int assCount, ObjEntityMolecule *I);
int  EntityAssemblyReadSurfaceStrOld(ObjAssemblyInfo *assi, char *buffer, int assCount, int cavityCountPrev, ObjEntityMolecule *I);
void EntityMoleculeGenerateCenter(ObjEntityMolecule *I);
void EntityMoleculeNeighbor(ObjEntityMolecule *I, float cutoff, char *buffer_molprobity, char *buffer_contact);
void EntityMoleculeLigandAngle(ObjEntityMolecule *I, float cutoff);
int  EntityMoleculeNeighborPrint(FILE *fout, ObjEntityMolecule *I, int isAtomNeighbor, FILE* fout_pept, FILE* fout_nucl);
int  EntityMoleculeAnglePrint(FILE *fout, ObjEntityMolecule *I);
int  EntityMoleculeBondValence(ObjEntityMolecule *I, int isWater);
ObjIonBondValenceInfo *EntityMoleculeIonBondValenceAdd(ObjEntityMolecule *I, int bondvalenceid, ObjNeighborInfo *ni, int reverse, ObjAtomInfo *ai1, ObjAtomInfo *ai2, double bondvalence, float* bv_direction, int isWater);
int  ObjIonBondValenceCopy(ObjIonBondValenceInfo *ibvi, ObjIonBondValenceInfo *ibvj);
ObjIonBondValenceInfo *ObjIonBondValencePrevBidentate(ObjIonBondValenceInfo *ibvi, ObjIonBondValenceInfo *bv_info, int prev_count);
int  ObjIonBondValenceAssignPriority(ObjEntityMolecule *I, ObjIonBondValenceInfo *ibvi, ObjIonBindingSiteInfo *ibsi, ObjIonBondValenceInfo *bv_info, int bv_count, int prev_count, int isWater);
int  ObjIonBindingSiteRecordMoiety(ObjEntityMolecule *I, ObjIonBindingSiteInfo *ibsi, ObjIonBondValenceInfo *bv_info, int bv_count, ObjAtomInfo *ai, int residue_symop, int moiety_type, int ionlig_type);
static int ObjIonBondValenceIonAICmp(const void *p1, const void *p2);     // Procedure used for qsort of ion atom ID
static int ObjIonBondValenceValidCmp(const void *p1, const void *p2);     // Procedure used for qsort of valid ligands
static int ObjIonBondValenceBVCmp(const void *p1, const void *p2);        // Procedure used for qsort of descending bond valence values
static int ObjIonBondValenceInnerCmp(const void *p1, const void *p2);     // Procedure used for qsort of descending inner-sphere flag
static int ObjIonBondValenceBidentateCmp(const void *p1, const void *p2); // Procedure used for qsort of descending bidentate flag
static int ObjIonBondValenceLigRICmp(const void *p1, const void *p2);     // Procedure used for qsort of ligand residue ID
static int ObjIonLigAtomNeighborAngleCmp(const void *p1, const void *p2); // Procedure used for qsort of first coordination sphere LML angle
static int doublecmp (const void *p1, const void *p2);
void ObjIonBindingSiteVecsumNW(float *vec0,ObjIonBondValenceInfo *bv_info,int bv_count_inner);
float ObjIonBindginSiteSmallestAngle(float *new_bv_direction,ObjIonBondValenceInfo *bv_info,int bv_count_inner);
int  ObjIonBindingSiteBidentate(ObjIonBindingSiteInfo *ibsi, ObjIonBondValenceInfo *bv_info, int bv_count, ObjBidentateInfo *arr_bidentate, int cnt_bidentate);
int  ObjBidentateAdd(ObjBidentateInfo *arr_bidentate, int cnt_bidentate, int ind_bidentate, ObjIonBondValenceInfo *ibvi1, ObjIonBondValenceInfo *ibvi2, double distance);
int  ObjIonBindingSiteGeometry(ObjIonBindingSiteInfo *ibsi, ObjIonBondValenceInfo *bv_info, int bv_count, int geometry_bidentate);
int  ObjIonLigStrongestHB(ObjEntityMolecule *I, ObjResidueInfo *ri1, ObjResidueInfo *ri2);
int  ObjIonLigDresseq(ObjEntityMolecule *I, ObjResidueInfo *ri1, ObjResidueInfo *ri2);
int  ObjIonLigFCSIsoform(ObjIonLigAtomNeighborInfo *tmpIonLigAtomNeighbor, int numAtomNeighborFCS);
void ObjIonBindingSite(ObjEntityMolecule *I, ObjIonBindingSiteInfo *ibsi, ObjIonBondValenceInfo *bv_info, int bv_count_redundant, int isWater);
int  EntityMoleculeIonBindingSite(ObjEntityMolecule *I, int isWater);
void EntityMoleculeReport(ObjEntityMolecule *I, float cutoff, char *temp_dir);
char* process_cmdline_file(char* temp_dir, char* file_name, char* file_type, int is_optional);

#endif
