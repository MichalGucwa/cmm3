# MJH + PE: nawk script
#
#	Compare 2 files that have been lsq fitted.  
#	It does a comparion for residues with the same 
#	residue name, residue number and chain identifier.
# 
BEGIN { if (file1=="")file1="/y/people/emsley/awk/mine.pdb"
	if (file2=="")file2="/y/people/emsley/awk/1hho.pdb"
	print "file 1 =",file1," file2 =",file2
	readmol(file1)			# read file 1
	readmol(file2)			# read file 2
 	for ( i in res )
		check(i)		# check the atoms
}
function dist(a,b,c,d,e,f,ds){
	ds=(x[a,b,c]-x[d,e,f])**2+(y[a,b,c]-y[d,e,f])**2+(z[a,b,c]-z[d,e,f])**2
	return sqrt(ds)
}
function addatom(m,r,at){
	x[m,r,at]=$7; y[m,r,at]=$8; z[m,r,at]=$9 
}
function readmol(m){
	mol++
	while(getline < m > 0 ) {
		if ($1 == "ATOM"){
			if (($4=="GLU" && $3 ~ "OE[12]")||
			    ($4=="VAL" && $3 ~ "CG[12]")||
			    ($4=="LEU" && $3 ~ "CE[12]")||
			    ($4=="PHE" && $3 ~ "CE[12]")||
			    ($4=="ASN" && $3 ~ "[NO]G[12]")||
			    ($4=="HIS" && $3 ~ "[NC]G[12]")||
			    ($4=="TYR" && $3 ~ "CE[12]")){
				id=$4" "$5" "$6
				res[id]++
				if ($3 ~ "1" ) { 
					addatom(mol,id,1)
 				} else {
					addatom(mol,id,2)
				}
			}
		}
	}	
}
function check(j){
	oo=dist(1,j,1,2,j,1); ot=dist(1,j,1,2,j,2)
	to=dist(1,j,2,2,j,1); tt=dist(1,j,2,2,j,2)
	if(oo < ot && tt < to)ss="OK"
	else if(oo > ot && tt > to)ss="## incorrect"
	else ss="hmmm??"
 	printf "%-9s  1-1%5.2f  1-2%5.2f  2-1%5.2f  2-2%5.2f %s\n",
		i,oo,ot,to,tt,ss
}
