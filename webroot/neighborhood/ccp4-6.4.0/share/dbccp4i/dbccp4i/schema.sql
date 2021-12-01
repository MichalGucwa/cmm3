/* Demonstration SQLite database schema for BIOXHIT deliverable
   D5.2.8

   The schema has tables implementing an "extended parallel"
   database intended to mirror the database.def-based db (the
   "Jobs" table) and also describe the data used in the MLPHARE
   task in CCP4i, which holds information about heavy atom
   derivatives (the "Dataset" and "HA" tables).

   CVS_Id: $Id: schema.sql,v 1.3 2008/08/12 10:48:10 pjx Exp $
*/

/* Jobs table

   Records in this table map onto the records in the database.def
   database, and are intended to store additional data items.
   Use of this table is now deprecated.
*/
CREATE TABLE IF NOT EXISTS Jobs (
                   Jobs_Id INTEGER primary key,
                   JobNumber INTEGER,
                   JobQuality VARCHAR(40),
                   UserAgent VARCHAR(40));


/* Dataset table

   Records in this table describe the reflection data and related
   parameters derived from a diffraction experiment.
*/
CREATE TABLE IF NOT EXISTS Dataset (
		      Dataset_Id INTEGER primary key,
		      DatasetName VARCHAR(64) unique not null,
                      MTZfileProject VARCHAR(64) not null,
                      MTZfileName VARCHAR(200) not null,
                      Fmean VARCHAR(30) not null,
                      SigFmean VARCHAR(30) not null,
                      Dano VARCHAR(30),
                      SigDano VARCHAR(30),
                      MTZCrystalName VARCHAR(64),
                      MTZDatasetName VARCHAR(64),
                      CurrentHA INTEGER);

/* Heavy Atom Substructure (HA) table

   Records in this table store information about a heavy atom
   substructure.

   The "CurrentHA" item in the Dataset table refers to the
   HA_Id for a particular record in this table.
*/
CREATE TABLE IF NOT EXISTS HA (
                 HA_Id INTEGER primary key,
                 HAfileProject VARCHAR(64) not null,
                 HAfileName VARCHAR(200) not null,
                 JobNumber VARCHAR(10),
                 DatasetId INTEGER); 
      
	              