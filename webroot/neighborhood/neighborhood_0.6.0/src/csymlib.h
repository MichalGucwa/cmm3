#ifndef __CSymLib__
#define __CSymLib__

#include "util.h"

#define SymopNumLen             3
#define SymopStrLen             255
#define SpaceGroupNameLen       20
typedef char SymopNum[SymopNumLen+1];
typedef char SymopStr[SymopStrLen+1];
typedef char SGrpName[SpaceGroupNameLen+1];

typedef struct SymopDict {
  int           symop_id;
  SymopNum      symop_num;
  SymopStr      symop_str;
} SymopDict;

typedef struct ccp4_symop_
{
  float rot[3][3];
  float trn[3];
} ccp4_symop;

typedef struct ccp4_spacegroup_
{
  int spg_num;            /* true spacegroup number */
  int spg_ccp4_num;       /* CCP4 spacegroup number */
  char symbol_Hall[40];   /* Hall symbol */
  SGrpName symbol_xHM;    /* Extended Hermann Mauguin symbol  */
  SGrpName symbol_old;    /* old spacegroup name */

  SGrpName point_group;   /* point group name */
  SGrpName crystal;       /* crystal system */

  int nlaue;              /* CCP4 Laue class number, inferred from asu_descr */
  SGrpName laue_name;     /* Laue class name */
  int laue_sampling[3];   /* sampling factors for FFT */

  int npatt;              /* Patterson spacegroup number, inferred from asu_descr */
  char patt_name[40];     /* Patterson spacegroup name */

  int nsymop;             /* total number of symmetry operations */
  int nsymop_prim;        /* number of primitive symmetry operations */
  ccp4_symop *symop;      /* symmetry matrices */
  ccp4_symop *invsymop;   /* inverse symmetry matrices */

  float chb[3][3];        /* change of basis matrix from file */

  char asu_descr[80];     /* asu description from file */
  int (*asufn)(const int, const int, const int); /* pointer to ASU function */

  int centrics[12];       /* symop which generates centric zone, 0 if none */
  int epsilon[13];        /* flag which epsilon zones are applicable */

  char mapasu_zero_descr[80];  /* origin-based map asu: description from file */
  float mapasu_zero[3];   /* origin-based map asu: upper limits */

  char mapasu_ccp4_descr[80];  /* CCP4 map asu: defaults to mapasu_zero */
  float mapasu_ccp4[3];   /* CCP4 map asu: upper limits */

} CCP4SPG;


/** Look up spacegroup in standard setting by number, and load properties.
 * Allocates memory for the spacegroup structure. This can be freed
 * later by ccp4spg_free().
 * @param numspg spacegroup number
 * @return pointer to spacegroup
 */
CCP4SPG *ccp4spg_load_by_standard_num(const int numspg); 

/** Look up spacegroup by CCP4 number, and load properties.
 * Allocates memory for the spacegroup structure. This can be freed
 * later by ccp4spg_free().
 * @param ccp4numspg CCP4 spacegroup number
 * @return pointer to spacegroup
 */
CCP4SPG *ccp4spg_load_by_ccp4_num(const int ccp4numspg); 

/** Look up spacegroup by the extended Hermann Mauguin symbol.
 * Allocates memory for the spacegroup structure. This can be freed
 * later by ccp4spg_free().
 * @param spgname Spacegroup name in form of extended Hermann Mauguin symbol.
 * @return pointer to spacegroup
 */
CCP4SPG *ccp4spg_load_by_spgname(const char *spgname);

/** Look up spacegroup by name. This is for use by CCP4 programs
 * and is more complicated than ccp4spg_load_by_spgname. For each
 * spacegroup in syminfo.lib it checks the CCP4 spacegroup name
 * first, and then the extended Hermann Mauguin symbol.
 * Allocates memory for the spacegroup structure. This can be freed
 * later by ccp4spg_free().
 * @param ccp4spgname Spacegroup name.
 * @return pointer to spacegroup
 */
CCP4SPG *ccp4spg_load_by_ccp4_spgname(const char *ccp4spgname);

/** Look up spacegroup by symmetry operators and load properties.
 * Allocates memory for the spacegroup structure. This can be freed
 * later by ccp4spg_free().
 * @param nsym1 number of operators (including non-primitive)
 * @param op1 pointer to array of operators
 * @return pointer to spacegroup
 */
CCP4SPG * ccp4_spgrp_reverse_lookup(const int nsym1, const ccp4_symop *op1);

/** Look up spacegroup from SYMOP.
 *  This would not normally be called directly, but via one of
 *  the wrapping functions. 
 *  Allocates memory for the spacegroup structure. This can be freed
 *  later by ccp4spg_free().
 * @param numspg spacegroup number
 * @param ccp4numspg CCP4 spacegroup number
 * @param spgname Spacegroup name.
 * @param ccp4spgname Spacegroup name.
 * @param nsym1 number of operators (including non-primitive)
 * @param op1 pointer to array of operators
 * @return pointer to spacegroup
 */
CCP4SPG *ccp4spg_load_spacegroup(const int numspg, const int ccp4numspg,
        const char *spgname, const char *ccp4spgname, 
        const int nsym1, const ccp4_symop *op1); 

/* error defs */
#define  CPARSERR_Ok                  0
#define  CPARSERR_MaxTokExceeded      1
#define  CPARSERR_AllocFail           2
#define  CPARSERR_NullPointer         3
#define  CPARSERR_LongLine            4
#define  CPARSERR_CantOpenFile        5
#define  CPARSERR_NoName              6
#define  CPARSERR_ExpOverflow         7
#define  CPARSERR_ExpUnderflow        8
#define  CPARSERR_MatToSymop          9
#define  CPARSERR_SymopToMat         10

/* error defs */
#define  CSYMERR_Ok                  0
#define  CSYMERR_ParserFail          1
#define  CSYMERR_NoSyminfoFile       2
#define  CSYMERR_NullSpacegroup      3
#define  CSYMERR_NoAsuDefined        4
#define  CSYMERR_NoLaueCodeDefined   5
#define  CSYMERR_SyminfoTokensMissing 6

/** Call error reporting function according to
 * different error number
 */
void ccp4spg_error(int error_number, char* error_info);

/** Free memory associated with spacegroup.
 * @param sp pointer to spacegroup
 */
void ccp4spg_free(CCP4SPG **sp);

/** Load Laue data into spacegroup structure.
 * @param nlaue CCP4 code for Laue group
 * @param spacegroup Pointer to CCP4 spacegroup structure
 * @return 0 on success, 1 on failure to load Laue data
 */
int ccp4spg_load_patt(CCP4SPG* spacegroup, const int nlaue);
int ccp4spg_load_laue(CCP4SPG* spacegroup, const int nlaue);

/** Test if reflection is in asu of Laue group 1bar.
 * @return 1 if in asu else 0
 */
int ASU_1b   (const int h, const int k, const int l);
int ASU_2_m  (const int h, const int k, const int l);
int ASU_mmm  (const int h, const int k, const int l);
int ASU_4_m  (const int h, const int k, const int l);
int ASU_4_mmm(const int h, const int k, const int l);
int ASU_3b   (const int h, const int k, const int l);
int ASU_3bm  (const int h, const int k, const int l);
int ASU_3bmx (const int h, const int k, const int l);
int ASU_6_m  (const int h, const int k, const int l);
int ASU_6_mmm(const int h, const int k, const int l);
int ASU_m3b  (const int h, const int k, const int l);
int ASU_m3bm (const int h, const int k, const int l);

/** Function to return Hall symbol for spacegroup.
 * @param sp pointer to spacegroup
 * @return pointer to Hall symbol for spacegroup
 */
char *ccp4spg_symbol_Hall(CCP4SPG* sp);

/** inverts a symmetry operator. The input operator is
 * converted to a 4 x 4 matrix, inverted, and converted back.
 * @param ccp4_symop input symmetry operator
 * @return inverted symmetry operator
 */
ccp4_symop ccp4_symop_invert( const ccp4_symop op1 );

/** Compare two spacegroup names. Strings are converted to upper
 * case before making the comparison, but otherwise match must be
 * exact.
 * @param spgname1 First spacegroup name.
 * @param spgname2 Second spacegroup name.
 * @return 1 if they are equal else 0.
*/
int ccp4spg_name_equal(const char *spgname1, const char *spgname2);

/** Try to match a spacegroup name to one from SYMINFO. Blanks are 
 * removed when making the comparison. Strings are converted to upper
 * case before making the comparison. If spgname_lib has " 1 " and 
 * spgname_match doesn't, then strip out " 1" to do "short" comparison.
 * @param spgname1 First spacegroup name, assumed to be a standard one
 *  obtained at some point from SYMINFO
 * @param spgname2 Second spacegroup name that you are trying to match
 *  to a standard SYMINFO one. E.g. it might have been provided by the
 *  user.
 * @return 1 if they are equal else 0.
*/
int ccp4spg_name_equal_to_lib(const char *spgname_lib, const char *spgname_match);

/** Function to create "short" name of spacegroup. Blanks
 * are removed, as are " 1" elements (except for the special case
 * of "P 1").
 * @param shortname String long enough to hold short name.
 * @param longname Long version of spacegroup name.
 * @return Pointer to shortname.
*/
char *ccp4spg_to_shortname(char *shortname, const char *longname);

/** Function to deal with colon-specified spacegroup settings.
 * E.g. 'R 3 :H' is converted to 'H 3   '. Note that spaces are
 * returned and should be dealt with by the calling function.
 * @param name Spacegroup name.
 * @return void
*/
void ccp4spg_name_de_colon(char *name);

/** Compare two point group names. Blanks are removed when
 * making the comparison. Strings are converted to upper
 * case before making the comparison. Any initial "PG" is ignored.
 * @param pgname1 First point group name.
 * @param pgname2 Second point group name.
 * @return 1 if they are equal else 0.
*/
int ccp4spg_pgname_equal(const char *pgname1, const char *pgname2);

/** Function to normalise translations of a symmetry operator,
 * i.e. to ensure 0.0 <= op.trn[i] < 1.0.
 * @param op pointer to symmetry operator.
 * @return Pointer to normalised symmetry operator.
*/
ccp4_symop *ccp4spg_norm_trans(ccp4_symop *op);

/** Sort and compare two symmetry operator lists.
 * Kevin's code. The lists are coded as ints, which are then sorted and compared.
 * Note that no changes are made to the input operators, so that operators
 * differing by an integral number of unit cell translations are considered
 * unequal. If this is not what you want, normalise the operators with 
 * ccp4spg_norm_trans first.
 * @param nsym1 number of symmetry operators in first list
 * @param op1 first list of symmetry operators
 * @param nsym2 number of symmetry operators in second list
 * @param op2 second list of symmetry operators
 * @return 1 if they are equal else 0.
*/
int ccp4_spgrp_equal( int nsym1, const ccp4_symop *op1, int nsym2, const ccp4_symop *op2);

/** Compare two symmetry operator lists.
 * Kevin's code. The lists are coded as ints, which are compared.
 * Unlike ccp4_spgrp_equal, the lists are not sorted, so the same operators
 * in a different order will be considered unequal.
 * @param nsym1 number of symmetry operators in first list
 * @param op1 first list of symmetry operators
 * @param nsym2 number of symmetry operators in second list
 * @param op2 second list of symmetry operators
 * @return 1 if they are equal else 0.
*/
int ccp4_spgrp_equal_order( int nsym1, const ccp4_symop *op1, int nsym2, const ccp4_symop *op2);

/** Make an integer coding of a symmetry operator.
 * The coding takes 30 bits: 18 for the rotation and 12 for the translation.
 * @param op symmetry operator
 * @return int code.
 */
int ccp4_symop_code(ccp4_symop op);

/** Comparison of symmetry operators encoded as integers.
 * In ccp4_spgrp_equal, this is passed to the stdlib qsort.
 * @param p1 pointer to first integer
 * @param p1 pointer to second integer
 * @return difference between integers
*/
int ccp4_int_compare( const void *p1, const void *p2 );

/** Set up centric zones for a given spacegroup. This is called
 * upon loading a spacegroup.
 * @param sp pointer to spacegroup
 * @return void
 */
void ccp4spg_set_centric_zones(CCP4SPG* sp);

/** Set up epsilon zones for a given spacegroup. This is called
 * upon loading a spacegroup.
 * @param sp pointer to spacegroup
 * @return void
 */
void ccp4spg_set_epsilon_zones(CCP4SPG* sp);

/** Convert string of type 0<=y<=1/4 to 0.0-delta, 0.25+delta, where
 * delta is set to 0.00001 Makes many assumptions about string.
 * @param range input string.
 * @param limits output range limits.
 * @return 0 on success
 */
int range_to_limits(const char *range, float limits[2]);

/** Convert symmetry operator as string to ccp4_symop struct.
 * @param symchs_begin pointer to beginning of string
 * @param symchs_end pointer to end of string (i.e. last character
 *   is *(symchs_end-1) )
 * @return pointer to ccp4_symop struct
 */
ccp4_symop symop_to_rotandtrn(const char *symchs_begin, const char *symchs_end);

/** Convert symmetry operator as string to matrix.
 * This is Charles' version of symfr. Note that translations
 * are held in elements [*][3] and [3][3] is set to 1.0
 * @param symchs_begin pointer to beginning of string
 * @param symchs_end pointer to end of string (i.e. last character
 *   is *(symchs_end-1) )
 * @param rot 4 x 4 matrix operator
 * @return  NULL on error, final position pointer on success
 */
const char * symop_to_mat4(const char *symchs_begin, const char *symchs_end, float *rot);
int symop_to_mat4_err(const char *symop);
ccp4_symop mat4_to_rotandtrn(const float rsm[4][4]);
/* This is Charles' version of symtr */
char *rotandtrn_to_symop(char *symchs_begin, char *symchs_end, const ccp4_symop symop);
void rotandtrn_to_mat4(float rsm[4][4], const ccp4_symop symop);

/** Convert symmetry operator as matrix to string.
 * This is Charles' version of symtr. Note that translations
 * are held in elements [*][3] and [3][3] is set to 1.0
 * @param symchs_begin pointer to beginning of string
 * @param symchs_end pointer to end of string (i.e. last character
 *   is *(symchs_end-1) )
 * @param rsm 4 x 4 matrix operator
 * @return pointer to beginning of string
 */
char *mat4_to_symop(char *symchs_begin, char *symchs_end, const float rsm[4][4]);

/** Convert symmetry operator as matrix to string in reciprocal space notation.
 * This is Charles' version of symtr. Note that translations
 * are held in elements [*][3] and [3][3] is set to 1.0
 * @param symchs_begin pointer to beginning of string
 * @param symchs_end pointer to end of string (i.e. last character
 *   is *(symchs_end-1) )
 * @param rsm 4 x 4 matrix operator
 * @return pointer to beginning of string
 */
char *mat4_to_recip_symop(char *symchs_begin, char *symchs_end, const float rsm[4][4]);

#endif
