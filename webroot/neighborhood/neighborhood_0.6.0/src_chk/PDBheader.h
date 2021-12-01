#ifndef __PDBheader__
#define __PDBheader__

#include "util.h"
#include "csymlib.h"
#include "main.h"

/* Procedures that take care of the following fields in pdbfile table */
/*
    space_group_name    char(20),               // space group name from CRYST1 record (probably Extended Hermann Mauguin symbol)
    space_group_number  smallint,               // spacegroup number for Extended Hermann Mauguin symbol
    resolution          real,                   // resolution of the structure
    exp_method          smallint,               // number coded experimental method, 1 for XRAY, 2 for NMR
    deposition_date     date,                   // date of PDB structure deposition
    organism_id         smallint,               // organism from taxonomy database
    ec_primary          smallint,               // EC number top and second level, for primary component
    ec_3rd_level        smallint,               // EC number 3rd level for primary component
    ec_4th_level        smallint,               // EC number 4rd level for primary component
    ec_complex          smallint,               // This field will be set only if the PDB entry is a complex
    header              char(20),               // text field describing enzyme function
    title               text,                   // text description of the PDB structure
    cath_primary        smallint,               // CATH db protein class and architecture, for primary component
    cath_topology       smallint,               // CATH db protein topology
    cath_superfamily    smallint,               // CATH db protein homologous superfamily
*/

/* I. space_group_name, space_group_number: refer to csymlib.h for definition and procedures */

/* II. resolution, exp_method, deposition_date */
#define EXP_METHOD_UNDEF      0
#define EXP_METHOD_XRAY       1 // 59479
#define EXP_METHOD_NMR        2 //  8626
#define EXP_METHOD_ELEMICRO   3 //   335
#define EXP_METHOD_FIBERDIFF  4 //    37
#define EXP_METHOD_SOLSCAT    5 //    32
#define EXP_METHOD_NEUDIFF    6 //    30
#define EXP_METHOD_POWDERDIFF 7 //    18
#define EXP_METHOD_FTIR       8 //     4
#define EXP_METHOD_ELEDIFF    9 //     0
#define EXP_METHOD_ELETOMO   10 //     0
#define EXP_METHOD_FLUTR     11 //     0
#define EXP_METHOD_THEOMODEL 12 //     0
#define EXP_METHOD_MAX       13

/* III. organism_id */
/* primary source: ORGANISM_TAXID      field from SOURCE card */
/* second source:  ORGANISM_SCIENTIFIC field from SOURCE card */

/* IV. EC number, header, title: The procedures here may try to guess EC number from header, if not directly available */
/* primary source: EC field from COMPND card */
/* second source:           from HEADER card */
/* ec_primary will store the enzyme code for major component, while ec_complex will be NULL unless it is a complex,
 * which contains another protein, another DNA/RNA, or another small molecule ligand
 * ec_primary should choose a number between 100-899 whenever possible,
 * only if when information is vague, choose ec_primary number <100 or >=900
 * ec_complex could indicate the second component of the complex, or in cases when information is vague, the type of complex
 * ec_complex should normally be <100 or >=900
 * if ec_complex happened to be between 100-899, it should always satisfy the condition that ec_primary<=ec_complex
 * when choose a ec_primary >=900, ec_complex should be the same as ec_primary */
#define EC_000_UNKNOWN                    0     // STRUCTURAL GENOMICS, UNKNOWN FUNCTION, HYPOTHETICAL PROTEIN
#define EC_001_DE_NOVO                    1     // DE NOVO PROTEIN
#define EC_002_BIOSYNTHETIC               2     // BIOSYNTHETIC PROTEIN
#define EC_003_PLANT_PROTEIN              3     // PLANT PROTEIN
#define EC_007_GLYCOPROTEIN               7
#define EC_008_LIPOPROTEIN                8
#define EC_070_BINDING_LIGAND            70
#define EC_071_BINDING_METAL             71
#define EC_072_BINDING_OXYGEN            72
#define EC_073_BINDING_CALCIUM           73
#define EC_076_BINDING_COFACTOR          76     // BIOTIN BINDING PROTEIN
#define EC_077_BINDING_BIOTIN            77
#define EC_080_BINDING_POLYMER           80
#define EC_081_BINDING_PEPTIDE           81
#define EC_082_BINDING_PROTEIN           82     // ACTIN-BINDING PROTEIN
#define EC_083_BINDING_NUCLEOTIDE        83
#define EC_084_BINDING_DNA               84
#define EC_085_BINDING_RNA               85
#define EC_086_BINDING_SUGAR             86     // SUGAR BINDING, LECTIN, CARBOHYDRATE-BINDING MODULE, AGGLUTININ, CARBOHYDRATE-BINDING PROTEIN
#define EC_087_BINDING_LIPID             87
#define EC_088_BINDING_PERIPLASMIC       88
#define EC_089_MEMBRANE                  89     // MEMBRANE PROTEIN, TRANSMEMBRANE PROTEIN, OUTER MEMBRANE PROTEIN
#define EC_090_NUCLEIC_ACID              90
#define EC_091_DNA                       91
#define EC_092_RNA                       92
#define EC_093_DNA_RNA_HYBRID            93
#define EC_094_SUGAR                     94
#define EC_095_HYALURONIC_ACID           95     // TEXTURE OF CONNECTIVE TISSUE
#define EC_096_LIPID                     96
#define EC_098_MEMBRANE                  98

#define EC_100_OXIDOREDUCTASE           100     // OXIDO-REDUCTASE
#define EC_200_TRANSFERASE              200     // SYNTHASE
#define EC_300_HYDROLASE                300     // CELLULOSE DEGRADATION
#define EC_400_LYASE                    400
#define EC_500_ISOMERASE                500
#define EC_600_LIGASE                   600

#define EC_700_FUNCTIONAL               700
#define EC_701_ENZYME                   701
#define EC_710_TRANSPORT                710     // RETINOL TRANSPORT
#define EC_711_TRANSPORT_METAL          711
#define EC_712_TRANSPORT_ION            712
#define EC_713_TRANSPORT_IRON           713     // IRON STORAGE, IRON TRANSPORT
#define EC_714_TRANSPORT_OXYGEN         714     // OXYGEN STORAGE, OXYGEN TRANSPORT
#define EC_715_TRANSPORT_ELECTRON       715     // ELECTRON TRANSPORT, HEME PROTEIN, ELECTRON TRANSFER
#define EC_716_TRANSPORT_PROTON         716
#define EC_717_TRANSPORT_PROTEIN        717
#define EC_718_TRANSPORT_LIPID          718     // LIPID TRANSPORT, LIPOCALIN
#define EC_719_TRANSPORT_NUCLEAR        719     // NUCLEAR TRANSPORT
#define EC_720_SIGNALING                720     // SIGNAL TRANSDUCTION, SIGNALING PROTEIN, SIGNALLING PROTEIN
#define EC_730_RECEPTOR                 730     // HORMONE, GROWTH_FACTOR, RECEPTOR, HORMONE RECEPTOR
#define EC_731_RECEPTOR_NUCLEAR         731     // NUCLEAR RECEPTOR
#define EC_732_CHEMOTAXIS               732     // CHEMOTAXIS
#define EC_733_PHEROMONE_BINDING        733     // PHEROMONE BINDING PROTEIN
#define EC_736_HORMONE                  736
#define EC_737_CYTOKINE                 737     // CYTOKINE, CHEMOKINE
#define EC_738_GROWTH_FACTOR            738
#define EC_739_NEUROPEPTIDE             739     // NEUROPEPTIDE
#define EC_740_IMMUNE_SYSTEM            740
#define EC_741_IMMUNOGLOBULIN           741     // IMMUNOGLOBULIN, ANTIBODY, CATALYTIC ANTIBODY
#define EC_742_IMMUNOGLOBULIN_BINDING   742     // IMMUNOGLOBULIN-BINDING PROTEIN
#define EC_743_COAGULATION              743     // BLOOD CLOTTING, BLOOD COAGULATION, COAGULATION FACTOR, 
#define EC_746_ANTIGEN                  746     // HISTOCOMPATIBILITY ANTIGEN
#define EC_747_ALLERGEN                 747
#define EC_750_HUMAN_DISEASE            750
#define EC_751_ANTIBIOTIC_RESISTANCE    751     // ANTIBIOTIC RESISTANCE
#define EC_754_ONCOPROTEIN              754     // ONCOGENE PROTEIN
#define EC_755_TOXIN                    755     // TOXIN, NEUROTOXIN, ENTEROTOXIN
#define EC_760_DRUG_DEVELOPMENT         760     // ANTIMICROBIAL PROTEIN
#define EC_761_ANTIBIOTIC               761     // PEPTIDE ANTIBIOTIC, ANTIBIOTIC BIOSYNTHESIS
#define EC_762_ANTIVIRAL                762
#define EC_763_ANTIFUNGAL               763
#define EC_764_ANTITUMOR                764     // ANTI-ONCOGENE
#define EC_770_INHIBITOR                770
#define EC_771_INHIBITOR_OXIDOREDUCTASE 771
#define EC_772_INHIBITOR_TRANSFERASE    772
#define EC_773_INHIBITOR_HYDROLASE      773     // PROTEASE INHIBITOR, SERINE PROTEINASE INHIBITOR, PROTEINASE INHIBITOR
#define EC_774_INHIBITOR_LYASE          774
#define EC_775_INHIBITOR_ISOMERASE      775
#define EC_776_INHIBITOR_LIGASE         776
#define EC_777_INHIBITOR_TRANSPORT      777
#define EC_778_INHIBITOR_SIGNALING      778     // SIGNALING PROTEIN INHIBITOR
#define EC_779_INHIBITOR_CELL_PROCESS   779
#define EC_780_REGULATOR                780
#define EC_781_REGULATOR_OXIDOREDUCTASE 781     // METALLOTHIONEIN
#define EC_782_REGULATOR_TRANSFERASE    782
#define EC_783_REGULATOR_HYDROLASE      783     // HYDROLASE ACTIVATOR
#define EC_784_REGULATOR_LYASE          784
#define EC_785_REGULATOR_ISOMERASE      785
#define EC_786_REGULATOR_LIGASE         786
#define EC_787_REGULATOR_TRANSPORT      787
#define EC_788_REGULATOR_SIGNALING      788
#define EC_789_REGULATOR_CELL_PROCESS   789
#define EC_790_GENE_REGULATION          790
#define EC_791_REPLICATION              791
#define EC_792_REPAIR                   792
#define EC_793_RECOMBINATION            793     // DNA INTEGRATION
#define EC_794_TRANSCRIPTION            794     // TRANSCRIPTION REGULATOR. TRANSCRIPTION ACTIVATOR, TRANSCRIPTION REPRESSOR, TRANSCRIPTION FACTOR, TATA BOX-BINDING PROTEIN (TBP)
#define EC_795_SPLICING                 795     // SPLICING
#define EC_796_TRANSLATION              796     // ELONGATION FACTOR
#define EC_797_CHAPERONE                797
#define EC_798_NUCLEAR_PROTEIN          798

#define EC_800_STRUCTURAL               800
#define EC_801_HELIX_BUNDLE             801     // FOUR HELIX BUNDLE, ALPHA-HELICAL BUNDLE, DESIGNED HELICAL BUNDLE, THREE-HELIX BUNDLE
#define EC_802_LEUCINE_ZIPPER           802     // LEUCINE ZIPPER, LEUCINE ZIPPERS, LEUCINE-RICH REPEATS
#define EC_803_ZINC_FINGER              803     // ZINC FINGER DNA BINDING DOMAIN, ZINC FINGER, ZINC-FINGER PROTEIN
#define EC_808_SH3_DOMAIN               808     // SH3 DOMAIN
#define EC_809_EF_HAND                  809     // EF-HAND PROTEIN
#define EC_810_CELLULAR_PROCESS         810
#define EC_811_ENDOCYTOSIS              811     // PROTEIN TURNOVER, ENDOCYTOSIS
#define EC_812_CELL_CYCLE               812
#define EC_813_CELL_DIVISION            813
#define EC_814_APOPTOSIS                814
#define EC_816_CELL_ADHESION            816     // CELL ADHESION PROTEIN
#define EC_817_CELL_INVASION            817     // CELL INVASION
#define EC_820_CELLULAR_COMPONENT       820
#define EC_821_ANTIFREEZE               821     // ANTIFREEZE PROTEIN
#define EC_822_SURFACE_ACTIVE_PROTEIN   822     // SURFACE ACTIVE PROTEIN
#define EC_823_PLASMA_PROTEIN           823     // PLASMA PROTEIN
#define EC_824_EYE_LENS_PROTEIN         824     // EYE LENS PROTEIN
#define EC_830_CYTOSKELETON             830     // CYTOSKELETON, MOTOR PROTEIN, PROTEIN FIBRIL: collagens, elastins, keratin, actin, and myosin.
#define EC_840_CONTRACTILE              840     // CONTRACTILE PROTEIN, MUSCLE PROTEIN
#define EC_850_FLAVOPROTEIN             850     // FLAVOPROTEIN, FLAVOENZYME
#define EC_851_LUMINESCENCE             851     // LUMINESCENT PROTEIN, FLUORESCENT PROTEIN, LUMINESCENCE
#define EC_852_PHOTOSYNTHESIS           852     // PHOTOSYNTHESIS, PHOTORECEPTOR, PHOTOSYNTHETIC REACTION CENTER
#define EC_853_CIRCADIAN_CLOCK          853     // CIRCADIAN CLOCK PROTEIN
#define EC_860_SPECIAL                  860
#define EC_870_VAULT                    870     // title contains "VAULT"
#define EC_880_PRION                    880     // PRION PROTEIN
#define EC_890_VIRUS                    890     // VIRAL PROTEIN, VIRUS
#define EC_891_MATRIX                   891     // MATRIX PROTEIN

#define EC_900_COMPLEX                  900
#define EC_910_OXIDOREDUCTASE           910
#define EC_920_TRANSFERASE              920
#define EC_930_HYDROLASE                930     // HYDROLASE/HYDROLASE ACTIVATOR
#define EC_940_LYASE                    940
#define EC_950_ISOMERASE                950
#define EC_960_LIGASE                   960
#define EC_970_FUNCTIONAL               970
#define EC_971_TRANSPORT                971
#define EC_972_SIGNALING                972
#define EC_973_RECEPTOR                 973     // CYTOKINE/CYTOKINE RECEPTOR
#define EC_974_IMMUNE_SYETEM            974
#define EC_975_HUMAN_DISEASE            975
#define EC_976_DRUG_DEVELOPMENT         976
#define EC_977_INHIBITOR                977
#define EC_978_REGULATOR                978
#define EC_979_GENE_REGULATION          979
#define EC_980_STRUCTURAL               980     // STRUCTURAL PROTEIN/RNA
#define EC_981_CELLULAR_PROCESS         981
#define EC_982_CELLULAR_COMPONENT       982
#define EC_983_CYTOSKELETON             983
#define EC_984_CONTRACTILE              984
#define EC_985_FLAVOPROTEIN             985
#define EC_986_SPECIAL                  986
#define EC_987_VAULT                    987     // title contains "VAULT", complex
#define EC_988_PRION                    988     // PRION complex
#define EC_989_VIRUS                    989     // VIRUS/RECEPTOR

#define EC_990_PROTEIN_NUCLEIC_ACID     990
#define EC_991_PROTEIN_DNA              991     // PROTEIN/DNA
#define EC_992_PROTEIN_RNA              992
#define EC_993_REPLICATION_DNA          993
#define EC_994_REPAIR_DNA               994
#define EC_995_RECOMBINATION_DNA        995
#define EC_996_TRANSCRIPTION_RNA        996     // TRANSCRIPTION REGULATOR/DNA
#define EC_997_SPLICING_RNA             997
#define EC_998_TRANSLATION_RNA          998
#define EC_999_RIBOSOME                 999     // RIBOSOMAL PROTEIN


/* V. CATH protein class, architecture, topology, homologous superfamily from CATHdb */
#define CATH_0000_UNKNOWN                  0
#define CATH_1010_ORTHOGONAL_BUNDLE     1010
#define CATH_1020_UPDOWN_BUNDLE         1020
#define CATH_1025_ALPHA_HORSESHOE       1025
#define CATH_1040_ALPHA_SOLENOID        1040
#define CATH_1050_ALPHAALPHA_BARREL     1050
#define CATH_2010_RIBBON                2010
#define CATH_2020_SINGLE_SHEET          2020
#define CATH_2030_ROLL                  2030
#define CATH_2040_BETA_BARREL           2040
#define CATH_2050_CLAM                  2050
#define CATH_2060_SANDWICH              2060
#define CATH_2070_DISTORTED_SANDWICH    2070
#define CATH_2080_TREFOIL               2080
#define CATH_2090_ORTHOGONAL_PRISM      2090
#define CATH_2100_ALIGNED_PRISM         2100
#define CATH_2102_3LAYER_SANDWICH       2102
#define CATH_2105_3_PROPELLOR           2105
#define CATH_2110_4_PROPELLOR           2110
#define CATH_2115_5_PROPELLOR           2115
#define CATH_2120_6_PROPELLOR           2120
#define CATH_2130_7_PROPELLOR           2130
#define CATH_2140_8_PROPELLOR           2140
#define CATH_2150_2_SOLENOID            2150
#define CATH_2160_3_SOLENOID            2160
#define CATH_2170_BETA_COMPLEX          2170
#define CATH_3010_ROLL                  3010
#define CATH_3015_SUPER_ROLL            3015
#define CATH_3020_ALPHABETA_BARREL      3020
#define CATH_3030_2LAYER_SANDWICH       3030
#define CATH_3040_3LAYERABA_SANDWICH    3040
#define CATH_3050_3LAYERBBA_SANDWICH    3050
#define CATH_3055_3LAYERBAB_SANDWICH    3055
#define CATH_3060_4LAYER_SANDWICH       3060
#define CATH_3065_ALPHABETA_PRISM       3065
#define CATH_3070_BOX                   3070
#define CATH_3075_5STRANDED_PROPELLER   3075
#define CATH_3080_ALPHABETA_HORSESHOE   3080
#define CATH_3090_ALPHABETA_COMPLEX     3090
#define CATH_3100_RIBOSOME_L15K2        3100
#define CATH_4010_IRREGULAR             4010


void PDBheaderAssignRemark(ObjEntityMolecule *I, char *line, int remark_num);
void PDBheaderAssignTitle (ObjEntityMolecule *I, char *line, int continuation, int isEoS);
void PDBheaderAssignCompnd(ObjEntityMolecule *I, char *line, int continuation, int isEoS);
void PDBheaderAssignSource(ObjEntityMolecule *I, char *line, int continuation, int isEoS);
void PDBheaderAssignKeywds(ObjEntityMolecule *I, char *line, int continuation, int isEoS);
void PDBheaderAssignExpdta(ObjEntityMolecule *I, char *line, int continuation);
void PDBheaderAssignHeader(ObjEntityMolecule *I, char *line);
void PDBheaderAssignOrigx (ObjEntityMolecule *I, char *line, int matrix_row_num);
void PDBheaderAssignScale (ObjEntityMolecule *I, char *line, int matrix_row_num);
void PDBheaderAssignCryst (ObjEntityMolecule *I, char *line, int crystal_num);
void PDBheaderAddKeyword  (ObjEntityMolecule *I, char *word, ObjComponentInfo *comi);
void PDBheaderAddFunction (ObjEntityMolecule *I, char *word, ObjComponentInfo *comi);
void PDBheaderFinishTouch (ObjEntityMolecule *I);


#endif
