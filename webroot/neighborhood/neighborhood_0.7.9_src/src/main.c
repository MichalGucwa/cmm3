#include "main.h"
#include "AtomInfo.h"
#include "Hash.h"
#include "csymlib.h"
#include "PDBheader.h"

char* contact_pdb_buffer_str;

/*---------------------------------------------------------------------------*/
int ReadAminoAcidDictionary(ResidueDict *aminoacid_dictionary, char *file_aadict) {
  FILE *f;
  char* buffer=NULL;
  char *p;
  ResidueName nsa,aa;
  int rt,last_record=0;

  f=fopen(file_aadict,"rb");
  if (!f) { PFatalError("invalid Amino Acid Dictionary file name\n"); };
  buffer=str2cachetextfile(f);
  p=buffer;
  while(*p) {
    p=str2ncpy(aminoacid_dictionary[last_record].nsa,p,3);
    aminoacid_dictionary[last_record].nsa[3]=0;
    p=str2nskip(p,1);
    if     (!strncmp(p,"GLY",3)) rt=RESIDUE_GLY;
    else if(!strncmp(p,"ALA",3)) rt=RESIDUE_ALA;
    else if(!strncmp(p,"VAL",3)) rt=RESIDUE_VAL;
    else if(!strncmp(p,"LEU",3)) rt=RESIDUE_LEU;
    else if(!strncmp(p,"ILE",3)) rt=RESIDUE_ILE;
    else if(!strncmp(p,"SER",3)) rt=RESIDUE_SER;
    else if(!strncmp(p,"THR",3)) rt=RESIDUE_THR;
    else if(!strncmp(p,"CYS",3)) rt=RESIDUE_CYS;
    else if(!strncmp(p,"MET",3)) rt=RESIDUE_MET;
    else if(!strncmp(p,"PRO",3)) rt=RESIDUE_PRO;
    else if(!strncmp(p,"ASP",3)) rt=RESIDUE_ASP;
    else if(!strncmp(p,"ASN",3)) rt=RESIDUE_ASN;
    else if(!strncmp(p,"GLU",3)) rt=RESIDUE_GLU;
    else if(!strncmp(p,"GLN",3)) rt=RESIDUE_GLN;
    else if(!strncmp(p,"LYS",3)) rt=RESIDUE_LYS;
    else if(!strncmp(p,"ARG",3)) rt=RESIDUE_ARG;
    else if(!strncmp(p,"HIS",3)) rt=RESIDUE_HIS;
    else if(!strncmp(p,"PHE",3)) rt=RESIDUE_PHE;
    else if(!strncmp(p,"TYR",3)) rt=RESIDUE_TYR;
    else if(!strncmp(p,"TRP",3)) rt=RESIDUE_TRP;
    else                         rt=RESIDUE_UNDEF;
    p=str2ncpy(aminoacid_dictionary[last_record].aa,p,3);
    aminoacid_dictionary[last_record].aa[3]=0;
    aminoacid_dictionary[last_record].type=rt;
    last_record++;
    p=str2nextline(p);
  }
  aminoacid_dictionary[last_record].nsa[0]=0;
  aminoacid_dictionary[last_record].aa[0]=0;
  aminoacid_dictionary[last_record].type=-1;
  return last_record;   // return the number of records read into the aminoacid_dictionary array
}

/*---------------------------------------------------------------------------*/
ObjEntityMolecule *EntityMoleculeNew() {
  int i;
  OOAlloc(ObjEntityMolecule);
  /* The field filename/pdbid need to be explicitly defined immediately after initiation */
  I->pdbfileid          = 0;
  I->intra_residue_flag = 0;    I->shortest_only_flag = 1;
  I->numAssembly        = 0;    I->numComponent       = 0;
  I->numKeyword         = 0;    I->numChain           = 0;
  I->numMolecule        = 0;    I->numDomain          = 0;
  I->numResidue         = 0;    I->numAtom            = 0;
  I->numResNeighbor     = 0;    I->numAtmNeighbor     = 0;
  I->numNeighborVector  = 0;    I->numMolprobity      = 0;
  I->numAngle           = 0;    I->numWaterBondValence= 0;
  I->numIonBondValence  = 0;    I->numIonBindingSite  = 0;
  I->numIonLigResidue   = 0;    I->numIonLigMoiety    = 0;
  I->numIonLigAtom      = 0;    I->numIonLigNeighbor  = 0;
  I->numIonLigAtomNeighbor=0;   I->numWaterBindingSite= 0;
  /* It is important for this two memory allocation to be autozero */
  I->AssemblyInfo       = NULL; I->ComponentInfo      = NULL;
  I->KeywordInfo        = NULL; I->ChainInfo          = NULL;
  I->MoleculeInfo       = NULL; I->DomainInfo         = NULL;
  I->ResidueInfo        = NULL; I->AtomInfo           = NULL;
  I->ResNeighborInfo    = NULL; I->AtmNeighborInfo    = NULL;
  I->NeighborVectorInfo = NULL; I->MolprobityInfo     = NULL;
  I->AngleInfo          = NULL; I->WaterBondValenceInfo=NULL;
  I->IonBondValenceInfo = NULL; I->IonBindingSiteInfo = NULL;
  I->IonLigResidueInfo  = NULL; I->IonLigMoietyInfo   = NULL;
  I->IonLigAtomInfo     = NULL; I->IonLigNeighborInfo = NULL;
  I->IonLigAtomNeighborInfo=NULL;I->WaterBindingSiteInfo=NULL;
  I->Coord              = NULL;
  VectorClear3f(I->Max);
  VectorClear3f(I->Min);
  VectorClear3f(I->Center);
  /* initialize cell and symmetry info, together with resolution and deposition date */
  I->space_group        = NULL;  I->space_group_name[0]= 0;     I->space_group_number = -1;
  I->cell_a             = -1.0f; I->cell_b             = -1.0f; I->cell_c             = -1.0f;
  I->cell_alpha         = -1.0f; I->cell_beta          = -1.0f; I->cell_gamma         = -1.0f;
  I->z_value            = -1;    I->resolution         = -1;    strcpy(I->deposition_date,"31-DEC-69");
  I->symop_status       = 0;     I->symop              = NULL;  I->nsymop             = 0;
  I->origx_matrix       = NULL;  I->scale_matrix       = NULL;
  I->origx_done         = 0;     I->scale_done         = 0;     I->compnd_done        = 0;
  I->source_done        = 0;     I->compnd_wait        = 0;     I->source_wait        = 0;
  /* initialize functional info and fold info */
  I->exp_method  = EXP_METHOD_UNDEF;  I->header[0]     = 0;     I->title[0]           = 0;
  I->organism_id = -1;
  I->go_process  = -1;                I->go_function   = -1;    I->go_component       = -1;
  I->ec_primary  = EC_000_UNKNOWN;    I->ec_3rd_level  = -1;    I->ec_4th_level       = -1;
  I->ec_complex  = EC_000_UNKNOWN;    I->cluster50_id  = -1;    I->cluster90_id       = -1;
  I->cath_primary= CATH_0000_UNKNOWN; I->cath_topology = -1;    I->cath_superfamily   = -1;
  I->temp_index  = -1;                I->temp_field[0]=0;
  for(i=0;i<TABLE_MAX;i++) {
    I->tables[i]=1;
  }
  return(I);
}

/*---------------------------------------------------------------------------*/
void EntityMoleculeFree(ObjEntityMolecule *I) {
  int i;
  ObjChainInfo *ci;
  ObjResidueInfo *ri;
  ObjAtomInfo *ai;
  FreeP(I->AssemblyInfo);       FreeP(I->ComponentInfo);        FreeP(I->KeywordInfo);
  for(i=0;i<I->numChain;i++){
    ci=I->ChainInfo+i;
    ObjChainFree(ci);
  }
  for(i=0;i<I->numResidue;i++){
    ri=I->ResidueInfo+i;
    FreeP(ri->ResNeighborIndex);
  }
  for(i=0;i<I->numAtom;i++){
    ai=I->AtomInfo+i;
    FreeP(ai->AtmNeighborIndex);
  }
  FreeP(I->ChainInfo);              FreeP(I->MoleculeInfo);         FreeP(I->DomainInfo);
  FreeP(I->ResidueInfo);            FreeP(I->AtomInfo);             FreeP(I->AngleInfo);
  FreeP(I->ResNeighborInfo);        FreeP(I->AtmNeighborInfo);      FreeP(I->NeighborVectorInfo);
  FreeP(I->MolprobityInfo);         FreeP(I->WaterBondValenceInfo); FreeP(I->WaterBindingSiteInfo);
  FreeP(I->IonBondValenceInfo);     FreeP(I->IonBindingSiteInfo);   FreeP(I->IonLigResidueInfo);
  FreeP(I->IonLigMoietyInfo);       FreeP(I->IonLigAtomInfo);       FreeP(I->IonLigNeighborInfo);
  FreeP(I->IonLigAtomNeighborInfo); FreeP(I->Coord);                FreeP(I);
}

/*---------------------------------------------------------------------------*/
void ObjGeneOntologyInit(ObjGeneOntologyInfo *goi, char go_type, int index) {
  goi->index=index;       goi->chain=0;
  goi->go_type=go_type;   goi->go_id=-1;
  goi->qualifier=0;       goi->evidence[0]=0;
  goi->xref_db_name[0]=0; goi->xref_db_id[0]=0;
  goi->organism_id=-1;    goi->created_by[0]=0;
  strcpy(goi->creation_date,"12-31-69");
  goi->ref_db_name='U';   goi->ref_db_id=-1;
}

/*---------------------------------------------------------------------------*/
int ObjGeneOntologyMinimalID(ObjGeneOntologyInfo *goinfo, int numGO) {
  ObjGeneOntologyInfo *goi;
  int i, GOminID=-1;
  for(i=0;i<numGO;i++) {
    goi=goinfo+i;
    if(goi->go_id>=0) {
      if (GOminID<0) GOminID=goi->go_id;
      else if (GOminID>goi->go_id) GOminID=goi->go_id;
    }
  }
  return GOminID;
}

/*---------------------------------------------------------------------------*/
void ObjComponentInit(ObjComponentInfo *comi) {
  comi->index=-1;         comi->componentnum=-1;
  comi->numChain=0;       comi->component_name[0]=0;
  comi->numKeyword=0;     comi->KeywordInfo=NULL;
  comi->numFunction=0;    comi->FunctionInfo=NULL;
  comi->engineered=0;     comi->mutation=0;
  comi->synthetic=0;
  comi->organism_id=-1;   comi->organism_name[0]=0;
  comi->expression_id=-1; comi->expression_name[0]=0;
}

void ObjFunctionInit(ObjFunctionInfo *funi) {
  funi->index=-1;
  funi->ec_primary=-1;
  funi->ec_3rd_level=-1;
  funi->ec_4th_level=-1;
  funi->ComponentInfo=NULL;
}

void ObjKeywordInit(ObjKeywordInfo *keyi) {
  keyi->index=-1;
  keyi->keyword[0]=0;
  keyi->ComponentInfo=NULL;
}

void ObjChainInit(ObjChainInfo *ci) {
  ci->index=-1;           ci->chainid=0;
  ci->assembly_index=-1;  ci->AssemblyInfo=NULL;
  ci->ComponentInfo=NULL;
  ci->numWaterRes=0;      ci->numLigandRes=0;
  ci->numDnarnaRes=0;     ci->numProteinRes=0;
  ci->type2               =CHAIN_TYPE2_UNDEF;
  ci->clusterstatus       =CHAIN_CLUSTER_UNDEF;
  ci->cluster50_id=-1;    ci->represent50_id=-1;
  ci->cluster90_id=-1;    ci->represent90_id=-1;
  ci->numGeneOntology=0;
  ci->numBiolProcess=0;   ci->BiolProcessInfo=NULL;
  ci->numMoleFunction=0;  ci->MoleFunctionInfo=NULL;
  ci->numCellComponent=0; ci->CellComponentInfo=NULL;
  ci->numMolecule=0;      ci->MoleculeInfo=NULL;
  ci->numDomain=0;        ci->numFragment=0;
  ci->DomainInfo=NULL;    ci->numResidue=0;
  ci->numAtom=0;          ci->claimed=0;
  VectorClear3f(ci->Center);
}

void ObjChainFree(ObjChainInfo *ci) {
  FreeP(ci->BiolProcessInfo);
  FreeP(ci->MoleFunctionInfo);
  FreeP(ci->CellComponentInfo);
}

void ObjMoleculeInit(ObjMoleculeInfo *mi) {
  mi->index=-1;         mi->type=COMPONENT_OTHER;
  mi->assembly_index=-1;mi->AssemblyInfo=NULL;
  mi->chain=0;          mi->ChainInfo=NULL;
  mi->numResidue=0;
}

void ObjDomainInit(ObjDomainInfo *di) {
  di->index=-1;            di->chain=0;          di->residueid_begin=-9999;
  di->residueid_end=-9999; di->is_fragment=-1;   di->domainnum=-1;
  di->cath_primary=-1;     di->cath_topology=-1; di->cath_superfamily=-1;
  di->cath_s35=-1;         di->cath_s60=-1;      di->cath_s95=-1;
  di->cath_s100=-1;        di->cath_uniqueid=-1; di->numResidue=0;
}

void ObjResidueInit(ObjResidueInfo *ri) {
  ri->index=-1;                 ri->type=RESIDUE_UNDEF;
  ri->prev_index=-1;            ri->next_index=-1;
  ri->branch_index=-1;          ri->branch2_index=-1;
  ri->prev_atomname[0]=0;       ri->next_atomname[0]=0;
  ri->branch_atomname[0]=0;     ri->branch2_atomname[0]=0;
  ri->assembly_index=-1;        ri->AssemblyInfo=NULL;
  ri->cavity_index=-1;          ri->CavityInfo=NULL;
  ri->chain=0;                  ri->ChainInfo=NULL;
  ri->molecule_index=0;         ri->MoleculeInfo=NULL;
  ri->resn[0]=0;                ri->resi[0]=0;
  ri->resid=-9999;              ri->resi2=0;
  ri->numAtom=0;                ri->isSingle=-1;
  ri->containsMetal=-1;         ri->location=RESIDUE_LOCATE_UNDEF;
  ri->asa=-1;                   ri->msa=-1;
  ri->curvature=0;              ri->AtomInfo=NULL;
  ri->center_displacement=0.0f; ri->frozen=0;
  ri->maxResNeighbor=0;         ri->numResNeighbor=0;
  ri->ResNeighborIndex=NULL;    VectorClear3f(ri->Center);
}

void ObjResidueAssignResname(ObjResidueInfo *ri,char* q) {
  int rescodeFlag;
  rescodeFlag = (q[2]==' ') ? 0 : 1;
  if(q[1]!=' ') rescodeFlag+=2;
  if(q[0]!=' ') rescodeFlag+=4;
  switch(rescodeFlag){              /* a fast way to assign residue 3-letter-code */
    case 0: ri->resn[0]='_';  ri->resn[1]='_';  ri->resn[2]='_';  break;
    case 1: ri->resn[0]='_';  ri->resn[1]='_';  ri->resn[2]=q[2]; break;
    case 2: ri->resn[0]='_';  ri->resn[1]='_';  ri->resn[2]=q[1]; break;
    case 3: ri->resn[0]='_';  ri->resn[1]=q[1]; ri->resn[2]=q[2]; break;
    case 4: ri->resn[0]='_';  ri->resn[1]='_';  ri->resn[2]=q[0]; break;
    case 5: ri->resn[0]='_';  ri->resn[1]=q[0]; ri->resn[2]=q[2]; break;
    case 6: ri->resn[0]='_';  ri->resn[1]=q[0]; ri->resn[2]=q[1]; break;
    case 7: ri->resn[0]=q[0]; ri->resn[1]=q[1]; ri->resn[2]=q[2]; break;
  }
  ri->resn[3]=0;
}

void ObjResidueAssignAltLoc(ObjResidueInfo *ri) {
  int i, j;
  ObjAtomInfo *ai1, *ai2;
  char msg[FileLineLength];
  for(i=0;i<ri->numAtom;i++) {
    ai1=ri->AtomInfo+i;
//  ai1->numAltLoc=1;    // Skip Init here since it was initialized in the main procedure
    for(j=i+1;j<ri->numAtom;j++) {
      ai2=ri->AtomInfo+j;
      if(!strncmp(ai1->realname,ai2->realname,4)) {
        if(ai1->alt==ai2->alt) {
          if(ai1->protons!=AN_H && ai2->protons!=AN_H) {
            // hydrogen are allowed to have the same atomname in the same residue
            // otherwise, an error will be reported is not alternative location is reported
            sprintf(msg,"Alternative atoms (%d(%s)%c-%d(%s)%c) should be assigned different altLoc code\n",
                ai1->id, ai1->realname, ai1->alt, ai2->id, ai2->realname, ai2->alt);
            PFatalError(msg);
          }
        } else {
          ai1->AltLocStr[ai1->numAltLoc]=ai2->alt;
          ai1->numAltLoc++;
          ai2->AltLocStr[ai2->numAltLoc]=ai1->alt;
          ai2->numAltLoc++;
          if (ai1->numAltLoc>=16 || ai2->numAltLoc>=16) PFatalError("Too many alternative location for the same atom (n >= 16)\n");
        }
      }
    }
    ai1->AltLocStr[ai1->numAltLoc]=0;
  }
}

void ObjIonBindingSiteInit(ObjIonBindingSiteInfo *ibsi, ObjAtomInfo *ai_ion) {
  ibsi->residueid_ion   =ai_ion->ResidueInfo->index;
  ibsi->atomid_ion      =ai_ion->index;
  ibsi->bfactor_env_avg =0.0f;  ibsi->occupancy_env_avg =0.0f;
  ibsi->coord_number_3a =0;     ibsi->coord_number_geom =0;
  ibsi->coord_number_4a =0;     ibsi->rmsd_geom_angle   =-1.0f;
  ibsi->rmsd_geom_weight=1;     ibsi->geometry_type     =GEOM_FREE;
  ibsi->geometry_bidentate=-1;  ibsi->geometry_pseudo   =-1;
  ibsi->geometry_distort=1;

  ibsi->num_bidentate_all=0;    ibsi->num_bidentate_oo  =0;
  ibsi->num_bidentate_on=0;     ibsi->num_bidentate_nn  =0;
  ibsi->distance_avg    =0;     ibsi->distance_min      =10.0f;
  ibsi->distance_max    =-1.0f; ibsi->num_metal_4a      =0;
  ibsi->valence_3a      =0.0f;  ibsi->vecsum_3a         =-1.0f;
  ibsi->valence_4a      =0.0f;  ibsi->vecsum_4a         =-1.0f;
  ibsi->bvs_sodium      =0.0f;  ibsi->bvs_magnesium     =0.0f;
  ibsi->bvs_potassium   =0.0f;  ibsi->bvs_calcium       =0.0f;
  ibsi->bvs_manganese   =0.0f;  ibsi->bvs_iron          =0.0f;
  ibsi->bvs_cobalt      =0.0f;  ibsi->bvs_nickel        =0.0f;
  ibsi->bvs_copper      =0.0f;  ibsi->bvs_zinc          =0.0f;

  ibsi->atomid_cluster  =-1;    ibsi->size_cluster      =1;     ibsi->homosize_cluster  =1;
  ibsi->which_metal=ai_ion->protons; ibsi->which_geotype=-1;    ibsi->which_ligtype     =0;
  ibsi->which_XHCXX     =0;     ibsi->which_OOO         =0;     ibsi->which_wOOO2       =0;
  ibsi->which_PPP       =0;     ibsi->which_BNR         =0;     ibsi->which_wBNR2       =0;
  ibsi->which_mBRP2     =0;     ibsi->which_isoform     =-1;    ibsi->which_mobile      =0;
  ibsi->quality_valence =-1.0f; ibsi->quality_complete  =-1.0f; ibsi->quality_experiment=-1.0f;
  ibsi->quality_complete_nw=-1.0f;

  ibsi->num_oxygen      =0;     ibsi->num_nitrogen      =0;     ibsi->num_sulfur        =0;
  ibsi->num_phosphorus  =0;     ibsi->num_carbon        =0;     ibsi->num_others        =0;
  ibsi->n04_o_mc        =0;     ibsi->n08_o_amide       =0;     ibsi->n10_o_carboxyl    =0;
  ibsi->n17_o_hydroxyl  =0;     ibsi->n18_o_phenol      =0;     ibsi->n30_o_base        =0;
  ibsi->n31_o_ribose    =0;     ibsi->n32_op_bridge     =0;     ibsi->n33_op_terminal   =0;
  ibsi->n39_o_water     =0;     ibsi->n43_o_others      =0;
  ibsi->n01_n_mc        =0;     ibsi->n07_n_arginine    =0;     ibsi->n09_n_amide       =0;
  ibsi->n13_n_histidine =0;     ibsi->n14_n_lysine      =0;     ibsi->n15_n_tryptophan  =0;
  ibsi->n27_n_base_ring =0;     ibsi->n28_n_base_ribose =0;     ibsi->n29_n_base_amide  =0;
  ibsi->n42_n_others    =0;     ibsi->n11_s_cysteine    =0;     ibsi->n16_s_methionine  =0;
  ibsi->n45_s_others    =0;     ibsi->n19_selenium      =0;     ibsi->n53_others        =0;
}

/*---------------------------------------------------------------------------*/
void EntityMoleculeReadPDBStr(ObjEntityMolecule *I, char *buffer, ResidueDict *aminoacid_dictionary) {
  int              i,atomFlag,chainFound,numAtom=0;
  int              componentCount,keywordCount,chainCount,molCount,resCount,atomCount,coordCount;
  char             *p,*p2,q[FileLineLength];
  float            *coord=NULL;
  ObjComponentInfo *cpinfo=NULL,*comi;
  ObjKeywordInfo   *kwinfo=NULL,*keyi;
  ObjChainInfo     *chinfo=NULL,*ci,chain;
  ObjResidueInfo   *rsinfo=NULL,*ri,res;
  ObjAtomInfo      *atinfo=NULL,*ai;
  int              headerFlag,continuation,isEoS;
  int              compndCount,sourceCount;

  p=buffer;
  while(*p) {
    if     (!strncmp(p,"ATOM"  ,4)) numAtom++;
    else if(!strncmp(p,"HETATM",6)) numAtom++;
    else if(!strncmp(p,"COMPND",6)) headerFlag=3;       //  8 - 10 continuation,   11 - 80 compound
    else if(!strncmp(p,"SOURCE",6)) headerFlag=4;       //  8 - 10 continuation,   11 - 79 srcName
    else if(!strncmp(p,"ENDMDL",6)) break;
    else if(!strncmp(p,"END"   ,3)) break;
    p=str2nextline(p);
  }
  AllocP(coord, float,        3*(numAtom+1));
  AllocP(cpinfo,ObjComponentInfo,257);   /* Ribosome 50s subunit from E.coli (PDBID: 3OFD) contains only 31 different components */
  AllocP(kwinfo,ObjKeywordInfo,  257);   /* assuming max 257 keywords */
  AllocP(chinfo,ObjChainInfo,    257);   /* Look, chainid is only one char, 257 is for sure enough */
  AllocP(rsinfo,ObjResidueInfo,  (numAtom+1));
  AllocP(atinfo,ObjAtomInfo,     (numAtom+1));
  I->numComponent  = 0;         I->ComponentInfo = cpinfo;
  I->numKeyword    = 0;         I->KeywordInfo   = kwinfo;
  I->numChain      = 0;         I->ChainInfo     = chinfo;
  I->numResidue    = 0;         I->ResidueInfo   = rsinfo;
  I->numAtom       = numAtom;   I->AtomInfo      = atinfo; 
  I->Coord         = coord;

  p=buffer;
  componentCount=0;keywordCount=0;chainCount=0;resCount=0;atomCount=0;coordCount=0;
  comi=cpinfo+componentCount;   ObjComponentInit(comi);
  keyi=kwinfo+keywordCount;     ObjKeywordInit(keyi);
  ci=chinfo+chainCount;         ObjChainInit(ci);
  chain.index=-1;               chain.numResidue=0;     chain.numAtom=0;
//mi=moinfo+molCount;           ObjMoleculeInit(mi);
//mol.index=-1;                 mol.numResidue=0;
  ri=rsinfo+resCount;           ObjResidueInit(ri);
  res.index=-1;                 res.numAtom=0;
  while(*p) {
    if     (!strncmp(p,"ATOM"  ,4)) atomFlag=1;
    else if(!strncmp(p,"HETATM",6)) atomFlag=2;
    else {
      atomFlag=0;
      headerFlag=0;
      if     (!strncmp(p,"REMARK",6)) headerFlag=1;       //  8 - 10 remark type,    11 - 80 remark content
      else if(!strncmp(p,"TITLE ",6)) headerFlag=2;       //  9 - 10 continuation,   11 - 80 title
      else if(!strncmp(p,"COMPND",6)) headerFlag=3;       //  8 - 10 continuation,   11 - 80 compound
      else if(!strncmp(p,"SOURCE",6)) headerFlag=4;       //  8 - 10 continuation,   11 - 79 srcName
      else if(!strncmp(p,"KEYWDS",6)) headerFlag=5;       //  8 - 10 continuation,   11 - 79 srcName
      else if(!strncmp(p,"EXPDTA",6)) headerFlag=6;       //  9 - 10 continuation,   11 - 79 technique
      else if(!strncmp(p,"HEADER",6)) headerFlag=7;       // 11 - 50 classification, 51 - 59 depDate, 63 - 66 idCode
      else if(!strncmp(p,"ORIGX" ,5)) headerFlag=8;       // 11 - 20 On1, 21 - 30 On2, 31 - 40 On3, 46 - 55 Tn
      else if(!strncmp(p,"SCALE" ,5)) headerFlag=9;       // 11 - 20 Sn1, 21 - 30 Sn2, 31 - 40 Sn3, 46 - 55 Un
      else if(!strncmp(p,"CRYST" ,5)) headerFlag=10;      // 7-15a, 16-24b, 25-33c, 34-40alpha, 41-47beta, 48-54gamma, 56-66sGroup 
      else if(!strncmp(p,"ENDMDL",6)) break;
      else if(!strncmp(p,"END"   ,3)) break;
    }
    if(atomFlag) {
      ai=atinfo+atomCount;
      ai->index = atomCount;
      p=str2nskip(p,6);                 /* skip 1-6     "ATOM  " */
      ai->hetatm=(atomFlag==2) ? 1 : 0;
      p=str2ncpy(q,p,5);                /* read 7-11    serial   */
      if(sscanf(q,"%d",&ai->id)!=1) ai->id=0;
      /* atom serial number in the pdbfile */
 
      p=str2nskip(p,1);                 /* skip 12 */
      p=str2ncpy(ai->realname,p,4);     /* read 13-16   name     */
      if(sscanf(ai->realname,"%s",ai->name)!=1) ai->name[0]=0;
      /* atom name, first 2 chars are element name, followed by atom id */
 
      p=str2ncpy(q,p,1);                /* read 17      altLoc   */
      ai->alt=q[0];
      ai->numAltLoc=1;
      ai->AltLocStr[0]=ai->alt;
      ai->AltLocStr[1]=0;
      /* alternate location indicator, used with alternate chain id */
 
      p=str2ncpy(q,p,3);                /* read 18-20   resName  */
      ObjResidueAssignResname(&res,q);
      /* residue name, three letter code */
 
      p=str2nskip(p,1);                 /* skip 21 */
      p=str2ncpy(q,p,1);                /* read 22      chainId  */
      res.chain=q[0];
      chain.chainid=q[0];
      /* chain identifier, preserve original pdb chain ID here  */
 
      p=str2ncpy(q,p,4);                /* read 23-26   resSeq   */
      if(sscanf(q,"%s",res.resi)!=1) res.resi[0]=0;
      if(sscanf(q,"%d",&res.resid)!=1) res.resid=-9999;
      /* residue sequence number , together with residue insertion code */

      p=str2ncpy(q,p,1);                /* read 27      patched residue   */
      res.resi2=q[0];
      /* alternate residue id indicator, used with the main resseq - residue id */
 
      if (chain.chainid!=ci->chainid) {
        ci->numResidue += chain.numResidue;
        chain.numResidue= 0;
        chainFound      =-1;
        if (ci->index!=-1) {
          for(i=0;i<=chainCount;i++){
            ci=chinfo+i;
            if(chain.chainid==ci->chainid) chainFound=i;
          }
          if(chainFound==-1) chainCount++;
        }
        if(chainFound==-1) {
          ci=chinfo+chainCount;
          ObjChainInit(ci);
          ci->index     = chainCount;
          ci->chainid   = chain.chainid;
        } else ci=chinfo+chainFound;
      }
      ci->numAtom++;
      /* handling chain object creation and initiation */

      if (res.chain==ri->chain && res.resid==ri->resid && res.resi2==ri->resi2 && strcmp(res.resn,ri->resn)==0) {
        res.numAtom++;
      } else {
        ri->numAtom     = res.numAtom;
        VectorAverage3f(res.Center, res.numAtom);
        VectorCopy3f(ri->Center, res.Center);
        ObjResidueAssignAltLoc(ri);
        res.numAtom     = 1;
        VectorClear3f(res.Center);
        if (ri->index!=-1) resCount++;
        ri=rsinfo+resCount;
        ObjResidueInit(ri);
        ri->index       = resCount;
        ri->chain       = res.chain;
        ri->ChainInfo   = ci;
        str2ncpy(ri->resn,res.resn,ResidueNameLen);
        str2ncpy(ri->resi,res.resi,ResidueIdLen);
        ri->resid       = res.resid;
        ri->resi2       = res.resi2;
        ri->AtomInfo    = ai;
        ObjResidueAssignType(ri,aminoacid_dictionary);
        chain.numResidue++;
      }
      /* handling residue object creation and initiation */
      ai->residue_index = resCount;
      ai->ResidueInfo   = ri;
      /* establish link between residue information and atom information */

      p=str2nskip(p,3);                 /* skip 28-30 */
      p=str2ncpy(q,p,8);                /* read 31-38   x        */
      sscanf(q,"%f",coord+coordCount);
      p=str2ncpy(q,p,8);                /* read 39-46   y        */
      sscanf(q,"%f",coord+(coordCount+1));
      p=str2ncpy(q,p,8);                /* read 47-54   z        */
      sscanf(q,"%f",coord+(coordCount+2));
      VectorAdd3f(res.Center, (coord+coordCount));
      /* orthogonal coordinates for X,Y,Z in angstroms */
 
      p=str2ncpy(q,p,6);                /* read 55-60   occupancy */
      if(sscanf(q,"%f",&ai->occup)!=1) ai->occup=1.0;
      /* occupancy, default to 1.0 if not recognized */
 
      p=str2ncpy(q,p,6);                /* read 61-66   tempFactor*/
      if(sscanf(q,"%f",&ai->b)!=1) ai->b=0.0;
      /* read the temperature factor B, default to 0.0 if not recognized */
 
      p=str2nskip(p,10);                /* skip 67-72 */
                                        /* skip 73-76   segID    */
      p=str2ncpy(q,p,2);                /* read 77-78   element  */
      if(!isalpha(q[0]) || !isalpha(q[1])) {
        ai->elem[0]=0;
        ai->elem[1]=0;
        if(isalpha(q[0]) && q[1]==' ' && index("CONHSP",q[0])) {
          ai->elem[0]=q[0]; str2ncpy(q,p,2);
          if(isdigit(q[1]) && (isdigit(q[0]) || q[0]==' ')) ai->elem[0]=0;
        }/* prevent PDB misuse */
        if(isalpha(q[1]) && q[0]==' ') ai->elem[0]=q[1];
      } else if(sscanf(q,"%s",ai->elem)!=1) ai->elem[0]=0;
      /* element symbol, right-justified */
 
      p=str2ncpy(q,p,2);                /* read 79-80   charge   */
      q[5]=0;
      if(isdigit(q[0])) {
        if (q[1]=='+' || q[1]=='-') { q[4]=q[1];q[1]=q[0];q[0]=q[4];q[2]=0;q[5]=1;
        } else if (q[1]==' ') { q[1]=0;q[5]=1; }
      } else if(isdigit(q[1])) {
        if(isdigit(q[0]) || q[0]=='+' || q[0]=='-') { q[5]=1;
        } else if (q[0]==' ') { q[0]=q[1];q[1]=0;q[5]=1; }
      }
      if (q[5]==1) { if(sscanf(q,"%f",&ai->q)!=1) ai->q=0.0f;
      } else ai->q=0.0f;
      /* charge on the atom, in PDB specification but not widely used in practice */

      ai->cavity_index  =-1;            ai->CavityInfo=NULL;
      ai->moiety_type   =MOIETY_UNDEF;
      ai->type          =ATOM_UNDEF;
      ai->location      =ATOM_LOCATE_UNDEF;
      ai->asa           =-1;            ai->msa       =-1;
      ai->curvature     =0;             ai->vdw       =0.0f;
      ai->hydrogen      =0;             ai->protons   =0;
      ai->period        =0;             ai->group     =ELEM_GROUP_undef;
      ai->oxidation_state=0;            ai->bv_index  =-1;
      ai->numCovalentBond=0;            ai->isMetal   =-1;
      ai->numAtmNeighbor=0;             ai->AtmNeighborIndex=NULL;
      ai->center_displacement=0.0f;     ai->sigma_2fofc=-1.0f;
      AtomInfoAssignParameters(ai);
      /* Don't forget to do initiation of all other parameters that not yet been initiated yet */
      coordCount+=3;
      atomCount++;
    } else if(headerFlag) {
      p2=str2nextline(p);
      isEoS = strncmp(p2,p,6) ? 1 : 0;
      if (headerFlag <= 6) {
        p=str2nskip(p,7);
        p=str2ncpy(q,p,3);
        if(sscanf(q,"%d",&continuation)!=1) continuation=0;
      } else if (headerFlag >= 8) {
        p=str2nskip(p,5);
        p=str2ncpy(q,p,1);
        if(sscanf(q,"%d",&continuation)!=1) continuation=0;
        if(headerFlag!=10) p=str2nskip(p,4);
      } else {
        p=str2nskip(p,10);
      }
      switch(headerFlag) {
        case 1:  PDBheaderAssignRemark(I,p,continuation);       break;
        case 2:  PDBheaderAssignTitle (I,p,continuation,isEoS); break;
        case 3:  PDBheaderAssignCompnd(I,p,continuation,isEoS); break;
        case 4:  PDBheaderAssignSource(I,p,continuation,isEoS); break;
        case 5:  PDBheaderAssignKeywds(I,p,continuation,isEoS); break;
        case 6:  PDBheaderAssignExpdta(I,p,continuation);       break;
        case 7:  PDBheaderAssignHeader(I,p);                    break;
        case 8:  PDBheaderAssignOrigx (I,p,continuation);       break;
        case 9:  PDBheaderAssignScale (I,p,continuation);       break;
        case 10: PDBheaderAssignCryst (I,p,continuation);       break;
      }
    }
    p=str2nextline(p);
  }
  if(I->scale_matrix==NULL) PDBheaderAssignScale(I,"NULL",-1);
  ai=atinfo+atomCount; ai->index=-1;
  if (ri->index!=-1) {
    ri->numAtom = res.numAtom;
    VectorAverage3f(res.Center, res.numAtom);
    VectorCopy3f(ri->Center, res.Center);
    ObjResidueAssignAltLoc(ri);
    resCount++;
    ri=rsinfo+resCount; ri->index=-1;
    I->numResidue= resCount;
  }
  if (ci->index!=-1) {
    ci->numResidue += chain.numResidue;
    chainCount++;
    ci=chinfo+chainCount; ci->index=-1;
    I->numChain= chainCount;
  }
  EntityMoleculeAssignType(I);
  EntityMoleculeAssignCenterDisplacement(I);
}

/*---------------------------------------------------------------------------*/
void EntityMoleculeReadClusterStr(ObjEntityMolecule *I, char *buffer) {
  int           i,j,chainFlag,chainFound,ecFound,localCount,nonAlnumCount50=0,nonAlnumCount90=0;
  int           numGOProc=0,numGOFunc=0,numGOComp=0;
  int           nd,nf,numDomain=0,numFragment=0,domainCount,domainFound;
  char          *p,q[FileLineLength];
  ObjChainInfo  *ci,*cip,*cid;
  ObjDomainInfo *di;
  ObjComponentInfo    *comi;
  ObjFunctionInfo     *funi;
  ObjGeneOntologyInfo *goi;
  ObjCounter          *cnti;
  p=buffer;
  while(*p) {
    if     (!strncmp(p,"GOPROC ",7)) numGOProc++;
    else if(!strncmp(p,"GOFUNC ",7)) numGOFunc++;
    else if(!strncmp(p,"GOCOMP ",7)) numGOComp++;
    else if(!strncmp(p,"DOMALL ",7)) {
      p=str2nskip(p,10);
      if(sscanf(p,"D%dF%d",&nd,&nf)==2) {
        numDomain+=nd;
        numFragment+=nf;
      } else {
        PFatalError("invalid CLUSTER file format in DOMALL card.\n");
      }
    }
    p=str2nextline(p);
  }
  for(i=0;i<I->numChain;i++){
    ci=I->ChainInfo+i;
    // Simple allocate more than enough space for each individual chain
    AllocP(ci->BiolProcessInfo,ObjGeneOntologyInfo,(numGOProc+1));
    AllocP(ci->MoleFunctionInfo,ObjGeneOntologyInfo,(numGOFunc+1));
    AllocP(ci->CellComponentInfo,ObjGeneOntologyInfo,(numGOComp+1));
  }
  AllocP(I->DomainInfo,ObjDomainInfo,(numDomain+numFragment+1));
  domainCount=0;
  I->numDomain = domainCount;
  di=I->DomainInfo+domainCount;
  ObjDomainInit(di);

  p=buffer;
  while(*p) {
    chainFlag=0;
    if     (!strncmp(p,"GOCOMP ",7)) chainFlag=8;
    else if(!strncmp(p,"GOFUNC ",7)) chainFlag=7;
    else if(!strncmp(p,"GOPROC ",7)) chainFlag=6;
    else if(!strncmp(p,"DOMAIN ",7)) chainFlag=5;
    else if(!strncmp(p,"DOMALL ",7)) chainFlag=4;
    else if(!strncmp(p,"CLUST90",7)) chainFlag=3;
    else if(!strncmp(p,"CLUST50",7)) chainFlag=2;
    else if(!strncmp(p,"SHORT  ",7)) chainFlag=1;
    else if(!strncmp(p,"PDBFILE",7)) {
      p=str2nskip(p,10);
      p=str2ncpy(q,p,10);
      if(sscanf(q,"%d",&I->pdbfileid)!=1) I->pdbfileid=0;
    } else if(!strncmp(p,"NOTABLE",7)) {
      p=str2nskip(p,10);
      p=str2ncpy(q,p,40);       // assume table name is less than 40 chars
      if     (!strncasecmp(q,"NEIGHBORHOOD",                12)) I->tables[TABLE_NEIGHBORHOOD]=0;
      else if(!strncasecmp(q,"USAGES",                       6)) I->tables[TABLE_USAGES]=0;
      else if(!strncasecmp(q,"COMMENTS",                     8)) I->tables[TABLE_COMMENTS]=0;
      else if(!strncasecmp(q,"GENEONTOLOGY_DICTIONARY",     23)) I->tables[TABLE_GENEONTOLOGY_DICTIONARY]=0;
      else if(!strncasecmp(q,"GENEONTOLOGY_RELATIONSHIP",   25)) I->tables[TABLE_GENEONTOLOGY_RELATIONSHIP]=0;
      else if(!strncasecmp(q,"GENEONTOLOGY_REFERENCE",      22)) I->tables[TABLE_GENEONTOLOGY_REFERENCE]=0;
      else if(!strncasecmp(q,"EC_DICTIONARY",               13)) I->tables[TABLE_EC_DICTIONARY]=0;
      else if(!strncasecmp(q,"CATH_DICTIONARY",             15)) I->tables[TABLE_CATH_DICTIONARY]=0;
      else if(!strncasecmp(q,"AMINOACID_DICTIONARY",        20)) I->tables[TABLE_AMINOACID_DICTIONARY]=0;
      else if(!strncasecmp(q,"HETDICTIONARY",               13)) I->tables[TABLE_HETDICTIONARY]=0;
      else if(!strncasecmp(q,"PDBFILES",                     8)) PFatalError("PDBFILES table cannot be turned off");
      else if(!strncasecmp(q,"CCDINFO",                      7)) I->tables[TABLE_CCDINFO]=0;
      else if(!strncasecmp(q,"GENEONTOLOGIES",              14)) I->tables[TABLE_GENEONTOLOGIES]=0;
      else if(!strncasecmp(q,"ASSEMBLIES",                  10)) I->tables[TABLE_ASSEMBLIES]=0;
      else if(!strncasecmp(q,"CAVITIES",                     8)) I->tables[TABLE_CAVITIES]=0;
      else if(!strncasecmp(q,"COMPONENTS",                  10)) I->tables[TABLE_COMPONENTS]=0;
      else if(!strncasecmp(q,"FUNCTIONS",                    9)) I->tables[TABLE_FUNCTIONS]=0;
      else if(!strncasecmp(q,"KEYWORDS",                     8)) I->tables[TABLE_KEYWORDS]=0;
      else if(!strncasecmp(q,"CDHIT_CHAINS",                12)) I->tables[TABLE_CDHIT_CHAINS]=0;
      else if(!strncasecmp(q,"SYMOP_CHAINS",                12)) I->tables[TABLE_SYMOP_CHAINS]=0;
      else if(!strncasecmp(q,"MOLECULES",                    9)) I->tables[TABLE_MOLECULES]=0;
      else if(!strncasecmp(q,"DOMAINS",                      7)) I->tables[TABLE_DOMAINS]=0;
      else if(!strncasecmp(q,"RESIDUES",                     8)) I->tables[TABLE_RESIDUES]=0;
      else if(!strncasecmp(q,"ATOMS",                        5)) I->tables[TABLE_ATOMS]=0;
      else if(!strncasecmp(q,"NEIGHBORS",                    9)) I->tables[TABLE_NEIGHBORS]=0;
      else if(!strncasecmp(q,"ATOMNEIGHBORS",               13)) I->tables[TABLE_ATOMNEIGHBORS]=0;
      else if(!strncasecmp(q,"NEIGHBORVECTORS",             15)) I->tables[TABLE_NEIGHBORVECTORS]=0;
      else if(!strncasecmp(q,"LIGAND_BONDANGLES",           17)) I->tables[TABLE_LIGAND_BONDANGLES]=0;
      else if(!strncasecmp(q,"ION_BONDVALENCES",            16)) I->tables[TABLE_ION_BONDVALENCES]=0;
      else if(!strncasecmp(q,"WATER_BONDVALENCES",          18)) I->tables[TABLE_WATER_BONDVALENCES]=0;
      else if(!strncasecmp(q,"ION_BINDINGSITES",            16)) I->tables[TABLE_ION_BINDINGSITES]=0;
      else if(!strncasecmp(q,"ION_BINDINGSITE_PROFILES",    24)) I->tables[TABLE_ION_BINDINGSITE_PROFILES]=0;
      else if(!strncasecmp(q,"ION_BINDINGSITE_LIGRESIDUES", 27)) I->tables[TABLE_ION_BINDINGSITE_LIGRESIDUES]=0;
      else if(!strncasecmp(q,"ION_BINDINGSITE_LIGMOIETIES", 27)) I->tables[TABLE_ION_BINDINGSITE_LIGMOIETIES]=0;
      else if(!strncasecmp(q,"ION_BINDINGSITE_LIGATOMS",    24)) I->tables[TABLE_ION_BINDINGSITE_LIGATOMS]=0;
      else if(!strncasecmp(q,"ION_BINDINGSITE_LIGNEIGHBORS",28)) I->tables[TABLE_ION_BINDINGSITE_LIGNEIGHBORS]=0;
      else if(!strncasecmp(q,"ION_BINDINGSITE_LIGATOMNEIGHBORS",32)) I->tables[TABLE_ION_BINDINGSITE_LIGATOMNEIGHBORS]=0;
      else if(!strncasecmp(q,"WATER_BINDINGSITES",          18)) I->tables[TABLE_WATER_BINDINGSITES]=0;
    }
    if(chainFlag) {
      p=str2nskip(p,8);
      p=str2ncpy(q,p,1);
      if(q[0]=='_') q[0]=' ';
      chainFound=-1;
      for(i=0;i<I->numChain;i++){
        ci=I->ChainInfo+i;
        if(ci->chainid==q[0]) chainFound=i;
      } /* loop around to find the same chain_id */
      if(chainFound==-1) {
        localCount=0;
        for(i=0;i<I->numChain;i++){
          ci=I->ChainInfo+i;
          if(!isalnum(ci->chainid)) {
            if(chainFlag==3){
              if(localCount==nonAlnumCount90) { if(chainFound==-1) { chainFound=i; nonAlnumCount90++; } } else localCount++;
            }else if(chainFlag==2){
              if(localCount==nonAlnumCount50) { if(chainFound==-1) { chainFound=i; nonAlnumCount50++; } } else localCount++;
            }
          }
        }
      } /* loop around to find the next unclaimed chain_id */
      if(chainFound!=-1) {
        ci=I->ChainInfo+chainFound;
        switch(chainFlag) {
          case 1: ci->clusterstatus=CHAIN_CLUSTER_SHORT;
                  break;
          case 2:
            p=str2nskip(p,1);
            p=str2ncpy(q,p,6);
            if(sscanf(q,"%d",&ci->cluster50_id)!=1) ci->cluster50_id=-1;
            p=str2ncpy(q,p,6);
            if(sscanf(q,"%d",&ci->represent50_id)!=1) ci->represent50_id=-1;
            if(ci->clusterstatus<CHAIN_CLUSTER_CLUSTERED){
              ci->clusterstatus = (ci->represent50_id==1) ? CHAIN_CLUST50_REPRESENT : CHAIN_CLUSTER_CLUSTERED;
            };    break;
          case 3:
            p=str2nskip(p,1);
            p=str2ncpy(q,p,6);
            if(sscanf(q,"%d",&ci->cluster90_id)!=1) ci->cluster90_id=-1;
            p=str2ncpy(q,p,6);
            if(sscanf(q,"%d",&ci->represent90_id)!=1) ci->represent90_id=-1;
            if(ci->clusterstatus<CHAIN_CLUSTER_CLUSTERED){
              ci->clusterstatus = (ci->represent90_id==1) ? CHAIN_CLUST90_REPRESENT : CHAIN_CLUSTER_CLUSTERED;
            };    break;
          case 4:
            p=str2nskip(p,1);
            p=str2ncpy(q,p,6);
            if(sscanf(q,"D%dF%d",&nd,&nf)==2) {
              ci->numDomain=nd;
              ci->numFragment=nf;
              ci->DomainInfo=di;
              for(i=0;i<nd;i++) {
                di->index=domainCount;
                di->chain=ci->chainid;
                di->is_fragment=0;
                domainCount++;
                di=I->DomainInfo+domainCount;
                ObjDomainInit(di);
              }
              for(i=0;i<nf;i++) {
                di->index=domainCount;
                di->chain=ci->chainid;
                di->is_fragment=1;
                domainCount++;
                di=I->DomainInfo+domainCount;
                ObjDomainInit(di);
              }
            }
                  break;
          case 5:
            di=ci->DomainInfo;
            domainFound=0;
            for(i=0;i<ci->numDomain;i++) {
              di=ci->DomainInfo+i;
              if(di->domainnum==-1) {
                domainFound=1;
                break;
              }
            }
            if(domainFound) {
              p=str2nskip(p,1);
              p=str2ncpy(q,p,6); if (sscanf(q,"%d",&di->domainnum)!=1)        di->domainnum=0;
              p=str2ncpy(q,p,6); if (sscanf(q,"%d",&nd)!=1)                   nd=0;
              p=str2ncpy(q,p,6); if (sscanf(q,"%d",&di->cath_primary)!=1)     di->cath_primary=0;
              di->cath_primary+=(nd*1000);
              p=str2ncpy(q,p,6); if (sscanf(q,"%d",&di->cath_topology)!=1)    di->cath_topology=0;
              p=str2ncpy(q,p,6); if (sscanf(q,"%d",&di->cath_superfamily)!=1) di->cath_superfamily=0;
              p=str2ncpy(q,p,6); if (sscanf(q,"%d",&di->cath_s35)!=1)         di->cath_s60=0;
              p=str2ncpy(q,p,6); if (sscanf(q,"%d",&di->cath_s60)!=1)         di->cath_s60=0;
              p=str2ncpy(q,p,6); if (sscanf(q,"%d",&di->cath_s95)!=1)         di->cath_s95=0;
              p=str2ncpy(q,p,6); if (sscanf(q,"%d",&di->cath_s100)!=1)        di->cath_s100=0;
              p=str2ncpy(q,p,6); if (sscanf(q,"%d",&di->cath_uniqueid)!=1)    di->cath_uniqueid=0;
              p=str2ncpy(q,p,6); if (sscanf(q,"%d",&di->numResidue)!=1)       di->numResidue=0;
            } else {
              PFatalError("Cannot locate corresponding DOMALL from DOMAIN card in CLUSTER file.\n");
            }
                  break;
          case 6:
          case 7:
          case 8:
            if     (chainFlag==6) { goi=ci->BiolProcessInfo  +ci->numBiolProcess;   ObjGeneOntologyInit(goi,'P',ci->numBiolProcess);   ci->numBiolProcess++;   }
            else if(chainFlag==7) { goi=ci->MoleFunctionInfo +ci->numMoleFunction;  ObjGeneOntologyInit(goi,'F',ci->numMoleFunction);  ci->numMoleFunction++;  }
            else if(chainFlag==8) { goi=ci->CellComponentInfo+ci->numCellComponent; ObjGeneOntologyInit(goi,'C',ci->numCellComponent); ci->numCellComponent++; }
            goi->chain=ci->chainid;
            p=str2ncpy(q,p,7);   if(sscanf(q,"%d",&goi->go_id)!=1)        goi->go_id=-1;
            p=str2ncpy(q,p,6);   if(sscanf(q,"%d",&goi->qualifier)!=1)    goi->qualifier=0;
            p=str2ncpy(q,p,6);   if(sscanf(q,"%s",goi->evidence)!=1)      goi->evidence[0]=0;
            p=str2ncpy(q,p,12);  if(sscanf(q,"%s",goi->xref_db_name)!=1)  goi->xref_db_name[0]=0;
            p=str2ncpy(q,p,18);  if(sscanf(q,"%s",goi->xref_db_id)!=1)    goi->xref_db_id[0]=0;
            p=str2ncpy(q,p,9);   if(sscanf(q,"%d",&goi->organism_id)!=1)  goi->organism_id=-1;
            p=str2ncpy(q,p,9);   if(sscanf(q,"%s",goi->creation_date)!=1) goi->creation_date[0]=0;
            p=str2ncpy(q,p,18);  if(sscanf(q,"%s",goi->created_by)!=1)    goi->created_by[0]=0;
            p=str2ccpy(q,p,':'); if     (!strncasecmp(q,"GO_REF",6))      goi->ref_db_name='G';
                                 else if(!strncasecmp(q,"PMID",  4))      goi->ref_db_name='P';
                                 else if(!strncasecmp(q,"DOI",   3))      goi->ref_db_name='D';
                                 if(goi->ref_db_name=='G' || goi->ref_db_name=='P') {
            p=str2ncpy(q,p,30);  if(sscanf(q,"%d",&goi->ref_db_id)!=1)    goi->ref_db_id=-1;
                                 } else if(goi->ref_db_name=='D')         goi->ref_db_id=-1;
                  break;
        }
      }
    }
    p=str2nextline(p);
  }
  I->numDomain = domainCount;
  /* The follow sections are deserved for calculation of fields in ccdinfo table */
  /* Take the EC number from most populated function in all components tables
   * Take corresponding ec_3rd_level, ec_4th_level, if any */
  cnti=counterNew(256);
  for(i=0;i<I->numComponent;i++) {
    comi=I->ComponentInfo+i;
    for(j=0;j<comi->numFunction;j++) {
      funi=comi->FunctionInfo+j;
      counterAddRecord(cnti,funi->ec_primary);
    }
  }
  I->ec_primary=counterMostPopular(cnti);
  if(I->ec_primary>=100 && I->ec_primary<700) {
    ecFound=0;
    for(i=0;i<I->numComponent;i++) {
      comi=I->ComponentInfo+i;
      for(j=0;j<comi->numFunction;j++) {
        funi=comi->FunctionInfo+j;
        if(funi->ec_primary==I->ec_primary) {
          ecFound=1;
          break;
        }
      }
      if(ecFound) break;
    }
    if(ecFound) {
      I->ec_3rd_level=funi->ec_3rd_level;
      I->ec_4th_level=funi->ec_4th_level;
    } else {
      PFatalError("EC primary found, but cannot be matched due to inconsistency.\n");
    }
  }
  counterFree(cnti);
  /* Find the longest protein or DNA chain, if of equal length, protein chain is used */
  cip=I->ChainInfo;
  cid=I->ChainInfo;
  for(i=1;i<I->numChain;i++){
    ci=I->ChainInfo+i;
    ci->numGeneOntology=ci->numBiolProcess+ci->numMoleFunction+ci->numCellComponent;
    if(ci->numProteinRes > cip->numProteinRes) cip=ci;
    if(ci->numDnarnaRes  > cid->numDnarnaRes)  cid=ci;
  }
  /* Take the longest chain for clusterid of the whole entry */
  ci = (cip->numProteinRes >= cid->numDnarnaRes) ? cip : cid;   // Take the longest chain
  I->cluster50_id=ci->cluster50_id;
  I->cluster90_id=ci->cluster90_id;
  /* From the longest chain,
   * Take the GO taxon as the organism_id,
   * If no data captured, Take the TAXID from most populated Component */
  cnti=counterNew(256);
  for(i=0;i<ci->numBiolProcess;i++)   { goi=ci->BiolProcessInfo+i;   counterAddRecord(cnti,goi->organism_id); }
  for(i=0;i<ci->numMoleFunction;i++)  { goi=ci->MoleFunctionInfo+i;  counterAddRecord(cnti,goi->organism_id); }
  for(i=0;i<ci->numCellComponent;i++) { goi=ci->CellComponentInfo+i; counterAddRecord(cnti,goi->organism_id); }
  I->organism_id=counterMostPopular(cnti);
  counterFree(cnti);
  if(I->organism_id==-1) {
    cnti=counterNew(256);
    for(i=0;i<I->numComponent;i++) {
      comi=I->ComponentInfo+i;
      counterAddRecord(cnti,comi->organism_id);
    }
    I->organism_id=counterMostPopular(cnti);
    counterFree(cnti);
  }
  /* From the longest chain,
   * Take the GO term with min go_id,
   * supposedly to be a more general term */
  I->go_process  =ObjGeneOntologyMinimalID(ci->BiolProcessInfo,  ci->numBiolProcess);
  I->go_function =ObjGeneOntologyMinimalID(ci->MoleFunctionInfo, ci->numMoleFunction);
  I->go_component=ObjGeneOntologyMinimalID(ci->CellComponentInfo,ci->numCellComponent);
  /* From the longest chain,
   * Take the CATH class with max CATH_primary,
   * supposedly to be a more complicated domain archetecture */
  for(i=0;i<ci->numDomain;i++){
    di = ci->DomainInfo+i;
    if(di->cath_primary>I->cath_primary) {
      I->cath_primary    =di->cath_primary;
      I->cath_topology   =di->cath_topology;
      I->cath_superfamily=di->cath_superfamily;
    }
  }
}

/*---------------------------------------------------------------------------*/
void EntityMoleculeReadAssemblyStrOld(ObjEntityMolecule *I, char *buffer_surface, char* data_dir) {
  EntityFileName file_path;
  FILE           *f;
  char*          buffer=NULL;
  int            i,keyFlag;
  char           chainid;
  int            tempint,current_assembly_id=-1;
  int            numAssembly=0,numMacroChain=0,numSymChain=0,numChain;
  int            assCount,symCount,cavityCount=0;
  char           *p,q[FileLineLength];
  ObjAssemblyInfo*assinfo=NULL,*assi;
  ObjSymChainInfo*syminfo=NULL,*symi;
  ObjChainInfo   *ci;
  ObjResidueInfo *ri;
  p=buffer_surface;
  while(*p) {
    if(!strncmp(p,"ASSEMBLY",8)) numAssembly++;
    else if(!strncmp(p,"SYMCHAIN",8)) numSymChain++;
    else if(!strncmp(p,"CHAIN   ",8)) {
      p=str2nskip(p,9);
      chainid=p[0];
      for(i=0;i<I->numChain;i++){
        ci=I->ChainInfo+i;
        if(ci->chainid==chainid) ci->claimed++;
      }
    }
    p=str2nextline(p);
  }
  for(i=0;i<I->numChain;i++){
    ci=I->ChainInfo+i;
    if(ci->type2>=CHAIN_TYPE2_DNARNA) numMacroChain++;
  }
  AllocP(assinfo,ObjAssemblyInfo,(numAssembly+1));
  I->numAssembly        = numAssembly;
  I->AssemblyInfo       = assinfo;
  AllocP(syminfo,ObjSymChainInfo,(numSymChain+1));

  p=buffer_surface;
  assCount=0;
  assi=assinfo+assCount;
  assi->index=-1;
  symCount=0;
  symi=syminfo+symCount;
  symi->index=-1;
  while(*p) {
    keyFlag=0;
    chainid=0;
//  str2printline(p);
    if(!strncmp(p,"ASSEMBLY",8))      keyFlag=1; 
    else if(!strncmp(p,"SURFRESL",8)) keyFlag=2; 
    else if(!strncmp(p,"SURFDATA",8)) keyFlag=3; 
    else if(!strncmp(p,"TOTALASA",8)) keyFlag=4; 
    else if(!strncmp(p,"POLARASA",8)) keyFlag=5; 
    else if(!strncmp(p,"POSITASA",8)) keyFlag=6; 
    else if(!strncmp(p,"NEGATASA",8)) keyFlag=7; 
    else if(!strncmp(p,"TBACKASA",8)) keyFlag=8; 
    else if(!strncmp(p,"PBACKASA",8)) keyFlag=9; 
    else if(!strncmp(p,"TOTALMSA",8)) keyFlag=10;
    else if(!strncmp(p,"POLARMSA",8)) keyFlag=11;
    else if(!strncmp(p,"POSITMSA",8)) keyFlag=12;
    else if(!strncmp(p,"NEGATMSA",8)) keyFlag=13;
    else if(!strncmp(p,"TBACKMSA",8)) keyFlag=14;
    else if(!strncmp(p,"PBACKMSA",8)) keyFlag=15;
    else if(!strncmp(p,"NUMATOMS",8)) keyFlag=16;
    else if(!strncmp(p,"NUMCHAIN",8)) keyFlag=17;
    else if(!strncmp(p,"CHAIN   ",8)) keyFlag=18;
    else if(!strncmp(p,"SYMCHAIN",8)) keyFlag=19;
    else if(!strncmp(p,"ENDASSEM",8)) keyFlag=20;

    if(keyFlag) {
      p=str2nskip(p,9);
      if(keyFlag==18 || keyFlag==19) {
        chainid=p[0];
        p=str2nskip(p,1);
        if(keyFlag==18) p=str2wcpy(q,p);
      } else {
        p=str2wcpy(q,p);
      }

      switch(keyFlag) {
        case 1:  if(sscanf(q,"%d",&current_assembly_id)!=1) current_assembly_id=-1;
                 if (assi->index!=-1) assCount++;
                 assi=assinfo+assCount; numChain=0; // numMacroChain in assembly
                 assi->index=assCount;  assi->type=ASSEMBLY_UNDEF;
                 assi->total_asa=0;     assi->polar_asa=0;
                 assi->positive_asa=0;  assi->negative_asa=0;
                 assi->total_bb_asa=0;  assi->polar_bb_asa=0;
                 assi->total_msa=0;     assi->polar_msa=0;
                 assi->positive_msa=0;  assi->negative_msa=0;
                 assi->total_bb_msa=0;  assi->polar_bb_msa=0;
                 assi->numChain=0;      assi->numSymChain=0;
                 assi->numCavity=0;     assi->numSurfraceAtom=0; 
                 assi->CavityInfo=NULL; assi->SymChainInfo=NULL;
                 break;
        case 2:  break;
        case 3:  if (!strncmp(q,"NONE",4)) {
                   strcpy(file_path,q);
                 } else if (strlen(data_dir) > 0) {
                   strcpy(file_path,data_dir);
                   strcat(file_path,q);
                   /* NOTE: atomwise surface data processing is delayed till the end of assembly entity */
              }; break;
        case 4:  if(sscanf(q,"%f",&assi->total_asa   )!=1)   assi->total_asa   =0;   break;
        case 5:  if(sscanf(q,"%f",&assi->polar_asa   )!=1)   assi->polar_asa   =0;   break;
        case 6:  if(sscanf(q,"%f",&assi->positive_asa)!=1)   assi->positive_asa=0;   break;
        case 7:  if(sscanf(q,"%f",&assi->negative_asa)!=1)   assi->negative_asa=0;   break;
        case 8:  if(sscanf(q,"%f",&assi->total_bb_asa)!=1)   assi->total_bb_asa=0;   break;
        case 9:  if(sscanf(q,"%f",&assi->polar_bb_asa)!=1)   assi->polar_bb_asa=0;   break;
        case 10: if(sscanf(q,"%f",&assi->total_msa   )!=1)   assi->total_msa   =0;   break;
        case 11: if(sscanf(q,"%f",&assi->polar_msa   )!=1)   assi->polar_msa   =0;   break;
        case 12: if(sscanf(q,"%f",&assi->positive_msa)!=1)   assi->positive_msa=0;   break;
        case 13: if(sscanf(q,"%f",&assi->negative_msa)!=1)   assi->negative_msa=0;   break;
        case 14: if(sscanf(q,"%f",&assi->total_bb_msa)!=1)   assi->total_bb_msa=0;   break;
        case 15: if(sscanf(q,"%f",&assi->polar_bb_msa)!=1)   assi->polar_bb_msa=0;   break;
        case 16: if(sscanf(q,"%d",&assi->numSurfraceAtom)!=1)assi->numSurfraceAtom=0;break;
        case 17: if(sscanf(q,"%d",&assi->numChain    )!=1)   assi->numChain=0;       break;
        case 18: /* if(sscanf(q,"%d",&tempint)!=1) tempint=-1; if(tempint>=4) numChain++; */
                 for(i=0;i<I->numChain;i++){
                   ci=I->ChainInfo+i;
                   if(ci->chainid==chainid){
                     ci->assembly_index=assCount;
                     ci->AssemblyInfo=assi;
                     if(ci->type2>=CHAIN_TYPE2_DNARNA) numChain++;
                   }
              }; break;
        case 19: assi->numSymChain++;
                 if (assi->SymChainInfo==NULL) assi->SymChainInfo=symi;
                 if (symi->index!=-1) symCount++;
                 symi=syminfo+symCount;
                 symi->index=symCount;
                 symi->cdhit_chainid=chainid;
                 symi->assembly_index=assCount;
                 symi->AssemblyInfo=assi;
                 break;
        case 20: if(assi->numSymChain==0) assi->SymChainInfo=NULL;
                 if(assi->numSymChain) {
                   assi->type = (numChain==numMacroChain) ? ASSEMBLY_BIGGER : ASSEMBLY_OVERLAP;
                 } else {
                   assi->type = (numChain==numMacroChain) ? ASSEMBLY_EQUAL : ASSEMBLY_SMALLER;
                 }
                 if (!strncmp(file_path,"NONE",4)) break;
                 if (strlen(data_dir) > 0) {
                   f=fopen(file_path,"rb");
                   if (!f) { PFatalError("invalid SURFFILE name\n"); };
                   buffer=str2cachetextfile(f);
                   cavityCount=EntityAssemblyReadSurfaceStrOld(assi, buffer, assCount, cavityCount, I);
                   FreeP(buffer);
              }; break;
      }
    }
    p=str2nextline(p);
  }
  assCount++;   assi=assinfo+assCount;  assi->index=-1;
  symCount++;   symi=syminfo+symCount;  symi->index=-1;

  for(i=0;i<I->numResidue;i++) {
    ri=I->ResidueInfo+i;
    ri->assembly_index=ri->ChainInfo->assembly_index;
    ri->AssemblyInfo  =ri->ChainInfo->AssemblyInfo;
  }
}

/*---------------------------------------------------------------------------*/
void EntityMoleculeReadAssemblyStr(ObjEntityMolecule *I, char *buffer_buheader, char* data_dir) {
  EntityFileName file_path;
  FILE           *f;
  char*          buffer=NULL;
  int            i,keyFlag,resFound;
  char           chainid;
  int            tempint,current_assembly_id=-1;
  int            numAssembly=0,numMacroChain=0,numSymChain=0,numCavityResidue=0,numAssemblyChain,numAssUniqueChain;
  int            assCount,symCount,cavityCount=0;
  char           *p,q[FileLineLength],msg[FileLineLength];
  ObjAssemblyInfo*assinfo=NULL,*assi;
  ObjCavityInfo  *cavinfo=NULL,*cavi;
  ObjSymChainInfo*syminfo=NULL,*symi,symchain;
  int            *residue_indices=NULL;
  ObjChainInfo   *ci;
  ObjResidueInfo *ri,res;
  p=buffer_buheader;
  while(*p) {
    if(!strncmp(p,"ASSEMBLY",8)) numAssembly++;
    else if(!strncmp(p,"CHAIN",5)) numSymChain++;
    else if(!strncmp(p,"CAVERESI",8)) numCavityResidue++;
    p=str2nextline(p);
  }
  for(i=0;i<I->numChain;i++){
    ci=I->ChainInfo+i;
    if(ci->type2>=CHAIN_TYPE2_DNARNA) numMacroChain++;
  }
  AllocP(assinfo,ObjAssemblyInfo,(numAssembly+1));
  I->numAssembly        = numAssembly;
  I->AssemblyInfo       = assinfo;
  AllocP(cavinfo,ObjCavityInfo,(numAssembly+1));
  AllocP(syminfo,ObjSymChainInfo,(numSymChain+1));

  p=buffer_buheader;
  assCount=0;
  assi=assinfo+assCount;
  assi->index=-1;
  cavityCount=0;
  cavi=cavinfo+cavityCount;
  cavi->index=-1;
  symCount=0;
  symi=syminfo+symCount;
  symi->index=-1;
  file_path[0]=0;
  while(*p) {
    keyFlag=0;
    chainid=0;
//  str2printline(p);
    if(!strncmp(p,"ASSEMBLY",8))      keyFlag=1; 
    else if(!strncmp(p,"CAVERESI",8)) keyFlag=2; 
    else if(!strncmp(p,"CAVESIZE",8)) keyFlag=3; 
    else if(!strncmp(p,"TOTALASA",8)) keyFlag=4; 
    else if(!strncmp(p,"POLARASA",8)) keyFlag=5; 
    else if(!strncmp(p,"POSITASA",8)) keyFlag=6; 
    else if(!strncmp(p,"NEGATASA",8)) keyFlag=7; 
    else if(!strncmp(p,"TBACKASA",8)) keyFlag=8; 
    else if(!strncmp(p,"PBACKASA",8)) keyFlag=9; 
    else if(!strncmp(p,"TOTALMSA",8)) keyFlag=10;
    else if(!strncmp(p,"POLARMSA",8)) keyFlag=11;
    else if(!strncmp(p,"POSITMSA",8)) keyFlag=12;
    else if(!strncmp(p,"NEGATMSA",8)) keyFlag=13;
    else if(!strncmp(p,"TBACKMSA",8)) keyFlag=14;
    else if(!strncmp(p,"PBACKMSA",8)) keyFlag=15;
    else if(!strncmp(p,"NUMATOMS",8)) keyFlag=16;
    else if(!strncmp(p,"NUMCHAIN",8)) keyFlag=17;
    else if(!strncmp(p,"CHAIN",5))    keyFlag=18;
    else if(!strncmp(p,"APDBFILE",8)) keyFlag=19; 
    else if(!strncmp(p,"PMOLFILE",8)) keyFlag=20; 
    else if(!strncmp(p,"SITEFILE",8)) keyFlag=21; 
    else if(!strncmp(p,"SURFDATA",8)) keyFlag=22; 
    else if(!strncmp(p,"ENDASSEM",8)) keyFlag=23;

    if(keyFlag) {
      if(keyFlag==2) {    // 1. In the case of CAVERESI, multiple parameters need to be read into res object
        p=str2nskip(p,9);
        p=str2ncpy(q,p,1);      // residue's chainid
        res.chain=q[0];

        p=str2nskip(p,1);
        p=str2ncpy(q,p,4);      // resseq
        if(sscanf(q,"%s",res.resi)!=1) res.resi[0]=0;
        if(sscanf(q,"%d",&res.resid)!=1) res.resid=-9999;

        p=str2nskip(p,1);
        p=str2ncpy(q,p,3);      // resname
        if ((q[0]==' ') || (q[1]==' ') || (q[2]==' ')) { PFatalError("Only 3-letter-aa-code is expected in header file CAVERESI record.\n"); };
        ObjResidueAssignResname(&res,q);

      } if(keyFlag==18) { // 2. In the case of CHAIN, multiple parameters need to be read into symchain object
        p=str2nskip(p,5);
        p=str2ncpy(q,p,3);      // model_number
        if(sscanf(q,"%d",&symchain.model_number)!=1) symchain.model_number=-9999;

        p=str2nskip(p,1);
        p=str2ncpy(q,p,1);      // cdhit_chainid
        symchain.cdhit_chainid=q[0];

        p=str2nskip(p,1);
        p=str2ncpy(q,p,1);      // symop_chainid
        symchain.symop_chainid=q[0];

      } else {            // 3. For all other cases, one-word parameter is read into q for further processing
        p=str2nskip(p,9);
        p=str2wcpy(q,p);
      }

      switch(keyFlag) {
        case 1:  if(sscanf(q,"%d",&current_assembly_id)!=1) current_assembly_id=-1;
                 if (assi->index!=-1) assCount++;
                 assi=assinfo+assCount;
                 numAssemblyChain=0;            numAssUniqueChain=0; // numMacroChain in assembly
                 assi->index=assCount;          assi->assembly_number=current_assembly_id;
                 assi->type=ASSEMBLY_UNDEF;
                 assi->total_asa=0;             assi->polar_asa=0;
                 assi->positive_asa=0;          assi->negative_asa=0;
                 assi->total_bb_asa=0;          assi->polar_bb_asa=0;
                 assi->total_msa=0;             assi->polar_msa=0;
                 assi->positive_msa=0;          assi->negative_msa=0;
                 assi->total_bb_msa=0;          assi->polar_bb_msa=0;
                 assi->numChain=0;              assi->numSymChain=0;
                 assi->numCavity=0;             assi->numSurfraceAtom=0; 
                 assi->CavityInfo=NULL;         assi->SymChainInfo=NULL;
                 for(i=0;i<I->numChain;i++){
                   ci=I->ChainInfo+i;
                   ci->claimed=0;
                 }
                 strcpy(file_path,"NONE");
                 break;
        case 2:  resFound=-1;
                 for(i=0;i<I->numResidue;i++) {
                   ri=I->ResidueInfo+i;
                   if (res.chain==ri->chain && res.resid==ri->resid && strcmp(res.resn,ri->resn)==0) {
                     resFound=i; break;
                   }
                 }
                 if (resFound != -1) {
                   if (ri->location < RESIDUE_LOCATE_SDCAVITY) { ri->location += RESIDUE_LOCATE_SDCAVITY; }
                   if (assi->CavityInfo == NULL) {
                     if (cavi->index!=-1) cavityCount++;
                     cavi=cavinfo+cavityCount;      
                     cavi->index=cavityCount;   cavi->assembly_index=assCount;
                     cavi->AssemblyInfo=assi;   cavi->numResidue=0;
                     AllocP(residue_indices,int,(numCavityResidue+1));
                     cavi->residue_indices=residue_indices;
                     cavi->residue_indices[0]=-1;
                     cavi->numAtom=0;           cavi->volume=0;
                     assi->CavityInfo=cavi;     assi->numCavity=1;
                   }
                   cavi->residue_indices[cavi->numResidue]=resFound;
                   cavi->numResidue++;
                   cavi->residue_indices[cavi->numResidue]=-1;
                 } else {
                   sprintf(msg,"Failed to locate residue %c:%s %d from CAVERESI record.\n",res.chain,res.resn,res.resid);
                   PWarning(msg);
                 }
                 break;
        case 3:  if(sscanf(q,"%d",&cavi->volume      )!=1)   cavi->volume=0;         break;
        case 4:  if(sscanf(q,"%f",&assi->total_asa   )!=1)   assi->total_asa   =0;   break;
        case 5:  if(sscanf(q,"%f",&assi->polar_asa   )!=1)   assi->polar_asa   =0;   break;
        case 6:  if(sscanf(q,"%f",&assi->positive_asa)!=1)   assi->positive_asa=0;   break;
        case 7:  if(sscanf(q,"%f",&assi->negative_asa)!=1)   assi->negative_asa=0;   break;
        case 8:  if(sscanf(q,"%f",&assi->total_bb_asa)!=1)   assi->total_bb_asa=0;   break;
        case 9:  if(sscanf(q,"%f",&assi->polar_bb_asa)!=1)   assi->polar_bb_asa=0;   break;
        case 10: if(sscanf(q,"%f",&assi->total_msa   )!=1)   assi->total_msa   =0;   break;
        case 11: if(sscanf(q,"%f",&assi->polar_msa   )!=1)   assi->polar_msa   =0;   break;
        case 12: if(sscanf(q,"%f",&assi->positive_msa)!=1)   assi->positive_msa=0;   break;
        case 13: if(sscanf(q,"%f",&assi->negative_msa)!=1)   assi->negative_msa=0;   break;
        case 14: if(sscanf(q,"%f",&assi->total_bb_msa)!=1)   assi->total_bb_msa=0;   break;
        case 15: if(sscanf(q,"%f",&assi->polar_bb_msa)!=1)   assi->polar_bb_msa=0;   break;
        case 16: if(sscanf(q,"%d",&assi->numSurfraceAtom)!=1)assi->numSurfraceAtom=0;break;
        case 17: if(sscanf(q,"%d",&assi->numChain    )!=1)   assi->numChain=0;       break;
        case 18: // create symop chain records
                 if (symi->index!=-1) symCount++;
                 symi=syminfo+symCount;
                 symi->index=symCount;
                 symi->model_number=symchain.model_number;
                 symi->cdhit_chainid=symchain.cdhit_chainid;
                 symi->symop_chainid=symchain.symop_chainid;
                 symi->assembly_index=assCount;
                 symi->AssemblyInfo=assi;
                 // assign pointer for assembly
                 if (assi->SymChainInfo==NULL) assi->SymChainInfo=symi;
                 assi->numSymChain++;
                 // assign assembly_index and pointer for real chains
                 for(i=0;i<I->numChain;i++){
                   ci=I->ChainInfo+i;
                   if(ci->chainid==symchain.cdhit_chainid){
                     if (ci->AssemblyInfo==NULL) {
                       ci->assembly_index=assCount;
                       ci->AssemblyInfo=assi;
                     }
                     ci->claimed++;
                   }
                 }
                 break;
        case 19:        // APDBFILE record is not being processed
                 break;
        case 20:        // PMOLFILE record is not being processed
                 break;
        case 21:        // SITEFILE record is not being processed
                 break;
        case 22: if (q[0]=='/') {
                   strcpy(file_path,q);
                 } else if (!strncmp(q,"NONE",4)) {
                   strcpy(file_path,q);
                 } else if (strlen(data_dir) > 0) {
                   strcpy(file_path,data_dir);
                   strcat(file_path,q);
                   /* NOTE: atomwise surface data processing is delayed till the end of assembly entity */
              }; break;
        case 23: if(assi->numSymChain==0) assi->SymChainInfo=NULL;
                 for(i=0;i<I->numChain;i++){
                   ci=I->ChainInfo+i;
                   if(ci->type2>=CHAIN_TYPE2_DNARNA && ci->claimed) {
                     numAssemblyChain+=ci->claimed;
                     numAssUniqueChain++;
                   }
                 }
                 if(numAssemblyChain > numAssUniqueChain) {
                   assi->type = (numAssUniqueChain==numMacroChain) ? ASSEMBLY_BIGGER : ASSEMBLY_OVERLAP;
                 } else {
                   assi->type = (numAssUniqueChain==numMacroChain) ? ASSEMBLY_EQUAL : ASSEMBLY_SMALLER;
                 }
                 if (!strncmp(file_path,"NONE",4)) break;
                 if (strlen(file_path) > 0) {
                   f=fopen(file_path,"rb");
                   if (!f) {
                     sprintf(msg, "invalid SURFFILE name (%s)\n", I->pdbid);
                     PWarning(msg);
                     return;
                   };
                   buffer=str2cachetextfile(f);
                   EntityAssemblyReadSurfaceStr(assi, buffer, assCount, I);
                   FreeP(buffer);
              }; break;
      }
    }
    p=str2nextline(p);
  }
  if (assi->index!=-1) assCount++;    assi=assinfo+assCount;    assi->index=-1;
  if (symi->index!=-1) symCount++;    symi=syminfo+symCount;    symi->index=-1;
  if (cavi->index!=-1) cavityCount++; cavi=cavinfo+cavityCount; cavi->index=-1;

  if(assCount>0) {      // Only if at least one assembly record is detected
    for(i=0;i<I->numResidue;i++) {
      ri=I->ResidueInfo+i;
      ri->assembly_index=ri->ChainInfo->assembly_index;
      ri->AssemblyInfo  =ri->ChainInfo->AssemblyInfo;
    }
  }
}

/*---------------------------------------------------------------------------*/
void EntityAssemblyReadSurfaceStr(ObjAssemblyInfo *assi, char *buffer, int assCount, ObjEntityMolecule *I) {
  int           i,j,atomFlag;
  int           resCount,atomCount,resFound,atomFound;
  char          *p,q[FileLineLength],msg[FileLineLength],line[FileLineLength];
  ObjChainInfo  *ci;
  ObjSymChainInfo*symi;
  ObjResidueInfo*ri,res;
  ObjAtomInfo   *ai,*ai_cavity,atom;
  int           exact_match=0,cavity_record=0;
  char          chainid_from=0,chainid_to=0;

  p=buffer;
  resCount=0;
  ri=I->ResidueInfo+resCount;
  atomCount=-1;
  while(*p) {
//  str2ncpy(line,p,FileLineLength);
    atomFlag=-1;
    if(!strncmp(p,"ATOM",4))        atomFlag=1;
    else if(!strncmp(p,"HETATM",6)) atomFlag=2;
    else if(!strncmp(p,"CAVITY",6)) atomFlag=0;
//  str2printline(p);
    if(atomFlag>=1) {
/* STEP ONE: parse character 1-17 and store information in 'atom' object */
      p=str2nskip(p,6);                 /* skip 1-6     "ATOM  " */
      p=str2ncpy(q,p,5);                /* read 7-11    serial   */
      if(sscanf(q,"%d",&atom.id)!=1) atom.id=0;
      /* atom serial number in the pdbfile */
      p=str2nskip(p,1);                 /* skip 12 */
      p=str2ncpy(atom.realname,p,4);     /* read 13-16   name     */
      if(sscanf(atom.realname,"%s",atom.name)!=1) atom.name[0]=0;
      for(i=0;i<4;i++) if(atom.realname[i]==' ') atom.realname[i]='-';
      /* atom name, first 2 chars are element name, followed by atom id */
      p=str2ncpy(q,p,1);                /* read 17      altLoc   */
      atom.alt=q[0];
      /* alternate location indicator, used with alternate chain id */

/* STEP TWO: parse character 18-28 and store information in 'res' object */
      p=str2ncpy(q,p,3);                /* read 18-20   resName  */
      ObjResidueAssignResname(&res,q);
      /* residue name, three letter code */
      p=str2nskip(p,1);                 /* skip 21 */
      p=str2ncpy(q,p,1);                /* read 22      chainId  */
      res.chain=q[0];
      if (assi->SymChainInfo) {
        for (i=0;i<assi->numSymChain;i++) {
          symi=assi->SymChainInfo+i;
          if(res.chain == symi->symop_chainid) {
            res.chain=symi->cdhit_chainid;
            break;
          }
        }
      }
      /* chain identifier, preserve original pdb chain ID here  */
      p=str2ncpy(q,p,4);                /* read 23-26   resSeq   */
      if(sscanf(q,"%s",res.resi)!=1) res.resi[0]=0;
      if(sscanf(q,"%d",&res.resid)!=1) res.resid=-9999;
      /* residue sequence number , together with residue insertion code */
      p=str2ncpy(q,p,1);                /* read 27      patched residue   */
      res.resi2=q[0];
      /* alternate residue id indicator, used with the main resseq - residue id */
 
/* alternative solution for step 3 & 4, still in development */
//    ai=I->AtomInfo+AtomInfoLocateIndex4surfrace(&res, &atom, I, ai->index);
//    ri=ai->ResidueInfo;
/* End alternative solution for step 3 & 4, still in development */

/* STEP THREE: locate correct residue by res.(chain,resid,resi2,resn), store in ri-> */
//    printf("%s",line);
//    printf("=%c-%d-%d-%s=%c-%d-%d-%s=\n",res.chain,res.resid,res.resi2,res.resn,ri->chain,ri->resid,ri->resi2,ri->resn);
      if (res.chain==ri->chain && res.resid==ri->resid && res.resi2==ri->resi2 && strcmp(res.resn,ri->resn)==0) {
        atomCount++;
      }else if (exact_match==1 && res.chain==chainid_from) {
        if(res.resid==ri->resid && res.resi2==ri->resi2 && strcmp(res.resn,ri->resn)==0) atomCount++;
        else {
          resFound=-1;
          for(i=0; i<I->numResidue; i++){               // scan from the beginning to the end
            ri=I->ResidueInfo+i;
            if (chainid_to==ri->chain && res.resid==ri->resid &&
                res.resi2==ri->resi2 && strcmp(res.resn,ri->resn)==0) {
              exact_match=1; resFound=i; break;
            }
          }
          if(resFound==-1){
            ri=I->ResidueInfo; resCount=0; atomCount=0;
//          sprintf(msg,"Failed to locate residue %c:%s %d for SURFRACE file atom even with chain_id correction.\n",res.chain,res.resn,res.resid);
//          PFatalError(msg);
          } else { resCount=resFound; atomCount=0; }
        }
      }else{
        resFound=-1;
        for(i=resCount+1; i<I->numResidue; i++){        // scan to the end of coord
          ri=I->ResidueInfo+i;
          if (res.chain==ri->chain && res.resid==ri->resid &&
              res.resi2==ri->resi2 && strcmp(res.resn,ri->resn)==0) {
            exact_match=0; resFound=i; break;
          }
        }
        if(resFound==-1){
          for(i=0; i<resCount; i++){                    // scan from the beginning of coord
            ri=I->ResidueInfo+i;
            if (res.chain==ri->chain && res.resid==ri->resid &&
                res.resi2==ri->resi2 && strcmp(res.resn,ri->resn)==0) {
              exact_match=0; resFound=i; break;
            }
          }
          if(resFound==-1){
            for(i=0; i<I->numAtom; i++){                // try to allow chain_id mismatch, looking for next available chain
              ai=I->AtomInfo+i;
              if (atom.id==ai->id && res.resid==ri->resid && strcmp(res.resn,ri->resn)==0) {
                exact_match=1;          ri=ai->ResidueInfo;
                resFound=ri->index;
                chainid_from=res.chain; chainid_to=ri->chain; break;
              }
            }
          }
        }
        if(resFound==-1){                               // just don't report any error, although slower, it will still get automatically corrected during atom looking
          ri=I->ResidueInfo; resCount=0; atomCount=0;
        } else { resCount=resFound; atomCount=0; }
      }

// STEP FOUR: locate correct atom by atom.(name,alt,id), store in ai->
      atomFound=-1;
      if (resFound==-1) {
        for(i=0; i<I->numAtom; i++){            // try to allow chain_id mismatch, looking for next available chain
          ai=I->AtomInfo+i;
          if ((atom.id==ai->id || atom.id==ai->id+1) && strncmp(atom.realname,ai->realname,4)==0 && atom.alt==ai->alt) {
            exact_match=1;              ri=ai->ResidueInfo;
            resFound=ri->index;         atomFound=ai->index;        
            chainid_from=res.chain;     chainid_to=ri->chain; break;
          }
        }
        if (resFound==-1) {
          sprintf(msg,"Failed to locate residue %c:%s %d for SURFRACE file atom.\n",res.chain,res.resn,res.resid);
          PWarning(msg);
        }
      } else {
        for(i=atomCount;i<ri->numAtom;i++){     // scan to the end of residue
          ai=ri->AtomInfo+i;
          if(atom.id==ai->id && strncmp(atom.realname,ai->realname,4)==0 && atom.alt==ai->alt){
            atomFound=ai->index; break;
          }
        }
        if(atomFound==-1){
          for(i=0;i<atomCount;i++){             // scan from the beginning of residue
            ai=ri->AtomInfo+i;
            if(atom.id==ai->id && strncmp(atom.realname,ai->realname,4)==0 && atom.alt==ai->alt){
              atomFound=ai->index; break;
            }
          }
          if(atomFound==-1){
            for(i=0;i<ri->numAtom;i++){         // scan again with looser criteria
              ai=ri->AtomInfo+i;
              if(strncmp(atom.realname,ai->realname,4)==0 && atom.alt==ai->alt) {
                atomFound=ai->index; break;
              }
            }
            if((!strncmp(res.resn,"GLY",3)) && (!strncmp(atom.realname,"-CB-",4))) {    // Glycine do not have C beta atom, skip this case
              p=str2nextline(p);
              continue;
            }
            if(atomFound==-1) {
              sprintf(msg,"Failed to locate corresponding atom %d:%s:%c for SURFRACE file. Skipping...\n", atom.id, atom.realname, atom.alt);
              PWarning(msg);
              p=str2nextline(p);
              continue;
            }
          }
        }
      }

/* STEP FIVE: skip character 28-54, parse character 55-81 and store in ai-> object */
      /* NOTE: location, asa, msa and curvature for atom is update here, */
      /*       but those values for residue are left empty here, and assigned later */
      p=str2nskip(p,36);                /* skip 28-63 */
      p=str2ncpy(q,p,5);                /* read 64-68   assessible surface */
      if(sscanf(q,"%f",&ai->asa)!=1) ai->asa=0.0;
      p=str2nskip(p,2);                 /* skip 69-70 */
      p=str2ncpy(q,p,5);                /* read 71-75   molecule surface */
      if(sscanf(q,"%f",&ai->msa)!=1) ai->msa=0.0;
      p=str2nskip(p,1);                 /* skip 76 */
      p=str2ncpy(q,p,5);                /* read 77-81   surface curvature */
      if(sscanf(q,"%f",&ai->curvature)!=1) ai->curvature=0.0;

/* STEP SIX: process cavity-specific information */
      if(cavity_record==0){ /* for a residue in general, that is, no cavity info has been identified */
        if(ai->asa<=0 && ai->msa<=0) ai->location=ATOM_LOCATE_BURIED;
        else ai->location=ATOM_LOCATE_SURFACE;
      }else{              /* for a residue inside some cavity */
        ai->location=ATOM_LOCATE_CAVITY;
      }
    }else if(atomFlag==0){/* cavity record encounters */
      cavity_record = 1;
    }
    p=str2nextline(p);
  }

/* STEP SEVEN: derived residue information (location, asa, msa and curvature) from its atoms */
  int buried_detected,surface_detected,cavity_detected,is_sdcavity;
  float asa_sum,msa_sum,curvature_sum;
  for(i=0;i<I->numResidue;i++) {
    ri=I->ResidueInfo+i;
    buried_detected=0;
    surface_detected=0;
    cavity_detected=0;
    asa_sum=0;
    msa_sum=0;
    curvature_sum=0;
    for(j=0;j<ri->numAtom;j++){
      ai=ri->AtomInfo+j;
      switch(ai->location){
        case ATOM_LOCATE_BURIED:  buried_detected=1;  break;
        case ATOM_LOCATE_SURFACE: surface_detected=1; break;
        case ATOM_LOCATE_CAVITY:  cavity_detected=1; 
                               /* ai_cavity=ai; */    break;
      }
      if(ai->asa > 0) asa_sum+=ai->asa;
      if(ai->msa > 0) { msa_sum+=ai->msa; curvature_sum+=ai->msa*ai->curvature; }
    }
    is_sdcavity = ri->location>=RESIDUE_LOCATE_SDCAVITY ? 1 : 0;
    if(cavity_detected) {
      ri->location      =RESIDUE_LOCATE_CAVITY;
//    ri->cavity_index  =ai_cavity->cavity_index;
//    ri->CavityInfo    =ai_cavity->CavityInfo;
//    ri->CavityInfo->numResidue++;
      ri->asa           =asa_sum;
      ri->msa           =msa_sum;
      if(msa_sum>0) ri->curvature=curvature_sum/msa_sum;
      else          ri->curvature=0;
    } else if(surface_detected) {
      ri->location=RESIDUE_LOCATE_SURFACE;
      ri->asa           =asa_sum;
      ri->msa           =msa_sum;
      if(msa_sum>0) ri->curvature=curvature_sum/msa_sum;
      else          ri->curvature=0;
    } else if(buried_detected) {
      ri->location=RESIDUE_LOCATE_BURIED;
      ri->asa=0; ri->msa=0; ri->curvature=0;
    } else ri->location=RESIDUE_LOCATE_UNDEF;
    if(is_sdcavity) { ri->location += RESIDUE_LOCATE_SDCAVITY; }
  }
}

/*---------------------------------------------------------------------------*/
int EntityAssemblyReadSurfaceStrOld(ObjAssemblyInfo *assi, char *buffer, int assCount, int cavityCountPrev, ObjEntityMolecule *I) {
  int           i,j,atomFlag;
  int           resCount,atomCount,resFound,atomFound;
  int           cavityCount,numCavity=0;
  char          *p,q[FileLineLength],msg[FileLineLength];
  ObjChainInfo  *ci;
  ObjResidueInfo*ri,res;
  ObjAtomInfo   *ai,*ai_cavity,atom;
  ObjCavityInfo *cvinfo=NULL,*cvi;
  int           exact_match=0;
  char          chainid_from=0,chainid_to=0;

  p=buffer;
  while(*p) {
    if(!strncmp(p,"CAVITY",6)) numCavity++;
    p=str2nextline(p);
  }
  AllocP(cvinfo,ObjCavityInfo,(numCavity+2));
  assi->numCavity=numCavity;
  assi->CavityInfo=cvinfo;

  p=buffer;
  cavityCount=0;
  cvi=cvinfo+cavityCount;
  cvi->index=-1;
  resCount=0;
  ri=I->ResidueInfo+resCount;
  atomCount=-1;
  while(*p) {
    atomFlag=-1;
    if(!strncmp(p,"ATOM",4))        atomFlag=1;
    else if(!strncmp(p,"HETATM",6)) atomFlag=2;
    else if(!strncmp(p,"CAVITY",6)) atomFlag=0;
//  str2printline(p);
    if(atomFlag>=1) {
/* STEP ONE: parse character 1-17 and store information in 'atom' object */
      p=str2nskip(p,6);                 /* skip 1-6     "ATOM  " */
      p=str2ncpy(q,p,5);                /* read 7-11    serial   */
      if(sscanf(q,"%d",&atom.id)!=1) atom.id=0;
      /* atom serial number in the pdbfile */
      p=str2nskip(p,1);                 /* skip 12 */
      p=str2ncpy(atom.realname,p,4);     /* read 13-16   name     */
      if(sscanf(atom.realname,"%s",atom.name)!=1) atom.name[0]=0;
      for(i=0;i<4;i++) if(atom.realname[i]==' ') atom.realname[i]='-';
      /* atom name, first 2 chars are element name, followed by atom id */
      p=str2ncpy(q,p,1);                /* read 17      altLoc   */
      atom.alt=q[0];
      /* alternate location indicator, used with alternate chain id */

/* STEP TWO: parse character 18-28 and store information in 'res' object */
      p=str2ncpy(q,p,3);                /* read 18-20   resName  */
      ObjResidueAssignResname(&res,q);
      /* residue name, three letter code */
      p=str2nskip(p,1);                 /* skip 21 */
      p=str2ncpy(q,p,1);                /* read 22      chainId  */
      res.chain=q[0];
      /* chain identifier, preserve original pdb chain ID here  */
      p=str2ncpy(q,p,4);                /* read 23-26   resSeq   */
      if(sscanf(q,"%s",res.resi)!=1) res.resi[0]=0;
      if(sscanf(q,"%d",&res.resid)!=1) res.resid=-9999;
      /* residue sequence number , together with residue insertion code */
      p=str2ncpy(q,p,1);                /* read 27      patched residue   */
      res.resi2=q[0];
      /* alternate residue id indicator, used with the main resseq - residue id */
 
/* STEP THREE: locate correct residue by res.(chain,resid,resi2,resn), store in ri-> */
      if (res.chain==ri->chain && res.resid==ri->resid && res.resi2==ri->resi2 && strcmp(res.resn,ri->resn)==0) {
        atomCount++;
      }else if (exact_match==1 && res.chain==chainid_from) {
        if(res.resid==ri->resid && res.resi2==ri->resi2 && strcmp(res.resn,ri->resn)==0) atomCount++;
        else {
          resFound=-1;
          for(i=0; i<I->numResidue; i++){               /* scan from the beginning to the end */
            ri=I->ResidueInfo+i;
            if (chainid_to==ri->chain && res.resid==ri->resid &&
                res.resi2==ri->resi2 && strcmp(res.resn,ri->resn)==0) {
              exact_match=1; resFound=i; break;
            }
          }
          if(resFound==-1){
            ri=I->ResidueInfo; resCount=0; atomCount=0;
//          sprintf(msg,"Failed to locate residue %c:%s %d for SURFRACE file atom even with chain_id correction.\n",res.chain,res.resn,res.resid);
//          PFatalError(msg);
          } else { resCount=resFound; atomCount=0; }
        }
      }else{
        resFound=-1;
        for(i=resCount+1; i<I->numResidue; i++){        /* scan to the end of coord */
          ri=I->ResidueInfo+i;
          if (res.chain==ri->chain && res.resid==ri->resid &&
              res.resi2==ri->resi2 && strcmp(res.resn,ri->resn)==0) {
            exact_match=0; resFound=i; break;
          }
        }
        if(resFound==-1){
          for(i=0; i<resCount; i++){                    /* scan from the beginning of coord */
            ri=I->ResidueInfo+i;
            if (res.chain==ri->chain && res.resid==ri->resid &&
                res.resi2==ri->resi2 && strcmp(res.resn,ri->resn)==0) {
              exact_match=0; resFound=i; break;
            }
          }
          if(resFound==-1){
            for(i=0; i<I->numAtom; i++){                /* try to allow chain_id mismatch, looking for next available chain */
              ai=I->AtomInfo+i;
              if (atom.id==ai->id && res.resid==ri->resid && strcmp(res.resn,ri->resn)==0) {
                exact_match=1; ri=ai->ResidueInfo; resFound=ai->residue_index;
                chainid_from=res.chain; chainid_to=ri->chain; break;
              }
            }
          }
        }
        if(resFound==-1){                               /* just don't report any error, although slower, it will still get automatically corrected during atom looking */
          ri=I->ResidueInfo; resCount=0; atomCount=0;
//        sprintf(msg,"Failed to locate residue %c:%s %d for SURFRACE file atom.\n",res.chain,res.resn,res.resid);
//        PFatalError(msg);
        } else { resCount=resFound; atomCount=0; }
      }

/* STEP FOUR: locate correct atom by atom.(name,alt,id), store in ai-> */
      atomFound=-1;
      for(i=atomCount;i<ri->numAtom;i++){               /* scan to the end of residue */
        ai=ri->AtomInfo+i;
        if(atom.id==ai->id && strncmp(atom.realname,ai->realname,4)==0 && atom.alt==ai->alt){
          atomFound=i; break;
        }
      }
      if(atomFound==-1){
        for(i=0;i<atomCount;i++){                       /* scan from the beginning of residue */
          ai=ri->AtomInfo+i;
          if(atom.id==ai->id && strncmp(atom.realname,ai->realname,4)==0 && atom.alt==ai->alt){
            atomFound=i; break;
          }
        }
        if(atomFound==-1){
          for(i=0; i<I->numAtom; i++){                  /* try to allow chain_id mismatch, looking for next available chain */
            ai=I->AtomInfo+i;
            if (atom.id==ai->id && strncmp(atom.realname,ai->realname,4)==0 && atom.alt==ai->alt) {
              exact_match=1; ri=ai->ResidueInfo; atomFound=ai->index;
              chainid_from=res.chain; chainid_to=ri->chain; break;
            }
          }
          if(atomFound==-1){
            for(i=0;i<ri->numAtom;i++){                 /* scan again with losser criteria */
              ai=ri->AtomInfo+i;
              if(strncmp(atom.realname,ai->realname,4)==0) {
                atomFound=i; break;
              }
            }
            if(atomFound==-1) sprintf(msg,"Failed to locate corresponding atom %d:%s:%cfor SURFRACE file.\n", atom.id, atom.realname, atom.alt);
            else sprintf(msg,"Failed to locate exact match atom %d:%s:%cfor SURFRACE file.\n", atom.id, atom.realname, atom.alt);
            PFatalError(msg);
          }
        }
      }

/* STEP FIVE: skip character 28-54, parse character 55-81 and store in ai-> object */
      /* NOTE: location, asa, msa and curvature for atom is update here, */
      /*       but those values for residue are left empty here, and assigned later */
      p=str2nskip(p,36);                /* skip 28-63 */
      p=str2ncpy(q,p,5);                /* read 64-68   assessible surface */
      if(sscanf(q,"%f",&ai->asa)!=1) ai->asa=0.0;
      p=str2nskip(p,2);                 /* skip 69-70 */
      p=str2ncpy(q,p,5);                /* read 71-75   molecule surface */
      if(sscanf(q,"%f",&ai->msa)!=1) ai->msa=0.0;
      p=str2nskip(p,1);                 /* skip 76 */
      p=str2ncpy(q,p,5);                /* read 77-81   surface curvature */
      if(sscanf(q,"%f",&ai->curvature)!=1) ai->curvature=0.0;

/* STEP SIX: process cavity-specific information */
      if(cvi->index==-1){ /* for a residue in general, that is, no cavity info has been identified */
        if(ai->asa<=0 && ai->msa<=0) ai->location=ATOM_LOCATE_BURIED;
        else ai->location=ATOM_LOCATE_SURFACE;
      }else{              /* for a residue inside some cavity */
        ai->location=ATOM_LOCATE_CAVITY;
        ai->cavity_index=cvi->index;
        ai->CavityInfo=cvi;
        cvi->numAtom++;
      }
    }else if(atomFlag==0){/* cavity record encounters */
      if(cvi->index!=-1) cavityCount++;
      cvi=cvinfo+cavityCount;
      cvi->index        = cavityCountPrev+cavityCount;
      cvi->assembly_index=assCount;
      cvi->AssemblyInfo = assi;
      cvi->numResidue   = 0;
      cvi->numAtom      = 0;
    }
    p=str2nextline(p);
  }
  cavityCount++;
  cvi=cvinfo+cavityCount;
  cvi->index=-1;

/* STEP SEVEN: derived residue information (location, asa, msa and curvature) from its atoms */
  int buried_detected,surface_detected,cavity_detected;
  float asa_sum,msa_sum,curvature_sum;
  for(i=0;i<I->numResidue;i++) {
    ri=I->ResidueInfo+i;
    buried_detected=0;
    surface_detected=0;
    cavity_detected=0;
    asa_sum=0;
    msa_sum=0;
    curvature_sum=0;
    for(j=0;j<ri->numAtom;j++){
      ai=ri->AtomInfo+j;
      switch(ai->location){
        case ATOM_LOCATE_BURIED:  buried_detected=1;  break;
        case ATOM_LOCATE_SURFACE: surface_detected=1; break;
        case ATOM_LOCATE_CAVITY:
          if(cavity_detected==0){
            cavity_detected=1; ai_cavity=ai;
          }else if(ai_cavity->CavityInfo->numAtom < ai->CavityInfo->numAtom) {
            ai_cavity=ai;       /* choose the biggest cavity in case a residue belongs to multiple cavities */
          }; break;
      }
      if(ai->asa > 0) asa_sum+=ai->asa;
      if(ai->msa > 0) { msa_sum+=ai->msa; curvature_sum+=ai->msa*ai->curvature; }
    }
    if(cavity_detected) {
      ri->location      =RESIDUE_LOCATE_CAVITY;
      ri->cavity_index  =ai_cavity->cavity_index;
      ri->CavityInfo    =ai_cavity->CavityInfo;
      ri->CavityInfo->numResidue++;
      ri->asa           =asa_sum;
      ri->msa           =msa_sum;
      if(msa_sum>0) ri->curvature=curvature_sum/msa_sum;
      else          ri->curvature=0;
    } else if(surface_detected) {
      ri->location=RESIDUE_LOCATE_SURFACE;
      ri->asa           =asa_sum;
      ri->msa           =msa_sum;
      if(msa_sum>0) ri->curvature=curvature_sum/msa_sum;
      else          ri->curvature=0;
    } else if(buried_detected) {
      ri->location=RESIDUE_LOCATE_BURIED;
      ri->asa=0; ri->msa=0; ri->curvature=0;
    } else ri->location=RESIDUE_LOCATE_UNDEF;
  }
  return (cavityCountPrev+numCavity);
}

/*---------------------------------------------------------------------------*/
void ObjResidueAssignType(ObjResidueInfo *ri, ResidueDict *aminoacid_dictionary) {
  int i, j, irt;
  ObjChainInfo *ci;
  char *name;
  name=ri->resn;
  if(!strncmp(name,"HOH",3) ||
     !strncmp(name,"DOD",3) ||
     !strncmp(name,"MTO",3) ||
     !strncmp(name,"DIS",3) ||
     !strncmp(name,"WAT",3)) ri->type = RESIDUE_WATER;
  else if(!strncmp(name,"LEU",3)) ri->type = RESIDUE_LEU;
  else if(!strncmp(name,"ALA",3)) ri->type = RESIDUE_ALA;
  else if(!strncmp(name,"GLY",3)) ri->type = RESIDUE_GLY;
  else if(!strncmp(name,"VAL",3)) ri->type = RESIDUE_VAL;
  else if(!strncmp(name,"GLU",3)) ri->type = RESIDUE_GLU;
  else if(!strncmp(name,"SER",3)) ri->type = RESIDUE_SER;
  else if(!strncmp(name,"LYS",3)) ri->type = RESIDUE_LYS;
  else if(!strncmp(name,"ASP",3)) ri->type = RESIDUE_ASP;
  else if(!strncmp(name,"THR",3)) ri->type = RESIDUE_THR;
  else if(!strncmp(name,"ILE",3)) ri->type = RESIDUE_ILE;
  else if(!strncmp(name,"ARG",3)) ri->type = RESIDUE_ARG;
  else if(!strncmp(name,"PRO",3)) ri->type = RESIDUE_PRO;
  else if(!strncmp(name,"ASN",3)) ri->type = RESIDUE_ASN;
  else if(!strncmp(name,"PHE",3)) ri->type = RESIDUE_PHE;
  else if(!strncmp(name,"GLN",3)) ri->type = RESIDUE_GLN;
  else if(!strncmp(name,"TYR",3)) ri->type = RESIDUE_TYR;
  else if(!strncmp(name,"HIS",3)) ri->type = RESIDUE_HIS;
  else if(!strncmp(name,"MET",3)) ri->type = RESIDUE_MET;
  else if(!strncmp(name,"TRP",3)) ri->type = RESIDUE_TRP;
  else if(!strncmp(name,"CYS",3)) ri->type = RESIDUE_CYS;
  else if(!strncmp(name,"UNK",3) /* && ri->AtomInfo->hetatm==0 */) ri->type = RESIDUE_AMINOACID;
  else if( name[0]=='_' &&
          (name[1]=='_' || name[1]=='+' || name[1]=='D')&&
          (name[2]=='A' || name[2]=='G')) ri->type = (name[1]=='D') ? RESIDUE_DNA_PURINE : RESIDUE_RNA_PURINE;
  else if( name[0]=='_' &&
          (name[1]=='_' || name[1]=='+' || name[1]=='D')&&
          (name[2]=='T' || name[2]=='C' || name[2]=='U')) ri->type = (name[1]=='D') ? RESIDUE_DNA_PYRIMIDINE : RESIDUE_RNA_PYRIMIDINE;
  else if( name[0]=='_' &&
          (name[1]=='_' || name[1]=='+' || name[1]=='D')&&
          (name[2]=='N')) ri->type = RESIDUE_DNARNA;
  else if( name[1]=='P' && name[2]=='N') { if (name[0]=='A' || name[0]=='G') ri->type = RESIDUE_PNA_PURINE;
                                      else if (name[0]=='T' || name[0]=='C') ri->type = RESIDUE_PNA_PYRIMIDINE; }
  else if( name[0]=='4' && name[1]=='0') { if (name[2]=='A' || name[2]=='G') ri->type = RESIDUE_PNA_PURINE;
                                      else if (name[2]=='T' || name[2]=='C') ri->type = RESIDUE_PNA_PYRIMIDINE; }
  else if( name[0]=='A' && name[1]=='6') { if (name[2]=='A' || name[2]=='G') ri->type = RESIDUE_ANA_PURINE;
                                      else if (name[2]=='U' || name[2]=='C') ri->type = RESIDUE_ANA_PYRIMIDINE; }
  /* MSE, MLY, frequently observed cation, and anions (3000+) */
  else if(!strncmp(name,"MSE",3)) ri->type = RESIDUE_NSAA_BASE + RESIDUE_MET;
  else if(!strncmp(name,"MLY",3)) ri->type = RESIDUE_NSAA_BASE + RESIDUE_LYS;
  else if(!strcmp(name,"_LI")|| !strcmp(name,"_NA")|| !strcmp(name,"__K") || !strcmp(name,"NH4") ||
          !strcmp(name,"_RB")|| !strcmp(name,"_CS")) ri->type = RESIDUE_ALKALI;
  else if(!strcmp(name,"_MG")|| !strcmp(name,"_CA")||
          !strcmp(name,"_SR")|| !strcmp(name,"_BA")) ri->type = RESIDUE_ALKALINE;
  else if(!strcmp(name,"SO4")|| !strcmp(name,"SO3")|| !strcmp(name,"SUL")||
          !strcmp(name,"PO4")|| !strcmp(name,"PO3")|| !strcmp(name,"ACT")||
          !strcmp(name,"CO3")|| !strcmp(name,"NO3")|| !strcmp(name,"NO2")||
          !strcmp(name,"__F")|| !strcmp(name,"_CL")|| !strcmp(name,"_BR")||
          !strcmp(name,"IOD")) ri->type = RESIDUE_ANION;
  /* sugar, solvent, heme, cofactor, non-standard proline that exist more than 300 times in PDB */
  else if(!strncmp(name,"NAG",3)|| !strncmp(name,"MAN",3)|| !strncmp(name,"GLC",3)|| !strncmp(name,"BMA",3)||
          !strncmp(name,"GAL",3)|| !strncmp(name,"NDG",3)|| !strncmp(name,"FUC",3)|| !strncmp(name,"BGC",3)||
          !strncmp(name,"XYP",3))                                                   ri->type = RESIDUE_SUGAR;
  else if(!strncmp(name,"GOL",3)|| !strncmp(name,"EDO",3)|| !strncmp(name,"DMS",3)|| !strncmp(name,"MPD",3)||
          !strncmp(name,"BME",3)|| !strncmp(name,"TRS",3)|| !strncmp(name,"MES",3)|| !strncmp(name,"PEG",3)||
          !strncmp(name,"IPA",3)|| !strncmp(name,"EOH",3)|| !strncmp(name,"MOH",3)) ri->type = RESIDUE_SOLVENT;
  else if(!strncmp(name,"HEM",3)|| !strncmp(name,"CL1",3)|| !strncmp(name,"CLA",3)|| !strncmp(name,"HEC",3)||
          !strncmp(name,"BCL",3))                                                   ri->type = RESIDUE_PORPHYRIN;
  else if(!strncmp(name,"NAD",3)|| !strncmp(name,"ADP",3)|| !strncmp(name,"FAD",3)|| !strncmp(name,"NAP",3)||
          !strncmp(name,"ATP",3)|| !strncmp(name,"FMN",3)|| !strncmp(name,"GDP",3)|| !strncmp(name,"AMP",3)||
          !strncmp(name,"NDP",3))                                                   ri->type = RESIDUE_COFACTOR;
  /* a comprehensive list of metal ions in PDB */
  else if(!strcmp(name,"UNX")|| !strcmp(name,"_AL")|| !strcmp(name,"_GA")|| !strcmp(name,"GA1")||
          !strcmp(name,"_IN")|| !strcmp(name,"_TL")|| !strcmp(name,"_PB")||
          !strcmp(name,"__V")|| !strcmp(name,"_CR")|| !strcmp(name,"_MN")|| !strcmp(name,"MN3")||
          !strcmp(name,"_FE")|| !strcmp(name,"FE2")|| !strcmp(name,"_CO")|| !strcmp(name,"3CO")||
          !strcmp(name,"_NI")|| !strcmp(name,"3NI")|| !strcmp(name,"_CU")|| !strcmp(name,"CU1")||
          !strcmp(name,"_ZN")|| !strcmp(name,"ZN2")|| !strcmp(name,"_Y1")|| !strcmp(name,"YT3")||
          !strcmp(name,"_MO")|| !strcmp(name,"4MO")|| !strcmp(name,"6MO")||
          !strcmp(name,"_RU")|| !strcmp(name,"_PD")|| !strcmp(name,"_AG")|| !strcmp(name,"_CD")||
          !strcmp(name,"_LA")|| !strcmp(name,"_CE")|| !strcmp(name,"_PR")|| !strcmp(name,"_SM")||
          !strcmp(name,"_EU")|| !strcmp(name,"EU3")|| !strcmp(name,"_GD")|| !strcmp(name,"GD3")||
          !strcmp(name,"_TB")|| !strcmp(name,"_HO")|| !strcmp(name,"HO3")|| !strcmp(name,"ER3")||
          !strcmp(name,"_YB")|| !strcmp(name,"_LU")|| !strcmp(name,"__W")|| !strcmp(name,"_RE")||
          !strcmp(name,"_OS")|| !strcmp(name,"OS4")|| !strcmp(name,"_IR")|| !strcmp(name,"IR3")||
          !strcmp(name,"_PT")|| !strcmp(name,"PT4")|| !strcmp(name,"_AU")|| !strcmp(name,"AU3")||
          !strcmp(name,"_HG")) ri->type = RESIDUE_CATION;
  /* a comprehensive list of sugar, heme, cofactor in PDB */
  else if(!strcmp(name,"CYC")|| !strcmp(name,"BPH")|| !strcmp(name,"CHL")|| !strcmp(name,"HEA")||
          !strcmp(name,"BCB")|| !strcmp(name,"BLA")|| !strcmp(name,"DHE")|| !strcmp(name,"PEB")||
          !strcmp(name,"BPB")|| !strcmp(name,"SFP")|| !strcmp(name,"HDD")|| !strcmp(name,"FEC")||
          !strcmp(name,"PHO")|| !strcmp(name,"HNI")|| !strcmp(name,"SRM")|| !strcmp(name,"PP9")||
          !strcmp(name,"COH"))                                             ri->type = RESIDUE_PORPHYRIN;
  else if(!strcmp(name,"1CP")|| !strcmp(name,"CLN")|| !strcmp(name,"CP3")|| !strcmp(name,"DDH")||
          !strcmp(name,"DEU")|| !strcmp(name,"FDD")|| !strcmp(name,"FDE")|| !strcmp(name,"FMI")||
          !strcmp(name,"H01")|| !strcmp(name,"H02")|| !strcmp(name,"HCO")|| !strcmp(name,"HE5")||
          !strcmp(name,"HEG")|| !strcmp(name,"HEV")|| !strcmp(name,"HFM")|| !strcmp(name,"HIF")||
          !strcmp(name,"HME")|| !strcmp(name,"MHM")|| !strcmp(name,"MMP")|| !strcmp(name,"MNH")||
          !strcmp(name,"MNR")|| !strcmp(name,"MP1")|| !strcmp(name,"PC3")|| !strcmp(name,"PCU")||
          !strcmp(name,"PNI")|| !strcmp(name,"POH")|| !strcmp(name,"POR")|| !strcmp(name,"VEA")||
          !strcmp(name,"VER")|| !strcmp(name,"ZEM")|| !strcmp(name,"ZNH")) ri->type = RESIDUE_PORPHYRIN;
  else if(!strcmp(name,"SIA")|| !strcmp(name,"GLA")|| !strcmp(name,"SUC")|| !strcmp(name,"XYS")||
          !strcmp(name,"MMA")|| !strcmp(name,"MAL")|| !strcmp(name,"FUL")|| !strcmp(name,"NGA")||
          !strcmp(name,"ADA")|| !strcmp(name,"SGN")|| !strcmp(name,"F6P")|| !strcmp(name,"A2G")||
          !strcmp(name,"IDS")|| !strcmp(name,"FBP")|| !strcmp(name,"LAT")|| !strcmp(name,"DAN")||
          !strcmp(name,"TRE")|| !strcmp(name,"AHR")|| !strcmp(name,"HBI")|| !strcmp(name,"DDA")||
          !strcmp(name,"AMG")|| !strcmp(name,"SGC")|| !strcmp(name,"GCU")|| !strcmp(name,"FRU")||
          !strcmp(name,"G1P")|| !strcmp(name,"G6P")|| !strcmp(name,"XYL")|| !strcmp(name,"AAL")||
          !strcmp(name,"BDP")|| !strcmp(name,"M8C")|| !strcmp(name,"RAM")|| !strcmp(name,"MFU")||
          !strcmp(name,"GMH")|| !strcmp(name,"G2F")|| !strcmp(name,"NBG")|| !strcmp(name,"SOR")||
          !strcmp(name,"IDU")|| !strcmp(name,"2FG")|| !strcmp(name,"GLD")|| !strcmp(name,"RIP")||
          !strcmp(name,"MAG")|| !strcmp(name,"UGA")|| !strcmp(name,"BG6")|| !strcmp(name,"CBS")||
          !strcmp(name,"RIB")|| !strcmp(name,"SLB")|| !strcmp(name,"CBI")|| !strcmp(name,"MNA")||
          !strcmp(name,"2FL")|| !strcmp(name,"UDA")|| !strcmp(name,"XMM")|| !strcmp(name,"16G")||
          !strcmp(name,"MLR")|| !strcmp(name,"GAA")|| !strcmp(name,"G6D")|| !strcmp(name,"FCA")||
          !strcmp(name,"R1P")|| !strcmp(name,"RP5")|| !strcmp(name,"ROB")|| !strcmp(name,"MGL")||
          !strcmp(name,"GLP")|| !strcmp(name,"LBT")|| !strcmp(name,"2FP")|| !strcmp(name,"M6P")||
          !strcmp(name,"ADQ")|| !strcmp(name,"DAF")|| !strcmp(name,"AGL")|| !strcmp(name,"FDP")||
          !strcmp(name,"MGC")|| !strcmp(name,"GYP")|| !strcmp(name,"DDL")|| !strcmp(name,"CDR")||
          !strcmp(name,"RNS")|| !strcmp(name,"DXP")|| !strcmp(name,"GDD")|| !strcmp(name,"DX5")||
          !strcmp(name,"F6R")|| !strcmp(name,"AAB")|| !strcmp(name,"1GL")|| !strcmp(name,"CSF")||
          !strcmp(name,"MAV")|| !strcmp(name,"145")|| !strcmp(name,"G4S")|| !strcmp(name,"GCV")||
          !strcmp(name,"CTO")|| !strcmp(name,"MTT")|| !strcmp(name,"G6Q")|| !strcmp(name,"P5P")||
          !strcmp(name,"MBG")|| !strcmp(name,"GCN")|| !strcmp(name,"LGU")|| !strcmp(name,"ORP")||
          !strcmp(name,"SGA")|| !strcmp(name,"GLO")|| !strcmp(name,"MDM")) ri->type = RESIDUE_SUGAR;
  else if(!strcmp(name,"GTP")|| !strcmp(name,"5CM")|| !strcmp(name,"UDP")|| !strcmp(name,"PSU")||
          !strcmp(name,"UMP")|| !strcmp(name,"BRU")|| !strcmp(name,"_DU")|| !strcmp(name,"H2U")||
          !strcmp(name,"U5P")|| !strcmp(name,"TTP")|| !strcmp(name,"OMG")|| !strcmp(name,"5MC")||
          !strcmp(name,"ADN")|| !strcmp(name,"CBR")|| !strcmp(name,"5GP")|| !strcmp(name,"5BU")||
          !strcmp(name,"CMP")|| !strcmp(name,"5MU")|| !strcmp(name,"THM")|| !strcmp(name,"OMC")||
          !strcmp(name,"5IU")|| !strcmp(name,"TMP")|| !strcmp(name,"CTP")|| !strcmp(name,"1MA")||
          !strcmp(name,"APR")|| !strcmp(name,"C5P")|| !strcmp(name,"DTP")|| !strcmp(name,"TYD")||
          !strcmp(name,"OMU")|| !strcmp(name,"8OG")|| !strcmp(name,"DOC")|| !strcmp(name,"ADX")||
          !strcmp(name,"7MG")|| !strcmp(name,"DCP")|| !strcmp(name,"2MG")|| !strcmp(name,"MTA")||
          !strcmp(name,"DUT")|| !strcmp(name,"UTP")|| !strcmp(name,"M2G")|| !strcmp(name,"GSP")||
          !strcmp(name,"CDP")|| !strcmp(name,"DGT")|| !strcmp(name,"DUR")|| !strcmp(name,"C43")||
          !strcmp(name,"G48")|| !strcmp(name,"BGM")|| !strcmp(name,"DCT")|| !strcmp(name,"A2M")||
          !strcmp(name,"6MA")|| !strcmp(name,"C42")|| !strcmp(name,"BMP")|| !strcmp(name,"DCZ")||
          !strcmp(name,"6OG")|| !strcmp(name,"UFP")|| !strcmp(name,"ABG")|| !strcmp(name,"DDG")||
          !strcmp(name,"DUP")|| !strcmp(name,"A23")|| !strcmp(name,"GMP")|| !strcmp(name,"DGP")||
          !strcmp(name,"UP6")|| !strcmp(name,"G38")|| !strcmp(name,"DUD")|| !strcmp(name,"UMS")||
          !strcmp(name,"SAP")|| !strcmp(name,"2DT")|| !strcmp(name,"TDR")|| !strcmp(name,"M7G")||
          !strcmp(name,"_LG")|| !strcmp(name,"3AT")|| !strcmp(name,"A44")|| !strcmp(name,"U36")||
          !strcmp(name,"PDU")|| !strcmp(name,"BT5")|| !strcmp(name,"DCM")|| !strcmp(name,"1MG")||
          !strcmp(name,"D5M")|| !strcmp(name,"4SU")|| !strcmp(name,"CBV")|| !strcmp(name,"MGT")||
          !strcmp(name,"NYM")|| !strcmp(name,"DAD")|| !strcmp(name,"_LC")|| !strcmp(name,"CCC")||
          !strcmp(name,"CDF")|| !strcmp(name,"A43")|| !strcmp(name,"ATM")|| !strcmp(name,"_IU")||
          !strcmp(name,"A5M")|| !strcmp(name,"PCG")|| !strcmp(name,"5PC")|| !strcmp(name,"MA7")||
          !strcmp(name,"5AD")|| !strcmp(name,"THU")|| !strcmp(name,"126")|| !strcmp(name,"ATR"))
                                                                           ri->type = RESIDUE_COFACTOR;
  /* a comprehensive list of non-standard amino acid residues in PDB */
/*else if(!strcmp(name,"AIB")|| !strcmp(name,"ALM")|| !strcmp(name,"AYA")|| !strcmp(name,"CHG")||
          !strcmp(name,"CSD")|| !strcmp(name,"DAL")|| !strcmp(name,"DNP")|| !strcmp(name,"DHA")||
          !strcmp(name,"FLA")|| !strcmp(name,"HAC")|| !strcmp(name,"MAA")|| !strcmp(name,"PRR")||
          !strcmp(name,"TIH")|| !strcmp(name,"TPQ")|| !strcmp(name,"BAL")|| !strcmp(name,"DBZ")||
          !strcmp(name,"NAL")|| !strcmp(name,"PFF")|| !strcmp(name,"R1A")|| !strcmp(name,"NCB"))
                                                     ri->type = RESIDUE_NSAA_BASE + RESIDUE_ALA;
  else if(!strcmp(name,"C5C")|| !strcmp(name,"C6C")|| !strcmp(name,"CCS")|| !strcmp(name,"CEA")|| 
          !strcmp(name,"CME")|| !strcmp(name,"CSO")|| !strcmp(name,"CSP")|| !strcmp(name,"CSS")|| 
          !strcmp(name,"CSW")|| !strcmp(name,"CSX")|| !strcmp(name,"CY1")|| !strcmp(name,"CY3")|| 
          !strcmp(name,"CYG")|| !strcmp(name,"CYM")|| !strcmp(name,"CYQ")|| !strcmp(name,"BCS")|| 
          !strcmp(name,"BUC")|| !strcmp(name,"DCY")|| !strcmp(name,"EFC")|| !strcmp(name,"OCS")|| 
          !strcmp(name,"PR3")|| !strcmp(name,"PEC")|| !strcmp(name,"SCS")|| !strcmp(name,"SCH")|| 
          !strcmp(name,"SCY")|| !strcmp(name,"SHC")|| !strcmp(name,"SOC")|| !strcmp(name,"SMC")||
          !strcmp(name,"CAS")|| !strcmp(name,"CMH")|| !strcmp(name,"SC2")|| !strcmp(name,"CSU")||
          !strcmp(name,"CAF")|| !strcmp(name,"GSW")|| !strcmp(name,"NCY")|| !strcmp(name,"CSE")||
          !strcmp(name,"S2C")|| !strcmp(name,"SNC")|| !strcmp(name,"RCY")) ri->type = RESIDUE_NSAA_BASE + RESIDUE_CYS;
  else if(!strcmp(name,"2AS")|| !strcmp(name,"BHD")|| !strcmp(name,"DAS")|| !strcmp(name,"DSP")|| 
          !strcmp(name,"ASA")|| !strcmp(name,"ASB")|| !strcmp(name,"ASK")|| !strcmp(name,"ASL")|| 
          !strcmp(name,"ASI")|| !strcmp(name,"ACB")|| !strcmp(name,"PAL")|| !strcmp(name,"NCD")||
          !strcmp(name,"ASQ")|| !strcmp(name,"ASX")) ri->type = RESIDUE_NSAA_BASE + RESIDUE_ASP;
  else if(!strcmp(name,"5HP")|| !strcmp(name,"CGU")|| !strcmp(name,"DGL")|| !strcmp(name,"GGL")|| 
          !strcmp(name,"GLX")|| !strcmp(name,"GMA")|| !strcmp(name,"PCA")|| !strcmp(name,"NLG")||
          !strcmp(name,"GLH")|| !strcmp(name,"PGU")) ri->type = RESIDUE_NSAA_BASE + RESIDUE_GLU;
  else if(!strcmp(name,"BNN")|| !strcmp(name,"DAH")|| !strcmp(name,"DPN")|| !strcmp(name,"HPQ")|| 
          !strcmp(name,"NFA")|| !strcmp(name,"PHI")|| !strcmp(name,"PHL")) ri->type = RESIDUE_NSAA_BASE + RESIDUE_PHE;
  else if(!strcmp(name,"GSC")|| !strcmp(name,"GL3")|| !strcmp(name,"GLZ")|| !strcmp(name,"MPQ")||
          !strcmp(name,"MSA")|| !strcmp(name,"NMC")|| !strcmp(name,"SAR")|| !strcmp(name,"BET"))
                                                     ri->type = RESIDUE_NSAA_BASE + RESIDUE_GLY;
  else if(!strcmp(name,"3AH")|| !strcmp(name,"DHI")|| !strcmp(name,"HIP")|| !strcmp(name,"HIC")||
          !strcmp(name,"MHS")|| !strcmp(name,"NEP")|| !strcmp(name,"NEM")) ri->type = RESIDUE_NSAA_BASE + RESIDUE_HIS;
  else if(!strcmp(name,"DIL")|| !strcmp(name,"IIL")) ri->type = RESIDUE_NSAA_BASE + RESIDUE_ILE;
  else if(!strcmp(name,"ALY")|| !strcmp(name,"DLY")|| !strcmp(name,"LLY")|| !strcmp(name,"LLP")||
          !strcmp(name,"LYM")|| !strcmp(name,"LYZ")|| !strcmp(name,"KCX")|| !strcmp(name,"SHR")|| 
          !strcmp(name,"TRG")|| !strcmp(name,"M3L")|| !strcmp(name,"MLZ")|| !strcmp(name,"LCX"))
                                                     ri->type = RESIDUE_NSAA_BASE + RESIDUE_LYS;
  else if(!strcmp(name,"BUG")|| !strcmp(name,"CLE")|| !strcmp(name,"DLE")|| !strcmp(name,"MLE")|| 
          !strcmp(name,"NLE")|| !strcmp(name,"NLN")|| !strcmp(name,"NLP")|| !strcmp(name,"DNE")||
          !strcmp(name,"ONL"))                       ri->type = RESIDUE_NSAA_BASE + RESIDUE_LEU;
  else if(!strcmp(name,"SAM")|| !strcmp(name,"MME")|| !strcmp(name,"OMT")|| !strcmp(name,"CXM")||
          !strcmp(name,"FME"))                       ri->type = RESIDUE_NSAA_BASE + RESIDUE_MET;
  else if(!strcmp(name,"MEN")|| !strcmp(name,"DMH")|| !strcmp(name,"DSG")) ri->type = RESIDUE_NSAA_BASE + RESIDUE_ASN;
  else if(!strcmp(name,"DGN")|| !strcmp(name,"MGN")) ri->type = RESIDUE_NSAA_BASE + RESIDUE_GLN;
  else if(!strcmp(name,"ACL")|| !strcmp(name,"AGM")|| !strcmp(name,"ARM")|| !strcmp(name,"DAR")|| 
          !strcmp(name,"HAR")|| !strcmp(name,"HMR")|| !strcmp(name,"MAI")) ri->type = RESIDUE_NSAA_BASE + RESIDUE_ARG;
  else if(!strcmp(name,"DSN")|| !strcmp(name,"MIS")|| !strcmp(name,"OAS")|| !strcmp(name,"SAC")|| 
          !strcmp(name,"SEL")|| !strcmp(name,"SEP")|| !strcmp(name,"SET")|| !strcmp(name,"SVA")||
          !strcmp(name,"SEB"))                       ri->type = RESIDUE_NSAA_BASE + RESIDUE_SER;
  else if(!strcmp(name,"ALO")|| !strcmp(name,"BMT")|| !strcmp(name,"DTH")|| !strcmp(name,"TPO"))
                                                     ri->type = RESIDUE_NSAA_BASE + RESIDUE_THR;
  else if(!strcmp(name,"DIV")|| !strcmp(name,"DVA")|| !strcmp(name,"MVA")|| !strcmp(name,"NVA")||
          !strcmp(name,"SN0"))                       ri->type = RESIDUE_NSAA_BASE + RESIDUE_VAL;
  else if(!strcmp(name,"DTR")|| !strcmp(name,"HTR")|| !strcmp(name,"LTR")|| !strcmp(name,"TPL")|| 
          !strcmp(name,"TRO")|| !strcmp(name,"TRN")) ri->type = RESIDUE_NSAA_BASE + RESIDUE_TRP;
  else if(!strcmp(name,"DTY")|| !strcmp(name,"IYR")|| !strcmp(name,"PAQ")|| !strcmp(name,"PTR")|| 
          !strcmp(name,"STY")|| !strcmp(name,"TYB")|| !strcmp(name,"TYS")|| !strcmp(name,"TYY")|| 
          !strcmp(name,"TYQ")|| !strcmp(name,"TYI")) ri->type = RESIDUE_NSAA_BASE + RESIDUE_TYR;
  else if(!strncmp(name,"HYP",3)|| !strncmp(name,"DPR",3)|| !strncmp(name,"DP9",3)|| !strncmp(name,"4FB",3))
                                                                                    ri->type = RESIDUE_NSAA_BASE + RESIDUE_PRO;
  */
  else {
  /* everything else is just assigned as a general ligand */
    ri->type = RESIDUE_LIGAND;
  /* with the exception of rare non-standard amino acids */
    irt=RESIDUE_UNDEF;
    for(j=0;irt>=RESIDUE_UNDEF;j++) {
      irt=aminoacid_dictionary[j].type;
      if(!strcmp(name,aminoacid_dictionary[j].nsa)) {
        ri->type = RESIDUE_NSAA_BASE + irt;
        break;
      }
    }
  }
  ci=ri->ChainInfo;
  if(ri->type<=RESIDUE_AMINOACID)   ci->numProteinRes++;
  else if(ri->type==RESIDUE_WATER)  ci->numWaterRes++;
  else if(ri->type>=RESIDUE_DNA_PURINE && ri->type<=RESIDUE_DNARNA) ci->numDnarnaRes++;
  else                              ci->numLigandRes++;
}

void EntityMoleculeAssignType(ObjEntityMolecule *I) {
  int i, im, irt, j, numAtom;
  ObjChainInfo *ci;
  ObjMoleculeInfo*moinfo=NULL,*mi;
  ObjResidueInfo *ri;
  ObjAtomInfo *ai;
  char *name, *elem;

  /* Assign chain type2 */
  I->numMolecule=0;
  for(i=0;i<I->numChain;i++) {
    ci=I->ChainInfo+i;
    if(ci->numWaterRes)   { ci->type2+=CHAIN_TYPE2_WATER;   ci->numMolecule++; }
    if(ci->numLigandRes)  { ci->type2+=CHAIN_TYPE2_LIGAND;  ci->numMolecule+=ci->numLigandRes; }
    if(ci->numDnarnaRes)  { ci->type2+=CHAIN_TYPE2_DNARNA;  ci->numMolecule++; }
    if(ci->numProteinRes) { ci->type2+=CHAIN_TYPE2_PROTEIN; ci->numMolecule++; }
    I->numMolecule += ci->numMolecule;
  }

  /* Create molecule object and assign molecule type */
  AllocP(moinfo,ObjMoleculeInfo,(I->numMolecule+1));
  I->MoleculeInfo = moinfo;
  for(im=0;im<I->numMolecule;im++) {
    mi=I->MoleculeInfo+im;
    ObjMoleculeInit(mi);
    mi->index=im;
  }
  im=0;
  for(i=0;i<I->numChain;i++) {
    ci=I->ChainInfo+i;
    ci->MoleculeInfo = I->MoleculeInfo+im;
    if(ci->numProteinRes) {
      mi=I->MoleculeInfo+im;            mi->type=COMPONENT_AMINOACID;
      mi->chain=ci->chainid;            mi->ChainInfo=ci;
      mi->numResidue=ci->numProteinRes; im++;
    }
    if(ci->numDnarnaRes) {
      mi=I->MoleculeInfo+im;            mi->type=COMPONENT_NUCLEOTIDE;
      mi->chain=ci->chainid;            mi->ChainInfo=ci;
      mi->numResidue=ci->numDnarnaRes;  im++;
    }
    if(ci->numWaterRes) {
      mi=I->MoleculeInfo+im;            mi->type=COMPONENT_WATER;
      mi->chain=ci->chainid;            mi->ChainInfo=ci;
      mi->numResidue=ci->numWaterRes;   im++;
    }
    if(ci->numLigandRes) {
      for(j=0;j<ci->numLigandRes;j++) {
        mi=I->MoleculeInfo+im;      mi->type=COMPONENT_OTHER;
        mi->chain=ci->chainid;      mi->ChainInfo=ci;
        mi->numResidue=-1;          im++;
     // mi->numResidue is served as a flag to check if a ligand residue is linked to molecule or not
     // when mi->numResidue == -1, the corresponding ligand residue hasn't been linked to this molecule yet
     // only after a ligand residue is linked to the molecule, mi->numResidue will be set to 1
      }
    }
  }
  for(i=0;i<I->numResidue;i++) {
    ri=I->ResidueInfo+i;
    ci=ri->ChainInfo;
    mi=ci->MoleculeInfo;
    if(ri->type<=RESIDUE_AMINOACID) {
      if(mi->type == COMPONENT_AMINOACID) {
        ri->molecule_index=mi->index;
        ri->MoleculeInfo=mi;
      } else PFatalError("Invalid molecule type, amino acid residues should always be in first molecule of each chain.\n");
    } else if(ri->type>=RESIDUE_DNA_PURINE && ri->type<=RESIDUE_DNARNA) {
      if(mi->type == COMPONENT_AMINOACID)  { im=mi->index+1; mi=I->MoleculeInfo+im; }
      if(mi->type == COMPONENT_NUCLEOTIDE) {
        ri->molecule_index=mi->index;
        ri->MoleculeInfo=mi;
      } else PFatalError("Invalid molecule type, nucleotide residues should always be in first or second molecule of each chain.\n");
    } else if(ri->type==RESIDUE_WATER) {
      if(mi->type == COMPONENT_AMINOACID)  { im=mi->index+1; mi=I->MoleculeInfo+im; }
      if(mi->type == COMPONENT_NUCLEOTIDE) { im=mi->index+1; mi=I->MoleculeInfo+im; }
      if(mi->type == COMPONENT_WATER) {
        ri->molecule_index=mi->index;
        ri->MoleculeInfo=mi;
      } else PFatalError("Invalid molecule type, water residues should always be after amino acid and nucleotide residues of each chain.\n");
    } else {
      if(mi->type == COMPONENT_AMINOACID)  { im=mi->index+1; mi=I->MoleculeInfo+im; }
      if(mi->type == COMPONENT_NUCLEOTIDE) { im=mi->index+1; mi=I->MoleculeInfo+im; }
      if(mi->type == COMPONENT_WATER)      { im=mi->index+1; mi=I->MoleculeInfo+im; }
      while(mi->numResidue == 1)           { im=mi->index+1; mi=I->MoleculeInfo+im; }
      if(mi->type == COMPONENT_OTHER && mi->numResidue == -1) {
        ri->molecule_index=mi->index;
        ri->MoleculeInfo=mi;
        mi->numResidue=1;
      } else PFatalError("Invalid molecule type, either molecule is not expecting a small molecule ligand, or molecule has been occupied by another ligand residue.\n");
    }
  }

  /* Assign atom type */
  for(i=0;i<I->numAtom;i++) {
    ai=I->AtomInfo+i;
    elem=ai->elem;
    ai->type = ATOM_OTHER;      // default if won't be recognized
    ri=ai->ResidueInfo;
    if (ri->type <= RESIDUE_AMINOACID) {
      irt = ri->type;        // if it will be an even number, indicating non-standard residue,
      if (!(irt & 1)) irt--; // project to its corresponding standard residue name for atom type assignment whenever possible
      name=ai->realname;
      if(elem[1]=='_') {
        if(elem[0]=='C') {
           if(name[2]=='-') ai->type = ATOM_MC_C;
           else if(name[2]=='A' && name[3]=='-') ai->type = ATOM_MC_CA;
           else if(name[2]=='B' && name[3]=='-') ai->type = ATOM_SC_CB;
           else if(irt==RESIDUE_PHE || irt==RESIDUE_TYR ||
                   irt==RESIDUE_HIS || irt==RESIDUE_TRP) ai->type = ATOM_SC_C_RING;
           else ai->type = ATOM_SC_C;
        } else if(elem[0]=='O') {
           if(name[2]=='-') ai->type=ATOM_MC_O;
           else if(irt==RESIDUE_ASP || irt==RESIDUE_GLU) ai->type=ATOM_SC_O_CARBOXYL;
           else if(irt==RESIDUE_ASN || irt==RESIDUE_GLN) ai->type=ATOM_SC_O_AMIDE;
           else if(irt==RESIDUE_SER || irt==RESIDUE_THR) ai->type=ATOM_SC_O_HYDROXYL;
           else if(irt==RESIDUE_TYR)                     ai->type=ATOM_SC_O_PHENOL;
           else ai->type=ATOM_SC_O_HETERO;
        } else if(elem[0]=='N') {
           if(name[2]=='-') ai->type=ATOM_MC_N;
           else if(irt==RESIDUE_LYS) ai->type=ATOM_SC_N_LYS;
           else if(irt==RESIDUE_ARG) ai->type=ATOM_SC_N_ARG;
           else if(irt==RESIDUE_ASN || irt==RESIDUE_GLN) ai->type=ATOM_SC_N_AMIDE;
           else if(irt==RESIDUE_HIS) ai->type=ATOM_SC_N_HIS;
           else if(irt==RESIDUE_TRP) ai->type=ATOM_SC_N_TRP;
           else ai->type=ATOM_SC_N_HETERO;
        } else if(elem[0]=='S') {
           if(irt==RESIDUE_CYS) ai->type=ATOM_SC_S_CYS;
           else if(irt==RESIDUE_MET) ai->type=ATOM_SC_S_MET;
           else ai->type=ATOM_SC_S_HETERO;
        } else if(index("HDQ",elem[0])) ai->type = ATOM_HYDROGEN;
          else ai->type = ATOM_SC_X_HETERO;
        if (ai->type>=ATOM_MC_N && ai->type<=ATOM_MC_O) ai->moiety_type = MOIETY_MC;
        else if (irt==RESIDUE_ASP || irt==RESIDUE_GLU)  ai->moiety_type = MOIETY_SC_ACIDIC;
        else if (irt==RESIDUE_HIS || irt==RESIDUE_ARG || irt==RESIDUE_LYS)
                                                        ai->moiety_type = MOIETY_SC_BASIC;
        else if (irt==RESIDUE_SER || irt==RESIDUE_THR || irt==RESIDUE_CYS ||
                 irt==RESIDUE_ASN || irt==RESIDUE_GLN)  ai->moiety_type = MOIETY_SC_HYDROPHILIC;
        else                                            ai->moiety_type = MOIETY_SC_HYDROPHOBIC;
      } else if (!strncmp(elem,"Se",2)) { ai->moiety_type = MOIETY_SC_HYDROPHOBIC; ai->type = ATOM_SC_SE;
      } else ai->type = ATOM_SC_X_HETERO;
    } else if (ri->type == RESIDUE_WATER) {
      ai->moiety_type=MOIETY_WATER;
      if(elem[1]=='_') {
        if     (elem[0]=='O') ai->type = ATOM_WT_O;
        else if(index("HDQ",elem[0])) ai->type = ATOM_HYDROGEN;
      }
    } else if (ri->type>=RESIDUE_DNA_PURINE && ri->type<=RESIDUE_DNARNA) {
      name=ai->realname;
      if(elem[1]=='_') {
        if(elem[0]=='O') {
           if(name[3]=='\'') {
             ai->moiety_type = MOIETY_RIBOSE;
             if(name[2]=='2') ai->type = ATOM_NA_O2_RIBOSE;
             else if(name[2]=='4') ai->type = ATOM_NA_O4_RIBOSE;
             else if(name[2]=='3' || name[2]=='5') ai->type = ATOM_NA_OP_BRIDGE;
             else if((name[2]=='1' || name[2]=='7') && (ri->type==RESIDUE_PNA_PURINE || ri->type==RESIDUE_PNA_PYRIMIDINE)) {
               ai->moiety_type = MOIETY_MC;
               ai->type = ATOM_MC_O;
             } else PFatalError("Oxygen atom name from ribose in uncleic acid contains unrecognized pattern");
           } else {
             ai->moiety_type = (name[2]=='P') ? MOIETY_PHOSPHATE    : MOIETY_BASE;
             ai->type        = (name[2]=='P') ? ATOM_NA_OP_TERMINAL : ATOM_NA_O_BASE;
           }
        } else if(elem[0]=='N') {
           ai->moiety_type = MOIETY_BASE;
           if(name[3]=='-') {
             if(ri->type==RESIDUE_RNA_PURINE || ri->type==RESIDUE_DNA_PURINE || ri->type==RESIDUE_PNA_PURINE || ri->type==RESIDUE_ANA_PURINE) {
               if(name[2]=='9')            ai->type = ATOM_NA_N_BASE_RIBOSE;
               else if ((name[2]-'0') & 1) {
                 if(ri->resn[2]=='G' && name[2]=='1') ai->type = ATOM_NA_NH_BASE_ENDO;
                 else                      ai->type = ATOM_NA_N_BASE_ENDO;      // Odd number are on the ring
               } else                      ai->type = ATOM_NA_N_BASE_AMIDE;     // Even number are NH2
             } else if(ri->type==RESIDUE_RNA_PYRIMIDINE || ri->type==RESIDUE_DNA_PYRIMIDINE || ri->type==RESIDUE_PNA_PYRIMIDINE || ri->type==RESIDUE_ANA_PYRIMIDINE) {
               if(name[2]=='1')            ai->type = ATOM_NA_N_BASE_RIBOSE;
               else if ((name[2]-'0') & 1) {
                 if(ri->resn[2]=='U' && name[2]=='3') ai->type = ATOM_NA_NH_BASE_ENDO;
                 else                      ai->type = ATOM_NA_N_BASE_ENDO;      // Odd number are on the ring
               } else                      ai->type = ATOM_NA_N_BASE_AMIDE;     // Even number are NH2
             } else if(ri->type==RESIDUE_DNARNA) ai->type = ATOM_NA_N_BASE_ENDO;
           } else if(name[3]=='\'' && (name[2]=='1' || name[2]=='4') && (ri->type==RESIDUE_PNA_PURINE ||  ri->type==RESIDUE_PNA_PYRIMIDINE)) {
             ai->moiety_type = MOIETY_MC;
             ai->type = ATOM_MC_N;
           }
        } else if(elem[0]=='C') {
          if(name[3]!='\'' && name[2]!='\'') { ai->moiety_type = MOIETY_BASE; ai->type=ATOM_NA_C_BASE; }
          else {
            if(ri->type==RESIDUE_PNA_PURINE || ri->type==RESIDUE_PNA_PYRIMIDINE) {
              ai->moiety_type = MOIETY_MC;
              ai->type=ATOM_MC_C;
            } else {
              ai->moiety_type = MOIETY_RIBOSE;
              ai->type = (name[2]=='3' || name[2]=='5') ? ATOM_NA_C_BRIDGE : ATOM_NA_C_RIBOSE;
            }
          }
        } else if(elem[0]=='P') { ai->moiety_type = MOIETY_PHOSPHATE; ai->type = ATOM_NA_P;
        } else if(index("HDQ",elem[0])) ai->type = ATOM_HYDROGEN;
      }
    } else if (ri->type==RESIDUE_SUGAR) {
      ai->moiety_type = MOIETY_CARBOHYDRATE;
      if(elem[1]=='_') {
        if(elem[0]=='C')              ai->type=ATOM_GC_C;
        else if(elem[0]=='O')         ai->type=ATOM_GC_O;
        else if(elem[0]=='N')         ai->type=ATOM_GC_N;
        else if(index("HDQ",elem[0])) ai->type=ATOM_HYDROGEN;
        else                          ai->type=ATOM_GC_X;
      } else                          ai->type=ATOM_GC_X;
    } else {                    // assume RESIDUE_LIGAND as default
      ai->moiety_type = MOIETY_LIGAND;
      if(elem[1]=='_') {
        switch(elem[0]) {
          case 'C': ai->type = ATOM_LG_C; break;
          case 'O': ai->type = ATOM_LG_O; break;
          case 'N': ai->type = ATOM_LG_N; break;
          case 'P': ai->type = ATOM_LG_P; break;
          case 'S': ai->type = ATOM_LG_S; break;
          case 'H':
          case 'D':
          case 'Q': ai->type = ATOM_LG_H; break;
          case 'K': ai->type = ATOM_ALKALI;     break;
          case 'F':
          case 'I': ai->type = ATOM_HALOGEN;    break;
          case 'B': ai->type = ATOM_LIGHT;      break;
          default:  ai->type = ATOM_HEAVY;      break;
        }
      } else {
        if      (!strncmp(elem,"Li",2) || !strncmp(elem,"Na",2) || !strncmp(elem,"Rb",2) ||
                 !strncmp(elem,"Cs",2) || !strncmp(elem,"Fr",2)) ai->type = ATOM_ALKALI;
        else if (!strncmp(elem,"Be",2) || !strncmp(elem,"Mg",2) ||
                 !strncmp(elem,"Ca",2) || !strncmp(elem,"Sr",2) ||
                 !strncmp(elem,"Ba",2) || !strncmp(elem,"Ra",2)) ai->type = ATOM_ALKALINE;
        else if (!strncmp(elem,"Cl",2) || !strncmp(elem,"Br",2)) ai->type = ATOM_HALOGEN;
        else if (!strncmp(elem,"He",2) || !strncmp(elem,"Ne",2) || !strncmp(elem,"Al",2) ||
                 !strncmp(elem,"Si",2) || !strncmp(elem,"Ar",2)) ai->type = ATOM_LIGHT;
        else ai->type = ATOM_HEAVY;
      }
      if (ai->type == ATOM_ALKALI || ai->type == ATOM_ALKALINE) ai->moiety_type = MOIETY_CATION;
      else if (ai->type == ATOM_HALOGEN) ai->moiety_type = MOIETY_ANION;
      if (ai->type == ATOM_HEAVY && ri->type == RESIDUE_LIGAND) ri->type=RESIDUE_HEAVY; /* Heavy residue is defined as residue that contain at least one heavy atom */
//    if (ai->type==ATOM_HEAVY||ri->type==RESIDUE_LIGAND) ri->type=RESIDUE_HEAVY;       /* This wrong condition was misused in neighborhood v1.0 */
    }
  }

  /* Assign for each residue, whether residue contains more than one non-hydrogen atom, 2 indicates water */
  for(i=0;i<I->numResidue;i++) {
    ri=I->ResidueInfo+i;
    ri->isSingle=0;
    if(ri->type == RESIDUE_WATER) {
      ri->containsMetal=0;
      ri->isSingle=2;
    } else {
      numAtom=0;
      ri->containsMetal=0;
      for(j=0;j<ri->numAtom;j++) {
        ai=ri->AtomInfo+j;
        if(!ai->hydrogen) numAtom++;
        if(ai->isMetal) ri->containsMetal=1;
      }
      if(numAtom==1) ri->isSingle=1;
      /* Handle special case exception when a residue with single N atom on peptide chain N-terminal */
      if(ri->isSingle==1 && ri->type<=RESIDUE_AMINOACID) {
        ai=ri->AtomInfo;
        if(ai->type==ATOM_MC_N) ri->isSingle=0;
      }
    }
  }
}

/*---------------------------------------------------------------------------*/
void EntityMoleculeAssignCenterDisplacement(ObjEntityMolecule *I) {
  // Value to be assigned in this subroutine includes:
  // For each chain:   ObjChainInfo->Center
  // For each residue: ObjResidueInfo->center_displacement (regarding center of chain it belongs)
  // For each atom:    ObjAtomInfo->center_displacement    (regarding center of chain it belongs)
  //
  // ObjResidueInfo->Center, However, has already been assigned in subroutine EntityMoleculeReadPDBStr
  // And need not be assigned again here
  ObjChainInfo *ci;
  ObjResidueInfo *ri;
  ObjAtomInfo *ai;
  int i;
  float *v;
  // calculating ObjChainInfo->Center
  for(i=0;i<I->numChain;i++) {
    ci=I->ChainInfo+i;
    VectorClear3f(ci->Center);
  }
  for(i=0;i<I->numAtom;i++) {
    v=I->Coord+(3*i);
    ai=I->AtomInfo+i;
    ri=ai->ResidueInfo;
    ci=ri->ChainInfo;
    VectorAdd3f(ci->Center, v);
  }
  for(i=0;i<I->numChain;i++) {
    ci=I->ChainInfo+i;
    VectorAverage3f(ci->Center, ci->numAtom);
  }

  // calculating ObjResidueInfo->center_displacement
  for(i=0;i<I->numResidue;i++) {
    ri=I->ResidueInfo+i;
    ci=ri->ChainInfo;
    ri->center_displacement=VectorDistance2v(ri->Center, ci->Center);
  }

  // calculating ObjAtomInfo->center_displacement
  for(i=0;i<I->numAtom;i++) {
    v=I->Coord+(3*i);
    ai=I->AtomInfo+i;
    ri=ai->ResidueInfo;
    ci=ri->ChainInfo;
    ai->center_displacement=VectorDistance2v(v, ci->Center);
  }
}

/*---------------------------------------------------------------------------*/
void EntityMoleculeGenerateCenter(ObjEntityMolecule *I) {
  int i;
  float *v;
  if(I->numAtom) {
    v=I->Coord;
    VectorCopy3f(I->Min,v);
    VectorCopy3f(I->Max,v);
    for(i=0;i<I->numAtom;i++) {
      VectorMin3f(I->Min,v);
      VectorMax3f(I->Max,v);
      v+=3;
    }
  }
  VectorMiddle3f(I->Min,I->Max,I->Center);
}

/*---------------------------------------------------------------------------*/
void EntityMoleculeNeighbor(ObjEntityMolecule *I, float cutoff, char *buffer_molprobity, char *buffer_contact) {
  int i,j,k,a,b,c,d,e,f,contact_flag;
  int anbCount,maxNeighbor,anbCount0,nbvCount;          /* For STEP 1 */
  int symopCount,contact_fwd,contact_alt,compare_atom;  /* For STEP 2 */
  int rnbCount,maxNeighbor2,rnbCount0;                  /* For STEP 3 */
  int rnbFound, distCalculated;
  int hasMetalContact, backboneLink, consecutive_flag;
  int molprobity_section, numMolprobityMapping;
  float dist, dist_temp, dist_min;
  float *v1,*v2,v3[3];
  char *p,q[FileLineLength],msg[FileLineLength],bond_type,temp_chain;
  ObjAtomInfo     *atinfo, *ai1, *ai2, *ai3, atm1, atm2;
  ObjResidueInfo  *rsinfo, *ri1, *ri2, res1, res2;
  ObjNeighborInfo *anbinfo, *rnbinfo, *ani, *ani2, *rni;
  ObjNeighborVectorInfo *nbvinfo, *vni, *vni_res;
  MolprobityMapping *mpm=NULL;
  ObjMolprobityInfo *mpinfo=NULL, *mpi;
  ObjHash *hash;
  ObjNeighborStack *alt_stack, *vec_stack, *glycan_stack;
  RecNeighborStack *stack_rec;
  float cutoff2=cutoff+1.0f;
  int nalt1, alt_ai1[9], nalt2, alt_ai2[9], alt_processed, numSugarLink;
  int cell_id, symop_id, symop_id_max, symop_found;
  SymopNum symop_num;
  SymopDict *symmetryoperator_dictionary, *symopi;
  float v_shift[3],m_scale[4][4],m_inv_scale[4][4];
//float m_symop[4][4];
  const ccp4_symop sm=*(I->scale_matrix);
  rotandtrn_to_mat4(m_scale,sm);
  invert4matrix((const float (*)[4])m_scale,m_inv_scale);
//printf("%f\t%f\t%f\n%f\t%f\t%f\n%f\t%f\t%f\n",sm.rot[0][0],sm.rot[0][1],sm.rot[0][2],
//       sm.rot[1][0],sm.rot[1][1],sm.rot[1][2],sm.rot[2][0],sm.rot[2][1],sm.rot[2][2]);
  /* allocate a maximal number of neighbor interactions for filled sphere using
   * cutoff as radius ((2*cutoff)^3), since the neighbor interaction will be
   * directional, only half of it will be used, thus 4*(cutoff^3). */
  atinfo=I->AtomInfo;
  rsinfo=I->ResidueInfo;

  if(I->numAtom) {
  /* STEP 0: pre-calculate number of atom neighbors from contact program output */
    maxNeighbor=0;
    p=buffer_contact;
    while(*p) {
      maxNeighbor++;
      p=str2nextline(p);
    }
    maxNeighbor *= 2;   // To accomodate potential alternative conformation
    AllocP(contact_pdb_buffer_str,char,((I->numAtom+maxNeighbor+10)*81));       // To store the symmetry-related PDB file
  /* STEP 1: calculate all atom neighbors, store with distance */
    maxNeighbor += 4*cutoff*cutoff*cutoff*I->numAtom;
    anbCount = 0;
    AllocP(anbinfo,ObjNeighborInfo,(maxNeighbor+1));
    nbvCount = 0;
    AllocP(nbvinfo,ObjNeighborVectorInfo,(maxNeighbor+2));
    vni=nbvinfo+nbvCount; vni->index=nbvCount; vni->isym=0; vni->icell=555;     // Initialize the first NeighborVector object
    vni->direction[0]=0.0f; vni->direction[1]=0.0f; vni->direction[2]=0.0f;     // To be an empty reference
    nbvCount++;                                                                 // All real NeighborVector objects begin with index 1
    EntityMoleculeGenerateCenter(I);
    hash=HashNew5(cutoff,I->Coord,I->numAtom,I->Min,I->Max);
    if(hash)
      for(i=0;i<I->numAtom;i++) {
        v1=I->Coord+(3*i);
        ai1=atinfo+i;
//      AtomInfoPrintPDB(contact_pdb_buffer_str,ai1,ai1->ResidueInfo->chain,v1);
        if(ai1->hydrogen) continue;     /* skip hydrogen interactions */
        HashLocate(hash,v1,&a,&b,&c);   /* find the unit cube this vertex resides */
        for(d=a-1;d<=a+1;d++)
        for(e=b-1;e<=b+1;e++)
        for(f=c-1;f<=c+1;f++) {         /* for 27 adjacent cubes, seek for bond */
          j=*(HashFirst(hash,d,e,f));   /* get first vertex index */
          while(j>0) {                  /* stop when see -1, which is the end of list */
            if(i>=j)            { j=HashNext(hash,j); continue; }
                                        /* allow only one direction to avoid repetition */
            v2=I->Coord+(3*j);
            ai2=atinfo+j;
/* Slower version */
/* Can be further optimized, only calculate distance when the interaction involve
 * at least one atom which does not belong to standard amino acid or water */
            distCalculated=0;
            if((ai1->type>ATOM_SC_SE && ai1->type!=ATOM_WT_O) || (ai2->type>ATOM_SC_SE && ai2->type!=ATOM_WT_O)) {
              dist=(float)VectorDistance2v(v1,v2);
              distCalculated=1;
              if(dist<1.5) {
                ai1->numCovalentBond++;
                ai2->numCovalentBond++;
              }
            }
/* End Slower version */
            if(ai1->residue_index==ai2->residue_index) {
              if(!I->intra_residue_flag && ai1->type<=ATOM_WT_O && ai2->type<=ATOM_WT_O) {
                j=HashNext(hash,j); continue;
              } else {
                contact_flag = CONTACT_INTRA_RESIDUE;
              }
            } else {
              contact_flag = CONTACT_INTER_RESIDUE;
              if(ai1->ResidueInfo->molecule_index!=ai2->ResidueInfo->molecule_index) {
                contact_flag += CONTACT_INTER_MOLEC;
              }
            }
                                        /* skip intra-residue interactions */
            if(ai2->hydrogen)   { j=HashNext(hash,j); continue; }
                                        /* skip hydrogen interactions */
/* Faster version */
            if(!distCalculated) dist=(float)VectorDistance2v(v1,v2);
/* End Faster version */
            // DEBUG
//          if((ai1->ResidueInfo->resid==605 && ai2->ResidueInfo->resid==612) ||
//             (ai1->ResidueInfo->resid==612 && ai2->ResidueInfo->resid==605)) printf("%c%d[%s]%s-%c%d[%s]%s-%f\n",
//              ai1->ResidueInfo->chain,ai1->ResidueInfo->resid,ai1->ResidueInfo->resn,ai1->realname,
//              ai2->ResidueInfo->chain,ai2->ResidueInfo->resid,ai2->ResidueInfo->resn,ai2->realname, dist);
            if(dist<=cutoff) {
              if(ai1->numAltLoc>1 && ai2->numAltLoc>1 && ai1->alt != ai2->alt) {
                if(str2symbolcnt(ai1->AltLocStr,ai2->alt) &&
                   str2symbolcnt(ai2->AltLocStr,ai1->alt)) {
                  // if there is potential for this pair of altLoc to agree with each other
                  j=HashNext(hash,j); continue; // skip when altLoc still do not agree
                }
              }
              if(anbCount >= maxNeighbor)
                PFatalError("IMPOSSIBLE: insufficient initial memory allocated for neighbor");
              contact_fwd=0;
              contact_alt=1;
              if (ai1->ResidueInfo->chain<ai2->ResidueInfo->chain) { contact_fwd=1;
              } else if (ai1->ResidueInfo->chain==ai2->ResidueInfo->chain) {
                if (ai1->ResidueInfo->resid<ai2->ResidueInfo->resid) { contact_fwd=1;
                } else if (ai1->ResidueInfo->resid==ai2->ResidueInfo->resid) {
                  compare_atom=strncmp(ai1->realname,ai2->realname,4);
                  if (compare_atom<0) { contact_fwd=1;
                  } else if (compare_atom==0) {
                    if (ai1->ResidueInfo->resi2<ai2->ResidueInfo->resi2) { contact_fwd=1;
                    } else if (ai1->ResidueInfo->resi2==ai2->ResidueInfo->resi2) {
                      if(strcmp(ai1->ResidueInfo->resn,ai2->ResidueInfo->resn)) {
                        contact_alt=0;
                      } else {
                        sprintf(msg, "Neighborhood calculation within AU shouldn't contain interaction with both ends (%d-%d) point to the same atom\n",
                            ai1->id, ai2->id);
                        PFatalError(msg);
                      }
                    }
                  }
                }
              }
              /* since j>i (atom index), we are assuming the same for
               * ai2->residue_index>ai1->residue_index (residue index) */
              if(contact_alt) {
                ani=anbinfo+anbCount; ani->index=anbCount;
                vni=nbvinfo+nbvCount; vni->index=nbvCount;
                if(contact_fwd) {
                  ani->atom_index[0]=i;
                  ani->atom_index[1]=j;
                  ani->residue_index[0]=ai1->residue_index;
                  ani->residue_index[1]=ai2->residue_index;
                  VectorCopy3f(vni->direction,v2);
                  VectorSubstract3f(vni->direction,v1);
                } else {
                  ani->atom_index[0]=j;
                  ani->atom_index[1]=i;
                  ani->residue_index[0]=ai2->residue_index;
                  ani->residue_index[1]=ai1->residue_index;
                  VectorCopy3f(vni->direction,v1);
                  VectorSubstract3f(vni->direction,v2);
                }
                ani->vector_index[0]=nbvCount;  ani->vec_fwd=vni;
                ani->vector_index[1]=-nbvCount; ani->vec_rev=vni;
              //ani->res1=ai1->ResidueInfo;
              //ani->atm1=ai1;
              //ani->res2=ai2->ResidueInfo;
              //ani->atm2=ai2;
                ani->bond_type='u';
                ani->score_probe=0.0f;  ani->score_hb=0.0f;
                ani->score_wc=0.0f;     ani->score_cc=0.0f;
                ani->score_so=0.0f;     ani->score_bo=0.0f;
                ani->contact_flag=contact_flag;
                ani->distance=dist;
                ani->bfactor_correlation=(float)BfactorCorrelation(ai1->b,ai2->b);
                ai1->numAtmNeighbor++;
                ai2->numAtmNeighbor++;
                anbCount++;
                vni->icell=555;   vni->isym=0;
                nbvCount++;
              }
            }
            j=HashNext(hash,j);
          }
        }
      }
    HashFree(hash);
//  I->numAtmNeighbor  = anbCount;      // will be assigned after next while loop
    I->AtmNeighborInfo    = anbinfo;
    I->NeighborVectorInfo = nbvinfo;
    anbCount0             = anbCount;   // save this value for residue neighbor processing

  /* STEP 2: Parse all neighbor from CCP4 contact program, and append to
   *         atom neighbor list with different contact_flag */
    p=buffer_contact;
    symopCount=0;
    alt_stack=stackNew();
    vec_stack=stackNew();
    symop_id_max=0;
    while(*p) {
      if(p[0]=='#') {
        p=str2cskip(p,' ');
        p=str2ccpy(symop_num,p,'|');
        if(sscanf(symop_num,"%d",&symop_id)!=1) symop_id=0;
        if(symop_id>symop_id_max) symop_id_max=symop_id;
        symopCount++;
      } else break;
      p=str2nextline(p);
    }
    if(symopCount>symop_id_max){
      sprintf(msg,"%s: Number of symmetry operators (%d) overflow maximal symmetry ID(%d) in crystal contact output.\n",
                  I->pdbid, symopCount, symop_id_max);
      PFatalError(msg);
    }
    AllocP(symmetryoperator_dictionary,SymopDict,(symop_id_max+1));
    for(symopCount=0;symopCount<=symop_id_max;symopCount++) {
      symopi=symmetryoperator_dictionary+symopCount;
      symopi->symop_id=0;
    }
    /* Read contact file header part */
    p=buffer_contact;
    symopCount=0;
    while(*p) {
      if(p[0]=='#') {
        /* New algorithm to assign symmetryoperator_dictionary */
        p=str2cskip(p,' ');
        p=str2ccpy(symop_num,p,'|');
        if(sscanf(symop_num,"%d",&symop_id)!=1) symop_id=0;
        symopi=symmetryoperator_dictionary+symop_id;
        p=str2ncpy(symopi->symop_str,p,SymopStrLen);
        strcpy(symopi->symop_num,symop_num);
        symopi->symop_id=symop_id;
        symop_to_mat4(symopi->symop_str,symopi->symop_str+strlen(symopi->symop_str),symopi->m_symop[0]);
        /* Old algorithm to assign symmetryoperator_dictionary */
//      symopi=symmetryoperator_dictionary+symopCount;
//      p=str2cskip(p,' ');
//      p=str2ccpy(symopi->symop_num,p,'|');
//      p=str2ncpy(symopi->symop_str,p,SymopStrLen);
//      if(sscanf(symopi->symop_num,"%d",&symopi->symop_id)!=1) symopi->symop_id=0;
//      symop_to_mat4(symopi->symop_str,symopi->symop_str+strlen(symopi->symop_str),symopi->m_symop[0]);
//      symopCount++;
      } else break;
      p=str2nextline(p);
    }
    /* Read contact file body part */
    hasMetalContact=0;
    while(*p) {
      p=str2ccpy(res1.resn,p,'|');      // Column 1-2:   resname, stored in res1, res2
      p=str2ccpy(res2.resn,p,'|');
      res1.chain=(*p); p=str2nskip(p,2);// Column 3-4:   chainid, stored in res1, res2
      res2.chain=(*p); p=str2nskip(p,2);
      p=str2ccpy(atm1.name,p,'|');      // Column 5-6:   atomname,stored in atm1, atm2
      p=str2ccpy(atm2.name,p,'|');
      p=str2ccpy(q,p,'|');              // Column 7-8:   translation (e.g.555), symop (e.g.005)
      if(sscanf(q,"%d",&cell_id)!=1) cell_id=555;
      for(i=0;i<3;i++) {
        v_shift[i]=(float)(q[i]-'5');
        if(v_shift[i]<-4 || v_shift[i]>4) PFatalError("Invalid v_shift for contact file record\n");
      }
      p=str2ccpy(q,p,'|');
      if(sscanf(q,"%d",&symop_id)!=1) symop_id=0;
        /* New algorithm to use symmetryoperator_dictionary */
      symopi=symmetryoperator_dictionary+symop_id;
      if(!symopi->symop_id) PFatalError("Invalid symop_id for contact file record\n");
        /* Old algorithm to use symmetryoperator_dictionary */
//    symop_found=0;
//    for(i=0;i<symopCount;i++) {
//      symopi=symmetryoperator_dictionary+i;
//      if(symopi->symop_id==symop_id) { symop_found=1; break; }
//    }
//    if(!symop_found) PFatalError("Invalid symop_id for contact file record\n");

      p=str2ccpy(q,p,'|');              // Column 9:     distance,stored in variable dist
      if(sscanf(q,"%f",&dist)!=1) dist=-1;
      if(dist<0.02) {                   // skip interaction if it's the same atom on border of assymetric unit 
        p=str2nextline(p);              // so that it is overlapped by symmetry operation
        continue;
      }
      p=str2ccpy(q,p,'|');              // Column 10:    assign to bond_type (00='0'; 01='1'; 11='3')
      bond_type='0';
      if(q[1]=='1') {
        if(q[0]=='0') bond_type='1';
        else if(q[0]=='1') bond_type='3';
      }
      p=str2ccpy(res1.resi,p,'|');      // Column 11-12: resseq,  stored in res1, res2
      p=str2ccpy(res2.resi,p,'|');
      if(sscanf(res1.resi,"%d",&res1.resid)!=1) res1.resid=-1;
      if(sscanf(res2.resi,"%d",&res2.resid)!=1) res2.resid=-1;
      
      contact_fwd=0;
      nalt1=AtomInfoLocateIndex4contact(alt_ai1, &res1, &atm1, I, ai1->index);
      nalt2=AtomInfoLocateIndex4contact(alt_ai2, &res2, &atm2, I, ai2->index);
      ai1=atinfo+alt_ai1[0];
      ai2=atinfo+alt_ai2[0];

      if (ai1->isMetal) { contact_fwd=1;
      } else if (ai2->isMetal) { contact_fwd=0;
      } else if (res1.chain<res2.chain) { contact_fwd=1;
      } else if (res1.chain==res2.chain) {
        if (res1.resid<res2.resid) { contact_fwd=1;
        } else if (res1.resid==res2.resid) {
          compare_atom=strncmp(atm1.name,atm2.name,4);
          if (compare_atom<0) { contact_fwd=1;
          } else if (compare_atom==0) { contact_fwd=2;  // Need special handling in case of an atom interact with its own mirror image by symmetry operation
          }
        }
      }

      if(anbCount >= maxNeighbor)
        PFatalError("IMPOSSIBLE: insufficient initial memory allocated for neighbor");
      alt_processed=0;
      if(nalt1>1 || nalt2>1 || contact_fwd==2) {      // Remove potential repetition in case of alternative conformation,
                                                      // or an atom interact with its own mirror image
        if(stackContains(alt_stack, &res1, &atm1, &res2, &atm2, cell_id, symop_id)) {
          alt_processed=1;
        } else {
          stackPush(alt_stack, &res1, &atm1, &res2, &atm2, cell_id, symop_id, 0, 0.0f);
        }
      }
      if(!alt_processed) {
       for(a=0;a<nalt1;a++) {
         for(b=0;b<nalt2;b++) {
           v1=I->Coord+(3*alt_ai1[a]);
           v2=I->Coord+(3*alt_ai2[b]);
           VectorCopy3f(v3, v2);                        // fprintf(stderr,"original   : "); VectorPrint3f(v3);
           VectorTransform3f44f(v3, m_scale[0]);        // fprintf(stderr,"original-f : "); VectorPrint3f(v3);
           VectorTransform3f44f(v3, symopi->m_symop[0]);// fprintf(stderr,"transform-f: "); VectorPrint3f(v3);
           VectorAdd3f(v3, v_shift);                    // fprintf(stderr,"translate-f: "); VectorPrint3f(v3);
           VectorTransform3f44f(v3, m_inv_scale[0]);    // fprintf(stderr,"transformed: "); VectorPrint3f(v3);
           dist_temp=(float)VectorDistance2v(v1,v3);
//         fprintf(stderr,"DEBUG: %s,\tdist:%f\tdist2:%f\n",symopi->symop_str,dist,dist_temp);
//         float diff = dist>dist_temp ? dist-dist_temp : dist_temp-dist;
//         printf("%f|%f|%f\n",dist,dist_temp,diff);
//         MatrixPrint44f(m_scale[0]);
//         MatrixPrint44f(m_symop[0]);
//         MatrixPrint44f(m_inv_scale[0]);

           if(dist_temp<=cutoff2) {
             contact_alt=1;
             ai1=atinfo+alt_ai1[a];
             ai2=atinfo+alt_ai2[b];
             if(ai1->numAltLoc>1 && ai2->numAltLoc>1 && ai1->alt != ai2->alt) {
               if(str2symbolcnt(ai1->AltLocStr,ai2->alt) &&
                  str2symbolcnt(ai2->AltLocStr,ai1->alt)) {
                 contact_alt=0;
               }
             }
             if(contact_alt) {
               vni=nbvinfo+nbvCount; vni->index=nbvCount;
               VectorCopy3f(vni->direction,v3);
               VectorSubstract3f(vni->direction,v1);
               vni->icell=cell_id;vni->isym=symop_id;
               if (contact_fwd) {
                 ani=anbinfo+anbCount; ani->index=anbCount;
                 ani->atom_index[0]=alt_ai1[a];
                 ani->atom_index[1]=alt_ai2[b];
                 ani->residue_index[0]=ai1->residue_index;
                 ani->residue_index[1]=ai2->residue_index;
//               ani->contact_flag = (ai1->ResidueInfo->molecule_index==ai2->ResidueInfo->molecule_index) ? CONTACT_FLAG_UNDEF : CONTACT_INTER_MOLEC;
//               ani->contact_flag = CONTACT_INTER_AU + CONTACT_CUTOFF_6A + CONTACT_INTER_MOLEC;
                 ani->bond_type=bond_type;
                 if(ani->bond_type=='3')      { ani->score_probe=1.0f;  ani->score_hb=1.0f; }
                 else if(ani->bond_type=='1') { ani->score_probe=0.1f;  ani->score_hb=0.1f; }
                 else                         { ani->score_probe=0.0f;  ani->score_hb=0.0f; }
                 ani->score_wc=0.0f;     ani->score_cc=0.0f;
                 ani->score_so=0.0f;     ani->score_bo=0.0f;
                 ani->contact_flag = CONTACT_INTER_RESIDUE + CONTACT_INTER_MOLEC + CONTACT_INTER_AU;
                 ani->distance=dist_temp;
                 ani->vector_index[0]=nbvCount;   ani->vec_fwd=vni;
                 ani->vector_index[1]=0;          ani->vec_rev=nbvinfo;
                 ani->bfactor_correlation=(float)BfactorCorrelation(ai1->b,ai2->b);
                 ai1->numAtmNeighbor++;
                 ai2->numAtmNeighbor++;
                 anbCount++;
                 if(ai1->isMetal && dist_temp<3 && ai2->protons != AN_C && ai2->protons != AN_H) {
                   AtomInfoPrintPDB(contact_pdb_buffer_str,ai2,'#',v3); hasMetalContact=1; }
               } else {
                 stackPush(vec_stack, &res1, &atm1, &res2, &atm2, alt_ai1[a], alt_ai2[b], nbvCount, dist_temp);
               }
               nbvCount++;
             }
           }
         }
       }
      }
      p=str2nextline(p);
    }
    I->numAtmNeighbor = anbCount;
    I->numNeighborVector = nbvCount;
    stackFree(alt_stack);
    if(!hasMetalContact) { contact_pdb_buffer_str[0]=0; }

  /* STEP 3: build a list of atomneighbor index inside atom object to speed up future operation */
    for(i=0;i<I->numAtom;i++) {
      ai1=atinfo+i;
      AllocP(ai1->AtmNeighborIndex,int,(ai1->numAtmNeighbor+1));
      ai1->indAtmNeighbor=0;
      ai1->ResidueInfo->maxResNeighbor+=ai1->numAtmNeighbor;
    }
    for(i=0;i<I->numResidue;i++) { // just allocate space, will assign value later
      ri1=rsinfo+i;
      AllocP(ri1->ResNeighborIndex,int,((ri1->maxResNeighbor+1)<<1));   // A dirty fix: allocate twice as much memory
      // because molprobity could introduce more AtomNeighbor interactions, which in turn could result in more residue neighbors
      // == WARNING == ai->numAtmNeighbor calculation is performed before molprobity and hence will not index any interactions from molprobity
      // So it is possible that there will be residue neighbors, but not atom neighbors (TODO) this may need to be fixed somehow in the future
    }
    for(i=0;i<anbCount;i++) {
      ani=anbinfo+i;
      ai1=atinfo+ani->atom_index[0];
      ai2=atinfo+ani->atom_index[1];
      ai1->AtmNeighborIndex[ai1->indAtmNeighbor]=i;
      ai2->AtmNeighborIndex[ai2->indAtmNeighbor]=i;
      ai1->indAtmNeighbor++;
      ai2->indAtmNeighbor++;
    }

  /* STEP 4: Parse all interaction from Molprobity probe program, and update
   *         atom neighbor list with different bond_type */
    p=buffer_molprobity;
    molprobity_section=0;
    ai1=atinfo;
    j=0;
    while(*p) {
      if(p[0]=='(') {
        mpm[j].index=j;
        str2ncpy(mpm[j].molprobity_index,p,MolprobityIndexLen);
        p=str2nskip(p,2);
        res1.chain=(*p); p=str2nskip(p,1);      // Column 3: chain
        p=str2ncpy(res1.resi,p,4);              // Column 4-7: resseq
        if(sscanf(res1.resi,"%d",&res1.resid)!=1) res1.resid=-1;
        res1.resi2=(*p); p=str2nskip(p,1);      // Column 8: iCode
        p=str2ncpy(q,p,3);                      // Column 9-11: resName
        ObjResidueAssignResname(&res1,q);
        p=str2nskip(p,1);                       // Column 12: empty
        p=str2ncpy(atm1.realname,p,4);          // Column 13-16: atomName
        atm1.alt=(*p);   p=str2nskip(p,3);      // Column 17: altLoc, 18-19: empty
        res2.chain=(*p); p=str2nskip(p,1);      // Column 20: chain
        p=str2ncpy(res2.resi,p,4);              // Column 21-24: resseq
        if(sscanf(res2.resi,"%d",&res2.resid)!=1) res2.resid=-1;
        res2.resi2=(*p); p=str2nskip(p,1);      // Column 25: iCode
        p=str2ncpy(q,p,3);                      // Column 9-11: resName
        ObjResidueAssignResname(&res2,q);
//      if(res1.resid==res2.resid && res1.chain==res2.chain && res1.resi2==res2.resi2 && !strncmp(res1.resn,res2.resn,4)) {
//        mpm[j].neighbor_index=-1;
//        j++;
//        p=str2nextline(p);    
//        continue; // Skip intra-residue interaction
//      }
        p=str2nskip(p,1);                       // Column 29: empty
        p=str2ncpy(atm2.realname,p,4);          // Column 30-33: atomName
        for(i=0;i<4;i++) if(atm1.realname[i]==' ') atm1.realname[i]='-';
        for(i=0;i<4;i++) if(atm2.realname[i]==' ') atm2.realname[i]='-';
        atm2.alt=(*p);   p=str2nskip(p,2);      // Column 34: altLoc
        ai2=AtomInfoLocateIndex4molprobity(&res1, &atm1, I, ai1->index);
        if(ai2==NULL || ai2->hydrogen) { mpm[j].neighbor_index=-1; j++; p=str2nextline(p); continue; }
        ai1=ai2;
//      printf("ai1 %s %s %d\n", ai1->ResidueInfo->resn, ai1->realname, ai1->numAtmNeighbor);
        rnbFound=0;
        for(k=0;k<2;k++) {
          for(i=0;i<ai1->numAtmNeighbor;i++) {
            ani=anbinfo+ai1->AtmNeighborIndex[i];
            if     (ai1->index == ani->atom_index[0]) { ai2=atinfo+ani->atom_index[1]; }
            else if(ai1->index == ani->atom_index[1]) { ai2=atinfo+ani->atom_index[0]; }
            ri2=ai2->ResidueInfo;
            if(res2.chain==ri2->chain && res2.resid==ri2->resid && res2.resi2==ri2->resi2 && !strncmp(res2.resn,ri2->resn,3)
                                                                && atm2.alt==ai2->alt && !strncmp(atm2.realname,ai2->realname,4)) {
              rnbFound=1;
              break;
            }
          }
          if(rnbFound) break;
          else if(k==0) {
            temp_chain=res2.chain;
            ai3=AtomInfoLocateIndex4molprobity(&res2, &atm2, I, ai1->index);
            if(temp_chain==res2.chain) break;
          }
        }
        if(rnbFound) {
          if(p[0]==':') {
            p=str2nskip(p,1);    p=str2cskip(p,':');    p=str2cskip(p,':');                    // skip src Element and des Element
            ani->bond_type=(*p); p=str2nskip(p,2);                                             // bond_type
            p=str2ccpy(q,p,':'); if(sscanf(q,"%f",&ani->score_hb)!=1)    ani->score_hb=0.0f;    // score_hb
            p=str2ccpy(q,p,':'); if(sscanf(q,"%f",&ani->score_wc)!=1)    ani->score_wc=0.0f;    // score_wc
            p=str2ccpy(q,p,':'); if(sscanf(q,"%f",&ani->score_cc)!=1)    ani->score_cc=0.0f;    // score_cc
            p=str2ccpy(q,p,':'); if(sscanf(q,"%f",&ani->score_so)!=1)    ani->score_so=0.0f;    // score_so
            p=str2ccpy(q,p,':'); if(sscanf(q,"%f",&ani->score_bo)!=1)    ani->score_bo=0.0f;    // score_bo
            p=str2wcpy(q,p);     if(sscanf(q,"%f",&ani->score_probe)!=1) ani->score_probe=0.0f; // score_probe
          } else if(p[0]=='(' && molprobity_section==2) {
            sprintf(msg,"Unexpected section for molprobity probe table for neighborhood: section %d delimiter '%c'.\n",molprobity_section,p[0]);
            PFatalError(msg);
          } else {
            sprintf(msg,"Unexpected pattern for molprobity probe table for neighborhood: section %d delimiter '%c'.\n",molprobity_section,p[0]);
            PFatalError(msg);
          }
        } else {
          ai2=ai3;
          if(ai2==NULL || ai2->hydrogen) { mpm[j].neighbor_index=-1; j++; p=str2nextline(p); continue; }
          v1=I->Coord+(3*ai1->index);
          v2=I->Coord+(3*ai2->index);
          dist=(float)VectorDistance2v(v1,v2);
          if(dist>cutoff-V_SMALL || ai1->residue_index==ai2->residue_index) {
            // create new neighbor interaction in case the distance is too far away
            //                              or in case when both atoms are from the same residue
            ani=anbinfo+anbCount; ani->index=anbCount;
            vni=nbvinfo+nbvCount; vni->index=nbvCount;
            ani->atom_index[0]=ai1->index;
            ani->atom_index[1]=ai2->index;
            ani->residue_index[0]=ai1->residue_index;
            ani->residue_index[1]=ai2->residue_index;
            VectorCopy3f(vni->direction,v2);
            VectorSubstract3f(vni->direction,v1);
            ani->vector_index[0]=nbvCount;  ani->vec_fwd=vni;
            ani->vector_index[1]=-nbvCount; ani->vec_rev=vni;
            p=str2nskip(p,1);    p=str2cskip(p,':');    p=str2cskip(p,':');                     // skip src Element and des Element
            ani->bond_type=(*p); p=str2nskip(p,2);                                              // bond_type
            p=str2ccpy(q,p,':'); if(sscanf(q,"%f",&ani->score_hb)!=1)    ani->score_hb=0.0f;    // score_hb
            p=str2ccpy(q,p,':'); if(sscanf(q,"%f",&ani->score_wc)!=1)    ani->score_wc=0.0f;    // score_wc
            p=str2ccpy(q,p,':'); if(sscanf(q,"%f",&ani->score_cc)!=1)    ani->score_cc=0.0f;    // score_cc
            p=str2ccpy(q,p,':'); if(sscanf(q,"%f",&ani->score_so)!=1)    ani->score_so=0.0f;    // score_so
            p=str2ccpy(q,p,':'); if(sscanf(q,"%f",&ani->score_bo)!=1)    ani->score_bo=0.0f;    // score_bo
            p=str2wcpy(q,p);     if(sscanf(q,"%f",&ani->score_probe)!=1) ani->score_probe=0.0f; // score_probe
            if(ai1->residue_index==ai2->residue_index) {
              ani->contact_flag=CONTACT_INTRA_RESIDUE;
            } else {
              ani->contact_flag=CONTACT_INTER_RESIDUE;
              if(ai1->ResidueInfo->molecule_index!=ai2->ResidueInfo->molecule_index) {
                ani->contact_flag += CONTACT_INTER_MOLEC;
              }
            }
            ani->distance=dist;
            ani->bfactor_correlation=(float)BfactorCorrelation(ai1->b,ai2->b);
            anbCount++;
            vni->icell=555;   vni->isym=0;
            nbvCount++;
          } else {
            sprintf(msg,"Cannot locate corresponding neighbor pair %f apart (%c%d[%s]%c:[%s]%c ~ %c%d[%s]%c:[%s]%c).\n", dist,
                res1.chain, res1.resid, res1.resn, res1.resi2, atm1.realname, atm1.alt,
                res2.chain, res2.resid, res2.resn, res2.resi2, atm2.realname, atm2.alt);
            PFatalError(msg);
          }
        }
        if(ani->bond_type=='h' && (ai1->protons==AN_C || ai2->protons==AN_C)) ani->bond_type='x';
        mpm[j].neighbor_index=ani->index;
        j++;
      } else if(p[0]=='#') {
        molprobity_section++;
        p=str2cskip(p,':');
        p=str2bskip(p,' ');
        p=str2wcpy(q,p);
        if(molprobity_section==1) {
          if(sscanf(q,"%d",&numMolprobityMapping)!=1) numMolprobityMapping=0; // number of records for the first section
          AllocP(mpm,MolprobityMapping,(numMolprobityMapping+1));
        } else if (molprobity_section==2) {
          if(sscanf(q,"%d",&I->numMolprobity)!=1) I->numMolprobity=0; // number of records for the second section
          AllocP(mpinfo,ObjMolprobityInfo,(I->numMolprobity+1));
          p=str2nextline(p);
          break;
        }
      }
      p=str2nextline(p);
    }
    I->numAtmNeighbor = anbCount;
    I->numNeighborVector = nbvCount;

    j=0; k=0;
    while(*p) {
      if(p[0]=='(') {
        p=str2ncpy(q,p,MolprobityIndexLen);
        if(!strncmp(mpm[j].molprobity_index,q,MolprobityIndexLen)) {
        } else if(j+1<numMolprobityMapping && !strncmp(mpm[j+1].molprobity_index,q,MolprobityIndexLen)) {
          j++;
        } else {
          for(j=0;j<numMolprobityMapping;j++) {
            if(!strncmp(mpm[j].molprobity_index,q,MolprobityIndexLen)) break;
          }
          if(j>=numMolprobityMapping) PFatalError("Unexpected large index for molprobity probe section 2: NO index in section 1.\n");
        }
        mpi=mpinfo+k;
        mpi->index=k;
        mpi->neighbor_index=mpm[j].neighbor_index;
        if(p[0]=='(') {
          p=str2nskip(p,1); p=str2ncpy(mpi->name_a,p,4);
          for(i=0;i<4;i++) if(mpi->name_a[i]==' ') mpi->name_a[i]='-';
          p=str2nskip(p,1); p=str2ncpy(mpi->name_b,p,4);
          for(i=0;i<4;i++) if(mpi->name_b[i]==' ') mpi->name_b[i]='-';
          p=str2nskip(p,1);    mpi->bond_type=(*p);                                           // bond_type
          p=str2nskip(p,3);    p=str2cskip(p,':');      p=str2cskip(p,':');                   // skip src Element and des Element
          p=str2ccpy(q,p,':'); if(sscanf(q,"%d",&mpi->num_dots)!=1)     mpi->num_dots=0;      // num_dots
          p=str2ccpy(q,p,':'); if(sscanf(q,"%d",&mpi->num_dots_fwd)!=1) mpi->num_dots_fwd=0;  // num_dots_fwd
          p=str2ccpy(q,p,':'); if(sscanf(q,"%d",&mpi->num_dots_rev)!=1) mpi->num_dots_rev=0;  // num_dots_rev
          p=str2ccpy(q,p,':'); if(sscanf(q,"%f",&mpi->score)!=1)        mpi->score=0.0f;      // score
          p=str2ccpy(q,p,':'); if(sscanf(q,"%f",&mpi->mingap)!=1)       mpi->mingap=0.0f;     // mingap
          p=str2ccpy(q,p,':'); if(sscanf(q,"%f",&mpi->gap)!=1)          mpi->gap=0.0f;        // gap
          p=str2wcpy(q,p);     if(sscanf(q,"%f",&mpi->spike_len)!=1)    mpi->spike_len=0.0f;  // spike_len
        } else PFatalError("Unexpected pattern encountered  for molprobity probe section 2: Sub index needed.\n");
        k++;
      }
      p=str2nextline(p);
    }
    I->MolprobityInfo=mpinfo;
    FreeP(mpm);

  /* STEP 5: Process vector stack */
    stack_rec=vec_stack->top;
    while(stack_rec) {
      ai1=atinfo+stack_rec->regid1;
      ai2=atinfo+stack_rec->regid2;
      dist_min=1;
      ani2=NULL;
      for(i=ai1->numAtmNeighbor-1;i>=0;i--) {
        ani=anbinfo+ai1->AtmNeighborIndex[i];
        if(ani->atom_index[0]==stack_rec->regid2 && ani->atom_index[1]==stack_rec->regid1 && ani->vector_index[1]==0) {
          dist_temp = (ani->distance>stack_rec->register_float)
                    ? ani->distance-stack_rec->register_float
                    : stack_rec->register_float-ani->distance;
          if(dist_temp<dist_min) {
            dist_min=dist_temp;
            ani2=ani;
          }
        }
      }
      if(ani2==NULL) { 
// TODO: example 3g9c, residue S17 contains 12 residues with different insertion code,
//       cannot be correctly handled by the function AtomInfoLocateIndex4contact
//       And will result in orphan reverse atom from contact program
//       (need either check insert code from contact, or check distance agreement from contact)
        sprintf(msg,"Potential orphan reverse atom neighbor vector for crystal contact(%s): ",I->pdbid);
        stackRecPrint(stack_rec, msg);
//      PWarning(msg);
      } else {
        if(dist_min>V_SMALL) {
          if(dist_min>SMALL) {
            sprintf(msg,"Highly suspicious reverse atom neighbor vector for crystal contact(%s): (%f)",I->pdbid,ani2->distance);
          } else {
            sprintf(msg,"Suspicious reverse atom neighbor vector for crystal contact(%s): (%f)",I->pdbid,ani2->distance);
          }
          stackRecPrint(stack_rec, msg);
          PWarning(msg);
        }
        ani2->vector_index[1]=stack_rec->register_int;
      }
      stack_rec=stack_rec->prev;
    }
    stackFree(vec_stack);

  /* STEP 6: Search all atom neighbors, calculate residue neighbor with shortest
   *         atom neighbor distance */
    maxNeighbor2 = anbCount;
    rnbCount = 0;
    AllocP(rnbinfo,ObjNeighborInfo,(maxNeighbor2+1));
//  for(i=0;i<anbCount0;i++) {}                 // process first part, intra-AU neighbors
    for(i=0;i<I->numAtmNeighbor;i++) {          // process both parts together now, intra-AU and inter-AU neighbors
      ani=anbinfo+i;
      vni=nbvinfo+ani->vector_index[0];
      if(ani->contact_flag != CONTACT_INTRA_RESIDUE) {  // intra-residue neighbor will never be considered as residue neighbor
        rnbFound=-1;                      // 1) rnbFound is first used as the index of the residue neighbor
        for(j=rnbCount-1;j>=0;j--) {
          rni=rnbinfo+j;
          vni_res=nbvinfo+rni->vector_index[0];
          if(ani->residue_index[0]==rni->residue_index[0] &&
             ani->residue_index[1]==rni->residue_index[1] &&
             vni->icell==vni_res->icell && vni->isym==vni_res->isym) {
          // contact between the same pair of residues but from different symmetry operators are considered as different residues
            rnbFound=j;
            break;
          }
        }
        if (rnbFound==-1) {
          rni=rnbinfo+rnbCount;
          rni->index=rnbCount;
          rni->residue_index[0]=ani->residue_index[0];
          rni->residue_index[1]=ani->residue_index[1];
          ri1=rsinfo+rni->residue_index[0];
          ri1->ResNeighborIndex[ri1->numResNeighbor]=rnbCount;
          ri1->numResNeighbor++;
          ri2=rsinfo+rni->residue_index[1];
          ri2->ResNeighborIndex[ri2->numResNeighbor]=rnbCount;
          ri2->numResNeighbor++;
          rnbCount++;
          rnbFound=1;                     // 2) rnbFound is used as an indicator of whether or not data need to be copied
        } else if (ani->distance < rni->distance) rnbFound=1; else rnbFound=0;
        if(rnbFound) {
          rni->atom_index[0]=ani->atom_index[0];
          rni->atom_index[1]=ani->atom_index[1];
          rni->bond_type=ani->bond_type;
          rni->score_probe=ani->score_probe;
          rni->score_hb=ani->score_hb;
          rni->score_wc=ani->score_wc;
          rni->score_cc=ani->score_cc;
          rni->score_so=ani->score_so;
          rni->score_bo=ani->score_bo;
          rni->contact_flag=ani->contact_flag;
          rni->vector_index[0]=ani->vector_index[0];
          rni->vector_index[1]=ani->vector_index[1];
          rni->vec_fwd=ani->vec_fwd;
          rni->vec_rev=ani->vec_rev;
          rni->distance=ani->distance;
          rni->bfactor_correlation=ani->bfactor_correlation;
        }
      }
    }
/* The following content is obsolete,
 * it was used to make residue neighbors independently for intra-AU and inter-AU contacts
 * But in this new version, Everything is handled by a single loop,
 * such distinction are made by the ani->icell and ani->isym variables
 * regardless of whether or not it is from intra-AU or inter-AU contact */
//  rnbCount0          = rnbCount;      // save this value for residue neighbor processing
//
// All code for this second loop is the carbon copy as last loop except for those 2 lines that begin with /**/
//*/for(i=anbCount0;i<I->numAtmNeighbor;i++) {  // process second part, inter-AU contacts
//    ani=anbinfo+i;
//    rnbFound=-1;
//*/  for(j=rnbCount-1;j>=rnbCount0;j--) {
//      rni=rnbinfo+j;
//      if(ani->residue_index[0]==rni->residue_index[0] &&
//         ani->residue_index[1]==rni->residue_index[1] &&
//         ani->icell==rni->icell && ani->isym==rni->isym) {
//        rnbFound=j;
//        break;
//      }
//    }
//    if (rnbFound==-1) {
//      rni=rnbinfo+rnbCount;
//      rni->index=rnbCount;
//      rni->atom_index[0]=ani->atom_index[0];
//      rni->atom_index[1]=ani->atom_index[1];
//      rni->residue_index[0]=ani->residue_index[0];
//      rni->residue_index[1]=ani->residue_index[1];
//      rni->contact_flag=ani->contact_flag;
//        rni->icell=ani->icell;  rni->isym=ani->isym;
//        VectorCopy3f(rni->direction,ani->direction);
//      rni->distance=ani->distance;
//      rni->bfactor_correlation=ani->bfactor_correlation;
//      rnbCount++;
//    } else if (ani->distance < rni->distance) {
//      rni->atom_index[0]=ani->atom_index[0];
//      rni->atom_index[1]=ani->atom_index[1];
//      rni->contact_flag=ani->contact_flag;
//        rni->icell=ani->icell;  rni->isym=ani->isym;
//        VectorCopy3f(rni->direction,ani->direction);
//      rni->distance=ani->distance;
//      rni->bfactor_correlation=ani->bfactor_correlation;
//    }
//  }
    I->numResNeighbor  = rnbCount;
    I->ResNeighborInfo = rnbinfo;

  /* STEP 7: Calculate all peptide bond + nucleic acid backbond info,
   *         and assign previous/next residues in poly-peptide chain */
    glycan_stack=stackNew();
    for(i=0;i<I->numResNeighbor;i++) {
      rni=rnbinfo+i;
      ri1=I->ResidueInfo+rni->residue_index[0];
      ri2=I->ResidueInfo+rni->residue_index[1];
      ai1=I->AtomInfo+rni->atom_index[0];
      ai2=I->AtomInfo+rni->atom_index[1];
      backboneLink=0;   // 0: No covalent bond; 1 or -1: primary covalent bond; 2 or -2: branch covalent bond
      if (ri1->type<=RESIDUE_AMINOACID && ri2->type<=RESIDUE_AMINOACID && rni->distance<1.5) {
        if (ai1->type==ATOM_MC_C && ai2->type==ATOM_MC_N) backboneLink=1;
        else if (ai1->type==ATOM_MC_N && ai2->type==ATOM_MC_C) backboneLink=-1;
      } else if (ri1->type>=RESIDUE_DNA_PURINE && ri1->type<=RESIDUE_DNARNA && ri2->type>=RESIDUE_DNA_PURINE && ri2->type<=RESIDUE_DNARNA && rni->distance<1.7) {
        if (ai1->type==ATOM_NA_OP_BRIDGE && ai2->type==ATOM_NA_P) backboneLink=1;
        else if (ai1->type==ATOM_NA_P && ai2->type==ATOM_NA_OP_BRIDGE) backboneLink=-1;
      } else if ((ri1->type==RESIDUE_SUGAR || ri2->type==RESIDUE_SUGAR) && rni->distance<1.7) {
        if      (ri2->type==RESIDUE_SUGAR && ri1->type<=RESIDUE_AMINOACID) backboneLink=2;
        else if (ri1->type==RESIDUE_SUGAR && ri2->type<=RESIDUE_AMINOACID) backboneLink=-2;
        else if (ri1->type==RESIDUE_SUGAR && ri2->type==RESIDUE_SUGAR && rni->contact_flag<CONTACT_INTER_AU)
          stackPush(glycan_stack, ri1, ai1, ri2, ai2, (int)(ai1->name[2]), (int)(ai2->name[2]), i, rni->distance);
          // The third character of the atomname in sugar residue is used for deciding the branch
          // The larger third character will become the major sequence, smaller one be branch
      }
      if(backboneLink!=0) {
        consecutive_flag=1;
        if (ri2->index!=ri1->index+backboneLink && backboneLink<=1 && backboneLink>=-1) {
          consecutive_flag=0;
          sprintf(msg,"Non-consecutive peptide bond found %s%d:%s%d (%s).",
                      ri1->resn, ri1->resid, ri2->resn, ri2->resid, I->pdbid);
          PWarning(msg);
        }
        if(backboneLink==1) {
          if(consecutive_flag || (ri1->next_index==-1 && ri2->prev_index==-1)) {
          // This condition reads "either residue consecutive, or peptide bond not yet detected" and is important in case of 1qcu,
          // because the structures overlaps, and if you allow non-consecutive residues to overwrite the existing consecutive
          // nucleotide bonds, multiple nucleotide bonds will be detected for the same residue and everything will screw up
            ri1->next_index=ri2->index;   strcpy(ri1->next_atomname,ai1->name);
            ri2->prev_index=ri1->index;   strcpy(ri2->prev_atomname,ai2->name);
          }
        } else if(backboneLink==-1) {
          if(consecutive_flag || (ri2->next_index==-1 && ri1->prev_index==-1)) {
            ri2->next_index=ri1->index;   strcpy(ri2->next_atomname,ai2->name);
            ri1->prev_index=ri2->index;   strcpy(ri1->prev_atomname,ai1->name);
          }
        } else if(backboneLink==2) {
          ri1->branch_index=ri2->index; strcpy(ri1->branch_atomname,ai1->name);
          ri2->prev_index=ri1->index;   strcpy(ri2->prev_atomname,ai2->name);
          ri2->frozen=2;
        } else if(backboneLink==-2) {
          ri1->prev_index=ri2->index;   strcpy(ri1->prev_atomname,ai1->name);
          ri2->branch_index=ri1->index; strcpy(ri2->branch_atomname,ai2->name);
          ri1->frozen=2;
        }
      }
    }
    // Dealing with glycans attached to protein
    numSugarLink=0;
    while(numSugarLink!=glycan_stack->size) {
      numSugarLink=glycan_stack->size;
      stack_rec=glycan_stack->top;
      while(stack_rec) {
        rni=rnbinfo+stack_rec->register_int;
        ri1=I->ResidueInfo+rni->residue_index[0];
        ri2=I->ResidueInfo+rni->residue_index[1];
        ai1=I->AtomInfo+rni->atom_index[0];
        ai2=I->AtomInfo+rni->atom_index[1];
        if(ri1->frozen && !ri2->frozen) {
          if(ri1->next_index==-1) {
            ri1->next_index=ri2->index;                 strcpy(ri1->next_atomname,ai1->name);
          } else if(ri1->branch_index==-1) {
            if(ri1->next_atomname[2]>=ai1->name[2]) {   // TODO: need to re-consider order when next_atomname[2]==branch_atomname[2]
              ri1->branch_index=ri2->index;             strcpy(ri1->branch_atomname,ai1->name);
            } else {
              ri1->branch_index=ri1->next_index;        strcpy(ri1->branch_atomname,ri1->next_atomname);
              ri1->next_index=ri2->index;               strcpy(ri1->next_atomname,ai1->name);
            }
          } else if(ri1->branch2_index==-1) {
            if(ri1->branch_atomname[2]>=ai1->name[2]) {
              ri1->branch2_index=ri2->index;            strcpy(ri1->branch2_atomname,ai1->name);
            } else if(ri1->next_atomname[2]>=ai1->name[2]) {
              ri1->branch2_index=ri1->branch_index;     strcpy(ri1->branch2_atomname,ri1->branch_atomname);
              ri1->branch_index=ri2->index;             strcpy(ri1->branch_atomname,ai1->name);
            } else {
              ri1->branch2_index=ri1->branch_index;     strcpy(ri1->branch2_atomname,ri1->branch_atomname);
              ri1->branch_index=ri1->next_index;        strcpy(ri1->branch_atomname,ri1->next_atomname);
              ri1->next_index=ri2->index;               strcpy(ri1->next_atomname,ai1->name);
            }
          } else PFatalError("Unusual 5-way branches glycosylation pattern found\n");
          ri2->prev_index=ri1->index;                   strcpy(ri2->prev_atomname,ai2->name);
          ri2->frozen=1;
          stackDelete(glycan_stack,stack_rec->register_int);
        } else if(ri2->frozen && !ri1->frozen) {
          if(ri2->next_index==-1) {
            ri2->next_index=ri1->index;                 strcpy(ri2->next_atomname,ai2->name);
          } else if(ri2->branch_index==-1) {
            if(ri2->next_atomname[2]>=ai2->name[2]) {   // TODO: need to re-consider order when next_atomname[2]==branch_atomname[2]
              ri2->branch_index=ri1->index;             strcpy(ri2->branch_atomname,ai2->name);
            } else {
              ri2->branch_index=ri2->next_index;        strcpy(ri2->branch_atomname,ri2->next_atomname);
              ri2->next_index=ri1->index;               strcpy(ri2->next_atomname,ai2->name);
            }
          } else if(ri2->branch2_index==-1) {
            if(ri2->branch_atomname[2]>=ai2->name[2]) {
              ri2->branch2_index=ri1->index;            strcpy(ri2->branch2_atomname,ai2->name);
            } else if(ri2->next_atomname[2]>=ai2->name[2]) {
              ri2->branch2_index=ri2->branch_index;     strcpy(ri2->branch2_atomname,ri2->branch_atomname);
              ri2->branch_index=ri1->index;             strcpy(ri2->branch_atomname,ai2->name);
            } else {
              ri2->branch2_index=ri2->branch_index;     strcpy(ri2->branch2_atomname,ri2->branch_atomname);
              ri2->branch_index=ri2->next_index;        strcpy(ri2->branch_atomname,ri2->next_atomname);
              ri2->next_index=ri1->index;               strcpy(ri2->next_atomname,ai2->name);
            }
          } else PFatalError("Unusual 5-way branches glycosylation pattern found\n");
          ri1->prev_index=ri2->index;           strcpy(ri1->prev_atomname,ai1->name);
          ri1->frozen=1;
          stackDelete(glycan_stack,stack_rec->register_int);
        } else if(ri1->frozen && ri2->frozen)
          PWarning("Unusual glycosylation pattern found with two covalent bonds to proteins\n");
        stack_rec=stack_rec->prev;
      }
    }
    // link free hanging around sugars
    stack_rec=glycan_stack->top;
    while(stack_rec) {
      rni=rnbinfo+stack_rec->register_int;
      if(rni->residue_index[0]==rni->residue_index[1]) PFatalError("Intra residue covalent is not supposed to be defined for glycans\n");
      else if(rni->residue_index[0]<rni->residue_index[1]) {
        ri1=I->ResidueInfo+rni->residue_index[0];
        ri2=I->ResidueInfo+rni->residue_index[1];
        ai1=I->AtomInfo+rni->atom_index[0];
        ai2=I->AtomInfo+rni->atom_index[1];
      } else {
        ri2=I->ResidueInfo+rni->residue_index[0];
        ri1=I->ResidueInfo+rni->residue_index[1];
        ai2=I->AtomInfo+rni->atom_index[0];
        ai1=I->AtomInfo+rni->atom_index[1];
      }
      if(ri2->prev_index==-1) {
        ri2->prev_index=ri1->index;           strcpy(ri2->prev_atomname,ai2->name);
      } else if(ri2->branch_index==-1) {
        ri2->branch_index=ri1->index;         strcpy(ri2->branch_atomname,ai2->name);
      } else if(ri2->branch2_index==-1) {
        ri2->branch2_index=ri1->index;        strcpy(ri2->branch2_atomname,ai2->name);
      }
      if(ri1->next_index==-1) {
        ri1->next_index=ri2->index;           strcpy(ri1->next_atomname,ai1->name);
      } else if(ri1->branch_index==-1) {
        ri1->branch_index=ri2->index;         strcpy(ri1->branch_atomname,ai1->name);
      } else if(ri1->branch2_index==-1) {
        ri1->branch2_index=ri2->index;        strcpy(ri1->branch2_atomname,ai1->name);
      }
      stack_rec=stack_rec->prev;
    }
    stackFree(glycan_stack);

  /* STEP 8: Calculate all covalent bond for each atom for LCN calculation later on */
    for(i=0;i<I->numAtom;i++) {
      ai1=I->AtomInfo+i;
      ri1=ai1->ResidueInfo;
      if (ai1->hydrogen) ai1->numCovalentBond=1; 
      else if (ri1->isSingle==2) ai1->numCovalentBond=2;
      else if (ri1->isSingle==1) ai1->numCovalentBond=0;
      else {
        switch (ai1->type) {
          case ATOM_MC_N         : ai1->numCovalentBond=3; break;
          case ATOM_MC_CA        : ai1->numCovalentBond=4; break;
          case ATOM_MC_C         : ai1->numCovalentBond=3; break;
          case ATOM_MC_O         : ai1->numCovalentBond=1; break;
          case ATOM_SC_CB        : ai1->numCovalentBond=4; break;
          case ATOM_SC_C         : ai1->numCovalentBond=4; break;
          case ATOM_SC_N_ARG     : ai1->numCovalentBond=3; break;
          case ATOM_SC_O_AMIDE   : ai1->numCovalentBond=1; break;
          case ATOM_SC_N_AMIDE   : ai1->numCovalentBond=3; break;
          case ATOM_SC_O_CARBOXYL: ai1->numCovalentBond=1; break;
          case ATOM_SC_S_CYS     : ai1->numCovalentBond=2; break;
          case ATOM_SC_C_RING    : ai1->numCovalentBond=3; break;
          case ATOM_SC_N_HIS     : ai1->numCovalentBond=2; break;
          case ATOM_SC_N_LYS     : ai1->numCovalentBond=4; break;
          case ATOM_SC_N_TRP     : ai1->numCovalentBond=3; break;
          case ATOM_SC_S_MET     : ai1->numCovalentBond=2; break;
          case ATOM_SC_O_HYDROXYL: ai1->numCovalentBond=2; break;
          case ATOM_SC_O_PHENOL  : ai1->numCovalentBond=2; break;
          case ATOM_SC_SE        : ai1->numCovalentBond=2; break;
        }
      }
    }
  }
}

/*---------------------------------------------------------------------------*/
void EntityMoleculeLigandAngle(ObjEntityMolecule *I, float cutoff) {
  int i,j,k,l,m,n;
  int maxLigAtom,maxNeighbor,maxAngle,agCount;
  int numNeighbor;
  int *tmpNBindex, *tmpNBatomindex, tmpDistanceindex;
  float *v1, *v2, dist0, dist1, dist2, diff, dist_adjusted;
  ObjAtomInfo     *ai0, *ai1, *ai2, *atinfo;
  ObjResidueInfo  *ri0, *ri1, *ri2;
  ObjNeighborInfo *nbinfo, *nb1, *nb2, *nb3;
  ObjAngleInfo    *aginfo, *agi, *agi2;
  int indDistance=0;
  Vector3f vec0;

  atinfo      = I->AtomInfo;
  nbinfo      = I->AtmNeighborInfo;
  agCount     = 0;
  maxNeighbor = 8*cutoff*cutoff*cutoff;
  maxLigAtom  = 0;
  maxAngle    = 0;
  for(i=0;i<I->numResidue;i++) {
    ri0=I->ResidueInfo+i;
    if(ri0->type>=RESIDUE_ALKALI) {
      maxLigAtom+=ri0->numAtom;
      for(j=0;j<ri0->numAtom;j++) {
        ai0=ri0->AtomInfo+j;
        maxAngle+=(ai0->numAtmNeighbor)*(ai0->numAtmNeighbor+1);
      }
    }
  }
  AllocP(tmpNBindex,int,(maxNeighbor+1));
  AllocP(tmpNBatomindex,int,(maxNeighbor+1));
  AllocP(aginfo,ObjAngleInfo,(maxAngle+1));
  /* STEP 6: Calculate bond angle for all ligands environments */
  for(i=0;i<I->numResidue;i++) {
    ri0=I->ResidueInfo+i;
    if(ri0->type>=RESIDUE_ALKALI) {
      printf("Processing chain %c, resi %d, resn %s\n", ri0->chain, ri0->resid, ri0->resn);
      for(j=0;j<ri0->numAtom;j++) {
        ai0=ri0->AtomInfo+j;
        if(ai0->protons != AN_C) {      // Only make angles for non-carbon atoms in ligand
          /* make a list of neighbors */
          numNeighbor=0;
          for(k=0;k<ai0->numAtmNeighbor;k++) {
            nb1=nbinfo+ai0->AtmNeighborIndex[k];
            if (nb1->distance<=cutoff) {
              if (nb1->atom_index[1]==ai0->index) {
                ai1=atinfo+nb1->atom_index[0];
                if (ai1->protons != AN_C) { // Only make angles for non-carbon atoms in protein
                  tmpNBatomindex[numNeighbor]=nb1->atom_index[0];
                  tmpNBindex[numNeighbor]=nb1->index;
                  numNeighbor++;
                }
              } else if (nb1->atom_index[0]==ai0->index) {
                ai1=atinfo+nb1->atom_index[1];
                if (ai1->protons != AN_C) { // Only make angles for non-carbon atoms in protein
                  tmpNBatomindex[numNeighbor]=nb1->atom_index[1];
                  tmpNBindex[numNeighbor]=nb1->index;
                  numNeighbor++;
                }
              }
            }
          }
          /* make all combination with the list of neighbors */
          for(k=0;k<numNeighbor;k++) {
            ai1=atinfo+tmpNBatomindex[k];
            nb1=nbinfo+tmpNBindex[k];
            dist1=nb1->distance;
            for(l=k+1;l<numNeighbor;l++) {
              ai2=atinfo+tmpNBatomindex[l];
              nb2=nbinfo+tmpNBindex[l];
              dist2=nb2->distance;
              if (nb1->contact_flag<CONTACT_INTER_AU && nb2->contact_flag<CONTACT_INTER_AU) {
                v1=I->Coord+(3*ai1->index);
                v2=I->Coord+(3*ai2->index);
                dist0=(float)VectorDistance2v(v1,v2);
              } else {
                VectorCopy3f(vec0,nb1->vec_fwd->direction);
                if((ai1->index==nb1->atom_index[0] && ai2->index==nb2->atom_index[1]) ||
                   (ai1->index==nb1->atom_index[1] && ai2->index==nb2->atom_index[0])) VectorAdd3f(vec0,nb2->vec_fwd->direction);
                else VectorSubstract3f(vec0,nb2->vec_fwd->direction);
                dist0=(float)VectorLength3f(vec0);
                /*obsolete*/ // dist0=-1;  // invalid dist0 value in case when inter-AU contact is encountered
              }
          /* make new angle object for each combination */
              agi=aginfo+agCount;
              agi->index=agCount;
              agi->atom_index[0]=ai0->index;
              agi->atom_index[1]=ai1->index;
              agi->atom_index[2]=ai2->index;
              agi->residue_index[0]=i;
              agi->residue_index[1]=ai1->residue_index;
              agi->residue_index[2]=ai2->residue_index;
              agi->atomneighbor_index[0]=nb1->index;
              agi->atomneighbor_index[1]=nb2->index;
              agi->distance[0]=dist0;
              agi->distance[1]=dist1;
              agi->distance[2]=dist2;
              agi->numDistance=0;
              agi->indDistance=-3;
              agi->DistanceList=NULL;
              if(dist0==-1) {   // OBSOLETE LOOP: This is not gonna happen after v0.5.8 using the nb1->direction & nb2->direction
                diff = (dist1>dist2) ? (dist1-dist2) : (dist2-dist1);
                AllocP(agi->DistanceList,float,(ai1->numAtmNeighbor+1));
                for(m=0;m<ai1->numAtmNeighbor;m++) {
                  nb3=nbinfo+ai1->AtmNeighborIndex[m];
                  if((nb3->atom_index[0]==ai1->index && nb3->atom_index[1]==ai2->index) ||
                     (nb3->atom_index[0]==ai2->index && nb3->atom_index[1]==ai1->index) ) {
                    if(nb3->distance<=1.3*(dist1+dist2) && nb3->distance>=0.9*diff) {
                      dist_adjusted=nb3->distance;
                      if (nb3->distance>=(dist1+dist2)) dist_adjusted=dist1+dist2-0.00001;
                      if (nb3->distance<=diff)          dist_adjusted=diff+0.00001;
                      tmpDistanceindex=0;
                      if(agi->numDistance) {
                        for(n=0;n<agi->numDistance;n++) if(dist_adjusted < agi->DistanceList[n]) break;
                        tmpDistanceindex=n;
                        for(n=agi->numDistance;n>tmpDistanceindex;n--) agi->DistanceList[n]=agi->DistanceList[n-1];
                      }
                      agi->DistanceList[tmpDistanceindex]=dist_adjusted;
                      agi->numDistance++;
                    }
                  }
                }
                agi->indDistance = (agi->numDistance) ? -1 : -2;
                if (agi->indDistance == -2) {
                  v1=I->Coord+(3*ai1->index);
                  v2=I->Coord+(3*ai2->index);
                  dist0=(float)VectorDistance2v(v1,v2);
                  if(dist0<=1.3*(dist1+dist2) && dist0>=0.9*diff) {
                    dist_adjusted=dist0;
                    if (dist0>=(dist1+dist2)) dist_adjusted=dist1+dist2-0.00001;
                    if (dist0<=diff)          dist_adjusted=diff+0.00001;
                    agi->distance[0]=dist_adjusted;
                  }
                }
              }
            //agi->angle = (dist0<0) ? -1 : VectorAngle3f(agi->distance);       // assign the angle later at the end of the procedure
              agCount++;
            }
          }
        }
      }
    }
  }
  agi=aginfo+agCount;
  agi->index=-1;
  I->numAngle=agCount;
  I->AngleInfo=aginfo;

  for(i=0;i<agCount;i++) {      // Mark redundant angle caused by symmetry operation
    agi=aginfo+i;
    if(agi->indDistance==-1) {  // OBSOLETE CONDITION: This is not gonna happen after v0.5.8 using the nb1->direction & nb2->direction
      indDistance=0;
      agi->indDistance=indDistance;
      for(j=i+1;j<agCount;j++) {
        agi2=aginfo+j;
        if(agi2->indDistance==-1) {
          if(  agi->atom_index[0]==agi2->atom_index[0] &&
             ((agi->atom_index[1]==agi2->atom_index[1] && agi->atom_index[2]==agi2->atom_index[2]) ||
              (agi->atom_index[1]==agi2->atom_index[2] && agi->atom_index[2]==agi2->atom_index[1]))) {
            indDistance++;
            agi2->indDistance=indDistance;
          }
        }
      }
    }
  }
  for(i=0;i<agCount;i++) {      // assign the corresponding distance by index
    agi=aginfo+i;
    if(agi->indDistance>=0) {   // OBSOLETE CONDITION: This is not gonna happen after v0.5.8 using the nb1->direction & nb2->direction
      agi->indDistance %= agi->numDistance;
      if(agi->distance[0]<0) agi->distance[0]=agi->DistanceList[agi->indDistance];
    }
    agi->angle = (agi->distance[0]<0) ? -1 : VectorAngle3f(agi->distance);
  }
}


/*---------------------------------------------------------------------------*/
int EntityMoleculeNeighborPrint(FILE *fout, ObjEntityMolecule *I, int isAtomNeighbor, FILE* fout_pept, FILE* fout_nucl) {
  ObjResidueInfo *ri1, *ri2;
  ObjAtomInfo    *ai1, *ai2;
  ObjNeighborInfo *ni, *NeighborInfo;
  int numNeighbor, i, nameCompare, reverse=0;
  int isPeptideBond=0,numNeighborReturn=0;
  FILE *fout_local;

  numNeighbor  = isAtomNeighbor ? I->numAtmNeighbor : I->numResNeighbor;
  NeighborInfo = isAtomNeighbor ? I->AtmNeighborInfo: I->ResNeighborInfo;
  numNeighborReturn=numNeighbor;
  for (i=0; i<numNeighbor; i++) {
    ni=NeighborInfo+i;
    ri1=I->ResidueInfo+ni->residue_index[0];
    ri2=I->ResidueInfo+ni->residue_index[1];
    ai1=I->AtomInfo+ni->atom_index[0];
    ai2=I->AtomInfo+ni->atom_index[1];
    isPeptideBond=0;    // 1 indicate peptide bond related interactions,
                        // 2 indicate nucleotide bond related interactions
    if (isAtomNeighbor) {
      if (ai1->type < ai2->type)      reverse=0;
      else if (ai1->type > ai2->type) reverse=1;
      else {
        nameCompare=strcmp(ai1->realname,ai2->realname);
        if(nameCompare>0) reverse=1;
        else if(!nameCompare && ai1->index>ai2->index) reverse=1;
        else reverse=0;
      }
      /* Only C1-N2 interaction will be recorded for 6 peptide bond interaction
       * CA1-N2, CA1-CA2, C1-N2, C1-CA2, O1-N2, O1-CA2 */
      if (ri1->next_index==ri2->index && ri2->prev_index==ri1->index) {
        if(ri1->type <= RESIDUE_AMINOACID) {
          if ((ai1->type==ATOM_MC_CA || ai1->type==ATOM_MC_O) && (ai2->type==ATOM_MC_N || ai2->type==ATOM_MC_CA))
            isPeptideBond=1;
          else if (ai1->type==ATOM_MC_C && ai2->type==ATOM_MC_CA)
            isPeptideBond=1;
        } else {
          if ((ai1->type==ATOM_NA_C_BRIDGE || ai1->type==ATOM_NA_OP_BRIDGE) && (ai2->type==ATOM_NA_OP_TERMINAL || ai2->type==ATOM_NA_OP_BRIDGE))
            isPeptideBond=2;
          else if ((ai1->type==ATOM_NA_C_BRIDGE && ai2->type==ATOM_NA_P) || (ai1->type==ATOM_NA_OP_BRIDGE && ai2->type==ATOM_NA_C_BRIDGE))
            isPeptideBond=2;
        }
      } else if (ri1->prev_index==ri2->index && ri2->next_index==ri1->index) {
        if(ri1->type <= RESIDUE_AMINOACID) {
          if ((ai2->type==ATOM_MC_CA || ai2->type==ATOM_MC_O) && (ai1->type==ATOM_MC_N || ai1->type==ATOM_MC_CA))
            isPeptideBond=1;
          else if (ai2->type==ATOM_MC_C && ai1->type==ATOM_MC_CA)
            isPeptideBond=1;
        } else {
          if ((ai2->type==ATOM_NA_C_BRIDGE || ai2->type==ATOM_NA_OP_BRIDGE) && (ai1->type==ATOM_NA_OP_TERMINAL || ai1->type==ATOM_NA_OP_BRIDGE))
            isPeptideBond=2;
          else if ((ai2->type==ATOM_NA_C_BRIDGE && ai1->type==ATOM_NA_P) || (ai2->type==ATOM_NA_OP_BRIDGE && ai1->type==ATOM_NA_C_BRIDGE))
            isPeptideBond=2;
        }
      }
    } else {
      if (ri1->type < ri2->type)      reverse=0;
      else if (ri1->type > ri2->type) reverse=1;
      else {
        nameCompare=strcmp(ri1->resn,ri2->resn);
        if(nameCompare>0) reverse=1;
        else if(!nameCompare && ri1->index>ri2->index) reverse=1;
        else reverse=0;
      }
    }
    if (isPeptideBond) {
      numNeighborReturn--;
      if(isPeptideBond==1 && fout_pept) fout_local=fout_pept;
      else if(isPeptideBond==2 && fout_nucl) fout_local=fout_nucl;
      else continue;
    } else {
      fout_local = fout;
    } /* Eliminate excessive peptide bond interaction in output */
    if (reverse) {
      fprintf(fout_local, "%d|%d|%d|%d|%s|%s|%d|%d|%d|%s|%s|%d|",
          I->pdbfileid,         ni->index,
          ni->residue_index[1], ni->residue_index[0],
          ri2->resn,            ri1->resn,            ri2->type*100+ri1->type,
          ni->atom_index[1],    ni->atom_index[0],
          ai2->realname,        ai1->realname,        ai2->type*100+ai1->type);
      if(!isPeptideBond)
        fprintf(fout_local, "%c|%f|%f|%f|%f|",
          ni->bond_type,        ni->score_probe,      ni->score_hb,
          ni->score_wc+ni->score_cc,    ni->score_so+ni->score_bo);
      fprintf(fout_local, "%04d|%f|%f|%d|%d\n",
          ni->contact_flag,     ni->distance,         ni->bfactor_correlation,
          ni->vector_index[1],  ni->vector_index[0]);
    } else {
      fprintf(fout_local, "%d|%d|%d|%d|%s|%s|%d|%d|%d|%s|%s|%d|",
          I->pdbfileid,         ni->index,
          ni->residue_index[0], ni->residue_index[1],
          ri1->resn,            ri2->resn,            ri1->type*100+ri2->type,
          ni->atom_index[0],    ni->atom_index[1],
          ai1->realname,        ai2->realname,        ai1->type*100+ai2->type);
      if(!isPeptideBond)
        fprintf(fout_local, "%c|%f|%f|%f|%f|",
          ni->bond_type,        ni->score_probe,      ni->score_hb,
          ni->score_wc+ni->score_cc,    ni->score_so+ni->score_bo);
      fprintf(fout_local, "%04d|%f|%f|%d|%d\n",
          ni->contact_flag,     ni->distance,         ni->bfactor_correlation,
          ni->vector_index[0],  ni->vector_index[1]);
    }
  }
  return numNeighborReturn;
}

/*---------------------------------------------------------------------------*/
int EntityMoleculeAnglePrint(FILE *fout, ObjEntityMolecule *I) {
  int numAngle, i, nameCompare, reverse=0;
  ObjResidueInfo *rsinfo, *ri0, *ri1, *ri2;
  ObjAtomInfo    *atinfo, *ai0, *ai1, *ai2;
  ObjAngleInfo   *aginfo, *agi;
  rsinfo=I->ResidueInfo;
  atinfo=I->AtomInfo;
  aginfo=I->AngleInfo;
  for (i=0; i<I->numAngle; i++) {
    agi=aginfo+i;
    ai0=atinfo+agi->atom_index[0];
    ai1=atinfo+agi->atom_index[1];
    ai2=atinfo+agi->atom_index[2];
    ri0=rsinfo+agi->residue_index[0];
    ri1=rsinfo+agi->residue_index[1];
    ri2=rsinfo+agi->residue_index[2];
    if (ai1->type < ai2->type)      reverse=0;
    else if (ai1->type > ai2->type) reverse=1;
    else {
      nameCompare=strcmp(ai1->realname,ai2->realname);
      if(nameCompare>0) reverse=1;
      else if(!nameCompare && ai1->index>ai2->index) reverse=1;
      else reverse=0;
    }
    if (reverse) {
      fprintf(fout, "%d|%d|%d|%d|%d|%s|%s|%s|%d|%d|%d|%d|%s|%s|%s|%d|%d|%d|%f|%f|%f|%f\n",
          I->pdbfileid,     agi->index,
          ri2->index,       ri0->index,       ri1->index,
          ri2->resn,        ri0->resn,        ri1->resn,
          ri2->type*10000  +ri0->type*100    +ri1->type,
          ai2->index,       ai0->index,       ai1->index,
          ai2->realname,    ai0->realname,    ai1->realname,
          ai2->type*10000  +ai0->type*100    +ai1->type,
          agi->atomneighbor_index[1],         agi->atomneighbor_index[0],
          agi->distance[2], agi->distance[1], agi->distance[0], agi->angle);
    } else {
      fprintf(fout, "%d|%d|%d|%d|%d|%s|%s|%s|%d|%d|%d|%d|%s|%s|%s|%d|%d|%d|%f|%f|%f|%f\n",
          I->pdbfileid,     agi->index,
          ri1->index,       ri0->index,       ri2->index,
          ri1->resn,        ri0->resn,        ri2->resn,
          ri1->type*10000  +ri0->type*100    +ri2->type,
          ai1->index,       ai0->index,       ai2->index,
          ai1->realname,    ai0->realname,    ai2->realname,
          ai1->type*10000  +ai0->type*100    +ai2->type,
          agi->atomneighbor_index[0],         agi->atomneighbor_index[1],
          agi->distance[1], agi->distance[2], agi->distance[0], agi->angle);
    }
  }
  return I->numAngle;
}


/*---------------------------------------------------------------------------*/
int EntityMoleculeBondValence(ObjEntityMolecule *I, int isWater) {
  ObjResidueInfo *ri1, *ri2;
  ObjAtomInfo    *ai1, *ai2;
  ObjNeighborInfo *ni, *NeighborInfo;
  ObjNeighborVectorInfo *vni;
  ObjIonBondValenceInfo *ibvi;
  double bondvalence;
  Vector3f bv_direction;
  int numNeighbor, i, forward, reverse, lcn;
  int maxBondValence_id=0;
  int isSingleFlag=isWater+1;   // ri->isSingle flag should be 2 in case of water,
                                // 1 in case of ion, and 0 in case of SM/AA/DNA/RNA

  numNeighbor  = I->numAtmNeighbor;
  NeighborInfo = I->AtmNeighborInfo;
  if(!isWater) { AllocP(I->IonBondValenceInfo,   ObjIonBondValenceInfo, numNeighbor); }
  else         { AllocP(I->WaterBondValenceInfo, ObjIonBondValenceInfo, numNeighbor*2); }
  // numNeighbor*2 is necessary for MD simulation with a lot of waters, e.g. 1QCH
  for (i=0; i<numNeighbor; i++) {
    ni=NeighborInfo+i;
    ri1=I->ResidueInfo+ni->residue_index[0];
    ri2=I->ResidueInfo+ni->residue_index[1];
    ai1=I->AtomInfo+ni->atom_index[0];
    ai2=I->AtomInfo+ni->atom_index[1];
    if((ri1->isSingle==isSingleFlag && ai1->protons!=6 && ai1->protons!=7) ||
       (ri2->isSingle==isSingleFlag && ai2->protons!=6 && ai1->protons!=7) ||
       (!isWater && (ai1->isMetal || ai2->isMetal))) {
//    printf("Record examined: %s(%c%d) ~ %s(%c%d)\n", ri1->resn, ri1->chain, ri1->resid, ri2->resn, ri2->chain, ri2->resid);
      if (ri1->isSingle==isSingleFlag && ai1->protons!=6 && ai1->protons!=7) reverse=1; else reverse=0;
      if (ri2->isSingle==isSingleFlag && ai2->protons!=6 && ai1->protons!=7) forward=1; else forward=0;
      if(!isWater) {
        if (ai1->isMetal) reverse=1;
        if (ai2->isMetal) forward=1;
      }
      if (reverse) {
        if(ai2->protons==AN_C) continue;
        lcn = ai2->numCovalentBond+1;
/* Obsolete handling of bond valence direction */
//      VectorClear3f(bv_direction); bv_direction_len=-1.0f;
//      if(ni->contact_flag<CONTACT_INTER_AU) {
//        VectorCopy3f(bv_direction, I->Coord+(3*ai1->index));
//        VectorSubstract3f(bv_direction, I->Coord+(3*ai2->index));
//        VectorScaleDown3f(bv_direction, ni->distance); bv_direction_len=ni->distance;
//      }
/* New handling of bond valence direction, with direction as an internal member of neighbor object */
        /* IMPORTANT: vector direction is reversed between neighbor record and bondvalence record
         * In neighbor record, vector originated from metal and end in the ligand (ray out)
         * However, in bond valence record, vector originated from ligand and end in metal (converge in) */
        if(ni->vector_index[0]>0) {
          VectorReverse3f(bv_direction, ni->vec_fwd->direction);
        } else {
          VectorCopy3f(bv_direction, ni->vec_fwd->direction);
        }
        VectorScaleDown3f(bv_direction, ni->distance);
        if (isWater) {
          bondvalence=AtomInfoBondValence(ai2->protons, BV_Na, ni->distance);
        } else {
          bondvalence=AtomInfoBondValence(ai2->protons, ai1->bv_index, ni->distance);
        }
        ibvi=EntityMoleculeIonBondValenceAdd(I, maxBondValence_id, ni, 1, ai2, ai1, bondvalence, bv_direction, isWater);
        maxBondValence_id++;
      }
      if (forward) {
        if(ai1->protons==AN_C) continue;
        lcn = ai1->numCovalentBond+1;
/* Obsolete handling of bond valence direction */
//      VectorClear3f(bv_direction); bv_direction_len=-1.0f;
//      if(ni->contact_flag<CONTACT_INTER_AU) {
//        VectorCopy3f(bv_direction, I->Coord+(3*ai2->index));
//        VectorSubstract3f(bv_direction, I->Coord+(3*ai1->index));
//        VectorScaleDown3f(bv_direction, ni->distance); bv_direction_len=ni->distance;
//      }
/* New handling of bond valence direction, with direction as an internal member of neighbor object */
        if(ni->vector_index[1]>0) {
          VectorReverse3f(bv_direction, ni->vec_rev->direction);  // Always reverse it due to convention, refer to comments earlier
        } else {
          VectorCopy3f(bv_direction, ni->vec_rev->direction);  // Always reverse it due to convention, refer to comments earlier
        }
        VectorScaleDown3f(bv_direction, ni->distance);
        if (isWater) {
          bondvalence=AtomInfoBondValence(ai1->protons, BV_Na, ni->distance);
        } else {
          bondvalence=AtomInfoBondValence(ai1->protons, ai2->bv_index, ni->distance);
        }
        ibvi=EntityMoleculeIonBondValenceAdd(I, maxBondValence_id, ni, 0, ai1, ai2, bondvalence, bv_direction, isWater);
        maxBondValence_id++;
      }
    }
  }
  if(!isWater) { I->numIonBondValence=maxBondValence_id; }
  else         { I->numWaterBondValence=maxBondValence_id; }
  return maxBondValence_id;
}

/*---------------------------------------------------------------------------*/
ObjIonBondValenceInfo *EntityMoleculeIonBondValenceAdd(ObjEntityMolecule *I, int bondvalenceid, ObjNeighborInfo *ni, int reverse, ObjAtomInfo *ai1, ObjAtomInfo *ai2, double bondvalence, float* bv_direction, int isWater) {
  ObjIonBondValenceInfo *ibvi;
  ObjNeighborVectorInfo *vni;
  ibvi = isWater ? I->WaterBondValenceInfo+bondvalenceid : I->IonBondValenceInfo+bondvalenceid;
  ibvi->index=bondvalenceid;
  ibvi->ni=ni;
  ibvi->reverse=reverse;
  ibvi->inner_sphere_flag=0;
  ibvi->ri_lig=ai1->ResidueInfo;
  ibvi->ri_ion=ai2->ResidueInfo;
  ibvi->ai_lig=ai1;
  ibvi->ai_ion=ai2;
  ibvi->valid=1;
  ibvi->valid_lig_occup=ai1->occup;
  ibvi->bondvalence =bondvalence;
  ibvi->bv_sodium   =AtomInfoBondValence(ai1->protons, BV_Na, ni->distance);
  ibvi->bv_magnesium=AtomInfoBondValence(ai1->protons, BV_Mg, ni->distance);
  ibvi->bv_potassium=AtomInfoBondValence(ai1->protons, BV_K,  ni->distance);
  ibvi->bv_calcium  =AtomInfoBondValence(ai1->protons, BV_Ca, ni->distance);
  ibvi->bv_manganese=AtomInfoBondValence(ai1->protons, BV_Mn, ni->distance);
  ibvi->bv_iron     =AtomInfoBondValence(ai1->protons, BV_Fe, ni->distance);
  ibvi->bv_cobalt   =AtomInfoBondValence(ai1->protons, BV_Co, ni->distance);
  ibvi->bv_nickel   =AtomInfoBondValence(ai1->protons, BV_Ni, ni->distance);
  ibvi->bv_copper   =AtomInfoBondValence(ai1->protons, BV_Cu, ni->distance);
  ibvi->bv_zinc     =AtomInfoBondValence(ai1->protons, BV_Zn, ni->distance);
  vni=I->NeighborVectorInfo+ni->vector_index[0];
  if(reverse) VectorReverse3f(ibvi->direction, vni->direction);
  else VectorCopy3f(ibvi->direction, vni->direction);
  VectorCopy3f(ibvi->bv_direction, bv_direction);
  ibvi->bv_direction_len=ni->distance;
  ibvi->bidentate_flag=0;
  return ibvi;
}

/*---------------------------------------------------------------------------*/
int ObjIonBondValenceCopy(ObjIonBondValenceInfo *ibvi, ObjIonBondValenceInfo *ibvj) {
  ibvi->index   = ibvj->index;   ibvi->ni               = ibvj->ni;
  ibvi->reverse = ibvj->reverse; ibvi->inner_sphere_flag= ibvj->inner_sphere_flag;
  ibvi->ri_lig  = ibvj->ri_lig;  ibvi->ri_ion           = ibvj->ri_ion;
  ibvi->ai_lig  = ibvj->ai_lig;  ibvi->ai_ion           = ibvj->ai_ion;
  ibvi->valid   = ibvj->valid;   ibvi->valid_lig_occup  = ibvj->valid_lig_occup;
  ibvi->bondvalence  = ibvj->bondvalence;
  ibvi->bv_sodium    = ibvj->bv_sodium   ; ibvi->bv_magnesium = ibvj->bv_magnesium;
  ibvi->bv_potassium = ibvj->bv_potassium; ibvi->bv_calcium   = ibvj->bv_calcium  ;
  ibvi->bv_manganese = ibvj->bv_manganese; ibvi->bv_iron      = ibvj->bv_iron     ;
  ibvi->bv_cobalt    = ibvj->bv_cobalt   ; ibvi->bv_nickel    = ibvj->bv_nickel   ;
  ibvi->bv_copper    = ibvj->bv_copper   ; ibvi->bv_zinc      = ibvj->bv_zinc     ;
  VectorCopy3f(ibvi->direction,ibvj->direction);
  VectorCopy3f(ibvi->bv_direction,ibvj->bv_direction);
  ibvi->bv_direction_len      = ibvj->bv_direction_len;
  ibvi->bidentate_flag        = ibvj->bidentate_flag;
}

/*---------------------------------------------------------------------------*/
ObjIonBondValenceInfo *ObjIonBondValencePrevBidentate(ObjIonBondValenceInfo *ibvi, ObjIonBondValenceInfo *bv_info, int prev_count) {
  int i;
  ObjAtomInfo *ai_prev, *ai=ibvi->ai_lig;
  ObjIonBondValenceInfo *ibvi_prev=NULL;
  switch(ai->type) {
    case ATOM_SC_O_CARBOXYL:
    case ATOM_NA_OP_TERMINAL:
    case ATOM_NA_OP_BRIDGE:
      for(i=prev_count;i>=0;i--) {
        ibvi_prev=bv_info+i;
        ai_prev=ibvi_prev->ai_lig;
        if((ai_prev->type==ATOM_SC_O_CARBOXYL && ai->type==ATOM_SC_O_CARBOXYL) ||
          ((ai_prev->type==ATOM_NA_OP_TERMINAL || ai_prev->type==ATOM_NA_OP_BRIDGE) &&
           (ai->type==ATOM_NA_OP_TERMINAL || ai->type==ATOM_NA_OP_BRIDGE))) {
          if(ibvi->ni->vec_fwd->icell == ibvi_prev->ni->vec_fwd->icell &&
             ibvi->ni->vec_fwd->isym  == ibvi_prev->ni->vec_fwd->isym) {
            if(ai->residue_index==ai_prev->residue_index && strncmp(ai->realname, "-O3'", 4) && strncmp(ai_prev->realname, "-O3'", 4)) return ibvi_prev; 
            else if(ai_prev->residue_index == ai->ResidueInfo->prev_index && !strncmp(ai_prev->realname, "-O3'", 4)) return ibvi_prev;
            else if(ai_prev->residue_index == ai->ResidueInfo->next_index && !strncmp(ai->realname, "-O3'", 4)) return ibvi_prev;
          }
        }
      }; break;
    default: break;
  }
  return NULL;
}

/*---------------------------------------------------------------------------*/
int  ObjIonBondValenceAssignPriority(ObjEntityMolecule *I, ObjIonBondValenceInfo *ibvi, ObjIonBindingSiteInfo *ibsi, ObjIonBondValenceInfo *bv_info, int bv_count, int prev_count, int isWater) {
  int priority=ISOFORM_DEFAULT_X;
  int hetatm=0;
  int j, ooo21, ooo22, ooo23, bnr21, bnr22, bnr23;
  ObjNeighborInfo *ni;
  ObjResidueInfo  *ri=ibvi->ri_lig;
  ObjAtomInfo     *ai2, *ai=ibvi->ai_lig;
  if(!isWater) ObjIonBindingSiteRecordMoiety(I,ibsi,bv_info,bv_count,ai,ibvi->ni->vec_fwd->icell*1000+ibvi->ni->vec_fwd->isym,ai->moiety_type,ILR_INNERSPHERE);
  /* define priority for general element types */
  switch(ai->protons) {
    case AN_O: ibsi->num_oxygen++;     priority=ISOFORM_DEFAULT_O; break;
    case AN_N: ibsi->num_nitrogen++;   priority=ISOFORM_DEFAULT_N; break;
    case AN_S: ibsi->num_sulfur++;     break;
    case AN_P: ibsi->num_phosphorus++; break;
    case AN_C: ibsi->num_carbon++;     break;
    default:   ibsi->num_others++;     break;
  }
  /* define priority for inner-sphere amino acid and nucleic acid */
  switch(ai->type) {
    case ATOM_MC_N            : ibsi->n01_n_mc++;                                         break;
    case ATOM_MC_O            : ibsi->n04_o_mc++;         priority=ISOFORM_MC_O;          break;
    case ATOM_SC_N_ARG        : ibsi->n07_n_arginine++;                                   break;
    case ATOM_SC_O_AMIDE      : ibsi->n08_o_amide++;      priority=ISOFORM_SC_O_AMIDE;    break;
    case ATOM_SC_N_AMIDE      : ibsi->n09_n_amide++;                                      break;
    case ATOM_SC_O_CARBOXYL   : ibsi->n10_o_carboxyl++;   priority=ISOFORM_SC_O_CARBOXYL;
                                ibsi->which_XHCXX += (!isWater && ObjIonBondValencePrevBidentate(ibvi,bv_info,prev_count)) ? 10 : 10000; break;
    case ATOM_SC_S_CYS        : ibsi->n11_s_cysteine++;   priority=ISOFORM_SC_S_CYS;      break;
    case ATOM_SC_N_HIS        : ibsi->n13_n_histidine++;  priority=ISOFORM_SC_N_HIS;      break;
    case ATOM_SC_N_LYS        : ibsi->n14_n_lysine++;                                     break;
    case ATOM_SC_N_TRP        : ibsi->n15_n_tryptophan++;                                 break;
    case ATOM_SC_S_MET        : ibsi->n16_s_methionine++;                                 break;
    case ATOM_SC_O_HYDROXYL   : ibsi->n17_o_hydroxyl++;   priority=ISOFORM_SC_O_HYDROXYL; break;
    case ATOM_SC_O_PHENOL     : ibsi->n18_o_phenol++;     priority=ISOFORM_SC_O_HYDROXYL; break;
    case ATOM_SC_SE           : ibsi->n19_selenium++;                                     break;
    case ATOM_SC_O_HETERO     : ibsi->n43_o_others++;     hetatm=1;                       break;
    case ATOM_SC_N_HETERO     : ibsi->n42_n_others++;     hetatm=1;                       break;
    case ATOM_SC_S_HETERO     : ibsi->n45_s_others++;     hetatm=1;                       break;
    case ATOM_NA_NH_BASE_ENDO :
    case ATOM_NA_N_BASE_ENDO  : ibsi->n27_n_base_ring++;  priority=ISOFORM_DR_N_BASE;     break;
    case ATOM_NA_N_BASE_RIBOSE: ibsi->n28_n_base_ribose++;                                break;
    case ATOM_NA_N_BASE_AMIDE : ibsi->n29_n_base_amide++; priority=ISOFORM_DR_N_BASE;     break;
    case ATOM_NA_O_BASE       : ibsi->n30_o_base++;       priority=ISOFORM_DR_O_BASE;     break;
    case ATOM_NA_O2_RIBOSE    :
    case ATOM_NA_O4_RIBOSE    : ibsi->n31_o_ribose++;     priority=ISOFORM_DR_O_RIBOSE;   break;
    case ATOM_NA_OP_BRIDGE    : ibsi->n32_op_bridge++;                                    break;
    case ATOM_NA_OP_TERMINAL  : ibsi->n33_op_terminal++;  priority=ISOFORM_DR_OP_TERMINAL;
                                ibsi->which_PPP += (!isWater && ObjIonBondValencePrevBidentate(ibvi,bv_info,prev_count)) ? 10 : 100; break;
    case ATOM_WT_O            : ibsi->n39_o_water++;      hetatm=1;                       break;
    case ATOM_LG_N            : ibsi->n42_n_others++;     hetatm=1;                       break;
    case ATOM_LG_O            : ibsi->n43_o_others++;     hetatm=1;                       break;
    case ATOM_LG_S            : ibsi->n45_s_others++;     hetatm=1;                       break;
    default:                    ibsi->n53_others++;
                             /* if(ibvi->bondvalence<0.45) */ priority=ISOFORM_UNDEF; /* else hetatm=1; */ break;  // Everything except O,N,S
   /* obsolete code -- This original code was problematic in case when phosphate falls close to the metal,
                    -- both oxygen and phosphate will interact, but only oxygen is in the first coodination sphere
                    -- We are now applying 0.08 valence cutoff for O,N,S but 0.16 valence cutoff for anything that is not O,N,S
                    -- This is for ourselves to be more confident for non-ONS ligands to be in first coordination sphere (FCS)
    */
  }
 
  /* define priority for outer-sphere plus inner-sphere hetero small molecule ligands */
  if(hetatm) {
    if(ri->isSingle) {
      priority=ISOFORM_MOBILE;
      ooo21=0, ooo22=0, ooo23=0, bnr21=0, bnr22=0, bnr23=0;
      for(j=0;j<ai->numAtmNeighbor;j++) {
        ni=I->AtmNeighborInfo+ai->AtmNeighborIndex[j];
        if(ni->bond_type=='h' || ni->bond_type=='3') {
          // define OP or carboxyl coordinated water only by hydrogen bonds
          ai2 = I->AtomInfo + ((ni->atom_index[0]==ai->index) ? ni->atom_index[1] : ni->atom_index[0]);
          if(ai2->type==ATOM_NA_OP_TERMINAL) priority=ISOFORM_WATER_OP;
          else if(ai2->type==ATOM_SC_O_CARBOXYL && priority==ISOFORM_MOBILE) priority=ISOFORM_WATER_CARBOXYL;
          else if(ai2->type==ATOM_SC_O_AMIDE) ooo21=1;
          else if(ai2->type==ATOM_SC_O_HYDROXYL || ai2->type==ATOM_SC_O_PHENOL) ooo22=1;
          else if(ai2->type==ATOM_MC_O) ooo23=1;
          else if(ai2->type==ATOM_NA_O_BASE) bnr21=1;
          else if(ai2->type==ATOM_NA_N_BASE_ENDO || ai2->type==ATOM_NA_NH_BASE_ENDO || ai2->type==ATOM_NA_N_BASE_AMIDE) bnr22=1;
          else if(ai2->type==ATOM_NA_O2_RIBOSE || ai2->type==ATOM_NA_O4_RIBOSE || ai2->type==ATOM_NA_OP_BRIDGE) bnr23=1;
          if(!isWater) ObjIonBindingSiteRecordMoiety(I,ibsi,bv_info,bv_count,ai2,ni->vec_fwd->icell*1000+ni->vec_fwd->isym,ai2->moiety_type,ILR_DIRECT_OUTERSPHERE);
        }
      }
      if (priority==ISOFORM_MOBILE) { ibsi->which_mobile++;
        if(ooo21) ibsi->which_wOOO2+=100; else if(ooo22) ibsi->which_wOOO2+=10; else if(ooo23) ibsi->which_wOOO2++;
        if(bnr21) ibsi->which_wBNR2+=100; else if(bnr22) ibsi->which_wBNR2+=10; else if(bnr23) ibsi->which_wBNR2++;
      } else if (priority==ISOFORM_WATER_OP)     { ibsi->which_mobile+=10; ibsi->which_PPP++; }
      else if (priority==ISOFORM_WATER_CARBOXYL) { ibsi->which_mobile+=10; ibsi->which_XHCXX++; }
    } else { ibsi->which_ligtype++;
      if (ai->protons==AN_O) priority=ISOFORM_LIGAND_O;
      else if (ai->protons==AN_N) priority=ISOFORM_LIGAND_N;
      else priority=ISOFORM_LIGAND_X;
    }
  }
  return priority;
}

/*---------------------------------------------------------------------------*/
int  ObjIonBindingSiteRecordMoiety(ObjEntityMolecule *I, ObjIonBindingSiteInfo *ibsi, ObjIonBondValenceInfo *bv_info, int bv_count, ObjAtomInfo *ai, int residue_symop, int moiety_type, int ionlig_type) {
  int i,j,moietyFound=-1;
  ObjIonBondValenceInfo *ibvi;
  ObjIonLigMoietyInfo *ilmi;
  ObjNeighborInfo *ni;
  ObjAtomInfo *ai2, *ai3;
  int num_ilm=I->numIonLigMoiety;
  if(num_ilm) {
    for(i=num_ilm-1;i>=0;i--) {
      ilmi=I->IonLigMoietyInfo+i;
      if(ilmi->bindingsite_index!=ibsi->index) break;
      if(ilmi->residue_index==ai->residue_index && ilmi->residue_symop==residue_symop && ilmi->moiety_type==moiety_type) { moietyFound=i; break; }
    }
  }
  if(moietyFound>=0) {
    ilmi=I->IonLigMoietyInfo+moietyFound;
    if(ilmi->type != ionlig_type) ilmi->type=ILR_HYBRID_INNER_OUTER;
  } else {
    if(ai->type==ATOM_NA_OP_BRIDGE && moiety_type==MOIETY_RIBOSE && ionlig_type==ILR_DIRECT_OUTERSPHERE) for(i=0;i<bv_count;i++) { // for outersphere O3'/O5'
      ibvi=bv_info+i;
      if(ibvi->inner_sphere_flag<=0) continue;
      ai2=ibvi->ai_lig;
      if(ai2->type==ATOM_NA_OP_TERMINAL) { // for innersphere OP1/OP2
        if(ai->residue_index==ai2->residue_index && !strncmp(ai->realname, "-O5'", 4)) return -1;
        else if(ai->ResidueInfo->next_index==ai2->residue_index && !strncmp(ai->realname, "-O3'",4)) return -1;
      } else if (ibvi->ri_lig->isSingle) { // for innersphere water or other single atom molecule
        for(j=0;j<ai2->numAtmNeighbor;j++) {
          ni=I->AtmNeighborInfo+ai2->AtmNeighborIndex[j];
          if(ni->bond_type=='h' || ni->bond_type=='3') { // for outersphere ligand with HB to innersphere water or other single atom molecule
            ai3 = I->AtomInfo + ((ni->atom_index[0]==ai2->index) ? ni->atom_index[1] : ni->atom_index[0]);
            if(ai3->type!=ATOM_NA_OP_TERMINAL) continue; // for outersphere OP1/OP2 only
            if(ai->residue_index==ai3->residue_index && !strncmp(ai->realname, "-O5'", 4)) return -1;
            else if(ai->ResidueInfo->next_index==ai3->residue_index && !strncmp(ai->realname, "-O3'",4)) return -1;
          }
        }
      }
    }
    ilmi=I->IonLigMoietyInfo+num_ilm;
    ilmi->local_index=num_ilm;
    ilmi->bindingsite_index=ibsi->index;
//  ilmi->valid=1;
    ilmi->moiety_type=moiety_type;
    ilmi->residue_index=ai->residue_index;
    ilmi->residue_symop=residue_symop;
    ilmi->type=ionlig_type;
    ilmi->num_inner_links=0;
    ilmi->num_outer_links=0;
    I->numIonLigMoiety++;
  }
  if(ionlig_type==ILR_INNERSPHERE) ilmi->num_inner_links++; else ilmi->num_outer_links++;
  return moietyFound;
}

/*---------------------------------------------------------------------------*/
/*
int ObjIonLigMoietyValid(ObjIonLigAtoms *I, The ribose moiety in question: mi) {
  int o3_valid=1;
  int o5_valid=1;
  if (mi has connection other than O3'/O5') return 1;
  for each inner-sphere atoms (aj) {
    if (atom aj is OP1/OP2 and covalently linked to the mi O3' to the same phosphate) o3_valid=0;
    if (atom aj is OP1/OP2 and covalently linked to the mi O5' to the same phosphate) o5_valid=0;
    for each outer-sphere atoms that connects to aj via hydrogen bond (ak) {
      if (atom ak is OP1/OP2 and covalently linked to the mi O3' to the same phosphate) o3_valid=0;
      if (atom ak is OP1/OP2 and covalently linked to the mi O5' to the same phosphate) o5_valid=0;
    }
  }
  return (o3_valid || o5_valid);
}
*/

/*---------------------------------------------------------------------------*/
static int ObjIonBondValenceIonAICmp(const void *p1, const void *p2) {
  ObjIonBondValenceInfo *ibvi1=(ObjIonBondValenceInfo *)p1;
  ObjIonBondValenceInfo *ibvi2=(ObjIonBondValenceInfo *)p2;
  return (ibvi1->ai_ion->index-ibvi2->ai_ion->index);
}

/*---------------------------------------------------------------------------*/
static int ObjIonBondValenceValidCmp(const void *p1, const void *p2) {
  ObjIonBondValenceInfo *ibvi1=(ObjIonBondValenceInfo *)p1;
  ObjIonBondValenceInfo *ibvi2=(ObjIonBondValenceInfo *)p2;
  return (ibvi2->valid-ibvi1->valid);
}

/*---------------------------------------------------------------------------*/
static int ObjIonBondValenceBVCmp(const void *p1, const void *p2) {
  ObjIonBondValenceInfo *ibvi1=(ObjIonBondValenceInfo *)p1;
  ObjIonBondValenceInfo *ibvi2=(ObjIonBondValenceInfo *)p2;
  float diff=ibvi2->bondvalence-ibvi1->bondvalence;
  if(diff>0) return 1;
  else if(diff<0) return -1;
  else return 0;
}

/*---------------------------------------------------------------------------*/
static int ObjIonBondValenceInnerCmp(const void *p1, const void *p2) {
  ObjIonBondValenceInfo *ibvi1=(ObjIonBondValenceInfo *)p1;
  ObjIonBondValenceInfo *ibvi2=(ObjIonBondValenceInfo *)p2;
  return (ibvi2->inner_sphere_flag-ibvi1->inner_sphere_flag);
}

/*---------------------------------------------------------------------------*/
static int ObjIonBondValenceBidentateCmp(const void *p1, const void *p2) {
  ObjIonBondValenceInfo *ibvi1=(ObjIonBondValenceInfo *)p1;
  ObjIonBondValenceInfo *ibvi2=(ObjIonBondValenceInfo *)p2;
  return (ibvi2->bidentate_flag-ibvi1->bidentate_flag);
}

/*---------------------------------------------------------------------------*/
static int ObjIonBondValenceLigRICmp(const void *p1, const void *p2) {
  ObjIonBondValenceInfo *ibvi1=(ObjIonBondValenceInfo *)p1;
  ObjIonBondValenceInfo *ibvi2=(ObjIonBondValenceInfo *)p2;
  int op1, op2;
  int retval=ibvi1->ri_lig->index-ibvi2->ri_lig->index;
  if(!retval) {
    op1=ibvi1->ni->vec_fwd->icell*1000+ibvi1->ni->vec_fwd->isym;
    op2=ibvi2->ni->vec_fwd->icell*1000+ibvi2->ni->vec_fwd->isym;
    retval=op1-op2;
  }
  if(!retval) retval=ibvi1->ai_lig->moiety_type-ibvi2->ai_lig->moiety_type;
  if(!retval) retval=ibvi1->bidentate_flag-ibvi2->bidentate_flag;
  return retval;
}

/*---------------------------------------------------------------------------*/
static int ObjIonLigAtomNeighborAngleCmp(const void *p1, const void *p2) {
  // qsort will order records by angle descendently
  ObjIonLigAtomNeighborInfo *ilani1=(ObjIonLigAtomNeighborInfo *)p1;
  ObjIonLigAtomNeighborInfo *ilani2=(ObjIonLigAtomNeighborInfo *)p2;
  int retval=0;
  if(ilani2->angle>ilani1->angle) retval=1;
  else if(ilani2->angle<ilani1->angle) retval=-1;
  return retval;
}

/*---------------------------------------------------------------------------*/
static int doublecmp (const void *p1, const void *p2) {
  // qsort will order records by value asendingly
  double *num1=(double *)p1;
  double *num2=(double *)p2;
  int retval=0;
  if(*num1>*num2) retval=1;
  else if(*num1<*num2) retval=-1;
  return retval;
}

/*---------------------------------------------------------------------------*/
void ObjIonBindingSiteVecsumNW(float *vec0,ObjIonBondValenceInfo *bv_info,int bv_count_inner) {
  int i;
  ObjIonBondValenceInfo *ibvi;
  VectorClear3f(vec0);
  for(i=0;i<bv_count_inner;i++) {
    ibvi=bv_info+i;
    if(ibvi->inner_sphere_flag!=0) {
      VectorAdd3f(vec0,ibvi->bv_direction);
    }
  }
}

/*---------------------------------------------------------------------------*/
float ObjIonBindginSiteSmallestAngle(float *new_bv_direction,ObjIonBondValenceInfo *bv_info,int bv_count_inner) {
  int i;
  float angle,smallest_angle=180;
  ObjIonBondValenceInfo *ibvi;
  for(i=0;i<bv_count_inner;i++) {
    ibvi=bv_info+i;
    if(ibvi->inner_sphere_flag <= 0) continue;
    angle = VectorAngle2v(new_bv_direction,ibvi->bv_direction);
    if (angle<smallest_angle) smallest_angle=angle;
  }
//printf("smallest angle is: %f\n", smallest_angle);
  return smallest_angle;
}

/*---------------------------------------------------------------------------*/
// function obsoleted Nov-2012 because bidentate determined based on residueid no longer in use
int  ObjIonBindingSiteBidentate(ObjIonBindingSiteInfo *ibsi, ObjIonBondValenceInfo *bv_info, int bv_count, ObjBidentateInfo *arr_bidentate, int cnt_bidentate) {
  // Search backwards for n=2 ligands
  Vector3f vec0;
  int bidentate=0;
  int bidentate_count=cnt_bidentate;
  ObjIonBondValenceInfo *ibvi1, *ibvi2;
  /* This procedures will be called only if bv_count>=2 */
  ibsi->num_bidentate_all++;
  if(bv_count==2) {
    ibvi1=bv_info; while(ibvi1->inner_sphere_flag<=0) ibvi1++;
    ibvi2=ibvi1+1; while(ibvi2->inner_sphere_flag<=0) ibvi2++;
    /* Mark special bidentate only when all of the following are true:
     * 1. From the same residue
     * 2. Form only two interactions
     * 3. Ligand Residue is an amino acid
     * 4. Both ligand atoms are from amino acid side chain */
    if(ibvi1->ai_lig->type>=ATOM_SC_N_ARG     && ibvi1->ai_lig->type<=ATOM_SC_N_HETERO &&
       ibvi2->ai_lig->type>=ATOM_SC_N_ARG     && ibvi2->ai_lig->type<=ATOM_SC_N_HETERO &&
       ibvi1->ri_lig->type<=RESIDUE_AMINOACID && ibvi2->ri_lig->type<=RESIDUE_AMINOACID) {
      if(ibvi1->ai_lig->protons==AN_O) {
        if(ibvi2->ai_lig->protons==AN_O)      {ibsi->num_bidentate_oo++;bidentate=1;}
        else if(ibvi2->ai_lig->protons==AN_N) {ibsi->num_bidentate_on++;bidentate=1;}
      } else if(ibvi1->ai_lig->protons==AN_N) {
        if(ibvi2->ai_lig->protons==AN_O)      {ibsi->num_bidentate_on++;bidentate=1;}
        else if(ibvi2->ai_lig->protons==AN_N) {ibsi->num_bidentate_nn++;bidentate=1;}
      }
    } else if(ibvi1->ri_lig->index==ibvi2->ri_lig->index
           && ibvi1->ri_lig->type>RESIDUE_AMINOACID && ibvi1->ri_lig->type!=RESIDUE_WATER
           && ibvi2->ri_lig->type>RESIDUE_AMINOACID && ibvi2->ri_lig->type!=RESIDUE_WATER) {
// ibvi1->ri_lig->index==ibvi2->ri_lig->index is not needed since this procedure is called only when 2 atoms are from the same residue
      // We only handle non-aqueous ligands here, water will be handled specially since it usually have different residue IDs
      // If we handle water here, and water indeed has same residue ID, it will be handled again later and create duplicate errors
      VectorCopy3f(vec0,ibvi1->direction);
      VectorSubstract3f(vec0,ibvi2->direction);
      if(VectorLength3f(vec0)<2.0f && VectorLength3f(vec0)>1.0f) {
        bidentate=1;
      }
    }
    if(bidentate) bidentate_count=ObjBidentateAdd(arr_bidentate, cnt_bidentate, cnt_bidentate, ibvi1, ibvi2, -2.0f);
//  printf("bidentating: %s, %d, %s, %s, %d, %s\n",ibvi1->ri_lig->resn,ibvi1->ri_lig->resid,ibvi1->ai_lig->realname,ibvi2->ri_lig->resn,ibvi1->ri_lig->resid,ibvi2->ai_lig->realname);
  }
  return bidentate_count;
}

int  ObjBidentateAdd(ObjBidentateInfo *arr_bidentate, int cnt_bidentate, int ind_bidentate, ObjIonBondValenceInfo *ibvi1, ObjIonBondValenceInfo *ibvi2, double distance) {
  int    bidentate_flag=3;
  int    bidentate_count=cnt_bidentate;
  double bidentate_distance=distance;
  Vector3f vec0;
  if(distance<=0.0f) {
    bidentate_flag=(distance<=1.5f) ? 2 : 1;
    VectorCopy3f(vec0,ibvi1->direction);
    VectorSubstract3f(vec0,ibvi2->direction);
    bidentate_distance=VectorLength3f(vec0);
  }
  /* Different bidentate_flags: 0: not bidentate; 1: phosphate/carboxyl bidentate; 2: other non-water bidentate; 3: water bidentate */
  ibvi1->bidentate_flag=bidentate_flag;
  ibvi2->bidentate_flag=bidentate_flag;
  arr_bidentate[ind_bidentate].bv1=ibvi1;
  arr_bidentate[ind_bidentate].bv2=ibvi2;
  arr_bidentate[ind_bidentate].distance=bidentate_distance;
  arr_bidentate[ind_bidentate].bondvalence=ibvi1->bondvalence+ibvi2->bondvalence;
//arr_bidentate[ind_bidentate].calcium_bondvalence=ibvi1->calcium_bondvalence+ibvi2->calcium_bondvalence;
  VectorCopy3f(arr_bidentate[ind_bidentate].bv_direction,ibvi1->bv_direction);
  VectorScaleUp3f(arr_bidentate[ind_bidentate].bv_direction,ibvi1->bondvalence);
  VectorCopy3f(vec0,ibvi2->bv_direction);
  VectorScaleUp3f(vec0,ibvi2->bondvalence);
  VectorAdd3f(arr_bidentate[ind_bidentate].bv_direction,vec0);
  VectorScaleDown3f(arr_bidentate[ind_bidentate].bv_direction,VectorLength3f(arr_bidentate[ind_bidentate].bv_direction));
  if(ind_bidentate==cnt_bidentate) bidentate_count++;
  return bidentate_count;
}

/*---------------------------------------------------------------------------*/
int ObjIonBindingSiteGeometry(ObjIonBindingSiteInfo *ibsi, ObjIonBondValenceInfo *bv_info, int bv_count, int geometry_bidentate) {
  int i, j, k, dict_base, numDataSamples, numModelCases;
  double rmsd_geom_angle=180.0f, geo_diff, geo_scores[6], geo_angles[56];       // geo_angles, array of 28 is sufficient, 29-56 should never be used
  int geometry_type=GEOM_FREE, geometry_pseudo=-1, geometry_distort=1, rmsd_geom_weight=1;
  int updateFlag=0;
  ObjIonBondValenceInfo *gbvi, *gbvj;
  Vector3f *vi, *vj;
  GeometryDict *geodict=geometry_dictionary;
  double bondvalence_limit;
  int coordnum, oxidation_state;
  if(!bv_count) PFatalError("ObjIonBindingSiteGeometry is called without any vertex data.\n");
/* code to calculate oxidation state moved to main procedure
  oxidation_state = bv_info->ai_ion->oxidation_state;
  if(oxidation_state>=-3 && oxidation_state<=-1) oxidation_state=1;
  if(oxidation_state<1 || oxidation_state>7) PFatalError("Unknown element and oxidation state.\n");
*/
  // Calculate coordination number using default setting
  coordnum=0;
  for(i=0;i<bv_count;i++) {
    gbvi=bv_info+i;
    if(gbvi->inner_sphere_flag>=1) coordnum++;
  }
/* deprecated code -- we have more delicate mechanism to define inner-sphere as defined by the inner_sphere_flag as of Nov-2012
  bondvalence_limit=oxidation_state*0.15f/coordnum;
  // Calculate coordination number according to preliminary coordination number
  if(bondvalence_limit>=0.08f) { bondvalence_limit=0.08f;
  } else {
    coordnum=0;
    for(i=0;i<bv_count;i++) {
      gbvi=bv_info+i;
      if(gbvi->bondvalence>=bondvalence_limit) coordnum++;
    }
  }
*/
  switch(coordnum) {
    case 0:  geometry_type=GEOM_FREE; geometry_pseudo=-1; rmsd_geom_angle=180.0f; break;
    case 1:  geometry_type=GEOM_UNDERFLOW; geometry_pseudo=1; rmsd_geom_angle=180.0f; break;
    case 2:  dict_base=1;  numModelCases=4; break;
    case 3:  dict_base=5;  numModelCases=5; break;
    case 4:  dict_base=10; numModelCases=5; break;
    case 5:  dict_base=15; numModelCases=2; break;
    case 6:  dict_base=17; numModelCases=3; break;
    case 7:  dict_base=20; numModelCases=2; break;
    case 8:  dict_base=22; numModelCases=3; break;
    default: geometry_type=GEOM_OVERFLOW;  geometry_pseudo=0; rmsd_geom_angle=180.0f; break;
  }
  if(coordnum>=2 && coordnum<=8) {
    // Calculate set of observed angles
    k=0;
    for(i=0;i<bv_count;i++) {
      gbvi=bv_info+i;
      if(gbvi->inner_sphere_flag>=1) {
        vi=&gbvi->bv_direction;
        for(j=i+1;j<bv_count;j++) {
        gbvj=bv_info+j;
          if(gbvj->inner_sphere_flag>=1) {
            vj=&gbvj->bv_direction;
            geo_angles[k]=VectorAngle2v(*vi,*vj);
          //printf("%c%d-%s, %c%d-%s, %c%d-%s -- %f\n",
          //  gbvi->ri_lig->chain,gbvi->ri_lig->resid,gbvi->ai_lig->realname,
          //  gbvi->ri_ion->chain,gbvi->ri_ion->resid,gbvi->ai_ion->realname,
          //  gbvj->ri_lig->chain,gbvj->ri_lig->resid,gbvj->ai_lig->realname,geo_angles[k]);
            k++;
          }
        }
      }
    }
    // Compute geometry
    numDataSamples=k;
    qsort(geo_angles,k,sizeof(double),doublecmp);
    for(i=0;i<numModelCases;i++) {
      j=dict_base+i;
      if(geodict[j].index!=j || geodict[j].coord_number!=coordnum) PFatalError("Inconsistent data detected for geometry dictionary.\n");
      if(geodict[j].angle_number != numDataSamples) PFatalError("Inconsistent number of angles detected for geometry dictionary.\n");
      geo_scores[i]=0.0f;
      for(k=0;k<numDataSamples;k++) {
        if(geodict[j].angle[k] < 0 || geo_angles[k] < 0) PFatalError("Negative angle detected for geometry dictionary.\n");
        geo_diff=geodict[j].angle[k]-geo_angles[k];
        geo_scores[i]+=geo_diff*geo_diff;
      }
      geo_scores[i]=sqrt(geo_scores[i]/numDataSamples);
    //printf("atomname: %s, i: %d, geo_score: %f, type: %d, missing %d\n",bv_info->ai_ion->realname,i,geo_scores[i],geodict[j].geometry_type,geodict[j].geometry_pseudo);
      if(geo_scores[i]/geodict[j].rmsd_geom_weight<rmsd_geom_angle/rmsd_geom_weight) {
        geometry_type=geodict[j].geometry_type;
        geometry_pseudo=geodict[j].geometry_pseudo;
        rmsd_geom_angle=geo_scores[i];
        rmsd_geom_weight=geodict[j].rmsd_geom_weight;
      }
    }
  }
  geometry_distort = rmsd_geom_angle<rmsd_geom_weight/10.0f ? 0 : 1;
  updateFlag=0;
  if(ibsi->rmsd_geom_angle<0) updateFlag=1;
  else if(ibsi->geometry_type && geometry_type) {
    if (rmsd_geom_angle/rmsd_geom_weight<ibsi->rmsd_geom_angle/ibsi->rmsd_geom_weight) updateFlag=1;
  }
  if(updateFlag) {
    ibsi->geometry_type     =geometry_type;
    ibsi->geometry_bidentate=geometry_bidentate;
    ibsi->geometry_pseudo   =geometry_pseudo;
    ibsi->geometry_distort  =geometry_distort;
    ibsi->rmsd_geom_angle   =rmsd_geom_angle;
    ibsi->rmsd_geom_weight  =rmsd_geom_weight;
    ibsi->coord_number_geom =coordnum;
//  for(i=0;i<bv_count;i++) {
//    gbvi=bv_info+i;
//    printf("%f-",gbvi->bv_direction_len);
//  }
//  printf("\n");
  }
  return coordnum;
}
/*---------------------------------------------------------------------------*
# Total 1
# ( 0        linear)       180
# (-1 pseudo triangle)     120
# (-2 pseudo tetrahedral)  109.5
# (-2 pseudo square planar) 90
# Total 3
# ( 0        triangle)           120,   120,   120
# (-1 pseudo tetrahedral)        109.5, 109.5, 109.5
# (-1 pseudo square planar)       90,    90,   180
# (-2 pseudo trigonal bipyramid)  90,    90,   120
# (-3 pseudo octahedral)          90,    90,    90
# Total 6
# ( 0             tetrahedral)        109.5, 109.5, 109.5, 109.5, 109.5, 109.5
# ( 0             square planar)       90,    90,    90,    90,   180,   180
# (-1 tip  pseudo trigonal bipyramid)  90,    90,    90,   120,   120,   120
# (-1 base pseudo trigonal bipyramid)  90,    90,    90,    90,   120,   180
# (-2      pseudo octahedral)          90,    90,    90,    90,    90,   180
# Total 10
# ( 0        trigonal bipyramid) 90, 90, 90, 90, 90, 90, 120, 120, 120, 180
# (-1 pseudo octahedral)         90, 90, 90, 90, 90, 90, 90,  90,  180, 180
# Total 15
# (octahedral)         90, 90, 90, 90, 90, 90,  90,  90,  90,  90,  90,  90, 180, 180, 180
# (trigonal biprism)   6 x 66.421822, 3 x 101.536957, 6 x 143.130096 (using side=1, height=sqrt(2))
# (trigonal antiprism) 70, 70, 70, 70, 70, 70, 110, 110, 110, 110, 110, 110, 180, 180, 180 (approx.)
# Total 21
# ( 0 capped trigonal biprism)  4 x 71.565048, 2 x 129.23152, plus 15 parameters from trigonal biprism (approx.)
# ( 0 pentagonal bipyramid)     5 x 72, 10 x 90, 5 x 144, 1 x 180
# Total 28
# ( 0 cubic)                    4 x (70.53 70.53 70.53 109.47 109.47 109.47 180)
# ( 0 square antiprism)         4 x (4 x 74.858490, 118.528267, 2 x 141.592468)
# ( 0 dodecahedral)             4 x (5 x 73.69345,  138.91964,      147.3869)
 *---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------*/
int ObjIonLigStrongestHB(ObjEntityMolecule *I, ObjResidueInfo *ri1, ObjResidueInfo *ri2) {
  int i,j,numHB=0,numOther=0,atomneighbor_index=-1,atomneighbor_index2=-1;
  double distance=10.0f; 
  double distance2=10.0f; 
  ObjAtomInfo     *ai1;
  ObjNeighborInfo *ni1;
  for(i=0;i<ri1->numAtom;i++) {
    ai1=ri1->AtomInfo+i;
    for(j=0;j<ai1->numAtmNeighbor;j++) {
      ni1=I->AtmNeighborInfo+ai1->AtmNeighborIndex[j];
      if((ri1->index==ni1->residue_index[0] && ri2->index==ni1->residue_index[1]) ||
         (ri2->index==ni1->residue_index[0] && ri1->index==ni1->residue_index[1])) {
        if(ni1->bond_type=='h' || ni1->bond_type=='3') { // || ni1->bond_type=='1')
          numHB++;
          if(ni1->distance<distance) {
            atomneighbor_index=ni1->index;
            distance=ni1->distance;
          }
        } else {
          numOther++;
          if(ni1->distance<distance2) {
            atomneighbor_index2=ni1->index;
            distance2=ni1->distance;
          }
        }
      }
    }
  }
  if(atomneighbor_index==-1 && atomneighbor_index2!=-1) atomneighbor_index=-atomneighbor_index2-2;
  // Return a negative atomneighborid when there is no hydrogen bond interaction
  return atomneighbor_index;
}

/*---------------------------------------------------------------------------*/
int ObjIonLigDresseq(ObjEntityMolecule *I, ObjResidueInfo *ri1, ObjResidueInfo *ri2) {
  int shift,dresseq=0;
  int reverse = (ri2->index > ri1->index) ? 0 : 1;
  ObjResidueInfo *ri = reverse ? ri2 : ri1;
  ObjResidueInfo *rj = reverse ? ri1 : ri2;
  ObjResidueInfo *circular_ri = ri;
  // The original algorithm enter an endless loop because of circular construct, e.g. structure 2oiu
  if(ri1->chain==ri2->chain) {
    shift=0;
    while(ri->next_index != -1 && ri->next_index != circular_ri->index) {
      ri=I->ResidueInfo+ri->next_index;
      shift++;
      if(ri->index == rj->index) {
        dresseq = reverse ? -shift : shift;
        return dresseq;
      }
    }
    ri = reverse ? ri2 : ri1;
    while(ri->prev_index != -1 && ri->prev_index != circular_ri->index) {
      ri=I->ResidueInfo+ri->prev_index;
      shift++;
      if(ri->index == rj->index) {
        dresseq = reverse ? shift : -shift;
        return dresseq;
      }
    }
  }
  return dresseq;
}

int ObjIonLigFCSIsoform(ObjIonLigAtomNeighborInfo *tmpIonLigAtomNeighbor, int numAtomNeighborFCS) {
  int i,priorities[4];
  int isoform2=0,isoform3=0,isoform=0;
  ObjIonLigAtomInfo *tmpIonLigAtom, *ilai, *ilai2;
  ObjIonLigAtomNeighborInfo *ilani;
  priorities[0]=-1; priorities[1]=-1; priorities[2]=-1; priorities[3]=-1; 
  for(i=0;i<numAtomNeighborFCS;i++) {
    ilani=tmpIonLigAtomNeighbor+i;
    if(ilani->angle>=135) {
      ilai =ilani->IonLigAtomInfo_a;
      ilai2=ilani->IonLigAtomInfo_b;
      if(ilai->isoform_considered==0 && ilai2->isoform_considered==0) {
        if(priorities[0]<0) {
          priorities[0]=ilai->priority;         priorities[1]=ilai2->priority;
        } else if(priorities[2]<0) {
          if(priorities[0]>ilai->priority || (priorities[0]==ilai->priority && priorities[1]>ilai2->priority)) {
            priorities[2]=priorities[0];        priorities[3]=priorities[1];
            priorities[0]=ilai->priority;       priorities[1]=ilai2->priority;
          } else {
            priorities[2]=ilai->priority;       priorities[3]=ilai2->priority;
          }
        } else {
          if(priorities[0]>ilai->priority || (priorities[0]==ilai->priority && priorities[1]>ilai2->priority)) {
            priorities[2]=priorities[0];        priorities[3]=priorities[1];
            priorities[0]=ilai->priority;       priorities[1]=ilai2->priority;
          } else if(priorities[2]>ilai->priority || (priorities[2]==ilai->priority && priorities[3]>ilai2->priority)) {
            priorities[2]=ilai->priority;       priorities[3]=ilai2->priority;
          }
        }
        ilai->isoform_considered=1;
        ilai2->isoform_considered=1;
      }
    }
  }
//printf("%d-%d-%d-%d\n",priorities[0],priorities[1],priorities[2],priorities[3]);
  if(priorities[0]!=-1) isoform+=1000; else return 0; // TODO: This only fix the problem temporarily for poly-nuclear sites, the actual BUG of incorrect 1111 for poly-nuclear sites is not fixed correctly
  if(priorities[1]!=-1) isoform2=(priorities[1]==priorities[0]) ? 1 : 2;
  if(priorities[2]!=-1) {
    if(priorities[2]==priorities[0])      isoform3=1;
    else if(priorities[2]==priorities[1]) isoform3=isoform2;
    else if(priorities[2]>priorities[1])  isoform3=isoform2+1;
    else { isoform3=isoform2; isoform2++; }
  }
  if(priorities[3]!=-1) {
    if(priorities[3]==priorities[0])         isoform++;
    else if(priorities[3]==priorities[1])    isoform+=isoform2;
    else if(priorities[3]==priorities[2])    isoform+=isoform3;
    else if(isoform2==isoform3) {
      if(priorities[3]>priorities[2])        isoform+=isoform3+1;
      else                                 { isoform+=isoform2; isoform2++; isoform3++; } // This case is impossible,
      // because priorities[3] is always greater than priorities[2] by definition
    } else if(priorities[1]<priorities[2]) {
      if(priorities[3]>priorities[2])        isoform+=isoform3+1;
      else if(priorities[3]>priorities[1]) { isoform+=isoform3; isoform3++; }
      else                                 { isoform+=isoform2; isoform2++; isoform3++; }
    } else if(priorities[1]>priorities[2]) {   
      if(priorities[3]>priorities[1])        isoform+=isoform2+1;
      else if(priorities[3]>priorities[2]) { isoform+=isoform2; isoform2++; }
      else                                 { isoform+=isoform3; isoform3++; isoform2++; }
    }
  }
  isoform+=100*isoform2+10*isoform3;
  return isoform;
}

/*---------------------------------------------------------------------------*/
void ObjIonBindingSite(ObjEntityMolecule *I, ObjIonBindingSiteInfo *ibsi, ObjIonBondValenceInfo *bv_info, int bv_count_redundant, int isWater) {
  int i, j, k, tmpAtomCount, lastResidueID, lastSymop;
  int priority, oxidation_state, bidenFound;
  ObjIonBondValenceInfo *ibvi, *ibvi2, *ibvi_closest, *ibvi_closest_2, *prev_residue_ibvi;
  ObjNeighborInfo       *ni;
  ObjAtomInfo           *ai, *ai2, *ai_ion=bv_info->ai_ion;
  ObjResidueInfo        *ri, *ri2, *ri3, *ri_prev=bv_info->ri_ion, *ri_ion=bv_info->ri_ion;
  Vector3f              *vi, *vj, bv_vec, vecsum_3a, vecsum_4a;
//Vector3f              calcium_bv_vec, calcium_vecsum_3a, calcium_vecsum_4a; 
  /* Site0: store non-bidentate info
   * Site2: store bidentate info in double form
   * Site1: store bidentate info in its pseudo-atom form, normalized vector calculated */
  ObjIonBondValenceInfo *tmpGeoSite0, *tmpGeoSite2, *tmpGeoSite1, *gbvi, *gbvi1;
  int tmpBVID0, tmpBVID2, tmpBVID1;
//int *listIndAtomFCS;
//int *listProtonAtomFCS;
//double *listDistAtomFCS;
  ObjIonLigResidueInfo *tmpIonLigResidue, *ili, *ili2;
  ObjIonLigMoietyInfo *ilmi;
  ObjIonLigAtomInfo *tmpIonLigAtom, *ilai, *ilai2;
  ObjIonLigAtomNeighborInfo *tmpIonLigAtomNeighbor, *ilani;
  ObjIonLigNeighborInfo *ilni;
  int tmpIonLigResidueID, tmpIonLigResidueID2;
  int indIonLigNeighbor=I->numIonLigNeighbor;	// This should not be effective if isWater=1
  int numAtomFCS, numAtomNeighborFCS;
  int resFound, ANindex, Dresseq, reverse;
  double rmsd_geom_angle=-1.0f;
  double bfactor1, bfactor2, lower_occup;
  int l, b[7];

  Vector3f vec0;
  double vec0len;
  ObjBidentateInfo arr_bidentate[64];
  int cnt_bidentate=0;
  int ind_bidentate=0;
  int bidentate_flag_last=10;
  int bv_count=bv_count_redundant;
  int bv_count_inner=0;
  int inner_sphere_min_ligands=2, inner_sphere_flag_column=1, inner_sphere_flag_code=0;
  int arr_atomid_cluster[64];
//int residue_present_in_inner_sphere;

  // Assign invalid ligands
  for(i=0;i<bv_count_redundant;i++) {
    ibvi=bv_info+i;
    if(ibvi->bv_direction_len<1.0f) {
      ibvi->valid=0;
      bv_count--;
    } else {
      for(j=i+1;j<bv_count_redundant;j++) {
        ibvi2=bv_info+j;
        VectorCopy3f(vec0,ibvi->direction);
        VectorSubstract3f(vec0,ibvi2->direction);
        if(ibvi->valid && ibvi2->valid && (VectorLength3f(vec0)<0.8f || (!ibvi->ai_lig->hydrogen && !ibvi2->ai_lig->hydrogen && VectorLength3f(vec0)<1.1f))) {
          k=0;
          if(ibvi->ai_lig->occup>ibvi2->ai_lig->occup) k=1;
          else if(ibvi->ai_lig->occup==ibvi2->ai_lig->occup) {
            if(ibvi->ai_lig->protons<ibvi2->ai_lig->protons) k=1;
            else if(ibvi->ai_lig->protons==ibvi2->ai_lig->protons) {
              if(ibvi->ai_lig->index<ibvi2->ai_lig->index) k=1;
            }
          }
          if(k) {
            ibvi2->valid=0;
            ibvi->valid_lig_occup+=ibvi2->valid_lig_occup;
            if(ibvi->valid_lig_occup>1) ibvi->valid_lig_occup=1;
          } else {
            ibvi->valid=0;
            ibvi2->valid_lig_occup+=ibvi->valid_lig_occup;
            if(ibvi2->valid_lig_occup>1) ibvi2->valid_lig_occup=1;
          }
          bv_count--;
        }
      }
    }
  }
  /* Sort#1: first sort by valid entries descendently */
  qsort(bv_info, bv_count_redundant, sizeof(ObjIonBondValenceInfo), ObjIonBondValenceValidCmp);
  /* Sort#2: out of valid entries, second sort by bond valence values descendently, to figure out the inner-sphere */
  qsort(bv_info, bv_count, sizeof(ObjIonBondValenceInfo), ObjIonBondValenceBVCmp);

  oxidation_state = bv_info->ai_ion->oxidation_state;
  if(oxidation_state>=-3 && oxidation_state<=-1) oxidation_state=1;
  if(oxidation_state<1 || oxidation_state>7) PFatalError("Unknown element and oxidation state.\n");
  inner_sphere_flag_column=1;   /* The first column is default unless overwritten by a AN match in the first row */
  for(i=2;i<12;i++) if(innersphere_dictionary[ATOM_UNDEF][i]==ibvi->ai_ion->protons) { inner_sphere_flag_column=i; break; }
  for(i=0;i<bv_count;i++) {
    ibvi=bv_info+i;
    ai=ibvi->ai_lig;
    ri=ibvi->ri_lig;
    if(ai->protons==AN_H || ibvi->ni->distance>=4.0f) continue;
    inner_sphere_flag_code   = innersphere_dictionary[ai->type][inner_sphere_flag_column];
    inner_sphere_min_ligands = innersphere_dictionary[ATOM_MAX][inner_sphere_flag_column];
    ibvi2=ObjIonBondValencePrevBidentate(ibvi,bv_info,i-1); // Do not compare with self (i), compare with only values before self (<i)
//  if(ibvi2 != NULL) {printf("bidentate detected: %c%d-%c%d,%s,%f-%c%d,%s,%f\n",ibvi->ri_ion->chain,ibvi->ri_ion->resid,ibvi->ri_lig->chain,ibvi->ri_lig->resid,ibvi->ai_lig->name,ibvi->ni->distance,ibvi2->ri_lig->chain,ibvi2->ri_lig->resid,ibvi2->ai_lig->name,ibvi2->ni->distance);}
    if (ibvi->bondvalence>=0.043148362*oxidation_state) {
      // 0.043148362*2 is empirical for divalent cation with CN=6 when bond distance deviation is 0.5
      if(inner_sphere_flag_code) {
        ibvi->inner_sphere_flag=1;
        bv_count_inner++;
      }
    } else if (ibvi->bondvalence>=0.011170687*oxidation_state) {
      // 0.011170687*2 is empirical for divalent cation with CN=6 when bond distance deviation is 1.0
      if(inner_sphere_flag_code >= 2 && bv_count_inner<inner_sphere_min_ligands) {
//      if(bv_count_inner==5) { 
//        ObjIonBindingSiteVecsumNW(vec0,bv_info,bv_count_inner);
//        VectorAdd3f(vec0,ibvi->bv_direction);
//        if(VectorLength3f(vec0)>0.3) continue;
//      }
// printf("%d, %c%d, %f, %f, %d\n", ibvi->ri_ion->resid, ibvi->ri_lig->chain, ibvi->ri_lig->resid, ibvi->bondvalence, ibvi->ni->distance, bv_count_inner);
        if(ObjIonBindginSiteSmallestAngle(ibvi->bv_direction,bv_info,bv_count_inner) < 50) continue;
// printf("passed: %d, %c%d, %f, %f, %d\n", ibvi->ri_ion->resid, ibvi->ri_lig->chain, ibvi->ri_lig->resid, ibvi->bondvalence, ibvi->ni->distance, bv_count_inner);
        if(inner_sphere_flag_code==4 && AtomInfoHasHydrogenBond(ai,I,0)) break;
        else if(inner_sphere_flag_code==3 && ibvi2 != NULL) {
          if(bv_count_inner==5) break;
          else { ibvi->inner_sphere_flag=-1; continue; } // If CN=1,2,3,4 flag fake atom, and continue
        }
        ibvi->inner_sphere_flag=2;
        bv_count_inner++;
      }
    }
    if(ibvi2 && ibvi->inner_sphere_flag && ibvi2->inner_sphere_flag) { // bidentate detected
      if(ibvi2->bidentate_flag==0) { // ibvi2 not yet assigned as another bidentate pair
        ibsi->num_bidentate_all++;
        ibvi2->bidentate_flag=bidentate_flag_last;
        bidentate_flag_last++;
      }
      ibvi->bidentate_flag=ibvi2->bidentate_flag;
    }
  }
  /* Sort#3: out of valid entries in the potential inner-sphere, thirdly sort by inner_sphere_flag descendingly */
  qsort(bv_info, bv_count, sizeof(ObjIonBondValenceInfo), ObjIonBondValenceInnerCmp);
///* Sort#4: out of valid entries in the inner-sphere, last sort by bidentate_flag descendingly */
//qsort(bv_info, bv_count_inner, sizeof(ObjIonBondValenceInfo), ObjIonBondValenceBidentateCmp);
  /* obsolted because residue ID no long in use: Sort#4: out of valid entries in the inner-sphere, last sort by residue id ascendingly */
  qsort(bv_info, bv_count_inner, sizeof(ObjIonBondValenceInfo), ObjIonBondValenceLigRICmp);
  // ordered by residue/moiety/bidentate_flag
  if(!isWater) {
    tmpIonLigResidue=I->IonLigResidueInfo+I->numIonLigResidue;                tmpIonLigResidueID=0;
    tmpIonLigAtom=I->IonLigAtomInfo+I->numIonLigAtom;                         numAtomFCS=0;
    tmpIonLigAtomNeighbor=I->IonLigAtomNeighborInfo+I->numIonLigAtomNeighbor; numAtomNeighborFCS=0;
//AllocP(listIndAtomFCS, int, bv_count);
//AllocP(listProtonAtomFCS, int, bv_count);
//AllocP(listDistAtomFCS, double, bv_count); numAtomFCS0=0;
  }

//for(i=0;i<bv_count;i++) {
//  ibvi=bv_info+i;
//  printf("%c%d-%s-%s: %d, %f, %d, %d\n",ibvi->ri_lig->chain,ibvi->ri_lig->resid,ibvi->ri_lig->resn,ibvi->ai_lig->realname,ibvi->ri_lig->index,ibvi->ni->distance,ibvi->ni->contact_flag,ibvi->ai_ion->protons);
//}
//printf("\n");
  ObjIonBindingSiteInit(ibsi,ai_ion);
  ObjIonBindingSiteVecsumNW(vec0,bv_info,bv_count);
  ibsi->quality_complete_nw=1-VectorLength3f(vec0);
  if(ibsi->quality_complete_nw<0) ibsi->quality_complete_nw=0;
  tmpAtomCount =-1;
  lastResidueID=-1;
  lastSymop    =-1;
  VectorClear3f(vecsum_3a);   //VectorClear3f(calcium_vecsum_3a);
  VectorClear3f(vecsum_4a);   //VectorClear3f(calcium_vecsum_4a);

  for(i=0;i<bv_count;i++) {
     ibvi=bv_info+i;
     ai=ibvi->ai_lig;
     ri=ibvi->ri_lig;
/*1*/if(ai->protons==AN_H || ibvi->ni->distance>=4.0f) continue;
     ibsi->coord_number_4a++;
     if(ai->isMetal) ibsi->num_metal_4a++;
     if(ibvi->bondvalence>0) {
       ibsi->bfactor_env_avg+=ai->b*ibvi->bondvalence;
       ibsi->occupancy_env_avg+=ibvi->valid_lig_occup*ibvi->bondvalence;
       ibsi->valence_4a+=ibvi->bondvalence;
       VectorCopy3f(bv_vec,ibvi->bv_direction);
       VectorScaleUp3f(bv_vec,ibvi->bondvalence);
       VectorAdd3f(vecsum_4a,bv_vec);
     }
     /* obsolete code -- CBVS, calcium bond valence is deprecated
     if(ibvi->calcium_bondvalence>0) {
       ibsi->calcium_valence_4a+=ibvi->calcium_bondvalence;
       VectorCopy3f(calcium_bv_vec,ibvi->bv_direction);
       VectorScaleUp3f(calcium_bv_vec,ibvi->calcium_bondvalence);
       VectorAdd3f(calcium_vecsum_4a,calcium_bv_vec);
     }
     */
/*2*/if(ibvi->inner_sphere_flag<=0) continue;    // Further processing only on innersphere ligands
     ibsi->coord_number_3a++;
     /* general operations */
     ibsi->distance_avg+=ibvi->ni->distance;
     if(ibvi->ni->distance>ibsi->distance_max) ibsi->distance_max=ibvi->ni->distance;
     if(ibvi->ni->distance<ibsi->distance_min) ibsi->distance_min=ibvi->ni->distance;
     if(ibvi->bondvalence>0) {
       ibsi->valence_3a+=ibvi->bondvalence;
       VectorAdd3f(vecsum_3a,bv_vec);
     }
     /* Additional steps for inner-sphere */
     ibsi->bvs_sodium    += ibvi->bv_sodium   ;  ibsi->bvs_magnesium += ibvi->bv_magnesium;
     ibsi->bvs_potassium += ibvi->bv_potassium;  ibsi->bvs_calcium   += ibvi->bv_calcium  ;
     ibsi->bvs_manganese += ibvi->bv_manganese;  ibsi->bvs_iron      += ibvi->bv_iron     ;
     ibsi->bvs_cobalt    += ibvi->bv_cobalt   ;  ibsi->bvs_nickel    += ibvi->bv_nickel   ;
     ibsi->bvs_copper    += ibvi->bv_copper   ;  ibsi->bvs_zinc      += ibvi->bv_zinc     ;
     priority=ObjIonBondValenceAssignPriority(I, ibvi, ibsi, bv_info, bv_count, numAtomFCS-1, isWater); // Some statistics of ibsi object is also updated accordingly

     /* obsolete code -- calculate bidentate based on residue ID is deprecated, now it is calculated based on carboxyl and phosphate only
     if(ibvi->ri_lig->index==lastResidueID && ibvi->ni->vec_fwd->icell*1000+ibvi->ni->vec_fwd->isym==lastSymop) {
       tmpAtomCount++;
     } else {
       lastResidueID=ibvi->ri_lig->index;
       lastSymop=ibvi->ni->vec_fwd->icell*1000+ibvi->ni->vec_fwd->isym;
       if(tmpAtomCount>=2) cnt_bidentate=ObjIonBindingSiteBidentate(ibsi,prev_residue_ibvi,tmpAtomCount,arr_bidentate,cnt_bidentate);
       tmpAtomCount=1;
       prev_residue_ibvi=ibvi;
     } */
 
/*3*/if(isWater) continue;    // Further processing only for ions and not water
     if(ri_prev->index == ri_ion->index || ri->index != ri_prev->index) {
       ili=tmpIonLigResidue+tmpIonLigResidueID;
       ili->local_index=tmpIonLigResidueID;
       ili->bindingsite_index=ibsi->index;
       ili->type=ILR_INNERSPHERE;
       ili->priority=priority;
       ili->residue_index=ri->index;
       ili->atom_index[0]=ai->index;
       ili->atom_index[1]=-1;
       ili->distance[0]=ibvi->ni->distance;
       ili->distance[1]=-9999.0f;
//     ili->numNeighbor=0;
//     AllocP(ili->AtmNeighborIndex,int,(ri->numResNeighbor+1));
       tmpIonLigResidueID++;
     } else if(ili->atom_index[1]==-1) {   // For first coordination sphere, this second field stores bidentate information
       if((ili->priority==ISOFORM_SC_O_CARBOXYL  && priority==ISOFORM_SC_O_CARBOXYL) ||
          (ili->priority==ISOFORM_DR_OP_TERMINAL && priority==ISOFORM_DR_OP_TERMINAL)) {
         if(ibvi->ni->distance > ili->distance[0]) {
           ili->atom_index[1]=ai->index;
           ili->distance[1]=ibvi->ni->distance;
         } else {
           ili->atom_index[1]=ili->atom_index[0];
           ili->distance[1]=ili->distance[0];
           ili->atom_index[0]=ai->index;
           ili->distance[0]=ibvi->ni->distance;
         }
       }
     }
     ri_prev=ri;
 
     ilai=tmpIonLigAtom+numAtomFCS;        ilai->local_index=numAtomFCS;
     ilai->bindingsite_index=ibsi->index;  ilai->priority=priority;
     ilai->IonLigResidueInfo=ili;          ilai->protons=ai->protons;
     ilai->atom_index=ai->index;           ilai->IonBondValenceInfo=ibvi;
     ilai->distance=ibvi->ni->distance;    ilai->bondvalence=ibvi->bondvalence;
     VectorCopy3f(ilai->bv_direction,ibvi->bv_direction);
     ilai->isoform_considered=0;
//   listIndAtomFCS[numAtomFCS]=ai->index;
//   listProtonAtomFCS[numAtomFCS]=ai->protons;
//   listDistAtomFCS[numAtomFCS]=ibvi->ni->distance;
     numAtomFCS++;
  }
  if(!isWater) ibsi->valence_3a = AtomInfoAssignOxidationState(ai_ion, numAtomFCS, tmpIonLigAtom, ibsi->valence_3a);
  else ai_ion->oxidation_state=-2;
  // Obsolete: An independent process 1: Finishing up amino acid side chain bidentate and summary info
  // if(tmpAtomCount>=2) cnt_bidentate=ObjIonBindingSiteBidentate(ibsi,prev_residue_ibvi,tmpAtomCount,arr_bidentate,cnt_bidentate);

//printf("innersphere done...%d-%d\n",bv_count,bv_count_inner);
  ibsi->bfactor_env_avg   /= ibsi->valence_4a;
  ibsi->occupancy_env_avg /= ibsi->valence_4a;
  ibsi->distance_avg      /= ibsi->coord_number_3a;
  if(ibsi->distance_min>3.5f) ibsi->distance_min=-1.0f;
  ibsi->vecsum_3a=VectorLength3f(vecsum_3a);
  ibsi->vecsum_4a=VectorLength3f(vecsum_4a);
  /* obsolete code -- CBVS, calcium bond valence is deprecated
  ibsi->calcium_vecsum_3a=VectorLength3f(calcium_vecsum_3a);
  ibsi->calcium_vecsum_4a=VectorLength3f(calcium_vecsum_4a);
  */
  for(i=0;i<bv_count_inner;i++) {
    ibvi=bv_info+i;
    if(ibvi->inner_sphere_flag <= 0) continue;
  // First process carobxyl/phosphate bidentate that has been marked in a previous procedure with ibvi->bidentate_flag>=10
    if(ibvi->bidentate_flag>=10) {
      bidenFound = 0;
      for(j=i+1;j<bv_count_inner;j++) {
        ibvi2=bv_info+j;
        if(ibvi2->bidentate_flag!=ibvi->bidentate_flag || ibvi2->inner_sphere_flag<=0) continue;
        // need to check all inner-sphere ligands, because ligand with the same bidentate_flag may come from different residues
        // and therefore may not be next to each other in records.
        if(!bidenFound) {
          bidenFound = 1;
          if(ibvi->bondvalence > ibvi2->bondvalence) {
            ibvi_closest=ibvi; ibvi_closest_2=ibvi2;
          } else {
            ibvi_closest=ibvi2; ibvi_closest_2=ibvi;
          }
        } else {
          if(ibvi2->bondvalence > ibvi_closest_2->bondvalence) {
            ibvi_closest_2->bidentate_flag=0; // clear the bidentate_flag for whatever has been chosen previously
                                              // but removed due to the presence of stronger interaction
            if(ibvi2->bondvalence > ibvi_closest->bondvalence) {
              ibvi_closest_2=ibvi_closest;
              ibvi_closest=ibvi2;
            } else {
              ibvi_closest_2=ibvi2;
            }
          } else ibvi2->bidentate_flag=0; // clear the bidentate_flag for whatever not chosen
        }
      }
      cnt_bidentate=ObjBidentateAdd(arr_bidentate, cnt_bidentate, cnt_bidentate, ibvi_closest, ibvi_closest_2, -1.0f);
  // Now process water bidentate: water bidentate is special because it usually have different residue IDs
  // However, in the one case of 1JUH, water bidentate indeed have same residue ID with alternative conformation
    } else if(ibvi->ai_lig->type==ATOM_WT_O) {
      for(j=i+1;j<bv_count_inner;j++) {
        ibvi2=bv_info+j;
        if(ibvi2->ai_lig->type!=ATOM_WT_O || ibvi2->inner_sphere_flag<=0) continue;
        VectorCopy3f(vec0,ibvi->direction);
        VectorSubstract3f(vec0,ibvi2->direction);
        vec0len=VectorLength3f(vec0);
        if(vec0len>=2.0f) continue;
        ind_bidentate=cnt_bidentate;
        for(k=0;k<cnt_bidentate;k++) {
          if(arr_bidentate[k].bv1==ibvi || arr_bidentate[k].bv1==ibvi2 ||
             arr_bidentate[k].bv2==ibvi || arr_bidentate[k].bv2==ibvi2) {
            if(arr_bidentate[k].distance > vec0len) ind_bidentate=k;
          } 
        }
        cnt_bidentate=ObjBidentateAdd(arr_bidentate, cnt_bidentate, ind_bidentate, ibvi, ibvi2, vec0len);
      }
    }
  }

  AllocP(tmpGeoSite0, ObjIonBondValenceInfo, bv_count*2+1);   tmpBVID0=0;  // To store non-bidentate BV records temporarily
  AllocP(tmpGeoSite1, ObjIonBondValenceInfo, bv_count*2+1);   tmpBVID1=0;  // To store bidentate BV records temporarily
  AllocP(tmpGeoSite2, ObjIonBondValenceInfo, bv_count*4+1); tmpBVID2=0;
  // To store bidentate BV records temporarily, entry 3p4c failed if bv_count not doubled
  for(i=0;i<bv_count;i++) {
    ibvi=bv_info+i;
  //ai=ibvi->ai_lig;
    if(ibvi->inner_sphere_flag>=1 && ibvi->bv_direction_len>0.0f && !ibvi->bidentate_flag) {
  //    && (ai->protons==AN_O || ai->protons==AN_N || ai->protons==AN_S)
      gbvi=tmpGeoSite0+tmpBVID0;
      tmpBVID0++;
      ObjIonBondValenceCopy(gbvi,ibvi);
    }
  }
  for(i=0;i<cnt_bidentate;i++) {
    ibvi=arr_bidentate[i].bv1;
    ibvi2=arr_bidentate[i].bv2;
    if((ibvi->inner_sphere_flag>=1 && ibvi->bv_direction_len>0.0f) || (ibvi2->inner_sphere_flag>=1 && ibvi2->bv_direction_len>0.0f)) {
      gbvi=tmpGeoSite2+tmpBVID2;
      ObjIonBondValenceCopy(gbvi,ibvi);
      gbvi=tmpGeoSite2+tmpBVID2+1;
      ObjIonBondValenceCopy(gbvi,ibvi2);
      tmpBVID2+=2;
      gbvi1=tmpGeoSite1+tmpBVID1;
      gbvi1->index=-1;    gbvi1->ni=NULL;
      gbvi1->reverse=-1;  gbvi1->valid=1;
      gbvi1->ri_lig=NULL; gbvi1->ri_ion=ibvi->ri_ion;
      gbvi1->ai_lig=NULL; gbvi1->ai_ion=ibvi->ai_ion;
      gbvi1->bondvalence=arr_bidentate[i].bondvalence;
//    gbvi1->calcium_bondvalence=arr_bidentate[i].calcium_bondvalence;
      VectorCopy3f(gbvi1->bv_direction,arr_bidentate[i].bv_direction);
      gbvi1->bv_direction_len=-1.0f;
      tmpBVID1++;
    }
  }

//printf("tmpBVID: %d %d %d\n",tmpBVID0,tmpBVID1,tmpBVID2);
//for(i=0;i<tmpBVID0;i++) { gbvi=tmpGeoSite0+i; VectorPrint3f(gbvi->bv_direction); }
//for(i=0;i<tmpBVID1;i++) { gbvi=tmpGeoSite1+i; VectorPrint3f(gbvi->bv_direction); }
//for(i=0;i<tmpBVID2;i++) { gbvi=tmpGeoSite2+i; VectorPrint3f(gbvi->bv_direction); }
  for(i=0;i<tmpBVID0;i++) {
    gbvi=tmpGeoSite0+i;
  }
  if(tmpBVID2!=2*tmpBVID1) PFatalError("Inconsistent data tmpBVID2!=2*tmpBVID1.\n");
  if(tmpBVID1==0 || (tmpBVID0+tmpBVID1<=2)) {   // Reference table top left corner
    for(i=0;i<tmpBVID2;i++) {
      gbvi=tmpGeoSite0+tmpBVID0+i;
      gbvi1=tmpGeoSite2+i;
      ObjIonBondValenceCopy(gbvi,gbvi1);
    }
    if(tmpBVID0+tmpBVID2)
      ObjIonBindingSiteGeometry(ibsi,tmpGeoSite0,tmpBVID0+tmpBVID2,0);
  } else if(tmpBVID0+tmpBVID1>=8) {             // Refernece table bottom right corner OVERFLOW
    for(i=0;i<tmpBVID1;i++) {
      gbvi=tmpGeoSite0+tmpBVID0+i;
      gbvi1=tmpGeoSite1+i;
      ObjIonBondValenceCopy(gbvi,gbvi1);
    }
    ObjIonBindingSiteGeometry(ibsi,tmpGeoSite0,tmpBVID0+tmpBVID1,tmpBVID1);
  } else {
    l=1<<tmpBVID1;
    for(i=0;i<l;i++) {
      k=0;
      for(j=0;j<tmpBVID1;j++) {
        b[j]=(i>>j)%2;
        k+=b[j];
        k++;
      }
      if(tmpBVID0+k>8) continue;
//    for(j=0;j<tmpBVID1;j++) printf("%d,",b[j]);
//    printf("\n");
      k=0;
      for(j=0;j<tmpBVID1;j++) {
        gbvi=tmpGeoSite0+tmpBVID0+k;
        if(b[j]) {
          gbvi1=tmpGeoSite2+(j*2);
          ObjIonBondValenceCopy(gbvi,gbvi1);
          k++;
          gbvi=tmpGeoSite0+tmpBVID0+k;
          gbvi1=tmpGeoSite2+(j*2+1);
        } else {
          gbvi1=tmpGeoSite1+j;
        }
        ObjIonBondValenceCopy(gbvi,gbvi1);
        k++;
      }
      ObjIonBindingSiteGeometry(ibsi,tmpGeoSite0,tmpBVID0+k,tmpBVID2-k);
    }
  }
  FreeP(tmpGeoSite1);
  FreeP(tmpGeoSite2);
  FreeP(tmpGeoSite0);
  if(isWater) return;   // No further processing about classification for water

  // An independent process 2: Calculate IonLigNeighbors based on IonLigSites
  tmpIonLigResidueID2=tmpIonLigResidueID;     // tmpIonLigResidueID = CN (1st coord sphere), tmpIonLigResidueID2 = CN (2nd coord sphere)
  for(i=0;i<tmpIonLigResidueID;i++) { 
    ili=tmpIonLigResidue+i;
    ri=I->ResidueInfo+ili->residue_index;
    for(j=0;j<ri->numResNeighbor;j++) {
      ni=I->ResNeighborInfo+ri->ResNeighborIndex[j];
      ri2=I->ResidueInfo+((ni->residue_index[0]==ri->index) ? ni->residue_index[1] : ni->residue_index[0]);
      resFound=-1;
      for(k=0;k<tmpIonLigResidueID2;k++) {
        ili2=tmpIonLigResidue+k;
        if(ili2->residue_index==ri2->index) { resFound=ri2->index; break; }
      }
      if(resFound==-1 && ri2->index!=ri_ion->index && ObjIonLigStrongestHB(I, ri, ri2)>=0) {
        ili2=tmpIonLigResidue+tmpIonLigResidueID2;
        ili2->local_index=tmpIonLigResidueID2;
        ili2->bindingsite_index=ibsi->index;
        ili2->type=ILR_INDIRECT_OUTERSPHERE;   // type 1: 1st coord sphere; type 2: 2nd coord sphere
        ili2->priority=-1;                     // isoform is only calculated for 1st coordination sphere
        ili2->residue_index=ri2->index;
        ili2->atom_index[0]=-1;
        ili2->atom_index[1]=-1;
        ili2->distance[0]=-9999.0f;
        ili2->distance[1]=-9999.0f;
//      ili2->numNeighbor=0;
//      AllocP(ili2->AtmNeighborIndex,int,(ri2->numResNeighbor+1));
        tmpIonLigResidueID2++;
      }
    }
  }

  // Assign outersphere number of moieties to classification field which_mBRP2
  if(I->numIonLigMoiety) {
    for(i=I->numIonLigMoiety-1;i>=0;i--) {
      ilmi=I->IonLigMoietyInfo+i;
      if(ilmi->bindingsite_index!=ibsi->index) break;
      if(ilmi->type==ILR_DIRECT_OUTERSPHERE && ilmi->moiety_type>=MOIETY_PHOSPHATE && ilmi->moiety_type<=MOIETY_BASE) {
/*        if(ilmi->type==MOIETY_RIBOSE) { 
          for(j=0;j<tmpIonLigResidueID2;j++) {
            ili=tmpIonLigResidue+j;
          }
          ilmi->valid=ObjIonLigMoietyValid(I->IonLigAtomInfo);
        }
        if(!ilmi->valid) continue; */
//       residue_present_in_inner_sphere = 0;
//       for(j=0;j<bv_count_inner;j++) {
//         ibvi=bv_info+j;
//         if(ibvi->inner_sphere_flag <= 0) continue;
//         if(ibvi->ri_lig->index==ilmi->residue_index) residue_present_in_inner_sphere = 1;
//       }
//       if(residue_present_in_inner_sphere) continue;
        if(ilmi->moiety_type==MOIETY_PHOSPHATE)   ibsi->which_mBRP2++;
        else if(ilmi->moiety_type==MOIETY_RIBOSE) ibsi->which_mBRP2+=10;
        else if(ilmi->moiety_type==MOIETY_BASE)   ibsi->which_mBRP2+=100;
      }
    }
  }

  /* assign interaction towards metal center for second coordination sphere */
  for(l=0;l<numAtomFCS;l++) {                   // For each atom in the first coordination sphere
    ilai2=tmpIonLigAtom+l;
    ai2=I->AtomInfo+ilai2->atom_index;
    /* Task 1: assign first coordination sphere ion_bindingsite_ligatomneighbors records */
    if(l<numAtomFCS-1) for(i=l+1;i<numAtomFCS;i++) {
      ilai=tmpIonLigAtom+i;
      ai=I->AtomInfo+ilai->atom_index;
      ilani=tmpIonLigAtomNeighbor+numAtomNeighborFCS;
      ilani->local_index=numAtomNeighborFCS;
      ilani->bindingsite_index=ibsi->index;
      vi=&(ilai->bv_direction);
      vj=&(ilai2->bv_direction);
      ilani->angle=VectorAngle2v(*vi,*vj);
      ilani->bvproduct_cos_angle=ilai->bondvalence*ilai2->bondvalence*cos(ilani->angle);
      ri=ai->ResidueInfo;
      ri2=ai2->ResidueInfo;
      Dresseq = ObjIonLigDresseq(I, ri, ri2);           // non-covalent interaction relationship
      reverse=0;
      if(ilai->priority > ilai2->priority) reverse=1;
      else if(ilai->priority == ilai2->priority) {
        if(ilai->IonLigResidueInfo->residue_index > ilai2->IonLigResidueInfo->residue_index) reverse=1;
        else if(ilai->IonLigResidueInfo->residue_index == ilai2->IonLigResidueInfo->residue_index) {
          if(ilai->distance > ilai2->distance) reverse=1;
          else if(ilai->distance == ilai2->distance) reverse = strncmp(ai->realname,ai2->realname,4)>0 ? 1 : 0;
        }
      }
      if(reverse) {
        ilani->priority_type=ilai2->priority*100+ilai->priority;        ilani->dresseq=-Dresseq;
        ilani->IonLigAtomInfo_a=ilai2; ilani->atom_index[0]=ai2->index; ilani->residue_index[0]=ri2->index;
        ilani->IonLigAtomInfo_b=ilai;  ilani->atom_index[1]=ai->index;  ilani->residue_index[1]=ri->index; 
      } else {
        ilani->priority_type=ilai->priority*100+ilai2->priority;        ilani->dresseq=Dresseq;
        ilani->IonLigAtomInfo_a=ilai;  ilani->atom_index[0]=ai->index;  ilani->residue_index[0]=ri->index;
        ilani->IonLigAtomInfo_b=ilai2; ilani->atom_index[1]=ai2->index; ilani->residue_index[1]=ri2->index;
      }
      if(Dresseq==0 && ri->index!=ri2->index) ilani->dresseq=-9999;
      numAtomNeighborFCS++;
    }
    /* Task 2: assign interaction towards metal center for second coordination sphere */
    for(i=tmpIonLigResidueID;i<tmpIonLigResidueID2;i++) {     // For each residue in 2nd coordnation sphere
      ili=tmpIonLigResidue+i;
      ri=I->ResidueInfo+ili->residue_index;
      for(j=0;j<ri->numAtom;j++) {              // For each atom in this residue
        ai=ri->AtomInfo+j;
        for(k=0;k<ai2->numAtmNeighbor;k++) {    // For each neighbor of the first coordination sphere atom
          ni=I->AtmNeighborInfo+ai2->AtmNeighborIndex[k];
          if((ai2->index==ni->atom_index[0] && ai->index==ni->atom_index[1]) ||
             (ai->index==ni->atom_index[0] && ai2->index==ni->atom_index[1])) {
            if(ni->bond_type=='h' || ni->bond_type=='3') { // || ni->bond_type=='1')     // if these two atoms forms a hydrogen bond
// We do not want to take contact bond with 1 asteriod, because it is too weak to be considered a hydrogen bond in commonly accpeted notion
// example, 2nug F545-HOH and D2-A-N6 distance 4.54, and contact predicted as a weak hydrogen bond with one star
              if(ili->atom_index[0]==-1 || ni->distance+ilai2->distance<ili->distance[0]) {
                ili->type=ILR_DIRECT_OUTERSPHERE;
                ili->atom_index[0]=ai->index;
                ili->distance[0]=ni->distance+ilai2->distance;       // This field rather stores the cumulative distance towards the metal
                ili->atom_index[1]=ai2->index;
                ili->distance[1]=ilai2->distance;    // This field stores the first coordination distance towards the metal
              }
            }
          }
        }
      }
    }
  }
  for(i=tmpIonLigResidueID;i<tmpIonLigResidueID2;i++) {     // For each residue in 2nd coordnation sphere
    ili=tmpIonLigResidue+i;
    if(ili->atom_index[0]==-1 && ili->atom_index[1]==-1) {
      ri=I->ResidueInfo+ili->residue_index;
      for(j=0;j<tmpIonLigResidueID;j++) {
        ili2=tmpIonLigResidue+j;
        ri2=I->ResidueInfo+ili2->residue_index;
        ANindex=ObjIonLigStrongestHB(I, ri, ri2);
        if(ANindex>=0) {
          ni=I->AtmNeighborInfo+ANindex;
          if(ni->residue_index[0]==ri->index && ni->residue_index[1]==ri2->index) {
            ai=I->AtomInfo+ni->atom_index[0];
            ai2=I->AtomInfo+ni->atom_index[1];
          } else {
            ai=I->AtomInfo+ni->atom_index[1];
            ai2=I->AtomInfo+ni->atom_index[0];
          }
          ili->atom_index[0]=ai->index;
          ili->distance[0]=-ni->distance;
          ili->atom_index[1]=ai2->index;
          ili->distance[1]=-9999.0f;
        }
      }
    }
  }
  /* assign ionligneighbors */
  for(i=0;i<tmpIonLigResidueID2-1;i++) {
    ili=tmpIonLigResidue+i;
    ri=I->ResidueInfo+ili->residue_index;
    for(j=i+1;j<tmpIonLigResidueID2;j++) {
      ili2=tmpIonLigResidue+j;
      ri2=I->ResidueInfo+ili2->residue_index;
      ANindex = ObjIonLigStrongestHB(I, ri, ri2);       // non-covalent interaction relationship
      Dresseq = ObjIonLigDresseq(I, ri, ri2);           // sequence covalent relationship
      if(Dresseq!=0 || ANindex>=0) {                    // Need at least one relationship to get an IonLigNeighbor record
        ilni=I->IonLigNeighborInfo+indIonLigNeighbor;
        ilni->index=indIonLigNeighbor;
        ilni->bindingsite_index=ibsi->index;
        reverse = 0; if(Dresseq<0) { reverse=1; Dresseq = -Dresseq; }
        ilni->dresseq = Dresseq ? Dresseq : -9999;
        if(reverse) {
          ilni->type = ili2->type*10+ili->type;
          ilni->IonLigResidueInfo_a=ili2; ilni->residue_index[0]=ili2->residue_index; ilni->atom_index[0]=ili2->atom_index[0];
          ilni->IonLigResidueInfo_b=ili;  ilni->residue_index[1]=ili->residue_index;  ilni->atom_index[1]=ili->atom_index[0];
        } else {
          ilni->type = ili->type*10+ili2->type;
          ilni->IonLigResidueInfo_a=ili;  ilni->residue_index[0]=ili->residue_index;  ilni->atom_index[0]=ili->atom_index[0];
          ilni->IonLigResidueInfo_b=ili2; ilni->residue_index[1]=ili2->residue_index; ilni->atom_index[1]=ili2->atom_index[0];
        }
        ilni->type *= 100;
        if(ANindex>=0) ilni->type+=10;
        if(Dresseq!=0) ilni->type++;
        ilni->neighbor_index    = -1;
        for(k=0;k<ri->numResNeighbor;k++) {
          ni=I->ResNeighborInfo+ri->ResNeighborIndex[k];
          if((ili->residue_index==ni->residue_index[0] && ili2->residue_index==ni->residue_index[1]) ||
             (ili->residue_index==ni->residue_index[1] && ili2->residue_index==ni->residue_index[0])) {
            ilni->neighbor_index=ni->index;
          }
        }
        if(ANindex!=-1) {
          ilni->atomneighbor_index=(ANindex>=0) ? ANindex : -ANindex-2; // strongest hydrogen bonds versus strongest non-hydrogen bond interaction
          ni=I->AtmNeighborInfo+ilni->atomneighbor_index;
          if(ni->residue_index[0]==ilni->residue_index[0] && ni->residue_index[1]==ilni->residue_index[1]) {
            ilni->atom_index[2] = ni->atom_index[0];
            ilni->atom_index[3] = ni->atom_index[1];
          } else if(ni->residue_index[0]==ilni->residue_index[1] && ni->residue_index[1]==ilni->residue_index[0]) {
            ilni->atom_index[2] = ni->atom_index[1];
            ilni->atom_index[3] = ni->atom_index[0];
          } else {
            if(!bv_count) PFatalError("Inconsistent data: (I->AtmNeighborInfo+ANindex)->residue_index do not agree with ilni->residue_index.\n");
          }
        } else {
          ilni->atomneighbor_index= -1;
          ilni->atom_index[2]     = -1;
          ilni->atom_index[3]     = -1;
        }
        indIonLigNeighbor++;
      }
    }
  }

/* Assign for SCOM (Structural Classification of Metal binding site) parameters */
  // 1. IA and IIA groups of metals (alkali and alkaline) are always octahedral crystal field
  // Plus, the lack of Jahn-Teller effect for IA and IIA makes it no chance to be square planar
  if(ai_ion->period>=2 && (ai_ion->group == ELEM_GROUP_IA || ai_ion->group == ELEM_GROUP_IIA)) {
    ibsi->which_geotype=1;
    if (ibsi->geometry_type == GEOM_SQUARE_PLANAR) {
      ibsi->geometry_type = GEOM_OCTAHEDRAL;
      ibsi->geometry_pseudo+=2; }
  // 2. assignment based on element preference
  } else if(ibsi->geometry_type == GEOM_UNDERFLOW || ibsi->geometry_type == GEOM_FREE) {
    if (ai_ion->group == ELEM_GROUP_IB || ai_ion->group == ELEM_GROUP_IIB) ibsi->which_geotype=0;
    else ibsi->which_geotype=1;
  // 3. default assignment for tetrahedral crystal field
  } else if(ibsi->geometry_type == GEOM_TRIANGLE || ibsi->geometry_type == GEOM_TETRAHEDRAL) ibsi->which_geotype=0;
  // 4. default assignment for octahedral crystal field
  else ibsi->which_geotype=1;
  // 5. indication of di-metal sites or metal cluster
  if(ibsi->num_metal_4a) {
    ibsi->which_geotype+=10;
    arr_atomid_cluster[0]=ai_ion->index;
    arr_atomid_cluster[1]=-1;
    ibsi->atomid_cluster=AtomInfoExploreCluster(I->AtomInfo,I->AtmNeighborInfo,arr_atomid_cluster);
    ibsi->homosize_cluster=0;
    for(i=0;arr_atomid_cluster[i]!=-1;i++) {
      ai=I->AtomInfo+arr_atomid_cluster[i];
      if(ai_ion->protons==ai->protons) ibsi->homosize_cluster++;
    }
    ibsi->size_cluster=i;
  } else ibsi->atomid_cluster=ibsi->atomid_ion;
  ibsi->which_ligtype+=10*(ibsi->n33_op_terminal+ibsi->n30_o_base       +ibsi->n27_n_base_ring  +ibsi->n29_n_base_amide +ibsi->n31_o_ribose)
                     +100*(ibsi->n10_o_carboxyl +ibsi->n13_n_histidine  +ibsi->n11_s_cysteine
                          +ibsi->n04_o_mc       +ibsi->n08_o_amide      +ibsi->n17_o_hydroxyl   +ibsi->n18_o_phenol);
  ibsi->which_XHCXX +=1000*ibsi->n13_n_histidine + 100*ibsi->n11_s_cysteine;
  ibsi->which_OOO    =100*ibsi->n08_o_amide    + 10*(ibsi->n17_o_hydroxyl+ibsi->n18_o_phenol) + ibsi->n04_o_mc;
  ibsi->which_BNR    =100*ibsi->n30_o_base     + 10*(ibsi->n27_n_base_ring+ibsi->n29_n_base_amide) + (ibsi->n31_o_ribose+ibsi->n32_op_bridge);
  qsort(tmpIonLigAtomNeighbor, numAtomNeighborFCS, sizeof(ObjIonLigAtomNeighborInfo), ObjIonLigAtomNeighborAngleCmp);
  ibsi->which_isoform=ObjIonLigFCSIsoform(tmpIonLigAtomNeighbor,numAtomNeighborFCS);
//printf("%d\n",ibsi->which_isoform);
  
//printf("bfactors: %f,%d\n",ibsi->valence_3a,ai_ion->oxidation_state);
  ibsi->quality_valence   = 1.0f-fabs(ibsi->valence_3a-ai_ion->oxidation_state)/ai_ion->oxidation_state;
  ibsi->quality_complete  = ibsi->valence_3a>V_SMALL ? (ibsi->valence_3a-ibsi->vecsum_3a)/ibsi->valence_3a : ibsi->valence_3a;
  if(ai_ion->occup>V_SMALL && ibsi->occupancy_env_avg>V_SMALL) {
    bfactor1=ai_ion->b/ai_ion->occup;
    bfactor2=ibsi->bfactor_env_avg/ibsi->occupancy_env_avg;
    lower_occup=(ai_ion->occup>ibsi->occupancy_env_avg) ? ibsi->occupancy_env_avg : ai_ion->occup; 
    if(bfactor1<0) bfactor1=-bfactor1;
    if(bfactor2<0) bfactor2=-bfactor2;
    if(bfactor1>bfactor2 && bfactor1>V_SMALL) {
      ibsi->quality_experiment=lower_occup*bfactor2/bfactor1;
    } else if(bfactor2>bfactor1 && bfactor2>V_SMALL) {
      ibsi->quality_experiment=lower_occup*bfactor1/bfactor2;
    } else if(bfactor1==bfactor2 && bfactor1>SMALL) {
      ibsi->quality_experiment=1.0f;
    } else {
      ibsi->quality_experiment=0.0f;
    }
  } else {
    ibsi->quality_experiment=ai_ion->occup*ibsi->occupancy_env_avg;
  }
//FreeP(listIndAtomFCS);
//FreeP(listProtonAtomFCS);
//FreeP(listDistAtomFCS);
  I->numIonLigResidue+=tmpIonLigResidueID2;     // local index
  I->numIonLigAtom+=numAtomFCS;                 // local index
  I->numIonLigNeighbor=indIonLigNeighbor;       // absolute index
  I->numIonLigAtomNeighbor+=numAtomNeighborFCS; // local index
}
/*---------------------------------------------------------------------------* 
 * Table for bidentate evaluation
 * Header: Site0: number of non-bidentate ligands
 *         Site2: number of bidentate ligand atoms
 *         Site1: number of bidentate ligand residues
 * Legend: Site0: Only use Site0 ligands for geometry calculation
 *         Site2: Only use Site2 ligands for geometry calculation
 *         Site1: Only use Site1 pseudo atoms for geometry calculation
 *         1-extra: 1 Site  out of N sites can be treated as either bidentate or non-bidentate
 *         4-extra: 4 Sites out of N sites can be treated as either bidentate or non-bidentate
        Site2   2       4       6       8       10      12      14      16
        Site1   1       2       3       4       5       6       7       8
 *Site0 under   Site2   Site2   3-extra 4-extra 3-extra 2-extra 1-extra Site1
 *    1 Site0   Site2   2-extra 3-extra 3-extra 2-extra 1-extra Site1
 *    2 Site0   1-extra 2-extra 3-extra 2-extra 1-extra Site1
 *    3 Site0   1-extra 2-extra 2-extra 1-extra Site1
 *    4 Site0   1-extra 2-extra 1-extra Site1
 *    5 Site0   1-extra 1-extra Site1                    O V E R
 *    6 Site0   1-extra Site1                            F L O W
 *    7 Site0   Site1
 *    8 Site0   
 *---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------*/
int  EntityMoleculeIonBindingSite(ObjEntityMolecule *I, int isWater) {
  int i, j, maxSites, maxILNeighbor, maxAtoms, maxResiduesSCS, tmpAtomCnt, lastAtomID;
  ObjIonBondValenceInfo *ibvi, *bv_info;
  ObjIonBindingSiteInfo *ibsi, *bs_info;
  int num_bv;
  if(isWater) {
    num_bv=I->numWaterBondValence;
    bv_info=I->WaterBondValenceInfo;
  } else {
    num_bv=I->numIonBondValence;
    bv_info=I->IonBondValenceInfo;
  }
// for(i=0;i<num_bv;i++) printf("nnn %d\n", (I->IonBondValenceInfo+i)->index);
  qsort(bv_info, num_bv, sizeof(ObjIonBondValenceInfo), ObjIonBondValenceIonAICmp);
  /* count number of sites for memory allocation */
  maxSites=0;
  I->numIonLigNeighbor=0;
  maxAtoms=0;
  tmpAtomCnt=-1;
  lastAtomID=-1;
  for (i=0;i<num_bv;i++) {
    ibvi=bv_info+i;
    if(ibvi->ai_ion->index==lastAtomID) {
      tmpAtomCnt++;
    } else {
      lastAtomID=ibvi->ai_ion->index;
      if(tmpAtomCnt>maxAtoms) maxAtoms=tmpAtomCnt;
      tmpAtomCnt=1;
      maxSites++;
    }
  }
  if(tmpAtomCnt>maxAtoms) maxAtoms=tmpAtomCnt; // maximal number of first coordination sphere atoms (residues)
  if(isWater) {
    AllocP(I->WaterBindingSiteInfo, ObjIonBindingSiteInfo, maxSites);
    bs_info=I->WaterBindingSiteInfo;
  } else {
    AllocP(I->IonBindingSiteInfo, ObjIonBindingSiteInfo, maxSites);
    bs_info=I->IonBindingSiteInfo;
    maxResiduesSCS=maxAtoms*6;    // maximal number of first and second coordination sphere residues
    AllocP(I->IonLigResidueInfo, ObjIonLigResidueInfo, maxSites*maxResiduesSCS);
    AllocP(I->IonLigMoietyInfo, ObjIonLigMoietyInfo, maxSites*maxResiduesSCS*3); // maximal 3 moieties per residue as in nucleotide
    AllocP(I->IonLigAtomInfo, ObjIonLigAtomInfo, maxSites*maxAtoms);
    AllocP(I->IonLigNeighborInfo, ObjIonLigNeighborInfo, maxSites*maxResiduesSCS*maxAtoms);
    AllocP(I->IonLigAtomNeighborInfo, ObjIonLigAtomNeighborInfo, maxSites*maxAtoms*maxAtoms);
  }
  /* site info assignment */
  tmpAtomCnt=-1;
  lastAtomID=-1;
  maxSites=0;
  for (i=0;i<num_bv;i++) {
    ibvi=bv_info+i;
    if(ibvi->ai_ion->index==lastAtomID) {
      tmpAtomCnt++;
    } else {
      lastAtomID=ibvi->ai_ion->index;
      /* I->numIonLigResidue, I->numIonLigAtomInfo and I->IonLigAtomNeighborInfo are assigned within the ObjIonBindingSite procedure via I */
//printf("bbb %d,%d\n",i,num_bv);
      if(tmpAtomCnt>0) ObjIonBindingSite(I, ibsi, ibvi-tmpAtomCnt, tmpAtomCnt, isWater);
      tmpAtomCnt=1;
      ibsi=bs_info+maxSites;
      ibsi->index=maxSites;
      maxSites++;
    }
  }
  if(tmpAtomCnt>0) ObjIonBindingSite(I, ibsi, ibvi+1-tmpAtomCnt, tmpAtomCnt, isWater);
  if(isWater) I->numWaterBindingSite=maxSites;
  else I->numIonBindingSite=maxSites;
  return maxSites;
}

/*---------------------------------------------------------------------------*/
void EntityMoleculeReport(ObjEntityMolecule *I, float cutoff, char *temp_dir) {
  ObjGeneOntologyInfo*goi;
  ObjAssemblyInfo    *assi;
  ObjCavityInfo      *cavi;
  ObjComponentInfo   *comi;     
  ObjFunctionInfo    *funi;     
  ObjKeywordInfo     *keyi;     
  ObjSymChainInfo    *symi;
  ObjMoleculeInfo    *mi;
  ObjDomainInfo      *di;
  ObjChainInfo       *ci;
  ObjResidueInfo     *ri, *ri1, *ri2;
  ObjAtomInfo        *ai, *ai1, *ai2, *ai3;
  ObjNeighborInfo    *ani, *rni;
  ObjMolprobityInfo  *mpi;
  ObjNeighborVectorInfo     *vni;
  ObjIonBondValenceInfo     *ibvi;
  ObjIonBindingSiteInfo     *ibsi;
  ObjIonLigResidueInfo      *ilri;
  ObjIonLigMoietyInfo       *ilmi;
  ObjIonLigAtomInfo         *ilai;
  ObjIonLigNeighborInfo     *ilni;
  ObjIonLigAtomNeighborInfo *ilani;
  char               bond_type;
  float              *coord;
  int i,j,numGO=0,numCavity=0,numFunction=0,numSymChain=0,output_redirected=0,numBondValence=0,numNeighbor=0,numIonBindingSite=0;
  EntityFileName temp_pdbfile_path,     temp_ccdinfo_path,        temp_geneontology_path,     temp_assembly_path;
  EntityFileName temp_cavity_path,      temp_component_path,      temp_function_path,         temp_keyword_path;
  EntityFileName temp_cdchain_path,     temp_symchain_path,       temp_molecule_path,         temp_domain_path;
  EntityFileName temp_residue_path,     temp_atom_path,           temp_neighbor_path,         temp_atomneighbor_path;
  EntityFileName temp_molprobity_path,  temp_peptidebond_path,    temp_nucleotidebond_path,   temp_neighborvector_path;
  EntityFileName temp_ligbondangle_path,temp_ion_bondvalence_path,temp_water_bondvalence_path,temp_ion_bindingsite_path;
  EntityFileName temp_ibs_profile_path, temp_ibs_ligresidue_path, temp_ibs_ligmoiety_path,    temp_ibs_ligatom_path;
  EntityFileName temp_ibs_ligneighbor_path,          temp_ibs_ligatomneighbor_path,           temp_water_bindingsite_path;
  EntityFileName sql_copydata_path, crystal_contact_pdbfile;
  FILE *fout = stdout;
  FILE *fout_pept, *fout_nucl;
  if (strlen(temp_dir) > 0) {
    strcpy(temp_pdbfile_path,            temp_dir); strcat(temp_pdbfile_path,            "PDBFILE.data");
    strcpy(temp_ccdinfo_path,            temp_dir); strcat(temp_ccdinfo_path,            "CCDINFO.data");
    strcpy(temp_geneontology_path,       temp_dir); strcat(temp_geneontology_path,       "GENEONTOLOGY.data");
    strcpy(temp_assembly_path,           temp_dir); strcat(temp_assembly_path,           "ASSEMBLY.data");
    strcpy(temp_cavity_path,             temp_dir); strcat(temp_cavity_path,             "CAVITY.data");
    strcpy(temp_component_path,          temp_dir); strcat(temp_component_path,          "COMPONENT.data");
    strcpy(temp_function_path,           temp_dir); strcat(temp_function_path,           "FUNCTION.data");
    strcpy(temp_keyword_path,            temp_dir); strcat(temp_keyword_path,            "KEYWORD.data");
    strcpy(temp_cdchain_path,            temp_dir); strcat(temp_cdchain_path,            "CDHIT_CHAIN.data");
    strcpy(temp_symchain_path,           temp_dir); strcat(temp_symchain_path,           "SYMOP_CHAIN.data");
    strcpy(temp_molecule_path,           temp_dir); strcat(temp_molecule_path,           "MOLECULE.data");
    strcpy(temp_domain_path,             temp_dir); strcat(temp_domain_path,             "DOMAIN.data");
    strcpy(temp_residue_path,            temp_dir); strcat(temp_residue_path,            "RESIDUE.data");
    strcpy(temp_atom_path,               temp_dir); strcat(temp_atom_path,               "ATOM.data");
    strcpy(temp_neighbor_path,           temp_dir); strcat(temp_neighbor_path,           "NEIGHBOR.data");
    strcpy(temp_atomneighbor_path,       temp_dir); strcat(temp_atomneighbor_path,       "ATOMNEIGHBOR.data");
    strcpy(temp_molprobity_path,         temp_dir); strcat(temp_molprobity_path,         "MOLPROBITY.data");
    strcpy(temp_peptidebond_path,        temp_dir); strcat(temp_peptidebond_path,        "PEPTIDEBOND.data");
    strcpy(temp_nucleotidebond_path,     temp_dir); strcat(temp_nucleotidebond_path,     "NUCLEOTIDEBOND.data");
    strcpy(temp_neighborvector_path,     temp_dir); strcat(temp_neighborvector_path,     "NEIGHBORVECTOR.data");
    strcpy(temp_ligbondangle_path,       temp_dir); strcat(temp_ligbondangle_path,       "LIGAND_BONDANGLE.data");
    strcpy(temp_ion_bondvalence_path,    temp_dir); strcat(temp_ion_bondvalence_path,    "ION_BONDVALENCE.data");
    strcpy(temp_water_bondvalence_path,  temp_dir); strcat(temp_water_bondvalence_path,  "WATER_BONDVALENCE.data");
    strcpy(temp_ion_bindingsite_path,    temp_dir); strcat(temp_ion_bindingsite_path,    "ION_BINDINGSITE.data");
    strcpy(temp_ibs_profile_path,        temp_dir); strcat(temp_ibs_profile_path,        "ION_BINDINGSITE_PROFILE.data");
    strcpy(temp_ibs_ligresidue_path,     temp_dir); strcat(temp_ibs_ligresidue_path,     "ION_BINDINGSITE_LIGRESIDUE.data");
    strcpy(temp_ibs_ligmoiety_path,      temp_dir); strcat(temp_ibs_ligmoiety_path,      "ION_BINDINGSITE_LIGMOIETY.data");
    strcpy(temp_ibs_ligatom_path,        temp_dir); strcat(temp_ibs_ligatom_path,        "ION_BINDINGSITE_LIGATOM.data");
    strcpy(temp_ibs_ligneighbor_path,    temp_dir); strcat(temp_ibs_ligneighbor_path,    "ION_BINDINGSITE_LIGNEIGHBOR.data");
    strcpy(temp_ibs_ligatomneighbor_path,temp_dir); strcat(temp_ibs_ligatomneighbor_path,"ION_BINDINGSITE_LIGATOMNEIGHBOR.data");
    strcpy(temp_water_bindingsite_path,  temp_dir); strcat(temp_water_bindingsite_path,  "WATER_BINDINGSITE.data");
    strcpy(sql_copydata_path,            temp_dir); strcat(sql_copydata_path,            "copyNeighborhoodData.sql");
    strcpy(crystal_contact_pdbfile,      temp_dir); strcat(crystal_contact_pdbfile,      "contact.pdb");
    output_redirected=1;
  }

  if(strlen(contact_pdb_buffer_str)>0) {
    fout=fopen(crystal_contact_pdbfile,"w");
    fprintf(fout, "%s", contact_pdb_buffer_str);
    fclose(fout);
  }
/* BEGIN TEMP TABLE TURN OFF */
// I->tables[TABLE_NEIGHBORVECTORS]=0;
// I->tables[TABLE_WATER_BONDVALENCES]=0;
// I->tables[TABLE_WATER_BINDINGSITES]=0;
/* END */

  /* For TABLE ccdinfo, 14 fields */
  if(I->tables[TABLE_CCDINFO]) {
   printf("#CCDINFO(%d):%s\n", I->pdbfileid, I->filename);
   if (output_redirected) fout=fopen(temp_ccdinfo_path,"w");
   fprintf(fout, "%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d\n",    I->pdbfileid,
       I->organism_id,  I->ec_primary,    I->ec_3rd_level, I->ec_4th_level, I->ec_complex,
       I->cluster50_id, I->cluster90_id,  I->go_process,   I->go_function,  I->go_component, 
       I->cath_primary, I->cath_topology, I->cath_superfamily);
   if (output_redirected) fclose(fout);
  }
  
  /* For TABLE geneontologies, 14 fields */
  if(I->tables[TABLE_GENEONTOLOGIES]) {
   if (output_redirected) fout=fopen(temp_geneontology_path,"w");
   for (i=0; i<I->numChain; i++) {
     ci=I->ChainInfo+i;
     for (j=0; j<ci->numBiolProcess; j++) {
       goi=ci->BiolProcessInfo+j; numGO++;
       fprintf(fout, "%d|%s|%c|%c|%d|%d|%s|%s|%s|%d|%s|%s|%c|%d\n", I->pdbfileid, I->pdbid,
           ci->chainid,        goi->go_type,      goi->go_id,       goi->qualifier,
           goi->evidence,      goi->xref_db_name, goi->xref_db_id,  goi->organism_id,
           goi->creation_date, goi->created_by,   goi->ref_db_name, goi->ref_db_id);
     }
     for (j=0; j<ci->numMoleFunction; j++) {
       goi=ci->MoleFunctionInfo+j; numGO++;
       fprintf(fout, "%d|%s|%c|%c|%d|%d|%s|%s|%s|%d|%s|%s|%c|%d\n", I->pdbfileid, I->pdbid,
           ci->chainid,        goi->go_type,      goi->go_id,       goi->qualifier,
           goi->evidence,      goi->xref_db_name, goi->xref_db_id,  goi->organism_id,
           goi->creation_date, goi->created_by,   goi->ref_db_name, goi->ref_db_id);
     }
     for (j=0; j<ci->numCellComponent; j++) {
       goi=ci->CellComponentInfo+j; numGO++;
       fprintf(fout, "%d|%s|%c|%c|%d|%d|%s|%s|%s|%d|%s|%s|%c|%d\n", I->pdbfileid, I->pdbid,
           ci->chainid,        goi->go_type,      goi->go_id,       goi->qualifier,
           goi->evidence,      goi->xref_db_name, goi->xref_db_id,  goi->organism_id,
           goi->creation_date, goi->created_by,   goi->ref_db_name, goi->ref_db_id);
     }
   }
   if (output_redirected) fclose(fout);
   printf("#GENEONTOLOGY:%d\n", numGO);
  }
  
  /* For TABLE assemblies, 20 fields */
  if(I->tables[TABLE_ASSEMBLIES]) {
   printf("#ASSEMBLY:%d\n", I->numAssembly);
   if (output_redirected) fout=fopen(temp_assembly_path,"w");
   for (i=0; i<I->numAssembly; i++) {
     assi=I->AssemblyInfo+i;
     numCavity+=assi->numCavity;
     numSymChain+=assi->numSymChain;
     fprintf(fout, "%d|%d|%d|%03d|%d|%d|%d|%d|%f|%f|%f|%f|%f|%f|%f|%f|%f|%f|%f|%f\n",
         I->pdbfileid,           assi->index,            assi->assembly_number,  assi->type,
         assi->numChain,         assi->numSymChain,      assi->numCavity,        assi->numSurfraceAtom,
         assi->total_asa,        assi->polar_asa,        assi->positive_asa,
         assi->negative_asa,     assi->total_bb_asa,     assi->polar_bb_asa,
         assi->total_msa,        assi->polar_msa,        assi->positive_msa,
         assi->negative_msa,     assi->total_bb_msa,     assi->polar_bb_msa);
   }
   if (output_redirected) fclose(fout);
  }
  
  /* For TABLE cavities, 6 fields */
  if(I->tables[TABLE_CAVITIES]) {
   printf("#CAVITY:%d\n", numCavity);
   if (output_redirected) fout=fopen(temp_cavity_path,"w");
   for (i=0; i<I->numAssembly; i++) {
     assi=I->AssemblyInfo+i;
     for (j=0; j<assi->numCavity; j++) {
       cavi=assi->CavityInfo+j;
       fprintf(fout, "%d|%d|%d|%d|%d|%d\n", I->pdbfileid,
         cavi->index, cavi->numResidue, cavi->numAtom, cavi->volume, cavi->assembly_index);
     }
   }
   if (output_redirected) fclose(fout);
  }
  
  /* For TABLE components, 11 fields */
  if(I->tables[TABLE_COMPONENTS]) {
   printf("#COMPONENT:%d\n", I->numComponent);
   if (output_redirected) fout=fopen(temp_component_path,"w");
   for (i=0; i<I->numComponent; i++) {
     comi=I->ComponentInfo+i;
     numFunction+=comi->numFunction;
     fprintf(fout, "%d|%d|%d|%s|%d|%d|%d|%d|%d|%d|%d|%s|%d|%s\n", I->pdbfileid,
       comi->index,        comi->componentnum,  comi->component_name,
       comi->numChain,     comi->numKeyword,    comi->numFunction,
       comi->engineered,   comi->mutation,      comi->synthetic,
       comi->organism_id,  comi->organism_name, comi->expression_id, comi->expression_name);
   }
   if (output_redirected) fclose(fout);
  }
  
  /* For TABLE functions, 6 fields */
  if(I->tables[TABLE_FUNCTIONS]) {
   printf("#FUNCTION:%d\n", numFunction);
   if (output_redirected) fout=fopen(temp_function_path,"w");
   for (i=0; i<I->numComponent; i++) {
     comi=I->ComponentInfo+i;
     for (j=0; j<comi->numFunction; j++) {
       funi=comi->FunctionInfo+j;
       fprintf(fout, "%d|%d|%d|%d|%d|%d\n", I->pdbfileid,       comi->index,
         funi->index,    funi->ec_primary,  funi->ec_3rd_level, funi->ec_4th_level);
     }
   }
   if (output_redirected) fclose(fout);
  }
  
  /* For TABLE keywords, 4 fields */
  if(I->tables[TABLE_KEYWORDS]) {
   printf("#KEYWORD:%d\n", I->numKeyword);
   if (output_redirected) fout=fopen(temp_keyword_path,"w");
   for (i=0; i<I->numKeyword; i++) {
     keyi=I->KeywordInfo+i;
     if(keyi->ComponentInfo==NULL) j=-1;
     else j=keyi->ComponentInfo->index;
     fprintf(fout, "%d|%d|%d|%s\n", I->pdbfileid, j, keyi->index, keyi->keyword);
   }
   if (output_redirected) fclose(fout);
  }
  
  
  /* For TABLE cdhit_chains, 22 fields */
  if(I->tables[TABLE_CDHIT_CHAINS]) {
   printf("#CDHIT_CHAIN:%d\n", I->numChain);
   if (output_redirected) fout=fopen(temp_cdchain_path,"w");
   for (i=0; i<I->numChain; i++) {
     ci=I->ChainInfo+i;
     fprintf(fout, "%d|%s|%c|%d|%04d|%03d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d\n",
       I->pdbfileid,        I->pdbid,           ci->chainid,         ci->assembly_index, ci->type2,
       ci->clusterstatus,   ci->cluster50_id,   ci->represent50_id,  ci->cluster90_id,   ci->represent90_id,
       ci->numGeneOntology, ci->numBiolProcess, ci->numMoleFunction, ci->numCellComponent,
       ci->numMolecule,     ci->numDomain,      ci->numFragment,     ci->numResidue,
       ci->numWaterRes,     ci->numLigandRes,   ci->numDnarnaRes,    ci->numProteinRes);
   }
   if (output_redirected) fclose(fout);
  }
  
  /* For TABLE symop_chains, 7 fields */
  if(I->tables[TABLE_SYMOP_CHAINS]) {
   printf("#SYMOP_CHAIN:%d\n", numSymChain);
   if (output_redirected) fout=fopen(temp_symchain_path,"w");
   numSymChain=0;
   for (i=0; i<I->numAssembly; i++) {
     assi=I->AssemblyInfo+i;
     for (j=0; j<assi->numSymChain; j++) {
       symi=assi->SymChainInfo+j;
       fprintf(fout, "%d|%d|%s|%d|%c|%c|%d\n", I->pdbfileid, numSymChain, I->pdbid,
           symi->model_number, symi->cdhit_chainid, symi->symop_chainid, symi->assembly_index);
       numSymChain++;
     }
   }
   if (output_redirected) fclose(fout);
  }
  
  /* For TABLE molecules, 6 fields */
  if(I->tables[TABLE_MOLECULES]) {
   printf("#MOLECULE:%d\n", I->numMolecule);
   if (output_redirected) fout=fopen(temp_molecule_path,"w");
   for (i=0; i<I->numMolecule; i++) {
     mi=I->MoleculeInfo+i;
     fprintf(fout, "%d|%d|%02d|%c|%d|%d\n",
       I->pdbfileid, mi->index, mi->type, mi->chain, mi->numResidue, mi->assembly_index);
   }
   if (output_redirected) fclose(fout);
  }
   
  /* For TABLE domains, 17 fields */
  if(I->tables[TABLE_DOMAINS]) {
   printf("#DOMAIN:%d\n", I->numDomain);
   if (output_redirected) fout=fopen(temp_domain_path,"w");
   for (i=0; i<I->numDomain; i++) {
     di=I->DomainInfo+i;
     fprintf(fout, "%d|%s|%d|%c|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d\n",    I->pdbfileid,
       I->pdbid,        di->index,     di->chain,        di->residueid_begin, di->residueid_end,
       di->is_fragment, di->domainnum, di->cath_primary, di->cath_topology,   di->cath_superfamily,
       di->cath_s35, di->cath_s60, di->cath_s95, di->cath_s100, di->cath_uniqueid, di->numResidue);
   }
   if (output_redirected) fclose(fout);
  }
  
  /* For TABLE residues, 20 fields */
  if(I->tables[TABLE_RESIDUES]) {
   printf("#RESIDUE:%d\n", I->numResidue);
   if (output_redirected) fout=fopen(temp_residue_path,"w");
   for (i=0; i<I->numResidue; i++) {
     ri=I->ResidueInfo+i;
     fprintf(fout, "%d|%d|%d|%s|%c|%d|%d|", I->pdbfileid, ri->index,
             ri->type, ri->resn, ri->chain, ri->resid,    ri->numAtom);
     if(ri->containsMetal>=0) fprintf(fout,"%d",ri->containsMetal);     // boolean value in database, empty implies NULL
     fprintf(fout, "|%03d|%f|%f|%f|%f|%d|%d|%d|%d|%d|%d|%d|%d\n", ri->location,    ri->center_displacement,
       ri->asa,          ri->msa,            ri->curvature,    ri->assembly_index, ri->cavity_index,
       ri->domain_index, ri->molecule_index, ri->prev_index,   ri->next_index,     ri->branch_index,    ri->branch2_index);
   }
   if (output_redirected) fclose(fout);
  }
  
  /* For TABLE atoms, 20 fields */
  if(I->tables[TABLE_ATOMS]) {
   printf("#ATOM:%d\n", I->numAtom);
   if (output_redirected) fout=fopen(temp_atom_path,"w");
   for (i=0; i<I->numAtom; i++) {
     ai=I->AtomInfo+i;
     fprintf(fout, "%d|%d|%d|%d|%d|%s|%s|%d|%d|%c|%f|%f|%f|%f|%03d|%f|%f|%f|%f|%d|%d\n",
         I->pdbfileid, ai->residue_index, ai->index,     ai->moiety_type,  ai->type,        ai->realname, ai->elem, ai->protons,
         ai->id,       ai->alt,           ai->occup,     ai->b, ai->q,     ai->sigma_2fofc, ai->location, ai->center_displacement,
         ai->asa,      ai->msa,           ai->curvature, ai->cavity_index, ai->ResidueInfo->molecule_index);
   }
   if (output_redirected) fclose(fout);
  }
  
  /* For TABLE neighbors, 22 fields */
  if(I->tables[TABLE_NEIGHBORS]) {
   if (output_redirected) fout=fopen(temp_neighbor_path,"w");
   numNeighbor=EntityMoleculeNeighborPrint(fout, I, 0, NULL, NULL);
   if (output_redirected) fclose(fout);
   printf("#RESIDUE_NEIGHBOR:%d\n", numNeighbor);
  }
  
  /* For TABLE atomneighbors, 22 fields */
  if(I->tables[TABLE_ATOMNEIGHBORS]) {
   if (output_redirected) fout=fopen(temp_atomneighbor_path,"w");
   if(I->tables[TABLE_PEPTIDEBONDS]) fout_pept = (output_redirected) ? fopen(temp_peptidebond_path,"w") : stdout;
   else fout_pept = NULL;
   if(I->tables[TABLE_NUCLEOTIDEBONDS]) fout_nucl = (output_redirected) ? fopen(temp_nucleotidebond_path,"w") : stdout;
   else fout_nucl = NULL;
   numNeighbor=EntityMoleculeNeighborPrint(fout, I, 1, fout_pept, fout_nucl);
   if (output_redirected) { fclose(fout);
     if (fout_pept) fclose(fout_pept);
     if (fout_nucl) fclose(fout_nucl);
   }
   printf("#ATOM_NEIGHBOR:%d\n", numNeighbor);
  }
  
  /* For TABLE molprobities, 13 fields */
  if(I->tables[TABLE_MOLPROBITIES]) {
   printf("#MOLPROBITY:%d\n", I->numMolprobity);
   if (output_redirected) fout=fopen(temp_molprobity_path,"w");
   for (i=0; i<I->numMolprobity; i++) {
     mpi=I->MolprobityInfo+i;
     fprintf(fout, "%d|%d|%d|%s|%s|%c|%d|%d|%f|%f|%f|%f\n", I->pdbfileid, mpi->index, mpi->neighbor_index,
         mpi->name_a, mpi->name_b, mpi->bond_type, mpi->num_dots,
         (mpi->num_dots_fwd>mpi->num_dots_rev) ? (mpi->num_dots_fwd-mpi->num_dots_rev) : (mpi->num_dots_rev>mpi->num_dots_fwd),
         mpi->score, mpi->mingap, mpi->gap, mpi->spike_len);
   }
   if (output_redirected) fclose(fout);
  }

  /* For TABLE neighborvectors, 7 fields */
  if(I->tables[TABLE_NEIGHBORVECTORS]) {
   printf("#NEIGHBOR_VECTOR:%d\n", I->numNeighborVector);
   if (output_redirected) fout=fopen(temp_neighborvector_path,"w");
   for (i=0; i<I->numNeighborVector; i++) {
     vni=I->NeighborVectorInfo+i;
     fprintf(fout, "%d|%d|%d|%d|%f|%f|%f\n", I->pdbfileid, vni->index,
         vni->icell, vni->isym, vni->direction[0], vni->direction[1], vni->direction[2]);
   }
   if (output_redirected) fclose(fout);
  }
  
  /* For TABLE ligand_bondangles, 22 fields */
  if(I->tables[TABLE_LIGAND_BONDANGLES]) {
   printf("#LIGAND_BONDANGLE:%d\n", I->numAngle);
   if (output_redirected) fout=fopen(temp_ligbondangle_path,"w");
   EntityMoleculeAnglePrint(fout, I);
   if (output_redirected) fclose(fout);
  }
  
  if(I->tables[TABLE_ION_BINDINGSITES]) {
//  if (output_redirected) fout=fopen(temp_ion_bindingsite_path,"w");
//  numIonBindingSite=EntityMoleculeIonBindingSitePrint(fout, I);
//  if (output_redirected) fclose(fout);
//  I->numIonBindingSite=numIonBindingSite;

  /* For TABLE ion_bindingsite_path, 42 fields */
    printf("#ION_BINDINGSITE:%d\n", I->numIonBindingSite);
    if (output_redirected) fout=fopen(temp_ion_bindingsite_path,"w");
    for (i=0; i<I->numIonBindingSite; i++) {
      ibsi=I->IonBindingSiteInfo+i;
      ri=I->ResidueInfo+ibsi->residueid_ion;
      ai=I->AtomInfo+ibsi->atomid_ion;
                   /* 1  2  3  4  5  6  7  8  9 10 11 12  1  2  3  4  5  6  7  8  9 10 11  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16*/
      fprintf(fout, "%d|%d|%d|%s|%d|%s|%d|%d|%f|%f|%f|%f|%d|%d|%d|%d|%d|%d|%f|%d|%f|%f|%f|%f|%f|%d|%d|%f|%f|%f|%f|%f|%f|%f|%f|%f|%f|%f|%f\n",
        I->pdbfileid, ibsi->index, ri->index, ri->resn,  ai->index, ai->realname, ai->protons,
        ai->oxidation_state,     ai->b,      ibsi->bfactor_env_avg, ai->occup,    ibsi->occupancy_env_avg,
        ibsi->coord_number_3a,   ibsi->coord_number_geom,ibsi->geometry_type,     ibsi->geometry_bidentate,
        ibsi->geometry_pseudo,   ibsi->geometry_distort, ibsi->rmsd_geom_angle,   ibsi->num_bidentate_all, 
        ibsi->distance_avg,      ibsi->distance_min,     ibsi->distance_max,
        ibsi->valence_3a,        ibsi->vecsum_3a,        ibsi->coord_number_4a,   ibsi->num_metal_4a,
        ibsi->valence_4a,        ibsi->vecsum_4a,        ibsi->bvs_sodium,        ibsi->bvs_magnesium,
        ibsi->bvs_potassium,     ibsi->bvs_calcium,      ibsi->bvs_manganese,     ibsi->bvs_iron,
        ibsi->bvs_cobalt,        ibsi->bvs_nickel,       ibsi->bvs_copper,        ibsi->bvs_zinc);
    }
    if (output_redirected) fclose(fout);
  /* For TABLE ion_bindingsite_profile_path, 48 fields */
    if(I->tables[TABLE_ION_BINDINGSITE_PROFILES]) {
      printf("#ION_BINDINGSITE_PROFILES:%d\n", I->numIonBindingSite);
      if (output_redirected) fout=fopen(temp_ibs_profile_path,"w");
      for (i=0; i<I->numIonBindingSite; i++) {
        ibsi=I->IonBindingSiteInfo+i;
        ai=I->AtomInfo+ibsi->atomid_ion;
                     /* 1  2  3  4  5  6  7  8    9 10 11 12 13 14 15 16 17*/
        fprintf(fout, "%d|%d|%d|%d|%d|%d|%d|%d|%02d|%d|%d|%d|%d|%d|%d|%d|%d|", I->pdbfileid,  ibsi->index,
          ibsi->residueid_ion, ibsi->atomid_ion,    ibsi->atomid_cluster, ibsi->size_cluster, ibsi->homosize_cluster,
          ai->protons,         ibsi->which_geotype, ibsi->which_ligtype,  ibsi->which_XHCXX,  ibsi->which_OOO,
          ibsi->which_wOOO2,   ibsi->which_PPP,     ibsi->which_BNR,      ibsi->which_wBNR2,  ibsi->which_mBRP2);
        if(ibsi->which_isoform>=0) fprintf(fout,"%d",ibsi->which_isoform);     // boolean value in database, empty implies NULL
                      /* 1  2  3  4  5  6  7  8  9 10  1  2  3  4  5  6  7  8  9 20  1  2  3  4  5  6  7  8  9 30  1  2  3  4  5  6 */
        fprintf(fout, "|%d|%f|%f|%f|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d\n", ibsi->which_mobile,
          ibsi->quality_valence, ibsi->quality_complete,ibsi->quality_experiment,ibsi->num_oxygen,      ibsi->num_nitrogen,
          ibsi->num_sulfur,      ibsi->num_phosphorus,  ibsi->num_carbon,        ibsi->num_others,      ibsi->n04_o_mc,
          ibsi->n08_o_amide,     ibsi->n10_o_carboxyl,  ibsi->n17_o_hydroxyl,    ibsi->n18_o_phenol,    ibsi->n30_o_base,
          ibsi->n31_o_ribose,    ibsi->n32_op_bridge,   ibsi->n33_op_terminal,   ibsi->n39_o_water,     ibsi->n43_o_others,
          ibsi->n01_n_mc,        ibsi->n07_n_arginine,  ibsi->n09_n_amide,       ibsi->n13_n_histidine, ibsi->n14_n_lysine,
          ibsi->n15_n_tryptophan,ibsi->n27_n_base_ring, ibsi->n28_n_base_ribose, ibsi->n29_n_base_amide,ibsi->n42_n_others,
          ibsi->n11_s_cysteine,  ibsi->n16_s_methionine,ibsi->n45_s_others,      ibsi->n19_selenium,    ibsi->n53_others);
      }
      if (output_redirected) fclose(fout);
  /* For TABLE ion_bindingsite_ligresidue_path, 9 fields */
      if(I->tables[TABLE_ION_BINDINGSITE_LIGRESIDUES]) {
        printf("#ION_BINDINGSITE_LIGRESIDUES:%d\n", I->numIonLigResidue);
        if (output_redirected) fout=fopen(temp_ibs_ligresidue_path,"w");
        for (i=0; i<I->numIonLigResidue; i++) {
          ilri=I->IonLigResidueInfo+i;
          ri=I->ResidueInfo+ilri->residue_index;
          fprintf(fout, "%d|%d|%d|%d|%d|%d|%d|%s|%c|%d|%d|%s|%f|%d|%s|%f\n", I->pdbfileid, ilri->bindingsite_index,
            ilri->type, ilri->priority, ri->type, (ilri->atom_index[0]<0) ? ATOM_UNDEF : (I->AtomInfo+ilri->atom_index[0])->type,
            ri->index, ri->resn, ri->chain, ri->resid,
            ilri->atom_index[0], (ilri->atom_index[0]<0) ? "" : (I->AtomInfo+ilri->atom_index[0])->realname, ilri->distance[0],
            ilri->atom_index[1], (ilri->atom_index[1]<0) ? "" : (I->AtomInfo+ilri->atom_index[1])->realname, ilri->distance[1]);
        }
        if (output_redirected) fclose(fout);
      }
  /* For TABLE ion_bindingsite_ligmoiety_path, 11 fields */
      if(I->tables[TABLE_ION_BINDINGSITE_LIGMOIETIES]) {
        printf("#ION_BINDINGSITE_LIGMOIETIES:%d\n", I->numIonLigMoiety);
        if (output_redirected) fout=fopen(temp_ibs_ligmoiety_path,"w");
        for (i=0; i<I->numIonLigMoiety; i++) {
          ilmi=I->IonLigMoietyInfo+i;
          ri=I->ResidueInfo+ilmi->residue_index;
//        if(ilmi->valid)
          fprintf(fout, "%d|%d|%d|%d|%d|%d|%s|%c|%d|%d|%d\n", I->pdbfileid, ilmi->bindingsite_index,
            ilmi->type, ilmi->moiety_type, ri->type, ri->index, ri->resn, ri->chain, ri->resid,
            ilmi->num_inner_links, ilmi->num_outer_links);
        }
        if (output_redirected) fclose(fout);
      }
  /* For TABLE ion_bindingsite_ligatom_path, 17 fields */
      if(I->tables[TABLE_ION_BINDINGSITE_LIGATOMS]) {
        printf("#ION_BINDINGSITE_LIGATOMS:%d\n", I->numIonLigAtom);
        if (output_redirected) fout=fopen(temp_ibs_ligatom_path,"w");
        for (i=0; i<I->numIonLigAtom; i++) {
          ilai=I->IonLigAtomInfo+i;
          ri=I->ResidueInfo+ilai->IonLigResidueInfo->residue_index;
          ai=I->AtomInfo+ilai->atom_index;
          fprintf(fout, "%d|%d|%d|%d|%d|%s|%c|%d|%d|%s|%f|%f\n",   I->pdbfileid,   ilai->bindingsite_index,
            ilai->priority,     ai->type,       ri->index,      ri->resn,       ri->chain,
            ri->resid,          ai->index,      ai->realname,   ilai->distance, ilai->bondvalence);
        }
        if (output_redirected) fclose(fout);
      }
  /* For TABLE ion_bindingsite_ligneighbor_path, 20 fields */
      if(I->tables[TABLE_ION_BINDINGSITE_LIGNEIGHBORS]) {
        printf("#ION_BINDINGSITE_LIGNEIGHBORS:%d\n", I->numIonLigNeighbor);
        if (output_redirected) fout=fopen(temp_ibs_ligneighbor_path,"w");
        for (i=0; i<I->numIonLigNeighbor; i++) {
          ilni=I->IonLigNeighborInfo+i;
          ri  =I->ResidueInfo     +ilni->residue_index[0];
          ri1 =I->ResidueInfo     +ilni->residue_index[1];
          if(ilni->atomneighbor_index>=0) {
            ani=I->AtmNeighborInfo+ilni->atomneighbor_index;
            bond_type=ani->bond_type;
          } else bond_type=' ';
          fprintf(fout, "%d|%d|%d|%d|%d|%s|%s|", I->pdbfileid, ilni->bindingsite_index,
            ilni->type,    ri->index,  ri1->index, ri->resn,      ri1->resn);
          //if(ilni->dresseq>=0)
          fprintf(fout, "%d", ilni->dresseq);
          fprintf(fout, "|%d|%d|", ilni->atom_index[0], ilni->atom_index[1]);
          if(ilni->atom_index[0]>=0) { ai =I->AtomInfo+ilni->atom_index[0]; fprintf(fout, "%s|", ai->realname); } else fprintf(fout, "----|");
          if(ilni->atom_index[1]>=0) { ai =I->AtomInfo+ilni->atom_index[1]; fprintf(fout, "%s|", ai->realname); } else fprintf(fout, "----|");
          fprintf(fout, "%c|%d|%d|", bond_type, ilni->atom_index[2], ilni->atom_index[3]);
          if(ilni->atom_index[2]>=0) { ai =I->AtomInfo+ilni->atom_index[2]; fprintf(fout, "%s|", ai->realname); } else fprintf(fout, "----|");
          if(ilni->atom_index[3]>=0) { ai =I->AtomInfo+ilni->atom_index[3]; fprintf(fout, "%s|", ai->realname); } else fprintf(fout, "----|");
          fprintf(fout, "%d|%d|%d|", ilni->neighbor_index, ilni->atomneighbor_index,
                                     ri->type>ri1->type ? ri1->type*100+ri->type : ri->type*100+ri1->type);
          if(ilni->atom_index[2]>=0 && ilni->atom_index[3]>=0) {
            ai2 =I->AtomInfo +ilni->atom_index[2];
            ai3 =I->AtomInfo +ilni->atom_index[3];
            fprintf(fout, "%d\n", ai2->type>ai3->type ? ai3->type*100+ai2->type : ai2->type*100+ai3->type);
          } else fprintf(fout, "%d\n", -1);
        }
        if (output_redirected) fclose(fout);
      }
  /* For TABLE ion_bindingsite_ligatomneighbor_path, 10 fields */
      if(I->tables[TABLE_ION_BINDINGSITE_LIGATOMNEIGHBORS]) {
        printf("#ION_BINDINGSITE_LIGATOMNEIGHBORS:%d\n", I->numIonLigAtomNeighbor);
        if (output_redirected) fout=fopen(temp_ibs_ligatomneighbor_path,"w");
        for (i=0; i<I->numIonLigAtomNeighbor; i++) {
          ilani=I->IonLigAtomNeighborInfo+i;
          fprintf(fout, "%d|%d|%d|%f|%f|%d|%d|%d|%d|%d\n", I->pdbfileid, ilani->bindingsite_index,
            ilani->priority_type, ilani->angle, ilani->bvproduct_cos_angle, ilani->dresseq,
            ilani->atom_index[0], ilani->atom_index[1], ilani->residue_index[0], ilani->residue_index[1]);
        }
        if (output_redirected) fclose(fout);
      }
    }
  }

  /* For TABLE ion_bondvalences, 37 fields */
  if(I->tables[TABLE_ION_BONDVALENCES]) {
    if (output_redirected) fout=fopen(temp_ion_bondvalence_path,"w");
    printf("#ION_BONDVALENCE:%d\n", I->numIonBondValence);
    for (i=0; i<I->numIonBondValence; i++) {
      ibvi=I->IonBondValenceInfo+i;
      ani=ibvi->ni;
      if(ibvi->reverse) {
        ai1=I->AtomInfo+ani->atom_index[1];
        ai2=I->AtomInfo+ani->atom_index[0];
        ri1=I->ResidueInfo+ani->residue_index[1];
        ri2=I->ResidueInfo+ani->residue_index[0];
      } else {
        ai1=I->AtomInfo+ani->atom_index[0];
        ai2=I->AtomInfo+ani->atom_index[1];
        ri1=I->ResidueInfo+ani->residue_index[0];
        ri2=I->ResidueInfo+ani->residue_index[1];
      }
      fprintf(fout, "%d|%d|%d|%d|%f|%d|%d|%d|%s|%s|%d|%d|%d|%s|%s|%d|%d|%d|",
        I->pdbfileid, i, -1,      ani->index,    ibvi->bondvalence, ibvi->inner_sphere_flag,
        ri1->index,   ri2->index, ri1->resn,     ri2->resn,         ri1->type*100+ri2->type,
        ai1->index,   ai2->index, ai1->realname, ai2->realname,     ai1->type*100+ai2->type,
        ai1->protons, ai2->protons);
      fprintf(fout, "%d|%04d|%f|%f|%f|%f|%d|%f|%f|%f|%f|%f|%f|%f|%f|%f|%f|%f\n",
        ai1->numCovalentBond+1, ani->contact_flag,        ani->distance,
        ibvi->bv_direction[0],  ibvi->bv_direction[1],    ibvi->bv_direction[2],
        ani->vector_index[0],   ani->bfactor_correlation, ibvi->bv_sodium,
        ibvi->bv_magnesium,     ibvi->bv_potassium,       ibvi->bv_calcium,
        ibvi->bv_manganese,     ibvi->bv_iron,            ibvi->bv_cobalt,
        ibvi->bv_nickel,        ibvi->bv_copper,          ibvi->bv_zinc);
    }
    if (output_redirected) fclose(fout);
  }
  
  if(I->tables[TABLE_WATER_BINDINGSITES]) {
    EntityMoleculeIonBindingSite(I,1);
    fprintf(stderr,"%s: Water site calculation successfully.\n", I->pdbid);    // calculate water site informations for ligands
    printf("#WATER_BINDINGSITE:%d\n", I->numWaterBindingSite);
    if (output_redirected) fout=fopen(temp_water_bindingsite_path,"w");
    for (i=0; i<I->numWaterBindingSite; i++) {
      ibsi=I->WaterBindingSiteInfo+i;
      ai=I->AtomInfo+ibsi->atomid_ion;
                   /* 1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 */
      fprintf(fout, "%d|%d|%d|%d|%f|%f|%f|%f|%f|%f|%f|%f|%f|%f|%f|%f|%f|%f|%f\n",
        I->pdbfileid,      ibsi->index,           ibsi->residueid_ion, ibsi->atomid_ion,
        ai->b,             ibsi->bfactor_env_avg, ai->occup,           ibsi->occupancy_env_avg,
        ibsi->vecsum_3a,   ibsi->bvs_sodium,      ibsi->bvs_magnesium, ibsi->bvs_potassium,
        ibsi->bvs_calcium, ibsi->bvs_manganese,   ibsi->bvs_iron,      ibsi->bvs_cobalt,
        ibsi->bvs_nickel,  ibsi->bvs_copper,      ibsi->bvs_zinc);
    }
    if (output_redirected) fclose(fout);
  }

  /* For TABLE water_bondvalences, 32 fields */
  if(I->tables[TABLE_WATER_BONDVALENCES]) {
    if (output_redirected) fout=fopen(temp_water_bondvalence_path,"w");
    printf("#WATER_BONDVALENCE:%d\n", I->numWaterBondValence);
    for (i=0; i<I->numWaterBondValence; i++) {
      ibvi=I->WaterBondValenceInfo+i;
      ani=ibvi->ni;
      if(ibvi->reverse) {
        ai1=I->AtomInfo+ani->atom_index[1];
        ai2=I->AtomInfo+ani->atom_index[0];
        ri1=I->ResidueInfo+ani->residue_index[1];
        ri2=I->ResidueInfo+ani->residue_index[0];
      } else {
        ai1=I->AtomInfo+ani->atom_index[0];
        ai2=I->AtomInfo+ani->atom_index[1];
        ri1=I->ResidueInfo+ani->residue_index[0];
        ri2=I->ResidueInfo+ani->residue_index[1];
      }
      fprintf(fout, "%d|%d|%d|%d|%d|%d|%s|%d|%d|%d|%s|%d|%d|", I->pdbfileid, i, -1, ani->index,
        ri1->index, ri2->index, ri1->resn,     ri1->type*100+ri2->type,
        ai1->index, ai2->index, ai1->realname, ai1->type*100+ai2->type, ai1->protons);
      fprintf(fout, "%d|%04d|%f|%f|%f|%f|%d|%f|%f|%f|%f|%f|%f|%f|%f|%f|%f|%f\n",
        ai1->numCovalentBond+1, ani->contact_flag,        ani->distance,
        ibvi->bv_direction[0],  ibvi->bv_direction[1],    ibvi->bv_direction[2],
        ani->vector_index[0],   ani->bfactor_correlation, ibvi->bv_sodium,
        ibvi->bv_magnesium,     ibvi->bv_potassium,       ibvi->bv_calcium,
        ibvi->bv_manganese,     ibvi->bv_iron,            ibvi->bv_cobalt,
        ibvi->bv_nickel,        ibvi->bv_copper,          ibvi->bv_zinc);
    }
    if (output_redirected) fclose(fout);
  }
  /* table ion_bondvalence, water_bondvalence is printed after ion_bindingsites, water_bindingsites table,
   * because the value inner_sphere_flag is modified after the calculation of bindingsites */
  
  /* For TABLE pdbfile, 23 fields */
  printf("#DISTANCE:%f\n", cutoff);
  if(I->tables[TABLE_PDBFILES]) {
   printf("#PDBFILE(%d):%s\n", I->pdbfileid, I->filename);
   if (output_redirected) fout=fopen(temp_pdbfile_path,"w");
   fprintf(fout, "%d|%s|%s|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%s|%d|%f|%s|%d|%s|%s\n",
       I->pdbfileid,            I->filename,           I->pdbid,            I->numAssembly,
       I->numComponent,         I->numChain,           I->numMolecule,      I->numDomain,
       I->numResidue,           I->numAtom,            I->numResNeighbor,   I->numAtmNeighbor,
       I->numMolprobity,        I->numNeighborVector,  I->numAngle,         I->numIonBindingSite,
       I->numIonLigResidue,     I->numIonLigMoiety,    I->numIonLigAtom,    I->numIonLigNeighbor,
       I->numIonLigAtomNeighbor,I->numWaterBindingSite,I->space_group_name, I->space_group_number,
       I->resolution, I->deposition_date, I->exp_method, I->header, I->title);
   if (output_redirected) fclose(fout);
  }

  /* For generating sql script to copy data into database */
  if (output_redirected) {
   fout=fopen(sql_copydata_path,"w");
   if(I->tables[TABLE_PDBFILES]) {
    fprintf(fout, "\\copy pdbfiles (pdbfileid, filename, pdbid, numofassemblies, numofcomponents, numofchains, numofmolecules, numofdomains,");
    fprintf(fout, "  numofresidues, numofatoms, numofneighbors, numofatomneighbors, numofmolprobities, numofneighborvectors, numofligandangles,");
    fprintf(fout, "  numofionbindingsites, numofibsresidues, numofibsmoieties, numofibsatoms, numofibsneighbors, numofibsatomneighbors, numofwaterbindingsites,");
    fprintf(fout, "  space_group_name, space_group_number, resolution, deposition_date, exp_method, header, title) FROM %s WITH DELIMITER '|'\n", temp_pdbfile_path);
   }
   if(I->tables[TABLE_CCDINFO]) {
    fprintf(fout, "\\copy ccdinfo (pdbfileid, organism_id, ec_primary, ec_3rd_level, ec_4th_level, ec_complex,");
    fprintf(fout, "  cluster50_id, cluster90_id, go_process, go_function, go_component, cath_primary, cath_topology, cath_superfamily) FROM %s WITH DELIMITER '|'\n", temp_ccdinfo_path);
   }
   if(I->tables[TABLE_GENEONTOLOGIES]) {
    fprintf(fout, "\\copy geneontologies (pdbfileid, pdbid, chainid, go_type, go_id, qualifier, evidence, xref_db_name, xref_db_id,");
    fprintf(fout, "  organism_id, creation_date, created_by, ref_db_name, ref_db_id) FROM %s WITH DELIMITER '|'\n", temp_geneontology_path);
   }
   if(I->tables[TABLE_ASSEMBLIES]) {
    fprintf(fout, "\\copy assemblies (pdbfileid, assemblyid, assemblynum, assemblytype, numofcdhit_chains, numofsymop_chains, numofcavities, numofsurfrace_atoms,");
    fprintf(fout, "  total_asa, polar_asa, positive_charge_asa, negative_charge_asa, total_backbone_asa, polar_backbone_asa,");
    fprintf(fout, "  total_msa, polar_msa, positive_charge_msa, negative_charge_msa, total_backbone_msa, polar_backbone_msa) FROM %s WITH DELIMITER '|'\n", temp_assembly_path);
   }
   if(I->tables[TABLE_CAVITIES])
    fprintf(fout, "\\copy cavities (pdbfileid, cavityid, numofresidues, numofatoms, volume, assemblyid) FROM %s WITH DELIMITER '|'\n", temp_cavity_path);
    /* UP: pdbfile,ccdinfo,geneontology,assembly,cavity; DOWN: component,chain,molecule,domain */
   if(I->tables[TABLE_COMPONENTS]) {
    fprintf(fout, "\\copy components (pdbfileid, componentid, componentnum, component_name, numofchains, numofkeywords, numoffunctions,");
    fprintf(fout, "  engineered, mutation, synthetic, organism_id, organism_name, expression_id, expression_name) FROM %s WITH DELIMITER '|'\n", temp_component_path);
   }
   if(I->tables[TABLE_FUNCTIONS])
    fprintf(fout, "\\copy functions (pdbfileid, componentid, functionid, ec_primary, ec_3rd_level, ec_4th_level) FROM %s WITH DELIMITER '|'\n", temp_function_path);
   if(I->tables[TABLE_KEYWORDS])
    fprintf(fout, "\\copy keywords (pdbfileid, componentid, keywordid, keyword) FROM %s WITH DELIMITER '|'\n", temp_keyword_path);
   if(I->tables[TABLE_CDHIT_CHAINS]) {
    fprintf(fout, "\\copy cdhit_chains (pdbfileid, pdbid, chainid, assemblyid, chaintype,");
    fprintf(fout, "  clusterstatus, cluster50_id, represent50_id, cluster90_id, represent90_id,");
    fprintf(fout, "  num_go_all, num_go_process, num_go_function, num_go_component,");
    fprintf(fout, "  numofmolecules, numofdomains, numoffragments, numofresidues,");
    fprintf(fout, "  numres_water, numres_ligand, numres_dnarna, numres_protein) FROM %s WITH DELIMITER '|'\n", temp_cdchain_path);
   }
   if(I->tables[TABLE_SYMOP_CHAINS])
    fprintf(fout, "\\copy symop_chains (pdbfileid, chainid, pdbid, model_number, cdhit_chainid, symop_chainid, assemblyid) FROM %s WITH DELIMITER '|'\n", temp_symchain_path);
   if(I->tables[TABLE_MOLECULES])
    fprintf(fout, "\\copy molecules (pdbfileid, moleculeid, moleculetype, chainid, numofresidues, assemblyid) FROM %s WITH DELIMITER '|'\n", temp_molecule_path);
   if(I->tables[TABLE_DOMAINS]) {
    fprintf(fout, "\\copy domains (pdbfileid, pdbid, domainid, chainid, residueid_begin, residueid_end, is_fragment, domainnum,");
    fprintf(fout, "  cath_primary, cath_topology, cath_superfamily, cath_s35, cath_s60, cath_s95, cath_s100,");
    fprintf(fout, "  cath_uniqueid, numofresidues) FROM %s WITH DELIMITER '|'\n", temp_domain_path);
   }
    /* UP: component,chain,molecule,domain; DOWN: residue,atom */
   if(I->tables[TABLE_RESIDUES]) {
    fprintf(fout, "\\copy residues (pdbfileid, residueid, residuetype, resname, chainid, resseq, numofatoms, contains_metal,");
    fprintf(fout, "  location, center_displacement, accessible_surface, molecular_surface, curvature, assemblyid, cavityid,");
    fprintf(fout, "  moleculeid, domainid, prev_residueid, next_residueid, branch_residueid, branch2_residueid) FROM %s WITH DELIMITER '|'\n", temp_residue_path);
   }
   if(I->tables[TABLE_ATOMS]) {
    fprintf(fout, "\\copy atoms (pdbfileid, residueid, atomid, moietytype, atomtype, atomname, atomelem, protons, atomseq, alt,");
    fprintf(fout, "  occup, bfactor, charge, sigma_2fofc, location, center_displacement, accessible_surface, molecular_surface,");
    fprintf(fout, "  curvature, cavityid, moleculeid) FROM %s WITH DELIMITER '|'\n", temp_atom_path);
   }
    /* UP: residue,atom; DOWN: neighbor,atomneighbor,peptidebond,nucleotidebond,neighborvector,ligbondangle */
   if(I->tables[TABLE_NEIGHBORS]) {
    fprintf(fout, "\\copy neighbors (pdbfileid, neighborid, residueid_a, residueid_b, resname_a, resname_b, neighbortype,");
    fprintf(fout, "  atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype,");
    fprintf(fout, "  bond_type, score_probe, score_hb, score_vdw, score_clash,");
    fprintf(fout, "  contact_flag, distance, bfactor_correlation, neighborvectorid, neighborvectorid2) FROM %s WITH DELIMITER '|'\n", temp_neighbor_path);
   }
   if(I->tables[TABLE_ATOMNEIGHBORS]) {
    fprintf(fout, "\\copy atomneighbors (pdbfileid, atomneighborid, residueid_a, residueid_b, resname_a, resname_b, neighbortype,");
    fprintf(fout, "  atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype,");
    fprintf(fout, "  bond_type, score_probe, score_hb, score_vdw, score_clash,");
    fprintf(fout, "  contact_flag, distance, bfactor_correlation, neighborvectorid, neighborvectorid2) FROM %s WITH DELIMITER '|'\n", temp_atomneighbor_path);
   }
   if(I->tables[TABLE_MOLPROBITIES]) {
    fprintf(fout, "\\copy molprobities (pdbfileid, molprobityid, atomneighborid, atomname_a, atomname_b, bond_type, num_dots,");
    fprintf(fout, "  dots_diff, score, mingap, gap, spike_len) FROM %s WITH DELIMITER '|'\n", temp_molprobity_path);
   }
   if(I->tables[TABLE_PEPTIDEBONDS]) {
    fprintf(fout, "\\copy peptidebonds (pdbfileid, atomneighborid, residueid_a, residueid_b, resname_a, resname_b, neighbortype,");
    fprintf(fout, "  atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype,");
    fprintf(fout, "  contact_flag, distance, bfactor_correlation, neighborvectorid, neighborvectorid2) FROM %s WITH DELIMITER '|'\n", temp_peptidebond_path);
   }
   if(I->tables[TABLE_NUCLEOTIDEBONDS]) {
    fprintf(fout, "\\copy nucleotidebonds (pdbfileid, atomneighborid, residueid_a, residueid_b, resname_a, resname_b, neighbortype,");
    fprintf(fout, "  atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype,");
    fprintf(fout, "  contact_flag, distance, bfactor_correlation, neighborvectorid, neighborvectorid2) FROM %s WITH DELIMITER '|'\n", temp_nucleotidebond_path);
   }
   if(I->tables[TABLE_NEIGHBORVECTORS]) {
    fprintf(fout, "\\copy neighborvectors (pdbfileid, neighborvectorid, icell, isym, vec_x, vec_y, vec_z)");
    fprintf(fout, "  FROM %s WITH DELIMITER '|'\n", temp_neighborvector_path);
   }
   if(I->tables[TABLE_LIGAND_BONDANGLES]) {
    fprintf(fout, "\\copy ligand_bondangles (pdbfileid, bondangleid,");
    fprintf(fout, "  residueid_a, residueid_lig, residueid_b, resname_a, resname_lig, resname_b, resangletype,");
    fprintf(fout, "  atomid_a, atomid_lig, atomid_b, atomname_a, atomname_lig, atomname_b, atomangletype,");
    fprintf(fout, "  atomneighborid_a, atomneighborid_b, dist_a, dist_b, dist_lig, angle) FROM %s WITH DELIMITER '|'\n", temp_ligbondangle_path);
   }
    /* UP: neighbor,atomneighbor,peptidebond,nucleotidebond,neighborvector,ligbondangle; DOWN: ion_bondvalence, water_bondvalence, ion_bindingsite */
   if(I->tables[TABLE_ION_BONDVALENCES]) {
    fprintf(fout, "\\copy ion_bondvalences (pdbfileid, bondvalenceid, neighborid, atomneighborid, bondvalence, inner_sphere_flag,");
    fprintf(fout, "  residueid_lig, residueid_ion, resname_lig, resname_ion, neighbortype,");
    fprintf(fout, "  atomid_lig, atomid_ion, atomname_lig, atomname_ion, atomneighbortype, protons_lig, protons_ion, coord_number_lig,");
    fprintf(fout, "  contact_flag, distance, vec_x, vec_y, vec_z, neighborvectorid, bfactor_correlation,");
    fprintf(fout, "  bv_sodium, bv_magnesium, bv_potassium, bv_calcium, bv_manganese, bv_iron,");
    fprintf(fout, "  bv_cobalt, bv_nickel, bv_copper, bv_zinc) FROM %s WITH DELIMITER '|'\n", temp_ion_bondvalence_path);
   }
   if(I->tables[TABLE_WATER_BONDVALENCES]) {
    fprintf(fout, "\\copy water_bondvalences (pdbfileid, bondvalenceid, neighborid, atomneighborid,");
    fprintf(fout, "  residueid_lig, residueid_water, resname_lig, neighbortype,");
    fprintf(fout, "  atomid_lig, atomid_water, atomname_lig, atomneighbortype, protons_lig, coord_number_lig,");
    fprintf(fout, "  contact_flag, distance, vec_x, vec_y, vec_z, neighborvectorid, bfactor_correlation,");
    fprintf(fout, "  bv_sodium, bv_magnesium, bv_potassium, bv_calcium, bv_manganese, bv_iron,");
    fprintf(fout, "  bv_cobalt, bv_nickel, bv_copper, bv_zinc) FROM %s WITH DELIMITER '|'\n", temp_water_bondvalence_path);
   }
   if(I->tables[TABLE_ION_BINDINGSITES]) {
    fprintf(fout, "\\copy ion_bindingsites (pdbfileid, bindingsiteid, residueid_ion, resname_ion, atomid_ion,"); 
    fprintf(fout, "  atomname_ion, protons_ion, oxidation_state, bfactor_ion, bfactor_env_avg, occupancy_ion, occupancy_env_avg,");       /* 12 */
    fprintf(fout, "  coordnum_inner, coordnum_bidentate_merged, geometry_type, geometry_bidentate, geometry_pseudo, geometry_distort,");
    fprintf(fout, "  rmsd_geom_angle, num_bidentate_all, distance_avg, distance_min, distance_max,");       /* 11 */
    fprintf(fout, "  valence_3a, vecsum_3a, coord_number_4a, num_metal_4a, valence_4a, vecsum_4a,");
    fprintf(fout, "  bvs_sodium, bvs_magnesium, bvs_potassium, bvs_calcium, bvs_manganese, bvs_iron,");
    fprintf(fout, "  bvs_cobalt, bvs_nickel, bvs_copper, bvs_zinc) FROM %s WITH DELIMITER '|'\n", temp_ion_bindingsite_path);      /* 16 */
    if(I->tables[TABLE_ION_BINDINGSITE_PROFILES]) {
     fprintf(fout,"\\copy ion_bindingsite_profiles (pdbfileid, bindingsiteid, residueid_ion,");
     fprintf(fout,"  atomid_ion, atomid_cluster, size_cluster, homosize_cluster, which_metal, which_geotype, which_ligtype,");     /* 10 */
     fprintf(fout,"  which_XHCXX, which_OOO, which_wOOO2, which_PPP, which_BNR, which_wBNR2, which_mBRP2,");
     fprintf(fout,"  which_isoform, which_mobile, quality_valence, quality_complete, quality_experiment,");     /* 11 */
     fprintf(fout,"  num_oxygen, num_nitrogen, num_sulfur, num_phosphorus, num_carbon, num_others,");           /* 6 */
     fprintf(fout,"  n04_o_mc, n08_o_amide, n10_o_carboxyl, n17_o_hydroxyl, n18_o_phenol, n30_o_base,");
     fprintf(fout,"  n31_o_ribose, n32_op_bridge, n33_op_terminal, n39_o_water, n43_o_others,");
     fprintf(fout,"  n01_n_mc, n07_n_arginine, n09_n_amide, n13_n_histidine, n14_n_lysine,");
     fprintf(fout,"  n15_n_tryptophan, n27_n_base_ring, n28_n_base_ribose, n29_n_base_amide, n42_n_others,");   /* 26 = 11 oxygen +10 nitrogen + 5 sulfur */
     fprintf(fout,"  n11_s_cysteine, n16_s_methionine, n45_s_others, n19_selenium, n53_others) FROM %s WITH DELIMITER '|'\n", temp_ibs_profile_path);
     if(I->tables[TABLE_ION_BINDINGSITE_LIGRESIDUES]) {
      fprintf(fout,"\\copy ion_bindingsite_ligresidues (pdbfileid, bindingsiteid, ligresiduetype, ligatomtype, residuetype, atomtype, residueid, resname, chainid, resseq,");
      fprintf(fout," atomid_a, atomname_a, distance_a, atomid_b, atomname_b, distance_b) FROM %s WITH DELIMITER '|'\n", temp_ibs_ligresidue_path);
     }
     if(I->tables[TABLE_ION_BINDINGSITE_LIGMOIETIES]) {
      fprintf(fout,"\\copy ion_bindingsite_ligmoieties (pdbfileid, bindingsiteid, ligmoietytype, moietytype,");
      fprintf(fout," residuetype, residueid, resname, chainid, resseq, num_inner_links, num_outer_links) FROM %s WITH DELIMITER '|'\n", temp_ibs_ligmoiety_path);
     }
     if(I->tables[TABLE_ION_BINDINGSITE_LIGATOMS]) {
      fprintf(fout,"\\copy ion_bindingsite_ligatoms (pdbfileid, bindingsiteid, ligatomtype, atomtype, residueid, resname, chainid, resseq,");
      fprintf(fout," atomid, atomname, distance, bondvalence) FROM %s WITH DELIMITER '|'\n", temp_ibs_ligatom_path);
     }
     if(I->tables[TABLE_ION_BINDINGSITE_LIGNEIGHBORS]) {
      fprintf(fout,"\\copy ion_bindingsite_ligneighbors (pdbfileid, bindingsiteid,");
      fprintf(fout," ligneighbortype, residueid_a, residueid_b, resname_a, resname_b,");
      fprintf(fout," dresseq, atomid_a, atomid_b, atomname_a, atomname_b,"); 
      fprintf(fout," bond_type, atomid_aa, atomid_bb, atomname_aa, atomname_bb,"); 
      fprintf(fout," neighborid, atomneighborid, neighbortype, atomneighbortype) FROM %s WITH DELIMITER '|'\n", temp_ibs_ligneighbor_path);
     }
     if(I->tables[TABLE_ION_BINDINGSITE_LIGATOMNEIGHBORS]) {
      fprintf(fout,"\\copy ion_bindingsite_ligatomneighbors (pdbfileid, bindingsiteid, ligatomneighbortype, angle, bvproduct_cos_angle,");
      fprintf(fout," dresseq, atomid_a, atomid_b, residueid_a, residueid_b) FROM %s WITH DELIMITER '|'\n", temp_ibs_ligatomneighbor_path);
     }
    }
   }
   if(I->tables[TABLE_WATER_BINDINGSITES]) {
    fprintf(fout, "\\copy water_bindingsites (pdbfileid, bindingsiteid, residueid_water, atomid_water,"); 
    fprintf(fout, "  bfactor_water, bfactor_env_avg, occupancy_water, occupancy_env_avg, vecsum_sodium,");       /* 9 */
    fprintf(fout, "  bvs_sodium, bvs_magnesium, bvs_potassium, bvs_calcium, bvs_manganese, bvs_iron,");
    fprintf(fout, "  bvs_cobalt, bvs_nickel, bvs_copper, bvs_zinc) FROM %s WITH DELIMITER '|'\n", temp_water_bindingsite_path);      /* 10 */
   }
   fclose(fout);
  }
}

char* process_cmdline_file(char* temp_dir, char* file_name, char* file_type, int is_optional) { 
  FILE *f;
  char* buffer;
  EntityFileName file_path;
  char msg[FileLineLength];
  if (is_optional && !strncmp(file_name,"NULL",4)) {
    AllocP(buffer,char,255);
    buffer[0]=0;
  } else {
    strcpy(file_path, temp_dir);
    strcat(file_path, file_name);
    f=fopen(file_path,"rb");
    if (!f) { sprintf(msg,"invalid %s FILE name\n",file_type); PFatalError(msg); };
    buffer=str2cachetextfile(f);
  }
  return buffer;
}

/*---------------------------------------------------------------------------*/
int main(int argc, char** argv) {
  FILE *f;
  ObjEntityMolecule *I;
  char* envhome=NULL;
  char* buffer=NULL;
  char* buffer_cluster=NULL;
  char* buffer_molprobity=NULL;
  char* buffer_contact=NULL;
  char* buffer_buheader=NULL;
  float cutoff = 4.0;
  EntityFileName temp_dir, file_path, data_dir, lib_dir, file_aadict;
  ResidueDict aminoacid_dictionary[2048];       // Assume maximal 2K non-standard amino acid records
  int i;
//fprintf(stderr, "argc is %i, ", argc);
//for(i=0;i<argc;i++){ fprintf(stderr, "argv[%i] is %s, ", i, argv[i]); }
  envhome=getenv("NEIGHBORHOOD");
  if (envhome == NULL) {
    PFatalError("Please set your environmental variable NEIGHBORHOOD to corresponding path before you can continue...\n");
  } else {
    strcpy(lib_dir, envhome);
    if(lib_dir[strlen(lib_dir)-1] != '/') strcat(lib_dir, "/");
    strcat(lib_dir, "lib/");
  }

/* code to test individual procedures
  AtomInfoPrintElement(element_dictionary);
  AtomInfoPrintBondValence(bondvalence_dictionary);
  ccp4spg_load_by_standard_num(146);
  ccp4spg_load_by_spgname("I 2 3");
  exit(0);
  */

  if (argc < 7) { PFatalError("usage: neighborhood TEMPDIR PDBFILE CLUSTERFILE MolprobityFILE CONTACTFILE Biological_Unit_HEADER_FILE [data_dir [distance [options]]]\n"); }
  if (argc >= 8) {
   strcpy(data_dir, argv[7]);
   if(data_dir[strlen(data_dir)-1] != '/') strcat(data_dir, "/");
   if (argc >= 9) {
    if(sscanf(argv[8],"%f",&cutoff)!=1) { PFatalError("invalid distance, distance should be numeric.\n"); };
    if (cutoff > 4.1) { PFatalError("invalid distance, distance too large for calculation.\n"); };
    if (cutoff < 0.1) { PFatalError("invalid distance, distance too small for calculation.\n"); };
   }
  } else {
    strcpy(data_dir, "/med/zenobi_data/MYPDB_NEW/");
//  strcpy(data_dir, "/data/MYPDB_ZENOBI/");
  }
  strcpy(file_aadict, lib_dir);
  strcat(file_aadict, "aminoacid_dictionary.data");
  ReadAminoAcidDictionary(aminoacid_dictionary, file_aadict);

  strcpy(temp_dir, argv[1]);
  if(temp_dir[strlen(temp_dir)-1] != '/') strcat(temp_dir, "/");

  strcpy(file_path, temp_dir);
  strcat(file_path, argv[2]);
  f=fopen(file_path,"rb");
  if (!f) { PFatalError("invalid PDBFILE name\n"); };
  buffer=str2cachetextfile(f);
  buffer_cluster    = process_cmdline_file(temp_dir,argv[3],"CLUSTER",0);
  buffer_molprobity = process_cmdline_file(temp_dir,argv[4],"Molprobity",1);
  buffer_contact    = process_cmdline_file(temp_dir,argv[5],"CONTACT",1);
  buffer_buheader   = process_cmdline_file(temp_dir,argv[6],"Biological Unit HEADER",1);

  I = (ObjEntityMolecule *)EntityMoleculeNew();    // create molecule object
  strcpy(I->filename, argv[2]);
  str2extractpdbid(I->pdbid, file_path);

  EntityMoleculeReadPDBStr(I, buffer, aminoacid_dictionary);            // create chain, molecule, residue, atom objects
  fprintf(stderr,"%s: PDB string read successfully.\n", I->pdbid);
  EntityMoleculeReadClusterStr(I, buffer_cluster);                      // assign pdbfileid, chain/symchain cluster info
  fprintf(stderr,"%s: Cluster string read successfully.\n", I->pdbid);
  PDBheaderFinishTouch(I);
  EntityMoleculeReadAssemblyStr(I, buffer_buheader, data_dir);          // create assembly, symchain, cavity objects
  fprintf(stderr,"%s: Assembly string read successfully.\n", I->pdbid);
  EntityMoleculeNeighbor(I, cutoff, buffer_molprobity, buffer_contact); // create neighbor, atomneighbor objects
  fprintf(stderr,"%s: Molprobity probe hydrogen bond/vdw interaction read successfully.\n", I->pdbid);  // import interaction type
  fprintf(stderr,"%s: contact string read successfully.\n", I->pdbid);  // add additional neighbors which are inter-molecule contacts
  EntityMoleculeLigandAngle(I, cutoff);                                 // create angle objects
  fprintf(stderr,"%s: Ligand angle calculation successfully.\n", I->pdbid);  // calculate neighbor angles for ligand
  EntityMoleculeBondValence(I, 0);                                           // create bond valence objects for metal ions
  EntityMoleculeBondValence(I, 1);                                           // create bond valence objects for water atoms
  fprintf(stderr,"%s: Bond valence calculation successfully.\n", I->pdbid);  // calculate bond valence informations for ligands
  EntityMoleculeIonBindingSite(I,0);
  fprintf(stderr,"%s: Ion binding site calculation successfully.\n", I->pdbid); // calculate ion binding site informations
  EntityMoleculeReport(I, cutoff, temp_dir);
  fprintf(stderr,"%s: Neighbor calculation successfully.\n", I->pdbid);

  EntityMoleculeFree(I);
  FreeP(buffer);
  FreeP(buffer_cluster);
  FreeP(buffer_contact);
  FreeP(buffer_buheader);
  return 0;
}
