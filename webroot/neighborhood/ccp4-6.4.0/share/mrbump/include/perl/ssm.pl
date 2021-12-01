#!perl 
#---------------------------------------------------
# WSPerlClient.pl
# 
# Project: MSD API Framework 
# Module:  Perl Client for MSD API Webservice (SOAP) Server 
# 
# SOAP User Layer
# Last updated: 25 February 2004 10:17
# (C) Siamak Sobhany
#---------------------------------------------------
 


use SOAP::Lite;
use IO::File;

my $proxy = $ENV{"http_proxy"};
my $service;

if ($proxy) {
  print "\nUsing proxy server: ".$proxy."\n";
  $service = SOAP::Lite
    ->uri('urn:msd_soap_service')
    ->proxy('http://geoff:cc12345678@www.ebi.ac.uk/msd-srv/msdsoapd',proxy=>['http'=>$proxy]);
} else {
  print "\nNo proxy server set in environment (http_proxy)\n";
  $service = SOAP::Lite
    ->uri('urn:msd_soap_service')
    ->proxy('http://geoff:cc12345678@www.ebi.ac.uk/msd-srv/msdsoapd');
}

 my $sessionid = "MrBUMP"."$ARGV[1]";
 my $connName = 'MyPerlConnection';
 my $queryName1 = 'MyPerlQuery1';
 my $resName1 = 'MyPerlResult1';
 my $queryName2 = 'MyPerlQuery2';
 my $resName2 = 'MyPerlResult2';
 my $buf=50;
 my $ssmQuery = "<SSMInput> <query> <type>PDB entry</type> <pdbcode>$ARGV[0]</pdbcode>".
'</query> <target> <type>PDB archive</type>'.
'</target> <selection> <type>Chain(s)</type>'.
'<chains>*(all)</chains> </selection> <percent1>70</percent1>'.
'<percent2>70</percent2> <sepchains>Yes</sepchains>'.
'<connectivity>Yes</connectivity> <bestmatch>Yes</bestmatch>'.
'<uniquematch>Yes</uniquematch> <precision>Normal</precision>'.
'<sorting>RMSD</sorting> </SSMInput>';

my $sqlSSMQuery = 'select s.target_id from ssm_out_tab s where s.session_id = \''. $sessionid .'\'';

my $sqlQuery = 'select e.entry_id, e.accession_code from entry e, author a '.
 ' where e.res_val <= 2.5 and e.entry_id = a.entry_id '.
 'and a.last_name = \'HENRICK\' and e.accession_code in ( '. $sqlSSMQuery . ')';


## select lower(h.accession_code) from hetgroup h where h.chem_comp_code like 'AL%' 


my $array = [$ssmQuery , $sessionid];
print "\nCalling method: msdSSM()\n";
my $result1 = $service->msdSSM(SOAP::Data->name('numofpars' => 2),
   SOAP::Data->name('inparams' => $array));
unless ($result1->fault) {
  print "\nmsdSSM() called successfully.\n";
  print $result1->result();
}else{
  print join ', ', 
  $result1->faultcode,
  $result1->faultstring;
}
for ($i=1; $i > 0 ; $i++)
  { my $result2 = $service->msdSSMParser(SOAP::Data->name('diyf')->type('xsd:int')->value(1),
   SOAP::Data->name('sessionid')->type('xsd:string')->value($sessionid));
   unless ($result2->fault || ($result2->faultstring != 'Result fille not ready')) {
   $i=-1;
   print $result2->result();
  }else{
   print join ', ', 
   "\nXML File not ready...retry: $i ",
   $result2->faultcode, 
   $result2->faultstring;
   }
   sleep(5);
}
   my $result3 = $service->msdSSMPurge(SOAP::Data->name('sessionid')->type('xsd:string')->value($sessionid));
   unless ($result3->fault) {
   print "\nmsdSSMPurge() called successfully.\n";
   print $result3->result();
  }else{
   print join ', ',
   $result3->faultcode,
   $result3->faultstring;
 }
print "\nCalling method: msdConnect() 1 \n";
my $result1 = $service->msdConnect(SOAP::Data->name('conn-name')->type('xsd:string')->value($connName));

unless ($result1->fault) {
    print "\nmsdConnect() 1 called successfully.\n";
	print $result1->result();
}else{
	print join  ', ', 
	$result1->faultcode, 
    $result1->faultstring;
}
print "\nCalling method: msdResultset() 1\n";
my $result2 = $service->msdResultset(SOAP::Data->name('conn-name')->type('xsd:string')->value($connName),
									 SOAP::Data->name('query-name')->type('xsd:string')->value($queryName1),
									 SOAP::Data->name('res-name')->type('xsd:string')->value($resName1));

unless ($result2->fault) {
    print "\nmsdResultset() 1 called successfully.\n";
	print $result2->result();
}else{
	print join  ', ', 
	$result2->faultcode, 
    $result2->faultstring;
}

print "\nCalling method: msdQuery() 1\n";
my $result3 = $service->msdQuery(SOAP::Data->name('conn-name' => $connName),
					             SOAP::Data->name('query-name'=> $queryName1),
					             SOAP::Data->name('result-name'=> $resName1),
					             SOAP::Data->name('stm'=> $sqlQuery));

unless ($result3->fault) {
    print "\nmsdQuery() 1 called successfully.\n";
	print $result3->result();
}else{
	print join  ', ', 
	$result3->faultcode, 
    $result3->faultstring;
}


print "\nCalling method: msdResultset() 2 \n";
my $result4 = $service->msdResultset(SOAP::Data->name('conn-name')->type('xsd:string')->value($connName),
									 SOAP::Data->name('query-name')->type('xsd:string')->value($queryName2),
									 SOAP::Data->name('res-name')->type('xsd:string')->value($resName2));

unless ($result4->fault) {
    print "\nmsdResultset() 2 called successfully.\n";
    print "\nList of SSM results:\n";
	print $result4->result();
}else{
	print join  ', ', 
	$result4->faultcode, 
    $result4->faultstring;
}

print "\nCalling method: msdQuery() 2\n";
my $result5 = $service->msdQuery(SOAP::Data->name('conn-name' => $connName),
					             SOAP::Data->name('query-name'=> $queryName2),
					             SOAP::Data->name('result-name'=> $resName2),
					             SOAP::Data->name('stm'=> $sqlSSMQuery));

unless ($result5->fault) {
    print "\nmsdQuery() 2 called successfully.\n";
	print $result5->result();
}else{
	print join  ', ', 
	$result5->faultcode, 
    $result5->faultstring;
}


print "\nCalling method: msdExecQuery() 1 \n";
my $result6 = $service->msdExecQuery(SOAP::Data->name('conn-name' => $connName),
					                 SOAP::Data->name('query-name'=> $queryName1),
					                 SOAP::Data->name('result-name'=> $resName1),
					                 SOAP::Data->name('buf'=> $buf));


unless ($result6->fault) {
    print "\nmsdExecQuery() 1 called successfully.\n";
	print $result6->result();

}else{
	print join  ', ', 
	$result6->faultcode, 
    $result6->faultstring;
}

print "\nCalling method: msdExecQuery() 2 \n";
my $result7 = $service->msdExecQuery(SOAP::Data->name('conn-name' => $connName),
					                 SOAP::Data->name('query-name'=> $queryName2),
					                 SOAP::Data->name('result-name'=> $resName2),
					                 SOAP::Data->name('buf'=> $buf));


unless ($result7->fault) {
    print "\nmsdExecQuery() 2 called successfully.\n";
	print $result7->result();

}else{
	print join  ', ', 
	$result7->faultcode, 
    $result7->faultstring;
}

print "\nCalling method: msdGetResultSet() 1 \n";
my $result8 = $service->msdGetResultSet(SOAP::Data->name('conn-name' => $connName),
					                 SOAP::Data->name('query-name'=> $queryName1),
					                 SOAP::Data->name('result-name'=> $resName1));
$col =1;
unless ($result8->fault) {
    print "\nmsdGetResultSet() 1 called successfully.\n";
	#print $result5->result();
	my $dataSet = $result8->result();
	$record_set = $dataSet;
	
	foreach  my $rec (@$record_set) {
     $row=1;
	 foreach my $val (@$rec) {
           print "Column ", $col ," Row: ", $row, " value = " ;
		   print $val, "\n"; 
      
	  $row++;
     }
	 $col++;
    }

}else{
	print join  ', ', 
	$result8->faultcode, 
    $result8->faultstring;
}

print "\nCalling method: msdGetResultSet() 2 \n";
my $result9 = $service->msdGetResultSet(SOAP::Data->name('conn-name' => $connName),
					                 SOAP::Data->name('query-name'=> $queryName2),
					                 SOAP::Data->name('result-name'=> $resName2));
$col =1;
unless ($result9->fault) {
    print "\nmsdGetResultSet() 2 called successfully.\n";
	#print $result9->result();
	my $dataSet = $result9->result();
	$record_set = $dataSet;
	
	foreach  my $rec (@$record_set) {
     $row=1;
	 foreach my $val (@$rec) {
           print "Column ", $col ," Row: ", $row, " value = " ;
		   print $val, "\n"; 
      
	  $row++;
     }
	 $col++;
    }

}else{
	print join  ', ', 
	$result9->faultcode, 
    $result9->faultstring;
}


print "\nCalling method: msdEndQueryPack() 1\n";
my $result10 = $service->msdEndQueryPack(SOAP::Data->name('query-name')->type('xsd:string')->value($queryName1),
								 SOAP::Data->name('result-name')->type('xsd:string')->value($resName1));

unless ($result10->fault) {
    print "\nmsdEndQueryPack() 1 called successfully.\n";
	print $result10->result();
}else{
	print join  ', ', 
	$result10->faultcode, 
    $result10->faultstring;
}

print "\nCalling method: msdEndQueryPack() 2\n";
my $result11 = $service->msdEndQueryPack(SOAP::Data->name('query-name')->type('xsd:string')->value($queryName2),
								 SOAP::Data->name('result-name')->type('xsd:string')->value($resName2));

unless ($result11->fault) {
    print "\nmsdEndQueryPack() 2 called successfully.\n";
	print $result11->result();
}else{
	print join  ', ', 
	$result11->faultcode, 
    $result11->faultstring;
}


print "\nCalling method: msdEndConnect() \n";
my $result12 = $service->msdEndConnect(SOAP::Data->name('conn-name')->type('xsd:string')->value($connName));

unless ($result12->fault) {
    print "\nmsdEndConnect()  called successfully.\n";
	print $result12->result();
}else{
	print join  ', ', 
	$result12->faultcode, 
    $result12->faultstring;
}

print "\nCalling method: msdEndSession() \n";
my $result13 = $service->msdEndSession(SOAP::Data->name('sessionid')->type('xsd:string')->value($sessionid));

unless ($result13->fault) {
    print "\nmsdEndSession()  called successfully.\n";
	print $result13->result();
}else{
	print join  ', ', 
	$result13->faultcode, 
    $result13->faultstring;
}

############## Google api calls

#my $key='fGeTRvdQFHLfeNjYlcoRt13M6mKs4SgT';
#my $query="KIM HENRICK and 9xia";
#my $googleSearch = SOAP::Lite -> service("http://api.google.com/GoogleSearch.wsdl"); #"file:googleapi/GoogleSearch.wsdl"
#my $result14 = $googleSearch -> doGoogleSearch($key, $query, 0, 10, "false", "", "false", "", "latin1", "latin1");

#print"Google API search:\n";
#print "\nAbout ", $result14->{'estimatedTotalResultsCount'}, " results.\n";
#print "\n";
#my $resEls = $result14->{'resultElements'};
#foreach  my $resEl (@$resEls) {
#		   print "\nTitle:\n",$resEl->{'title'}, "\n";
#		   print "URL:\n",$resEl->{'URL'}," \n";
#}
#my $result15 = $googleSearch -> doSpellingSuggestion($key, $query);
#print "\nDid you mean: \'", $result15 , "\'?\n";

