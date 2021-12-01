#ifndef _H_MAIN
#define _H_MAIN
#define SYSTEM_CHECKMYMETAL 1

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

#define CIF_MAX_GROUPS                      100
#define CIF_MAX_ITEMS                       100
#define CIF_ATOM_SITE                       1
#define CIF_ATOM_SITE__GROUP_PDB            1
#define CIF_ATOM_SITE__ID                   2  
#define CIF_ATOM_SITE__TYPE_SYMBOL          3
#define CIF_ATOM_SITE__LABEL_ATOM_ID        4
#define CIF_ATOM_SITE__LABEL_ALT_ID         5
#define CIF_ATOM_SITE__LABEL_COMP_ID        6
#define CIF_ATOM_SITE__LABEL_ASYM_ID        7
#define CIF_ATOM_SITE__LABEL_ENTITY_ID      8
#define CIF_ATOM_SITE__LABEL_SEQ_ID         9
#define CIF_ATOM_SITE__PDBX_PDB_INS_CODE    10
#define CIF_ATOM_SITE__CARTN_X              11
#define CIF_ATOM_SITE__CARTN_Y              12
#define CIF_ATOM_SITE__CARTN_Z              13
#define CIF_ATOM_SITE__OCCUPANCY            14
#define CIF_ATOM_SITE__B_ISO_OR_EQUIV       15
#define CIF_ATOM_SITE__PDBX_FORMAL_CHARGE   16
#define CIF_ATOM_SITE__AUTH_SEQ_ID          17
#define CIF_ATOM_SITE__AUTH_COMP_ID         18
#define CIF_ATOM_SITE__AUTH_ASYM_ID         19
#define CIF_ATOM_SITE__AUTH_ATOM_ID         20
#define CIF_ATOM_SITE__PDBX_PDB_MODEL_NUM   21

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
#define GEOM_LINEAR               1     // Class II popularity,  CN=2
#define GEOM_TRIANGLE             2     // Class II popularity,  CN=3
#define GEOM_SQUARE_PLANAR        3     // Class III popularity, CN=4
#define GEOM_TETRAHEDRAL          4     // Class III popularity, CN=4
#define GEOM_TRIGONAL_BIPYRAMID   5     // Class II popularity,  CN=5
#define GEOM_OCTAHEDRAL           6     // Class III popularity, CN=6
#define GEOM_TRIGONAL_BIPRISM     7     // Class I popularity
#define GEOM_TRIGONAL_ANTIPRISM   8     // Class I popularity
#define GEOM_CAP_TRIGONAL_BIPRISM 9     // Class I popularity
#define GEOM_PENTAGONAL_BIPYRAMID 10    // Class I popularity
#define GEOM_CUBIC                11    // Class I popularity
#define GEOM_SQUARE_ANTIPRISM     12    // Class I popularity
#define GEOM_DODECAHEDRAL         13    // Class I popularity
#define GEOM_IRREGULAR            14
#define GEOM_UNDERFLOW            15
#define GEOM_OVERFLOW             16
#define GEOM_MAX                  17

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
#define RESIDUE_DNARNA          42
#define RESIDUE_WATER           43
#define RESIDUE_ALKALI          44
#define RESIDUE_ALKALINE        45
#define RESIDUE_CATION          46
#define RESIDUE_ANION           47
#define RESIDUE_PORPHYRIN       48
#define RESIDUE_SOLVENT         49
#define RESIDUE_SUGAR           50
#define RESIDUE_COFACTOR        51
#define RESIDUE_HEAVY           52
#define RESIDUE_LIGAND          53
#define RESIDUE_MAX             54

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
#define ATOM_UNDEF              0
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

#define ATOM_DR_C               24
#define ATOM_DR_N               25
#define ATOM_DR_O               26
#define ATOM_DR_P               27
#define ATOM_WT_O               28
#define ATOM_LG_C               29
#define ATOM_LG_N               30
#define ATOM_LG_O               31
#define ATOM_LG_P               32
#define ATOM_LG_S               33
#define ATOM_LG_H               34
#define ATOM_HYDROGEN           35
#define ATOM_ALKALI             36
#define ATOM_ALKALINE           37
#define ATOM_HALOGEN            38
#define ATOM_LIGHT              39
#define ATOM_HEAVY              40
#define ATOM_OTHER              41
#define ATOM_MAX                42

/* ID for tables in the database */
/* table type 0 */
#define TABLE_TABLES                    0
#define TABLE_NEIGHBORHOOD              1
#define TABLE_USAGES                    2
#define TABLE_COMMENTS                  3

/* table type 1 */
#define TABLE_GENEONTOLOGY_DICTIONARY   4
#define TABLE_GENEONTOLOGY_RELATIONSHIP 5
#define TABLE_GENEONTOLOGY_REFERENCE    6
#define TABLE_EC_DICTIONARY             7
#define TABLE_CATH_DICTIONARY           8
#define TABLE_AMINOACID_DICTIONARY      9
#define TABLE_HETDICTIONARY             10

/* table type 2 */
#define TABLE_PDBFILES                  11
#define TABLE_CCDINFO                   12
#define TABLE_GENEONTOLOGIES            13
#define TABLE_ASSEMBLIES                14
#define TABLE_CAVITIES                  15
#define TABLE_COMPONENTS                16
#define TABLE_FUNCTIONS                 17
#define TABLE_KEYWORDS                  18

/* table type 3 */
#define TABLE_CDHIT_CHAINS              19
#define TABLE_SYMOP_CHAINS              20
#define TABLE_MOLECULES                 21
#define TABLE_DOMAINS                   22
#define TABLE_RESIDUES                  23
#define TABLE_ATOMS                     24

/* table type 4 */
#define TABLE_NEIGHBORS                 25
#define TABLE_ATOMNEIGHBORS             26
#define TABLE_LIGAND_BONDANGLES         27
#define TABLE_ION_BONDVALENCES          28
#define TABLE_WATER_BONDVALENCES        29
#define TABLE_ION_BINDINGSITES          30
#define TABLE_MAX                       31

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
{11,4,0,GEOM_SQUARE_PLANAR,       6,180, 90.0f, 90.0f, 90.0f, 90.0f,180.0f,180.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f},
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
  int                   engineered, mutation;
  int                   organism_id;
  OrganismName          organism_name;
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
  int                   prev_index;     // if in a polypeptide chain, index of previous residue
  int                   next_index;     // if in a polypeptide chain, index of next residue
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
} ObjResidueInfo;

typedef struct ObjAtomInfo {
  int                   index;
  int                   residue_index;
  int                   cavity_index;
  struct ObjResidueInfo *ResidueInfo;
  struct ObjCavityInfo  *CavityInfo;
  /* atom specific fields */
  int                   type;
  signed char           hetatm; // PDB ATOM record 1-6
  int                   id;     // PDB ATOM record 7-11
  AtomName              realname;//PDB ATOM record 13-16
  AtomName              name;   // PDB ATOM record 13-16, whithout whitespace
  char                  alt;    // PDB ATOM record 17
  int                   numAltLoc;
  char                  AltLocStr[16]; // Handle only up to 16 different alternative conformation
  AtomElem              elem;   // PDB ATOM record 77-78
  float                 occup,b,q,vdw;          /* atom properties */
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
  int                   contact_flag;   // new field Nov-2009
  int                   icell,isym;     // new field Feb-2011, to identify which cell and AU the 2nd vertex is relatively to the 1st vertex, default is 555,000
//int                   rcell,rsym;     // new field Feb-2011, to identify which cell and AU the 1st vertex is relatively to the 2nd vertex, default is 555,000
  double                distance;
  Vector3f              direction;      // new field Feb-2011, the direction of the vector, (x2,y2,z2)-(x1,y1,z1)
  double                bfactor_correlation;    // if B1>B2, (B1-B2)*(B1/B2), or vice versa
} ObjNeighborInfo;

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
  ObjResidueInfo        *ri_lig;
  ObjResidueInfo        *ri_ion;
  ObjAtomInfo           *ai_lig;
  ObjAtomInfo           *ai_ion;
  int                   valid;
  float                 valid_lig_occup;
  double                bondvalence, calcium_bondvalence;
  Vector3f              direction;
  Vector3f              bv_direction;
  double                bv_direction_len;
  int                   bidentate;      // indicate if it belongs to amino acid side chain bidentate
} ObjIonBondValenceInfo;

typedef struct ObjBidentateInfo {
  ObjIonBondValenceInfo*bv1;
  ObjIonBondValenceInfo*bv2;
  double                distance;
  double                bondvalence, calcium_bondvalence;
  Vector3f              bv_direction;
} ObjBidentateInfo;

typedef struct ObjIonBindingSiteInfo {
  int                   index;
  int                   residueid_ion;
  int                   atomid_ion;
  float                 bfactor_env_avg;
  float                 occupancy_env_avg;
  int                   coord_number_3a,       coord_number_geom,         coord_number_4a;
  float                 rmsd_geom_angle;
  int                   rmsd_geom_weight;
  int                   geometry_type,         geometry_bidentate,        geometry_pseudo,       geometry_distort;
  int                   num_oxygen,            num_nitrogen,              num_sulfur;
  int                   num_phosphorus,        num_carbon,                num_others;
  int                   num04_oxygen_mc,       num08_oxygen_amide,        num10_oxygen_carboxyl, num17_oxygen_hydroxyl,
                        num18_oxygen_phenol,   num26_oxygen_dnarna,       num28_oxygen_water,    num31_oxygen_others;
  int                   num01_nitrogen_mc,     num07_nitrogen_arginine,   num09_nitrogen_amide,  num13_nitrogen_histidine,
                        num14_nitrogen_lysine, num15_nitrogen_tryptophan, num25_nitrogen_dnarna, num30_nitrogen_others;
  int                   num11_sulfur_cysteine, num16_sulfur_methionine,   num33_sulfur_others,
                        num19_selenium,        num41_others;
  int                   num_bidentate_all,     num_bidentate_oo,          num_bidentate_on,      num_bidentate_nn;
  float                 distance_avg,          distance_min,              distance_max;
  int                   num_metal_4a;
  double                valence_3a,            vecsum_3a,                 calcium_valence_3a,    calcium_vecsum_3a;
  double                valence_4a,            vecsum_4a,                 calcium_valence_4a,    calcium_vecsum_4a;
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
  int                   numAngle;
  int                   numIonBondValence;
  int                   numIonBindingSite;      // new field Aug-2010
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
  ObjAngleInfo          *AngleInfo;
  ObjIonBondValenceInfo *IonBondValenceInfo;
  ObjIonBindingSiteInfo *IonBindingSiteInfo;    // new field Aug-2010
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
void ObjMoleculeInit(ObjMoleculeInfo *mi);
void ObjDomainInit(ObjDomainInfo *di);
void ObjResidueInit(ObjResidueInfo *ri);
void ObjResidueAssignAltLoc(ObjResidueInfo *ri);
void ObjResidueAssignType(ObjResidueInfo *ri, ResidueDict *aminoacid_dictionary);
void EntityMoleculeAssignType(ObjEntityMolecule *I);
void EntityMoleculeAssignCenterDisplacement(ObjEntityMolecule *I);
void EntityMoleculeReadCIFStr(ObjEntityMolecule *I, char *buffer, ResidueDict *aminoacid_dictionary);
void EntityMoleculeReadPDBStr(ObjEntityMolecule *I, char *buffer, ResidueDict *aminoacid_dictionary);
void EntityMoleculeReadClusterStr(ObjEntityMolecule *I, char *buffer);
void EntityMoleculeReadAssemblyStr(ObjEntityMolecule *I, char *buffer_buheader, char *data_dir);
void EntityMoleculeReadAssemblyStrOld(ObjEntityMolecule *I, char *buffer_surface, char *data_dir);
void EntityAssemblyReadSurfaceStr(ObjAssemblyInfo *assi, char *buffer, int assCount, ObjEntityMolecule *I);
int  EntityAssemblyReadSurfaceStrOld(ObjAssemblyInfo *assi, char *buffer, int assCount, int cavityCountPrev, ObjEntityMolecule *I);
void EntityMoleculeGenerateCenter(ObjEntityMolecule *I);
void EntityMoleculeNeighbor(ObjEntityMolecule *I, float cutoff, char *buffer_contact);
void EntityMoleculeLigandAngle(ObjEntityMolecule *I, float cutoff);
int  EntityMoleculeNeighborPrint(FILE *fout, ObjEntityMolecule *I, int isAtomNeighbor);
int  EntityMoleculeAnglePrint(FILE *fout, ObjEntityMolecule *I);
int  EntityMoleculeBondValencePrint(FILE *fout, ObjEntityMolecule *I, int isWater);
void EntityMoleculeIonBondValenceAdd(ObjEntityMolecule *I, int bondvalenceid, ObjNeighborInfo *ni, int reverse, ObjAtomInfo *ai1, ObjAtomInfo *ai2, double bondvalence, double calcium_bondvalence, float* bv_direction);
int  ObjIonBondValenceCopy(ObjIonBondValenceInfo *ibvi, ObjIonBondValenceInfo *ibvj);
static int ObjIonBondValenceIonAICmp(const void *p1, const void *p2);     // Procedure used for qsort of ion atom ID
static int ObjIonBondValenceValidCmp(const void *p1, const void *p2);     // Procedure used for qsort of valid ligands
static int ObjIonBondValenceLigRICmp(const void *p1, const void *p2);     // Procedure used for qsort of ligand residue ID
static int doublecmp (const void *p1, const void *p2);
int  ObjIonBindingSiteBidentate(ObjIonBindingSiteInfo *ibsi, ObjIonBondValenceInfo *bv_info, int bv_count, ObjBidentateInfo *arr_bidentate, int cnt_bidentate);
int  ObjBidentateAdd(ObjBidentateInfo *arr_bidentate, int cnt_bidentate, int ind_bidentate, ObjIonBondValenceInfo *ibvi1, ObjIonBondValenceInfo *ibvi2, double distance);
int  ObjIonBindingSiteGeometry(ObjIonBindingSiteInfo *ibsi, ObjIonBondValenceInfo *bv_info, int bv_count, int geometry_bidentate);
void ObjIonBindingSitePrint(FILE *fout, ObjIonBindingSiteInfo *ibsi, ObjIonBondValenceInfo *bv_info, int bv_count_redundant, int pdbfileid);
int  EntityMoleculeIonBindingSitePrint(FILE *fout, ObjEntityMolecule *I);
void EntityMoleculeReport(ObjEntityMolecule *I, float cutoff, char *temp_dir);

#endif
