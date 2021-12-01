drop table residues25_ion;
drop table residues29_lig;
update residues set residuetype=27 where residuetype>=28 and resname in ('UNX','_AL','_GA','GA1', '_IN','_TL','_PB', '__V','_CR','_MN','MN3', '_FE','FE2','_CO','3CO', '_NI','3NI','_CU','CU1', '_ZN','ZN2','_Y1','YT3', '_MO','4MO','6MO', '_RU','_PD','_AG','_CD', '_LA','_CE','_PR','_SM', '_EU','EU3','_GD','GD3', '_TB','_HO','HO3','ER3', '_YB','_LU','__W','_RE', '_OS','OS4','_IR','IR3', '_PT','PT4','_AU','AU3', '_HG');
CREATE TABLE residues25_ion AS (SELECT id, pdbfileid, residueid, chainid, resseq, resname, residuetype FROM residues WHERE residuetype>=25 AND residuetype<=28);
ALTER TABLE residues25_ion ADD PRIMARY KEY (pdbfileid, residueid);
CREATE TABLE residues29_lig AS (SELECT id, pdbfileid, residueid, chainid, resseq, resname, residuetype FROM residues WHERE residuetype=29 OR residuetype=30);
ALTER TABLE residues29_lig ADD PRIMARY KEY (pdbfileid, residueid);
DROP TABLE neighbors0125_gly_ion;
DROP TABLE neighbors0129_gly_lig;
DROP TABLE neighbors0225_ala_ion;
DROP TABLE neighbors0229_ala_lig;
DROP TABLE neighbors0325_val_ion;
DROP TABLE neighbors0329_val_lig;
DROP TABLE neighbors0425_leu_ion;
DROP TABLE neighbors0429_leu_lig;
DROP TABLE neighbors0525_ile_ion;
DROP TABLE neighbors0529_ile_lig;
DROP TABLE neighbors0625_ser_ion;
DROP TABLE neighbors0629_ser_lig;
DROP TABLE neighbors0725_thr_ion;
DROP TABLE neighbors0729_thr_lig;
DROP TABLE neighbors0825_cys_ion;
DROP TABLE neighbors0829_cys_lig;
DROP TABLE neighbors0925_met_ion;
DROP TABLE neighbors0929_met_lig;
DROP TABLE neighbors1125_pro_ion;
DROP TABLE neighbors1129_pro_lig;
DROP TABLE neighbors1225_asp_ion;
DROP TABLE neighbors1229_asp_lig;
DROP TABLE neighbors1325_asn_ion;
DROP TABLE neighbors1329_asn_lig;
DROP TABLE neighbors1425_glu_ion;
DROP TABLE neighbors1429_glu_lig;
DROP TABLE neighbors1525_gln_ion;
DROP TABLE neighbors1529_gln_lig;
DROP TABLE neighbors1625_lys_ion;
DROP TABLE neighbors1629_lys_lig;
DROP TABLE neighbors1725_arg_ion;
DROP TABLE neighbors1729_arg_lig;
DROP TABLE neighbors1825_his_ion;
DROP TABLE neighbors1829_his_lig;
DROP TABLE neighbors1925_phe_ion;
DROP TABLE neighbors1929_phe_lig;
DROP TABLE neighbors2025_tyr_ion;
DROP TABLE neighbors2029_tyr_lig;
DROP TABLE neighbors2125_trp_ion;
DROP TABLE neighbors2129_trp_lig;
DROP TABLE neighbors2225_all_ion;
DROP TABLE neighbors2229_all_lig;
DROP TABLE neighbors2325_dna_ion;
DROP TABLE neighbors2329_dna_lig;
DROP TABLE neighbors2425_wat_ion;
DROP TABLE neighbors2429_wat_lig;
DROP TABLE neighbors2525_ion_ion;
DROP TABLE neighbors2529_ion_lig;
DROP TABLE neighbors2929_lig_lig;

update neighbors set neighbortype=neighbortype-200 where neighbortype>=2900 and resname_a in ('UNX','_AL','_GA','GA1', '_IN','_TL','_PB', '__V','_CR','_MN','MN3', '_FE','FE2','_CO','3CO', '_NI','3NI','_CU','CU1', '_ZN','ZN2','_Y1','YT3', '_MO','4MO','6MO', '_RU','_PD','_AG','_CD', '_LA','_CE','_PR','_SM', '_EU','EU3','_GD','GD3', '_TB','_HO','HO3','ER3', '_YB','_LU','__W','_RE', '_OS','OS4','_IR','IR3', '_PT','PT4','_AU','AU3', '_HG');
update neighbors set neighbortype=neighbortype-2 where neighbortype%100=29 and resname_b in ('UNX','_AL','_GA','GA1', '_IN','_TL','_PB', '__V','_CR','_MN','MN3', '_FE','FE2','_CO','3CO', '_NI','3NI','_CU','CU1', '_ZN','ZN2','_Y1','YT3', '_MO','4MO','6MO', '_RU','_PD','_AG','_CD', '_LA','_CE','_PR','_SM', '_EU','EU3','_GD','GD3', '_TB','_HO','HO3','ER3', '_YB','_LU','__W','_RE', '_OS','OS4','_IR','IR3', '_PT','PT4','_AU','AU3', '_HG');

CREATE TABLE neighbors0125_gly_ion AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE (neighbortype>=125 AND neighbortype<=128));
ALTER TABLE neighbors0125_gly_ion ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);
CREATE TABLE neighbors0129_gly_lig AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE neighbortype=129 OR neighbortype=130);
ALTER TABLE neighbors0129_gly_lig ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);

CREATE TABLE neighbors0225_ala_ion AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE (neighbortype>=225 AND neighbortype<=228));
ALTER TABLE neighbors0225_ala_ion ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);
CREATE TABLE neighbors0229_ala_lig AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE neighbortype=229 OR neighbortype=230);
ALTER TABLE neighbors0229_ala_lig ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);

CREATE TABLE neighbors0325_val_ion AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE (neighbortype>=325 AND neighbortype<=328));
ALTER TABLE neighbors0325_val_ion ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);
CREATE TABLE neighbors0329_val_lig AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE neighbortype=329 OR neighbortype=330);
ALTER TABLE neighbors0329_val_lig ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);

CREATE TABLE neighbors0425_leu_ion AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE (neighbortype>=425 AND neighbortype<=428));
ALTER TABLE neighbors0425_leu_ion ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);
CREATE TABLE neighbors0429_leu_lig AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE neighbortype=429 OR neighbortype=430);
ALTER TABLE neighbors0429_leu_lig ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);

CREATE TABLE neighbors0525_ile_ion AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE (neighbortype>=525 AND neighbortype<=528));
ALTER TABLE neighbors0525_ile_ion ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);
CREATE TABLE neighbors0529_ile_lig AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE neighbortype=529 OR neighbortype=530);
ALTER TABLE neighbors0529_ile_lig ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);

CREATE TABLE neighbors0625_ser_ion AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE (neighbortype>=625 AND neighbortype<=628));
ALTER TABLE neighbors0625_ser_ion ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);
CREATE TABLE neighbors0629_ser_lig AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE neighbortype=629 OR neighbortype=630);
ALTER TABLE neighbors0629_ser_lig ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);

CREATE TABLE neighbors0725_thr_ion AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE (neighbortype>=725 AND neighbortype<=728));
ALTER TABLE neighbors0725_thr_ion ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);
CREATE TABLE neighbors0729_thr_lig AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE neighbortype=729 OR neighbortype=730);
ALTER TABLE neighbors0729_thr_lig ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);

CREATE TABLE neighbors0825_cys_ion AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE (neighbortype>=825 AND neighbortype<=828));
ALTER TABLE neighbors0825_cys_ion ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);
CREATE TABLE neighbors0829_cys_lig AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE neighbortype=829 OR neighbortype=830);
ALTER TABLE neighbors0829_cys_lig ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);

CREATE TABLE neighbors0925_met_ion AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE (neighbortype>=925 AND neighbortype<=928) OR (neighbortype>=1025 AND neighbortype<=1028));
ALTER TABLE neighbors0925_met_ion ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);
CREATE TABLE neighbors0929_met_lig AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE neighbortype=929 OR neighbortype=1029 OR neighbortype=930 OR neighbortype=1030);
ALTER TABLE neighbors0929_met_lig ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);

CREATE TABLE neighbors1125_pro_ion AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE (neighbortype>=1125 AND neighbortype<=1128));
ALTER TABLE neighbors1125_pro_ion ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);
CREATE TABLE neighbors1129_pro_lig AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE neighbortype=1129 OR neighbortype=1130);
ALTER TABLE neighbors1129_pro_lig ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);

CREATE TABLE neighbors1225_asp_ion AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE (neighbortype>=1225 AND neighbortype<=1228));
ALTER TABLE neighbors1225_asp_ion ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);
CREATE TABLE neighbors1229_asp_lig AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE neighbortype=1229 OR neighbortype=1230);
ALTER TABLE neighbors1229_asp_lig ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);

CREATE TABLE neighbors1325_asn_ion AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE (neighbortype>=1325 AND neighbortype<=1328));
ALTER TABLE neighbors1325_asn_ion ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);
CREATE TABLE neighbors1329_asn_lig AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE neighbortype=1329 OR neighbortype=1330);
ALTER TABLE neighbors1329_asn_lig ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);

CREATE TABLE neighbors1425_glu_ion AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE (neighbortype>=1425 AND neighbortype<=1428));
ALTER TABLE neighbors1425_glu_ion ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);
CREATE TABLE neighbors1429_glu_lig AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE neighbortype=1429 OR neighbortype=1430);
ALTER TABLE neighbors1429_glu_lig ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);

CREATE TABLE neighbors1525_gln_ion AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE (neighbortype>=1525 AND neighbortype<=1528));
ALTER TABLE neighbors1525_gln_ion ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);
CREATE TABLE neighbors1529_gln_lig AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE neighbortype=1529 OR neighbortype=1530);
ALTER TABLE neighbors1529_gln_lig ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);

CREATE TABLE neighbors1625_lys_ion AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE (neighbortype>=1625 AND neighbortype<=1628));
ALTER TABLE neighbors1625_lys_ion ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);
CREATE TABLE neighbors1629_lys_lig AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE neighbortype=1629 OR neighbortype=1630);
ALTER TABLE neighbors1629_lys_lig ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);

CREATE TABLE neighbors1725_arg_ion AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE (neighbortype>=1725 AND neighbortype<=1728));
ALTER TABLE neighbors1725_arg_ion ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);
CREATE TABLE neighbors1729_arg_lig AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE neighbortype=1729 OR neighbortype=1730);
ALTER TABLE neighbors1729_arg_lig ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);

CREATE TABLE neighbors1825_his_ion AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE (neighbortype>=1825 AND neighbortype<=1828));
ALTER TABLE neighbors1825_his_ion ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);
CREATE TABLE neighbors1829_his_lig AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE neighbortype=1829 OR neighbortype=1830);
ALTER TABLE neighbors1829_his_lig ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);

CREATE TABLE neighbors1925_phe_ion AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE (neighbortype>=1925 AND neighbortype<=1928));
ALTER TABLE neighbors1925_phe_ion ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);
CREATE TABLE neighbors1929_phe_lig AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE neighbortype=1929 OR neighbortype=1930);
ALTER TABLE neighbors1929_phe_lig ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);
CREATE TABLE neighbors2020_tyr_tyr AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance FROM neighbors WHERE neighbortype=2020);

CREATE TABLE neighbors2025_tyr_ion AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE (neighbortype>=2025 AND neighbortype<=2028));
ALTER TABLE neighbors2025_tyr_ion ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);
CREATE TABLE neighbors2029_tyr_lig AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE neighbortype=2029 OR neighbortype=2030);
ALTER TABLE neighbors2029_tyr_lig ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);

CREATE TABLE neighbors2125_trp_ion AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE (neighbortype>=2125 AND neighbortype<=2128));
ALTER TABLE neighbors2125_trp_ion ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);
CREATE TABLE neighbors2129_trp_lig AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE neighbortype=2129 OR neighbortype=2130);
ALTER TABLE neighbors2129_trp_lig ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);

CREATE TABLE neighbors2225_all_ion AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_a, resname_b FROM neighbors WHERE neighbortype<2300 AND neighbortype%100>=25 AND neighbortype%100<=28);
ALTER TABLE neighbors2225_all_ion ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);
CREATE TABLE neighbors2229_all_lig AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_a, resname_b FROM neighbors WHERE neighbortype<2300 AND neighbortype%100>=29 AND neighbortype%100<=30);
ALTER TABLE neighbors2229_all_lig ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);

CREATE TABLE neighbors2325_dna_ion AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_a, resname_b FROM neighbors WHERE (neighbortype>=2325 AND neighbortype<=2328));
ALTER TABLE neighbors2325_dna_ion ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);
CREATE TABLE neighbors2329_dna_lig AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_a, resname_b FROM neighbors WHERE neighbortype=2329 OR neighbortype=2330);
ALTER TABLE neighbors2329_dna_lig ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);

CREATE TABLE neighbors2425_wat_ion AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE (neighbortype>=2425 AND neighbortype<=2428));
ALTER TABLE neighbors2425_wat_ion ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);
CREATE TABLE neighbors2429_wat_lig AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b FROM neighbors WHERE neighbortype=2429 OR neighbortype=2430);
ALTER TABLE neighbors2429_wat_lig ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);

CREATE TABLE neighbors2525_ion_ion AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_a, resname_b FROM neighbors WHERE (neighbortype>=2525 AND neighbortype<=2528) OR (neighbortype>=2625 AND neighbortype<=2628) OR (neighbortype>=2725 AND neighbortype<=2728) OR (neighbortype>=2825 AND neighbortype<=2828));
ALTER TABLE neighbors2525_ion_ion ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);
CREATE TABLE neighbors2529_ion_lig AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_a, resname_b FROM neighbors WHERE neighbortype=2529 OR neighbortype=2629 OR neighbortype=2729 OR neighbortype=2829 OR neighbortype=2530 OR neighbortype=2630 OR neighbortype=2730 OR neighbortype=2830);
ALTER TABLE neighbors2529_ion_lig ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);
CREATE TABLE neighbors2929_lig_lig AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_a, resname_b FROM neighbors WHERE neighbortype=2929 OR neighbortype=3029 OR neighbortype=2930 OR neighbortype=3030);
ALTER TABLE neighbors2929_lig_lig ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);

