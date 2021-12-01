<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<!-- <html><head> 
  <title>Classification of Mg2+ binding sites in RNA crystal structures: Center for Structural Genomics of Infectious Diseases</title>
  <link href="csgid.css" rel="stylesheet" type="text/css" media="all"> 
  <style>
    div#a { background-image:none; }
    content { background-image:none; }
    body  { background-image:url(../img/csgid.png); }
  </style>
</head><body style="background-image:none">
<div id="a" style="background-image:none"> -->

<?php
function format_sts_str($sts) {
  $search  = array('cis', 'trans', 'fac', 'mer', 'OP', 'OR', 'OB', 'NB', 'PO', 'BO', 'RO');
  $replace = array('<i>cis</i>', '<i>trans</i>', '<i>fac</i>', '<i>mer</i>', 
                   'O<sub>P</sub>', 'O<sub>R</sub>', 'O<sub>B</sub>', 'N<sub>B</sub>', 'P<sub>out</sub>', 'B<sub>out</sub>', 'R<sub>out</sub>');
  return str_replace($search, $replace, $sts);
}

function output_summary_header() {
  echo "<tr> <!--<th>STID **</th>--> <th align=\"center\">Site type *</th> <th>Number of sites</th> </tr>";
}

function other_site_type_text($stid) {
  if    ($stid==99999) { return "Mg<sup>2+</sup> not bound by RNA"; }
  elseif($stid==19999) { return "other RNA-inner types"; }
  elseif($stid==29999) { return "other RNA-outer types"; }
  elseif($stid==30000) { return "Mg<sup>2+</sup> bound by non-RNA"; }
  elseif($stid==40000) { return "poly-nuclear Mg<sup>2+</sup> site"; }
  else                 { return "undefined text in other_site_type_text"; }
}

// var_dump($_REQUEST);

if(!isset($_REQUEST['submitbtn']) || $_REQUEST['submitbtn']!="Search") {
  $bench_link="/metalnas/index/"; $full_link="/metalnas/index/all/";
  if($summary<=0) { $bench_link.="$temp_id/"; $full_link.="$temp_id/"; } ;
  if ($bench==0) { $rootpath="/metalnas/index/all/"; $benchword="total";
    $switch_phrase="in the full dataset (".$html->link("switch to benchmark dataset", "$bench_link").")";
  } elseif ($bench==1) { $rootpath="/metalnas/index/"; $benchword="benchmark";
    $switch_phrase="in the benchmark dataset (".$html->link("switch to full dataset", "$full_link").")";
  } elseif ($bench==-1) { $rootpath="/metalnas/index/ful/"; $benchword="total";
    $switch_phrase=$html->link("switch to benchmark dataset", "$bench_link")." | ".$html->link("switch to full dataset", "$full_link");
  }
  $header0 = "<div id=\"home-anchor\" style=\"background-image:none;\">";
  if($summary!=1) {
    $header0.= $html->link("Back to Classification Home", $rootpath)."<br>";
  }
  if($summary==0) {
    $header0.= "<br><br><H1 style=\"text-align: center; color: black\"><br><br>Site type: ";
    if($temp_id==19999 or $temp_id>=29999) {
      $header0.= other_site_type_text($temp_id);
    } else {
      $header0.= format_sts_str($rep_site_type);
    }
    $header0.="</H1>";
  } elseif($summary==-1) {
    $header0.= "<H2 style=\"text-align: center; color: black\">List of Mg<sup>2+</sup> binding sites in structure $temp_id</H2>";
  } else {
    $header0.= "<H3 style=\"text-align: center; color: black\">Classification of Mg<sup>2+</sup> binding sites in RNA crystal structures";
  # $header0.= "$switch_phrase"
    $header0.= "</H3><br>";
  }
  $header0.= $html->tag('/div');
?>


  <?php if($summary==1) { $RNA_outer=0; $record_counter=0; echo "<table width=\"100%\"><tr><td>$header0</td></tr></table>"; ?>
    <table width="100%"><tr><th align="center">RNA in Mg<sup>2+</sup> inner sphere (RNA-inner)</th>
     <th colspan=2 align="center">RNA in Mg<sup>2+</sup> outer sphere only (RNA-outer)</th></tr><tr><td><table>
    <?php output_summary_header(); ?>
    <?php foreach($data as $stype): ?>
    <?php $sid=$stype['Metalna']['sid']; $record_counter++; ?>
    <?php if(($sid>=20000 and $RNA_outer==0) or $sid==22321) { $RNA_outer=1; ?>
    </table></td><td><table>
    <?php output_summary_header(); ?>
    <?php } ?>
    <tr>
<!--    <td style="padding:2px" align="center"><?php echo $html->link($sid, "$rootpath$sid/"); ?> </td>-->
        <td style="padding:2px" align="center"><?php 
          if($sid==19999 or $sid>=29999) {
            echo $html->link(other_site_type_text($sid), "$rootpath$sid/");
          } else {
            echo format_sts_str($html->link($stype['Metalna']['site_type'], "$rootpath$sid/"));
          } ?></td>
        <td style="padding:2px" align="right"><?php echo $html->link($stype['Metalna']['stype_cnt'], "$rootpath$sid/")."&nbsp;&nbsp;"; ?> </td>
    </tr>
    <?php endforeach; ?>
    </table></td></tr>
  <?php } else { ?>
    <?php 
          $sort_fields = "\"".$paginator->sort('PDB ID', 'pdbid')."\" or \"".$paginator->sort('Mg<sup>2+</sup> ID', 'resseq', array('escape'=>false))."\"";
          if ($summary == -1) {
            $cond = "in the PDB structure <b>$temp_id</b>";
            $sort_fields = "\"".$paginator->sort('Site type', 'sid')."\" or \"".$paginator->sort('Mg<sup>2+</sup> ID', 'resseq', array('escape'=>false))."\"";
          } elseif ($temp_id==19999 or $temp_id>=29999) {
            $cond = "with ".other_site_type_text($temp_id)." in RNA crystal structures";
          } else {
            $cond = "with the site type <b>".format_sts_str($data[0]['Metalna']['site_type'])."</b> in RNA crystal structures";
          } ;
#         if($bench==1) {                               $cond.= " in the benchmark dataset"; }
#         else {                                        $cond.= " in the full dataset"; } ;
    ?>
    <!-- Shows the page numbers -->
    <?php // $header1 = "<br><hr><br>List of all Mg<sup>2+</sup> binding sites in RNA crystal structures ".$switch_phrase."<br>"; ?>
    <!-- prints X of Y, where X is current page and Y is number of pages -->
    <?php /* $header1.= $paginator->counter(array(
    	'format' => 'Page <b>%page%</b> of <b>%pages%</b>,
    		     showing %current% Mg<sup>2+</sup> sites out of <b>%count% '.$benchword.' Mg<sup>2+</sup> sites</b> '.$cond.',
    		     starting on record %start%, ending on %end%'
    )); */ ?>

    <?php
      $header1 = $paginator->counter(array( 'format' => 'List of all %count% Mg<sup>2+</sup> binding sites '.$cond.' '.$switch_phrase.'<br>')); 
      $header1.= "Sites in the table can be ordered by the following fields by clicking the column header: $sort_fields";
    ?>

    <!-- Shows the pages counters, the next and previous links, and the pages -->
    <?php
      $paginator_numbers= $paginator->numbers();
      $header2 = $paginator->counter(array( 'format' => 'Page <b>%page%</b> of <b>%pages%</b>' ));
      if($paginator_numbers!="") {
        $header2.= " | ".$paginator->prev('« Previous ', null, null, array('class' => 'disabled'));
        $header2.= " | ".$paginator->next(' Next »', null, null, array('class' => 'disabled'));
        $header2.= " | ".$paginator_numbers;
      }
    ?>
    <table><tr><td style="padding: 0px"><table width="100%">
    <tr>
      <?php if ($summary == -1) {
              echo "<td align=\"left\">$header0<br><HR><br>$pdbfile_headline$header1<br>$header2</td>";
            } elseif ($summary==0) {
              if($bench==0) {$column_width=4; } else {$column_width=7; }
              echo "<td valign=\"top\">$header0";
              echo "<td width=\"220\" style=\"padding: 0px\" valign=\"middle\"><b>Schematic drawing for site type</b><br><img src=\"$sch_thumbnail\"></td>";
              echo "<td width=\"300\" rowspan=2 align=\"center\" valign=\"middle\" bgcolor=\"#FFEBD7\"><b>Representative site (";
              echo $html->link($rep_pdbid, "$rootpath$rep_pdbid/");
              echo ":";
              $site_link="/metalnas/view/$rep_pdbid/$rep_chainid/$rep_resseq/";
              echo $html->link("$rep_chainid$rep_resseq", $site_link);
              echo ", See in <i>";
              echo $html->link('JSmol',$site_link,array('escape'=>false));
              echo "</i>)</b><br>";
         #    echo "<br>$rep_summary<br>";
              echo "<span id=\"random\" onclick=\"javascript:if (document.getElementById('rep_thumbnail').src.indexOf('$rep_thumbnail')==-1) {document.getElementById('rep_thumbnail').src='$rep_thumbnail';} else {document.getElementById('rep_thumbnail').src='$rep_thumbnail2';}\"><img id=\"rep_thumbnail\" src=\"$rep_thumbnail\"></span></td>";
         #    if($temp_id==19999 or $temp_id>=29999) {
         #      echo other_site_type_text($temp_id);
         #    } else {
         #      echo format_sts_str($rep_site_type);
         #    }
              echo "</tr><tr><td colspan=2 valign=\"bottom\">$header1</td>";
              echo "</tr><tr><td colspan=2>$header2</td><td align=\"center\" bgcolor=\"#FFEBD7\"><b>Click on the image to toggle views</b></td>";
            }
      ?>
    </tr>
    </table></td></tr><tr><td style="padding: 0px">
    <table width="100%">
    <tr><th align="center" colspan=2>Mg<sup>2+</sup> ion</th>
        <th align="center" colspan=2 rowspan=2 valign="middle"><?php if($summary!=-1) {echo "Site type";} else {echo $paginator->sort('Site type', 'sid');}; ?> *</th>
      <?php if($bench==0) { ?>
        <th align="center" colspan=5>Validation parameters</th>
      <?php } else { ?>
        <th align="center" colspan=5>Inner-sphere ligands</th>
        <th align="center" colspan=3>Outer-sphere ligands</th>
      <?php } ?>
    </tr><tr>
        <th align="center"><?php if($summary==-1) {echo "PDB ID";} else {echo $paginator->sort('PDB ID', 'pdbid');}; ?></th>
        <th align="center"><?php echo $paginator->sort('Mg<sup>2+</sup> ID', 'resseq', array('escape'=>false)); ?></th>
<!--       <th align="center"><?php echo $paginator->sort('STID', 'sid'); ?> **</th> -->
<!--       <th align="center" colspan=2><?php if($summary!=-1) {echo "Site type";} else {echo $paginator->sort('Site type', 'sid');}; ?> *</th> -->
      <?php if($bench==0) { ?>
        <th align="center"><?php echo $paginator->sort('CN','cn'); ?></th>
        <th align="center"><i><?php echo $paginator->sort('Pv','pv'); ?></i> <sup>#</sup></th>
        <th align="center"><i><?php echo $paginator->sort('Ps','ps'); ?></i> <sup>#</sup></th>
        <th align="center"><i><?php echo $paginator->sort('Pe','pe'); ?></i> <sup>#</sup></th>
        <th align="center"><?php echo $paginator->sort('benchmark', 'bench'); ?></th>
      <?php } else { ?>
        <th align="center">O<sub>P</sub></th>
        <th align="center">O<sub>R</sub></th>
        <th align="center">O<sub>B</sub>+N<sub>B</sub></th>
        <th align="center">Water</th>
        <th align="center">Other</th>
        <th align="center">P<sub>out</sub></th>
        <th align="center">R<sub>out</sub></th>
        <th align="center">B<sub>out</sub></th>
      <?php } ?>
    </tr>
    <?php foreach($data as $stype): ?>
    <tr>
	<td align="center">
          <?php $pdbid=$stype['Metalna']['pdbid'];
                $chainid=$stype['Metalna']['chainid'];
                $resseq=$stype['Metalna']['resseq'];
                if($summary==-1) {echo $pdbid;} else {echo $html->link($pdbid, "$rootpath$pdbid/");}; ?></td>
	<td align="center"><?php echo $html->link("$chainid$resseq", "/metalnas/view/$pdbid/$chainid/$resseq/", array('class' => 'button', 'target' => "_$pdbid")); ?> </td>
      <?php $sid=$stype['Metalna']['sid']; ?>
      <?php if($sid==19999 or $sid>=29999) { ?>
        <td align="center" colspan=2><?echo other_site_type_text($sid); ?></td>
      <?php } else { ?>
<!--       <td align="center"><?php echo $html->link($sid, "$rootpath$sid/"); ?></td> -->
        <td align="center" colspan=2><?php 
                if($summary!=-1) {echo format_sts_str($stype['Metalna']['site_type']);} else {echo format_sts_str($html->link($stype['Metalna']['site_type'], "$rootpath$sid/"));}; ?></td>
      <?php } ?>
      <?php if($bench==0) { $cn=$stype['Metalna']['cn']; $bench2=$stype['Metalna']['bench'];
	$pv=sprintf('%6.2f',$stype['Metalna']['pv']);
	$ps=sprintf('%6.2f',$stype['Metalna']['ps']);
	$pe=sprintf('%6.2f',$stype['Metalna']['pe']);
	if($cn>=4 and $cn<=6) {$bg_cn="#DDDDDD";} else {$bg_cn="#FFAAAA";};
	if($pv>=0.50) {$bg_pv="#DDDDDD"; } else {$bg_pv="#FFAAAA";  if($pv<=0) {$pv=0;};  };
	if($ps>=0.50) {$bg_ps="#DDDDDD"; } else {$bg_ps="#FFAAAA";  if($ps<=0) {$ps=0;};  };
	if($pe>=0.50) {$bg_pe="#DDDDDD"; } else {$bg_pe="#FFAAAA";  if($pe<=0) {$pe=0;};  };
	if($bench2) {$bg_bench="#DDDDDD";} else {$bg_bench="#FFAAAA";};
	echo "<td align=\"center\" bgcolor=\"$bg_cn\">$cn</td>";
	echo "<td bgcolor=\"$bg_pv\">&nbsp;$pv</td>";
	echo "<td bgcolor=\"$bg_ps\">&nbsp;$ps</td>";
	echo "<td bgcolor=\"$bg_pe\">&nbsp;$pe</td>";
	echo "<td align=\"center\" bgcolor=\"$bg_bench\">$bench2</td>";
      ?>
      <?php } else { ?>
	<td><?php echo $stype['Metalna']['isp']; ?> </td>
	<td><?php echo $stype['Metalna']['isr']; ?> </td>
	<td><?php echo $stype['Metalna']['isb']; ?> </td>
	<td><?php echo $stype['Metalna']['isw']; ?> </td>
	<td><?php echo $stype['Metalna']['iso']; ?> </td>
	<td><?php echo $stype['Metalna']['osp']; ?> </td>
	<td><?php echo $stype['Metalna']['osr']; ?> </td>
	<td><?php echo $stype['Metalna']['osb']; ?> </td>
      <?php } ?>
    </tr>
    <?php endforeach; ?>
  <?php }?>
</table></td></tr></table>



<?php
  echo $footer;
  echo '<hr><br>Maintained by: Heping Zheng &lt;<a href="mailto:dust@iwonka.med.virginia.edu">dust@iwonka.med.virginia.edu</a>&gt;';
} else {
  echo "<div id='topnav'>".$_REQUEST['pdbid']." submitted..."."</div>";
  echo "<ol>";
  $data = Metalna::query_metalna($_REQUEST['pdbid']);
  echo '<table>';
  for($i=0; $i<count($data); $i++) {
    echo $html->tag('dt');
    echo '<tr>';
    echo '<td>'.$data[$i]['pdbfileid'].'</td>';
    echo '<td>'.$data[$i]['resname_ion'].'</td>';
    echo '<td>'.$data[$i]['distances'].'</td>';
    echo '</tr>';
  }
  echo '</table>';
  echo "</ol>";
}
?>

<!-- </div></body></html> -->
