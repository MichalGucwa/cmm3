DROP TABLE neighbors0122_kno_unk;
DROP TABLE neighbors2225_all_ion;
DROP TABLE neighbors2229_all_lig;
DROP TABLE neighbors2425_wat_ion;
DROP TABLE neighbors2429_wat_lig;
DROP TABLE neighbors2525_ion_ion;
DROP TABLE neighbors2529_ion_lig;
DROP TABLE neighbors2929_lig_lig;

CREATE TABLE neighbors0122_kno_unk AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_a, neighbortype FROM neighbors WHERE neighbortype=122 OR neighbortype=222 OR neighbortype=322 OR neighbortype=422 OR neighbortype=522 OR neighbortype=622 OR neighbortype=722 OR neighbortype=822 OR neighbortype=922 OR neighbortype=1022 OR neighbortype=1122 OR neighbortype=1222 OR neighbortype=1322 OR neighbortype=1422 OR neighbortype=1522 OR neighbortype=1622 OR neighbortype=1722 OR neighbortype=1822 OR neighbortype=1922 OR neighbortype=2022 OR neighbortype=2122);
CREATE TABLE neighbors2225_all_ion AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_a, resname_b, neighbortype FROM neighbors WHERE neighbortype<2300 AND neighbortype%100>=25 AND neighbortype%100<=28);
CREATE TABLE neighbors2229_all_lig AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_a, resname_b, neighbortype FROM neighbors WHERE neighbortype<2300 AND neighbortype%100>=29 AND neighbortype%100<=30);
CREATE TABLE neighbors2425_wat_ion AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b, neighbortype FROM neighbors WHERE (neighbortype>=2425 AND neighbortype<=2428));
CREATE TABLE neighbors2429_wat_lig AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_b, neighbortype FROM neighbors WHERE neighbortype=2429 OR neighbortype=2430);
CREATE TABLE neighbors2525_ion_ion AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_a, resname_b, neighbortype FROM neighbors WHERE (neighbortype>=2525 AND neighbortype<=2528) OR (neighbortype>=2625 AND neighbortype<=2628) OR (neighbortype>=2725 AND neighbortype<=2728) OR (neighbortype>=2825 AND neighbortype<=2828));
CREATE TABLE neighbors2529_ion_lig AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_a, resname_b, neighbortype FROM neighbors WHERE neighbortype=2529 OR neighbortype=2629 OR neighbortype=2729 OR neighbortype=2829 OR neighbortype=2530 OR neighbortype=2630 OR neighbortype=2730 OR neighbortype=2830);
CREATE TABLE neighbors2929_lig_lig AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, distance, resname_a, resname_b, neighbortype FROM neighbors WHERE neighbortype=2929 OR neighbortype=3029 OR neighbortype=2930 OR neighbortype=3030);
