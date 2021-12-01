DROP TABLE tables;
CREATE TABLE tables(
    id                  smallint,
    tabletype           smallint,
    numoffields         smallint,
    existence           boolean,
    action_drop         boolean,
    action_create       boolean,
    name                text,
    description         text
);
COPY tables (id,tabletype,numoffields,existence,action_drop,action_create,name,description) FROM stdin;
0	0	8	1	1	1	tables	Meta data that contains tables description
1	0	8	1	1	1	neighborhood	Database general information
2	0	6	1	1	1	identities	identities about IP resolution
3	0	6	1	1	1	browsers	identities about the browser used at a particular IP
4	0	4	1	1	1	visitors	website visiting history
5	0	4	1	1	1	stalkers	stalkers history
6	0	10	1	1	1	usages	Database usage history records
7	0	13	1	1	1	comments	Feedback that users suggest
8	1	17	1	1	1	geneontology_dictionary	Dictionary of GeneOntology terms
9	1	5	1	1	1	geneontology_relationship	Dictionary of relationship between GeneOntology terms
10	1	8	1	1	1	geneontology_reference	Dictionary of external reference links for GeneOntology terms
11	1	4	1	1	1	ec_dictionary	Dictionary of Enzyme Classification terms
12	1	4	1	1	1	cath_dictionary	Dictionary of CATH fold classification terms
13	1	2	1	1	1	aminoacid_dictionary	Dictionary of uncommon amino acid 3-letter residue codes
14	1	15	1	1	1	hetdictionary	Dictionary of small molecule ligands 3-letter residue codes
15	2	23	1	1	1	pdbfiles	List of PDB file records
16	2	14	1	1	1	ccdinfo	Information for longest chain/component/domain in the deposited PDB structures
17	2	15	1	1	1	geneontologies	GeneOntology defined from GO database
18	2	21	1	1	1	assemblies	Assembly reported as biological units in PDB
19	2	7	1	1	1	cavities	Largest cavity predicted by surflex-dock program for each biological unit
20	2	12	1	1	1	components	Components used to produce the structure defined in the PDB file header
21	2	7	1	1	1	functions	Biological function for each component, as defined by EC and home-defined terms
22	2	5	1	1	1	keywords	Keywords for each component
23	3	23	1	1	1	cdhit_chains	Macromolecule chain and cluster information predicted by CD-HIT program for non-redundant condition
24	3	8	1	1	1	symop_chains	Macromolecule chain that is used to form biological unit by crystal symmetry
25	3	7	1	1	1	molecules	Molecules are chains cut into different components
26	3	18	1	1	1	domains	Domains of macromolecule chains cut by topology definition in CATH database
27	3	20	1	1	1	residues	Basic building unit in polymer chain, or small molecule, or ion
28	3	20	1	1	1	atoms	Atoms in a residue, usually refer to non-hydrogen atoms
29	4	21	1	1	1	neighbors	Inter-residue interaction in protein crystal, can be either within AU or be crystal contact
30	4	21	1	1	1	atomneighbors	Inter-residue interaction, but defined for each individual pair of atoms
31	4	23	1	1	1	ligand_bondangles	Geometry angle for small molecule ligand as the vertex of the angle
32	4	26	1	1	1	ion_bondvalences	Bond Valence information for ions
33	4	23	1	1	1	water_bondvalences	Bond Valence information for single water molecules
34	4	63	1	1	1	ion_bindingsites	Ion binding site geometry, profile, valence, symmetry, completeness, and coordination number information
\.

CREATE OR REPLACE FUNCTION d34() RETURNS integer as 'declare v boolean; begin select into v action_drop from tables where name=''ion_bindingsites'';          if v then DROP TABLE ion_bindingsites;          end if; return null; end;' language 'plpgsql'; SELECT d34(); DROP FUNCTION d34();
CREATE OR REPLACE FUNCTION d33() RETURNS integer as 'declare v boolean; begin select into v action_drop from tables where name=''water_bondvalences'';        if v then DROP TABLE water_bondvalences;        end if; return null; end;' language 'plpgsql'; SELECT d33(); DROP FUNCTION d33();
CREATE OR REPLACE FUNCTION d32() RETURNS integer as 'declare v boolean; begin select into v action_drop from tables where name=''ion_bondvalences'';          if v then DROP TABLE ion_bondvalences;          end if; return null; end;' language 'plpgsql'; SELECT d32(); DROP FUNCTION d32();
CREATE OR REPLACE FUNCTION d31() RETURNS integer as 'declare v boolean; begin select into v action_drop from tables where name=''ligand_bondangles'';         if v then DROP TABLE ligand_bondangles;         end if; return null; end;' language 'plpgsql'; SELECT d31(); DROP FUNCTION d31();
CREATE OR REPLACE FUNCTION d30() RETURNS integer as 'declare v boolean; begin select into v action_drop from tables where name=''atomneighbors'';             if v then DROP TABLE atomneighbors;             end if; return null; end;' language 'plpgsql'; SELECT d30(); DROP FUNCTION d30();
CREATE OR REPLACE FUNCTION d29() RETURNS integer as 'declare v boolean; begin select into v action_drop from tables where name=''neighbors'';                 if v then DROP TABLE neighbors;                 end if; return null; end;' language 'plpgsql'; SELECT d29(); DROP FUNCTION d29();
CREATE OR REPLACE FUNCTION d28() RETURNS integer as 'declare v boolean; begin select into v action_drop from tables where name=''atoms'';                     if v then DROP TABLE atoms;                     end if; return null; end;' language 'plpgsql'; SELECT d28(); DROP FUNCTION d28();
CREATE OR REPLACE FUNCTION d27() RETURNS integer as 'declare v boolean; begin select into v action_drop from tables where name=''residues'';                  if v then DROP TABLE residues;                  end if; return null; end;' language 'plpgsql'; SELECT d27(); DROP FUNCTION d27();
CREATE OR REPLACE FUNCTION d26() RETURNS integer as 'declare v boolean; begin select into v action_drop from tables where name=''domains'';                   if v then DROP TABLE domains;                   end if; return null; end;' language 'plpgsql'; SELECT d26(); DROP FUNCTION d26();
CREATE OR REPLACE FUNCTION d25() RETURNS integer as 'declare v boolean; begin select into v action_drop from tables where name=''molecules'';                 if v then DROP TABLE molecules;                 end if; return null; end;' language 'plpgsql'; SELECT d25(); DROP FUNCTION d25();
CREATE OR REPLACE FUNCTION d24() RETURNS integer as 'declare v boolean; begin select into v action_drop from tables where name=''symop_chains'';              if v then DROP TABLE symop_chains;              end if; return null; end;' language 'plpgsql'; SELECT d24(); DROP FUNCTION d24();
CREATE OR REPLACE FUNCTION d23() RETURNS integer as 'declare v boolean; begin select into v action_drop from tables where name=''cdhit_chains'';              if v then DROP TABLE cdhit_chains;              end if; return null; end;' language 'plpgsql'; SELECT d23(); DROP FUNCTION d23();
CREATE OR REPLACE FUNCTION d22() RETURNS integer as 'declare v boolean; begin select into v action_drop from tables where name=''keywords'';                  if v then DROP TABLE keywords;                  end if; return null; end;' language 'plpgsql'; SELECT d22(); DROP FUNCTION d22();
CREATE OR REPLACE FUNCTION d21() RETURNS integer as 'declare v boolean; begin select into v action_drop from tables where name=''functions'';                 if v then DROP TABLE functions;                 end if; return null; end;' language 'plpgsql'; SELECT d21(); DROP FUNCTION d21();
CREATE OR REPLACE FUNCTION d20() RETURNS integer as 'declare v boolean; begin select into v action_drop from tables where name=''components'';                if v then DROP TABLE components;                end if; return null; end;' language 'plpgsql'; SELECT d20(); DROP FUNCTION d20();
CREATE OR REPLACE FUNCTION d19() RETURNS integer as 'declare v boolean; begin select into v action_drop from tables where name=''cavities'';                  if v then DROP TABLE cavities;                  end if; return null; end;' language 'plpgsql'; SELECT d19(); DROP FUNCTION d19();
CREATE OR REPLACE FUNCTION d18() RETURNS integer as 'declare v boolean; begin select into v action_drop from tables where name=''assemblies'';                if v then DROP TABLE assemblies;                end if; return null; end;' language 'plpgsql'; SELECT d18(); DROP FUNCTION d18();
CREATE OR REPLACE FUNCTION d17() RETURNS integer as 'declare v boolean; begin select into v action_drop from tables where name=''geneontologies'';            if v then DROP TABLE geneontologies;            end if; return null; end;' language 'plpgsql'; SELECT d17(); DROP FUNCTION d17();
CREATE OR REPLACE FUNCTION d16() RETURNS integer as 'declare v boolean; begin select into v action_drop from tables where name=''ccdinfo'';                   if v then DROP TABLE ccdinfo;                   end if; return null; end;' language 'plpgsql'; SELECT d16(); DROP FUNCTION d16();
CREATE OR REPLACE FUNCTION d15() RETURNS integer as 'declare v boolean; begin select into v action_drop from tables where name=''pdbfiles'';                  if v then DROP TABLE pdbfiles;                  end if; return null; end;' language 'plpgsql'; SELECT d15(); DROP FUNCTION d15();
CREATE OR REPLACE FUNCTION d14() RETURNS integer as 'declare v boolean; begin select into v action_drop from tables where name=''hetdictionary'';             if v then DROP TABLE hetdictionary;             end if; return null; end;' language 'plpgsql'; SELECT d14(); DROP FUNCTION d14();
CREATE OR REPLACE FUNCTION d13() RETURNS integer as 'declare v boolean; begin select into v action_drop from tables where name=''aminoacid_dictionary'';      if v then DROP TABLE aminoacid_dictionary;      end if; return null; end;' language 'plpgsql'; SELECT d13(); DROP FUNCTION d13();
CREATE OR REPLACE FUNCTION d12() RETURNS integer as 'declare v boolean; begin select into v action_drop from tables where name=''cath_dictionary'';           if v then DROP TABLE cath_dictionary;           end if; return null; end;' language 'plpgsql'; SELECT d12(); DROP FUNCTION d12();
CREATE OR REPLACE FUNCTION d11() RETURNS integer as 'declare v boolean; begin select into v action_drop from tables where name=''ec_dictionary'';             if v then DROP TABLE ec_dictionary;             end if; return null; end;' language 'plpgsql'; SELECT d11(); DROP FUNCTION d11();
CREATE OR REPLACE FUNCTION d10() RETURNS integer as 'declare v boolean; begin select into v action_drop from tables where name=''geneontology_reference'';    if v then DROP TABLE geneontology_reference;    end if; return null; end;' language 'plpgsql'; SELECT d10(); DROP FUNCTION d10();
CREATE OR REPLACE FUNCTION d09() RETURNS integer as 'declare v boolean; begin select into v action_drop from tables where name=''geneontology_relationship''; if v then DROP TABLE geneontology_relationship; end if; return null; end;' language 'plpgsql'; SELECT d09(); DROP FUNCTION d09();
CREATE OR REPLACE FUNCTION d08() RETURNS integer as 'declare v boolean; begin select into v action_drop from tables where name=''geneontology_dictionary'';   if v then DROP TABLE geneontology_dictionary;   end if; return null; end;' language 'plpgsql'; SELECT d08(); DROP FUNCTION d08();
CREATE OR REPLACE FUNCTION d07() RETURNS integer as 'declare v boolean; begin select into v action_drop from tables where name=''comments'';                  if v then DROP TABLE comments;                  end if; return null; end;' language 'plpgsql'; SELECT d07(); DROP FUNCTION d07();
CREATE OR REPLACE FUNCTION d06() RETURNS integer as 'declare v boolean; begin select into v action_drop from tables where name=''usages'';                    if v then DROP TABLE usages;                    end if; return null; end;' language 'plpgsql'; SELECT d06(); DROP FUNCTION d06();
CREATE OR REPLACE FUNCTION d05() RETURNS integer as 'declare v boolean; begin select into v action_drop from tables where name=''stalkers'';                  if v then DROP TABLE stalkers;                  end if; return null; end;' language 'plpgsql'; SELECT d05(); DROP FUNCTION d05();
CREATE OR REPLACE FUNCTION d04() RETURNS integer as 'declare v boolean; begin select into v action_drop from tables where name=''visitors'';                  if v then DROP TABLE visitors;                  end if; return null; end;' language 'plpgsql'; SELECT d04(); DROP FUNCTION d04();
CREATE OR REPLACE FUNCTION d03() RETURNS integer as 'declare v boolean; begin select into v action_drop from tables where name=''browsers'';                  if v then DROP TABLE browsers;                  end if; return null; end;' language 'plpgsql'; SELECT d03(); DROP FUNCTION d03();
CREATE OR REPLACE FUNCTION d02() RETURNS integer as 'declare v boolean; begin select into v action_drop from tables where name=''identities'';                if v then DROP TABLE identities;                end if; return null; end;' language 'plpgsql'; SELECT d02(); DROP FUNCTION d02();
CREATE OR REPLACE FUNCTION d01() RETURNS integer as 'declare v boolean; begin select into v action_drop from tables where name=''neighborhood'';              if v then DROP TABLE neighborhood;              end if; return null; end;' language 'plpgsql'; SELECT d01(); DROP FUNCTION d01();

CREATE TABLE neighborhood(
    purpose             text,
    version             char(6),
    creation_date       timestamp DEFAULT CURRENT_TIMESTAMP,
    host                text,
    ip                  inet,
    port                smallint,
    mac_address         macaddr,
    database_name       text
);

CREATE TABLE identities(
    id                  serial,
    ip                  inet,
    host                text,
    city                text,
    country             char(13),
    tag                 char(10),
    PRIMARY KEY (ip)
);

CREATE TABLE browsers(
    id                  serial,
    ip                  inet NOT NULL REFERENCES identities (ip) ON UPDATE NO ACTION ON DELETE NO ACTION,
    browser_id          smallint,
    browser_os          char(7),
    browser_name        char(17),       -- IE, FF, Safari, Chrome, Opera, Konqueror, mozilla, netscape, 360, QQ browser, lynx
    browser_version     text,
    PRIMARY KEY (ip,browser_id)
);

CREATE TABLE visitors(
    id                  serial,
    ip                  inet NOT NULL REFERENCES identities (ip) ON UPDATE NO ACTION ON DELETE NO ACTION,
    browser_id          smallint,
    creation_date       timestamp DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE stalkers(
    id                  serial,
    ip                  inet NOT NULL REFERENCES identities (ip) ON UPDATE NO ACTION ON DELETE NO ACTION,
    browser_id          smallint,
    creation_date       timestamp DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE usages(
    id                  serial,
    sessionid           char(13),       -- 4 chars for pdbid, 5 digits for csgid, up to 13 chars for upload file
    usagetype           smallint,       -- Upload user PDB file, using pdbid, or using CSGID
    test_data           boolean,
    crystal_contact     boolean,
    pdbfileid           integer,
    filename            text,
    ip                  inet NOT NULL REFERENCES identities (ip) ON UPDATE NO ACTION ON DELETE NO ACTION,
    browser_id          smallint,
    creation_date       timestamp DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE comments(
    id                  serial,
    firstname           text,
    lastname            text,
    email               text,
    institution         text,
    area                char(2),
    commenttype         smallint,       -- bug, feature, question, rating
    question            text,
    answer              text,
    filename            text,
    ip                  inet NOT NULL REFERENCES identities (ip) ON UPDATE NO ACTION ON DELETE NO ACTION,
    browser_id          smallint,
    creation_date       timestamp DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE geneontology_dictionary(
    go_id               integer NOT NULL,
    namespace           char(1) NOT NULL,
    name                text,
    def                 text,
    comment             text,
    created_by          char(20),
    creation_date       date,
    is_obsolete         boolean,
    unvetted            boolean,
    prok                boolean,
    plant               boolean,
    candida             boolean,
    pombe               boolean,
    generic             boolean,
    pir                 boolean,
    goa                 boolean,
    yeast               boolean,
    PRIMARY KEY (go_id)
);
\copy geneontology_dictionary (go_id, namespace, name, def, comment, created_by, creation_date, is_obsolete, unvetted, prok, plant, candida, pombe, generic, pir, goa, yeast) FROM '/med/zenobi_data/MYPDB_NEW/derived/geneontology_dictionary.data' WITH DELIMITER '@'

CREATE TABLE geneontology_relationship(
    id                  serial,
    go_id               integer NOT NULL REFERENCES geneontology_dictionary (go_id) ON UPDATE NO ACTION ON DELETE NO ACTION,
    relation_term       char(15),
--    alt_id            GO:xxx - 
--    is_a              GO:xxx ! abc -
--    intersection_of   (NULL,regulates,has_part,part_of,positively_regulates,negatively_regulates) GO:xxx ! abc -
--    relationship      (NULL,regulates,has_part,part_of,positively_regulates,negatively_regulates) GO:xxx ! abc -
--    consider          GO:xxx -
--    replaced_by       GO:xxx - 
--    disjoint_from     GO:xxx - 
    relation_detail     char(20),
    related_go_id       integer
);
\copy geneontology_relationship(go_id,relation_term,relation_detail,related_go_id) FROM '/med/zenobi_data/MYPDB_NEW/derived/geneontology_relationship.data' WITH DELIMITER '@'

CREATE TABLE geneontology_reference(
    id                  serial,
    go_id               integer NOT NULL REFERENCES geneontology_dictionary (go_id) ON UPDATE NO ACTION ON DELETE NO ACTION,
    is_ref              boolean,
    is_synonym          boolean,
--    synonym           "abc" (EXACT,BROAD,NARROW) [db_name:db_id]
--    xref              db_name:db_id "abc"
    synonym_modifier    char(1),
    ref_db_name         char(20),
    ref_db_id           text,
    description         text
);
\copy geneontology_reference(go_id,is_ref,is_synonym,synonym_modifier,ref_db_name,ref_db_id,description) FROM '/med/zenobi_data/MYPDB_NEW/derived/geneontology_reference.data' WITH DELIMITER '@'

CREATE TABLE ec_dictionary(
    ec_primary          smallint,
    ec_3rd_level        smallint,
    ec_4th_level        smallint,
    description         text,
    PRIMARY KEY (ec_primary, ec_3rd_level, ec_4th_level)
);

CREATE TABLE cath_dictionary(
    cath_primary        smallint,
    cath_topology       smallint,
    cath_superfamily    smallint,
    description         text,
    PRIMARY KEY (cath_primary, cath_topology, cath_superfamily)
);

CREATE TABLE aminoacid_dictionary(
    resname             char(3) NOT NULL,
    resname_std         char(3) NOT NULL,
    PRIMARY KEY (resname)
);
\copy aminoacid_dictionary (resname, resname_std) FROM '/med/zenobi_data/MYPDB_NEW/monomer/aminoacid_dictionary.data' WITH DELIMITER '@'

CREATE TABLE hetdictionary(
    resname             char(3) NOT NULL,
    numofatoms          smallint default -1,
    hetsyn              text,
    hetname             text,
    formula             text,
    charge              smallint default 0,
    num_heavyatom       smallint default -1,
    num_carbon          smallint default -1,
    num_hydrogen        smallint default -1,
    num_oxygen          smallint default -1,
    num_nitrogen        smallint default -1,
    num_sulfur          smallint default -1,
    num_phosphorus      smallint default -1,
    num_others          smallint default -1,
    remainder_formula   text,
    PRIMARY KEY (resname)
);
\copy hetdictionary (resname, numofatoms, hetsyn, hetname, formula, charge, num_heavyatom, num_carbon, num_hydrogen, num_oxygen, num_nitrogen, num_sulfur, num_phosphorus, num_others, remainder_formula) FROM '/med/zenobi_data/MYPDB_NEW/monomer/hetdictionary.data' WITH DELIMITER '@'

CREATE TABLE pdbfiles(
    pdbfileid           integer,
    filename            text NOT NULL,
    pdbid               char(4),
    numofassemblies     smallint,
    numofcomponents     smallint,
    numofchains         smallint,
    numofmolecules      smallint,
    numofdomains        smallint,
    numofresidues       integer,
    numofatoms          integer,
    numofneighbors      integer,
    numofatomneighbors  integer,
    numofligandangles   integer,
    numofbindingsites   smallint,
    space_group_name    char(20),
    space_group_number  smallint,
    resolution          real,
    deposition_date     date,
    exp_method          smallint,
    header              char(40),
    title               text,
    status              boolean,
    updated             timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (pdbfileid)
);

-- component, chain, and domain summary
CREATE TABLE ccdinfo(
    pdbfileid           integer NOT NULL REFERENCES pdbfiles (pdbfileid) ON UPDATE NO ACTION ON DELETE NO ACTION,
    organism_id         integer,
    ec_primary          smallint,
    ec_3rd_level        smallint,
    ec_4th_level        smallint,
    ec_complex          smallint,
    cluster50_id        integer,
    cluster90_id        integer,
    go_process          integer,
    go_function         integer,
    go_component        integer,
    cath_primary        smallint,
    cath_topology       smallint,
    cath_superfamily    smallint,
    PRIMARY KEY (pdbfileid)
);

CREATE TABLE geneontologies(
    id                  serial,
    pdbfileid           integer NOT NULL REFERENCES pdbfiles (pdbfileid) ON UPDATE NO ACTION ON DELETE NO ACTION,
    pdbid               char(4),
    chainid             char(1),
    go_type             char(1) NOT NULL,       -- 'P': Process, 'F': Function, 'C': Component
    go_id               integer,
    qualifier           smallint,               -- 0: undef, 1: no data, -1: NOT, 2: contributes_to, 3: colocalizes_with, -2: NOT|contributes_to, -3: NOT|colocalizes_with
    evidence            char(3) NOT NULL,       -- EXP, IMP, IC, IGI, IPI, ISS, IDA, IEP, IEA, TAS, NAS, NR, ND or RCA.
    xref_db_name        char(12),
    xref_db_id          char(18),
    organism_id         integer,
    creation_date       date,
    created_by          char(18),
    ref_db_name         char(1),                -- 'G': GO_REF, 'P': PMID, 'D': DOI
    ref_db_id           integer                 -- in case of DOI id, it is -1 for the moment
 --   PRIMARY KEY (pdbfileid,chainid,go_id)
);

CREATE TABLE assemblies(
    id                  serial,
    pdbfileid           integer NOT NULL REFERENCES pdbfiles (pdbfileid) ON UPDATE NO ACTION ON DELETE NO ACTION,
    assemblyid          smallint,
    assemblynum         smallint,
    assemblytype        BIT(3),
    numofcdhit_chains   smallint,
    numofsymop_chains   smallint,
    numofcavities       smallint,
    numofsurfrace_atoms integer,
    total_asa           real,
    polar_asa           real,
    positive_charge_asa real,
    negative_charge_asa real,
    total_backbone_asa  real,
    polar_backbone_asa  real,
    total_msa           real,
    polar_msa           real,
    positive_charge_msa real,
    negative_charge_msa real,
    total_backbone_msa  real,
    polar_backbone_msa  real,
    PRIMARY KEY (pdbfileid, assemblyid)
);

CREATE TABLE cavities(
    id                  serial,
    pdbfileid           integer NOT NULL REFERENCES pdbfiles (pdbfileid) ON UPDATE NO ACTION ON DELETE NO ACTION,
    cavityid            smallint,
    numofresidues       integer,
    numofatoms          integer,
    volume              integer,
    assemblyid          smallint,
    PRIMARY KEY (pdbfileid, cavityid)
);

CREATE TABLE components(
    id                  serial,
    pdbfileid           integer NOT NULL REFERENCES pdbfiles (pdbfileid) ON UPDATE NO ACTION ON DELETE NO ACTION,
    componentid         smallint NOT NULL,
    componentnum        smallint,
    component_name      text,
    numofchains         smallint,
    numofkeywords       smallint,
    numoffunctions      smallint,
    engineered          boolean,
    mutation            boolean,
    organism_id         integer,
    organism_name       text,
    PRIMARY KEY (pdbfileid, componentid)
);

CREATE TABLE functions(
    id                  serial,
    pdbfileid           integer NOT NULL REFERENCES pdbfiles (pdbfileid) ON UPDATE NO ACTION ON DELETE NO ACTION,
    componentid         smallint NOT NULL,
    functionid          smallint NOT NULL,
    ec_primary          smallint,
    ec_3rd_level        smallint,
    ec_4th_level        smallint,
    PRIMARY KEY (pdbfileid, componentid, functionid)
);

CREATE TABLE keywords(
    id                  serial,
    pdbfileid           integer NOT NULL REFERENCES pdbfiles (pdbfileid) ON UPDATE NO ACTION ON DELETE NO ACTION,
    componentid         smallint NOT NULL,
    keywordid           smallint NOT NULL,
    keyword             text,
    PRIMARY KEY (pdbfileid, componentid, keywordid)
);

CREATE TABLE cdhit_chains(
    id                  serial,
    pdbfileid           integer NOT NULL REFERENCES pdbfiles (pdbfileid) ON UPDATE NO ACTION ON DELETE NO ACTION,
    pdbid               char(4),
    chainid             char(1),
    assemblyid          smallint,
    chaintype           BIT(4),
    clusterstatus       BIT(3),
    cluster50_id        integer,
    represent50_id      smallint,
    cluster90_id        integer,
    represent90_id      smallint,
    num_go_all          smallint,
    num_go_process      smallint,
    num_go_function     smallint,
    num_go_component    smallint,
    numofmolecules      smallint,
    numofdomains        smallint,
    numoffragments      smallint,
    numofresidues       integer,
    numres_water        smallint,
    numres_ligand       smallint,
    numres_dnarna       smallint,
    numres_protein      smallint,
    PRIMARY KEY (pdbfileid, chainid)
);

CREATE TABLE symop_chains(
    id                  serial,
    pdbfileid           integer NOT NULL REFERENCES pdbfiles (pdbfileid) ON UPDATE NO ACTION ON DELETE NO ACTION,
    chainid             smallint,
    pdbid               char(4),
    model_number        smallint,
    cdhit_chainid       char(1),
    symop_chainid       char(1),
    assemblyid          smallint,
    PRIMARY KEY (pdbfileid, chainid)
);

CREATE TABLE molecules(
    id                  serial,
    pdbfileid           integer NOT NULL REFERENCES pdbfiles (pdbfileid) ON UPDATE NO ACTION ON DELETE NO ACTION,
    moleculeid          smallint NOT NULL,
    moleculetype        BIT(2),
    chainid             char(1),
    numofresidues       smallint,
    assemblyid          smallint,
    PRIMARY KEY (pdbfileid, moleculeid)
);

CREATE TABLE domains(
    id                  serial,
    pdbfileid           integer NOT NULL REFERENCES pdbfiles (pdbfileid) ON UPDATE NO ACTION ON DELETE NO ACTION,
    pdbid               char(4),
    domainid            smallint NOT NULL,
    chainid             char(1),
    residueid_begin     smallint,
    residueid_end       smallint,
    is_fragment         boolean,
    domainnum           smallint,
    cath_primary        smallint,
    cath_topology       smallint,
    cath_superfamily    smallint,
    cath_s35            smallint,
    cath_s60            smallint,
    cath_s95            smallint,
    cath_s100           smallint,
    cath_uniqueid       smallint,
    numofresidues       smallint,
    PRIMARY KEY (pdbfileid, domainid)
);

CREATE TABLE residues(
    id                  serial,
    pdbfileid           integer NOT NULL REFERENCES pdbfiles (pdbfileid) ON UPDATE NO ACTION ON DELETE NO ACTION,
    residueid           smallint NOT NULL,
    residuetype         smallint,
    resname             char(3),
    chainid             char(1),
    resseq              smallint NOT NULL,
    numofatoms          smallint,
    contains_metal      boolean,
    location            BIT(3),
    center_displacement real,
    accessible_surface  real,
    molecular_surface   real,
    curvature           real,
    assemblyid          smallint,
    cavityid            smallint,
    moleculeid          smallint,
    domainid            smallint,
    prev_residueid      smallint,
    next_residueid      smallint,
    PRIMARY KEY (pdbfileid, residueid)
);

CREATE TABLE atoms(
    id                  serial,
    pdbfileid           integer NOT NULL REFERENCES pdbfiles (pdbfileid) ON UPDATE NO ACTION ON DELETE NO ACTION,
    residueid           smallint NOT NULL,
    atomid              integer NOT NULL,
    atomtype            smallint,
    atomname            char(4),
    atomelem            char(4),
    protons             smallint,
    atomseq             integer NOT NULL,
    alt                 char(1),
    occup               real,
    bfactor             real,
    charge              real,
    location            BIT(3),
    center_displacement real,
    accessible_surface  real,
    molecular_surface   real,
    curvature           real,
    cavityid            smallint,
    moleculeid          smallint,
    PRIMARY KEY (pdbfileid, atomid)
);

CREATE TABLE neighbors(
    id                  serial,
    pdbfileid           integer NOT NULL REFERENCES pdbfiles (pdbfileid) ON UPDATE NO ACTION ON DELETE NO ACTION,
    neighborid          integer NOT NULL,
    residueid_a         smallint NOT NULL,
    residueid_b         smallint NOT NULL,
    resname_a           char(3),
    resname_b           char(3),
    neighbortype        smallint,

    atomid_a            integer,
    atomid_b            integer,
    atomname_a          char(4),
    atomname_b          char(4),
    atomneighbortype    smallint,

    contact_flag        BIT(4),
    icell               smallint,
    isym                smallint,
    distance            real,
    vec_x               real,
    vec_y               real,
    vec_z               real,
    bfactor_correlation real,
    PRIMARY KEY (pdbfileid, neighborid)
);

CREATE TABLE atomneighbors(
    id                  serial,
    pdbfileid           integer NOT NULL REFERENCES pdbfiles (pdbfileid) ON UPDATE NO ACTION ON DELETE NO ACTION,
    atomneighborid      integer NOT NULL,
    residueid_a         smallint NOT NULL,
    residueid_b         smallint NOT NULL,
    resname_a           char(3),
    resname_b           char(3),
    neighbortype        smallint,

    atomid_a            integer NOT NULL,
    atomid_b            integer NOT NULL,
    atomname_a          char(4),
    atomname_b          char(4),
    atomneighbortype    smallint,

    contact_flag        BIT(4),
    icell               smallint,
    isym                smallint,
    distance            real,
    vec_x               real,
    vec_y               real,
    vec_z               real,
    bfactor_correlation real,
    PRIMARY KEY (pdbfileid, atomneighborid)
);

CREATE TABLE ligand_bondangles (
    id                  serial,
    pdbfileid           integer NOT NULL REFERENCES pdbfiles (pdbfileid) ON UPDATE NO ACTION ON DELETE NO ACTION,
    bondangleid         integer NOT NULL,
    residueid_a         smallint NOT NULL,
    residueid_lig       smallint NOT NULL,
    residueid_b         smallint NOT NULL,
    resname_a           char(3),
    resname_lig         char(3),
    resname_b           char(3),
    resangletype        integer,

    atomid_a            integer NOT NULL,
    atomid_lig          integer NOT NULL,
    atomid_b            integer NOT NULL,
    atomname_a          char(4),
    atomname_lig        char(4),
    atomname_b          char(4),
    atomangletype       integer,

    atomneighborid_a    integer NOT NULL,
    atomneighborid_b    integer NOT NULL,
    dist_a              real,
    dist_b              real,
    dist_lig            real,
    angle               real,
    PRIMARY KEY (pdbfileid, bondangleid)
);

CREATE TABLE ion_bondvalences (
    id                  serial,
    pdbfileid           integer NOT NULL REFERENCES pdbfiles (pdbfileid) ON UPDATE NO ACTION ON DELETE NO ACTION,
    bondvalenceid       integer NOT NULL,
    neighborid          integer,
    atomneighborid      integer not NULL,

    residueid_lig       smallint NOT NULL,
    residueid_ion       smallint NOT NULL,
    resname_lig         char(3),
    resname_ion         char(3),
    neighbortype        smallint,

    atomid_lig          integer NOT NULL,
    atomid_ion          integer NOT NULL,
    atomname_lig        char(4),
    atomname_ion        char(4),
    atomneighbortype    smallint,

    protons_lig         smallint,
    protons_ion         smallint,
    coord_number_lig    smallint,

    contact_flag        BIT(4),
    distance            real,
    vec_x               real,
    vec_y               real,
    vec_z               real,
    bfactor_correlation real,

    bondvalence         real,
    calcium_bondvalence real,
    PRIMARY KEY (pdbfileid, bondvalenceid)
);

CREATE TABLE water_bondvalences (
    id                  serial,
    pdbfileid           integer NOT NULL REFERENCES pdbfiles (pdbfileid) ON UPDATE NO ACTION ON DELETE NO ACTION,
    bondvalenceid       integer NOT NULL,
    neighborid          integer,
    atomneighborid      integer not NULL,

    residueid_lig       smallint NOT NULL,
    residueid_water     smallint NOT NULL,
    resname_lig         char(3),
    neighbortype        smallint,

    atomid_lig          integer NOT NULL,
    atomid_water        integer NOT NULL,
    atomname_lig        char(4),
    atomneighbortype    smallint,

    protons_lig         smallint,
    coord_number_lig    smallint,

    contact_flag        BIT(4),
    distance            real,
    vec_x               real,
    vec_y               real,
    vec_z               real,
    bfactor_correlation real,

    sodium_bondvalence  real,
    calcium_bondvalence real,
    PRIMARY KEY (pdbfileid, bondvalenceid)
);

-- This last table is not to be filled within neighborhood calculation
-- The table schema is defined here only for reference purpose

CREATE TABLE ion_bindingsites (
    id                  serial,
    pdbfileid           integer NOT NULL REFERENCES pdbfiles (pdbfileid) ON UPDATE NO ACTION ON DELETE NO ACTION,
    bindingsiteid       integer NOT NULL,

    residueid_ion       smallint NOT NULL,
    resname_ion         char(3),
    atomid_ion          integer NOT NULL,
    atomname_ion        char(4),
    protons_ion         smallint,
    bfactor_ion         real,
    bfactor_env_avg     real,
    occupancy_ion       real,
    occupancy_env_avg   real,

    coord_number_3a     smallint,
    coord_number_3a_ons smallint,
    geometry_type       smallint,
    geometry_bidentate  smallint,       -- number of bidentate-pseudo-atom used
    geometry_pseudo     smallint,       -- number of vertex missed
    geometry_distort    boolean,        -- RMSD angle bigger than 15
    rmsd_geom_angle     real,           -- RMSD angle
    num_oxygen          smallint,
    num_nitrogen        smallint,
    num_sulfur          smallint,
    num_phosphorus      smallint,
    num_carbon          smallint,
    num_others          smallint,

    num04_oxygen_mc           smallint,
    num08_oxygen_amide        smallint, 
    num10_oxygen_carboxyl     smallint, 
    num17_oxygen_hydroxyl     smallint, 
    num18_oxygen_phenol       smallint, 
    num26_oxygen_dnarna       smallint,        
    num28_oxygen_water        smallint,       
    num31_oxygen_others       smallint,        
    num01_nitrogen_mc         smallint,    
    num07_nitrogen_arginine   smallint,      
    num09_nitrogen_amide      smallint, 
    num13_nitrogen_histidine  smallint,      
    num14_nitrogen_lysine     smallint,    
    num15_nitrogen_tryptophan smallint,        
    num25_nitrogen_dnarna     smallint,        
    num30_nitrogen_others     smallint,        
    num11_sulfur_cysteine     smallint,     
    num16_sulfur_methionine   smallint,        
    num33_sulfur_others       smallint,        
    num19_selenium            smallint, 
    num41_others              smallint,

    num_bidentate_all   smallint,
    num_bidentate_oo    smallint,
    num_bidentate_on    smallint,
    num_bidentate_nn    smallint,
    distance_avg        real,
    distance_min        real,
    distance_max        real,

    valence_3a          real,
    vecsum_3a           real,
    calcium_valence_3a  real,
    calcium_vecsum_3a   real,

    coord_number_4a     smallint,
    num_metal_4a        smallint,
    valence_4a          real,
    vecsum_4a           real,
    calcium_valence_4a  real,
    calcium_vecsum_4a   real,
    PRIMARY KEY (pdbfileid, bindingsiteid)
);


