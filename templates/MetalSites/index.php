<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html lang="en" dir="ltr">
  <head>
    <meta charset="utf-8">
    <title>Check My Metal</title>
  </head>
  <body>
    <?php
      function tutorial_html($pdbid,$form) {
        echo "<td>";
        echo "<a href=\"metal_site_tutorial\"><b>$pdbid</b></a>";
        echo "</td>";
      }

      function example_button($sessionid,$form,$listsite_action,$target = NULL) {
        if(strlen($sessionid)==4) {
          $lower_pdbid=strtolower($sessionid);
          $upper_pdbid=strtoupper($sessionid);
        } else {
          $lower_pdbid=$sessionid;
          $upper_pdbid=$sessionid;
        }
        echo "<td>";
        if ($target != NULL) {
          echo $form->create(null, array('action' => "$listsite_action", 'target' => "$target"));
          $upper_pdbid=strtoupper($target);
        } else {
          echo $form->Create(null, ['url'=>['action'=>$listsite_action], 'type'=>'post']);
        }
        echo '<input type="hidden" name="pdbid" value="'.$lower_pdbid.'">';
        echo '<input type="hidden" name="example" value="1">';
        echo $form->button($upper_pdbid,['name'=>'submitbtn']);
        echo $form->end();
        echo "</td>";
      }

      function stat_button($type,$form) {
          $lower_type=strtolower($type);
          $upper_type=strtoupper($type);
          echo "<td>".$form->Create(null, ['url'=>['action'=>'statistics'], 'type'=>'post']);
          echo '<input type="hidden" name="type" value="'.$lower_type.'">';
          echo '<input type="hidden" name="limit" value="1">';
          echo '<input type="hidden" name="example" value="1">';
          echo $form->button($lower_type,['name'=>'submitbtn']).$form->end()."</td>";
      }
    ?>


    <?php  if(!isset($_REQUEST['submitbtn']) || $_REQUEST['submitbtn']!="Search") {
            //we no longer have jsmol jmol so there is only one option
            $listsite_action = "listsite";
            $calcsite_action = "calcsite";
    ?>
      <div id="home-anchor">
        <!-- //Michal
        //we no longer have jmol or jsmall -->
        <div style="float:left; padding:8px">3D-viewer: <b>NGL</b></div>
        <?php
          $switch_phrase2="";

          if($output_content_type=="html") {$switch_phrase2.="<b><i>HTML</i></b> | ";
          } else {$switch_phrase2.="<i>".$this->Html->link('HTML', [ 'action' => 'index', ''])."</i> | ";};

          if($output_content_type=="refmac")  {$switch_phrase2.="<b><i>REFMAC</i></b> | ";
            $listsite_action = "listsite_refmac"; $calcsite_action = "calcsite_refmac";
          } else {$switch_phrase2.="<i>".$this->Html->link('REFMAC', [ 'action' => 'index', 'refmac'])."</i> | "; };

          if($output_content_type=="csv")  {$switch_phrase2.="<b><i>CSV</i></b> | ";
            $listsite_action = "listsite_csv"; $calcsite_action = "calcsite_csv";
          } else {$switch_phrase2.="<i>".$this->Html->link('CSV', [ 'action' => 'index', 'csv'])."</i> | "; };

          if($output_content_type=="json") {$switch_phrase2.="<b><i>JSON</i></b> | ";
            $listsite_action = "listsite_json"; $calcsite_action = "calcsite_json";
          } else {$switch_phrase2.="<i>".$this->Html->link('JSON', [ 'action' => 'index', 'json'])."</i> | "; };

          if($output_content_type=="xml")  {$switch_phrase2.="<b><i>XML</i></b>";
            $listsite_action = "listsite_xml"; $calcsite_action = "calcsite_xml";
          } else {$switch_phrase2.="<i>".$this->Html->link('XML', [ 'action' => 'index', 'xml'])."</i>"; };

        ?>

        <div style="float:left; padding:8px">Return format selection: (<?=$switch_phrase2?>)</div>

        </div>

        <p></p>
          <table width='650'>
            <?=$this->Html->tableHeaders(['Input PDBID', 'Test Data']);?>
            <tr>
              <td width="420">
                <table>
                  <tr>
                    <td>
                      <?php
                        echo $this->Form->Create(null, ['url'=>['action'=>$listsite_action], 'type'=>'post']);
                        echo $this->Form->control('pdbid',['size'=>5,'label'=>'PDB id:']);
                      ?>
                    </td>
                    <td width="180">
                      <input type="checkbox" name="resolutiondependent" value="1">&nbsp;Low resolution adjustment<br />
                    </td>
                    <td width="60">
                      <input type="hidden" name="example" value="0">
                      <?=$this->Form->button('Search',['name'=>'submitbtn']);?>
                      <?=$this->Form->end();?>
                    </td>
                  </tr>
                </table>
              </td>
              <td>
                <table>
                  <tr>
                    <?php
                      example_button("2fna",$this->Form,$listsite_action);
                      example_button("3eef",$this->Form,$listsite_action);
                      example_button("2xin",$this->Form,$listsite_action);
                      example_button("4ins",$this->Form,$listsite_action);
                    ?>
                  </tr>
                </table>
              </td>
            </tr>
          </table>

          <p></p>
          <table width="650">
            <?=$this->Html->tableHeaders(['Upload your own coordinate file in PDB format','Sample coordinates']);?>
            <tr>
              <td>
                <table>
                  <tr>
                    <td width="350">
                      <?=$this->Form->Create(null, ['url'=>['action'=>$calcsite_action], 'type'=>'file']);?>
                      PDB file:
                      <?=$this->Form->control('pdbfile', ['type' => 'file', 'label'=>false]);?>
                      2fo-fc file (*.dsn6):
                      <?=$this->Form->control('densityfile_2fo', ['type' => 'file', 'label'=>false]);?>
                      fo-fc file (*.dsn6):
                      <?=$this->Form->control('densityfile_fo', ['type' => 'file', 'label'=>false]);?>
                    </td>
                    <td width="60">
                      <?=$this->Form->button('Upload',['name'=>'submitbtn']);?>
                      <?=$this->Form->end();?>
                    </td>
                  </tr>
                </table>
              </td>
              <td>
                <table>
                  <tr>
                    <td width="90">
                      <center><a target="example" href="/ms_ext/examples/">Example files</a></center>
                    </td>
                    <td width="60">
                      <center><a target="example" href="/ms_ext/examples/CMM-rerefined-examples.tar.gz">(Download)</a></center>
                    </td>
                  </tr>
                </table>
              </td>
            </tr>
          </table>


          <!-- TODO I should do make it work, it not work bcs there is no query in database in index controller -->
          <p>
          <table width="650">
          <tr><td><h4>
          CMM has validated
          <font color="blue"><?php echo $index_stat[0][0]['stat_pdbids']; ?></font>
          PDB structures and
          <font color="blue"><?php echo $index_stat[0][0]['stat_structures']-$index_stat[0][0]['stat_pdbids']; ?></font>
          uploaded structures submitted by
          <font color="blue"><?php echo $index_stat[0][0]['stat_users']; ?></font>
          users from
          <font color="blue"><?php echo $index_stat[0][0]['stat_countries']; ?></font>
          countries since June, 2012
          </h4></td></tr>
          </table>



          <p>
          <table width="650">
          <tr><td colspan="2">The CMM server is developed in Wladek Minor's lab.</td</tr>
          <tr><td colspan="2">
          <b>Citing CheckMyMetal (CMM):</b><br>
          1. <a target="new" href="https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6235626/"><b>Characterizing metal-binding sites in proteins with X-ray crystallography.</b> Handing KB, Niedzialkowska E, Shabalin IG, Kuhn ML, Zheng H, Minor W (2018) <I>Nat Protocols</I>, <I>13</I>, 1062-1090</a><br><br>

          2. <a target="new" href="http://journals.iucr.org/d/issues/2017/03/00/ba5266/index.html"><b>CheckMyMetal: a macromolecular metal-binding validation tool.</b> Zheng,H., Cooper,D.R., Porebski,P.J., Shabalin,I.G., Handing,K.B., Minor,W. (2017) <I>Acta crystallographica. Section D, Structural biology</I>, <I>73</I>, 223-233.</a><br><br>
          3. <a target="new" href="http://www.ncbi.nlm.nih.gov/pubmed/24356774"><b>Validation of metal-binding sites in macromolecular structures with the CheckMyMetal web server.</b> Zheng,H., Chordia,M.D., Cooper,D.R., Chruszcz,M., M&uuml;ller,P., Sheldrick,G.M., Minor,W. (2014) <I>Nature Protocols</I>, <I>9(1)</I>, 156-70.</a>
          </td></tr>
          <tr><td colspan="2">
          The service is based on several well-established concepts reported previously: bond valence (1), VECSUM (2), metal binding sites (3), coordination geometries (4), assignment of sodium versus water (5), metal binding  environment (6) in protein structures. We thankfully acknowledge their important contributions. The list presented here may not be complete and suggestion for any additional references are appreicated.</td></tr>

          <tr>
          <td>1</td><td><a target="new" href="http://www.ncbi.nlm.nih.gov/pmc/articles/pmid/19728716">Brown,I.D. (2009) <I>Chem. Rev.</I>, <I>109</I>, 6858-6919.<br>
                        <b>Recent developments in the methods and applications of the bond valence model.</b>
          </a></td></tr><tr>
          <td>2</td><td><a target="new" href="http://www.ncbi.nlm.nih.gov/pubmed/12499536">M&uuml;ller,P. et al. (2003) <I>Acta Crystallogr. D Biol. Crystallogr.</I>, <I>59</I>, 32-37.<br>
                        <b>Is the bond-valence method able to identify metal atoms in protein structures?</b>
          </a></td></tr><tr>
          <td>3</td><td><a target="new" href="http://dx.doi.org/10.1080/0889311X.2010.485616">Harding,M.M. et al. (2010) <I>Cryst. Rev.</I>, <I>16</I>, 247-302.<br>
                        <b>Metals in protein structures: a review of their principal features.</b>
          </a></td></tr><tr>
          <td>4</td><td><a target="new" href="http://www.ncbi.nlm.nih.gov/pubmed/19708219">Kuppuraj,G. et al. (2009) <I>J. Phys. Chem. B</I>, <I>113</I>, 2952-2960.<br>
                        <b>Factors governing metal-ligand distances and coordination geometries of metal complexes.</b>
          </a></td></tr><tr>
          <td>5</td><td><a target="new" href="http://www.ncbi.nlm.nih.gov/pmc/articles/pmid/18614239">Nayal,M. and Di Cera,E. (1996) <I>J. Mol. Biol.</I>, <I>256</I>, 228-234.<br>
                        <b>Valence screening of water in protein crystals reveals potential Na+ binding sites.</b>
          </a></td></tr><tr>
          <td>6</td><td><a target="new" href="http://www.ncbi.nlm.nih.gov/pmc/articles/pmid/18614239">Zheng,H. et al. (2008) <I>J. Inorg. Biochem.</I>, <I>102</I>, 1765-1776.<br>
          	      <b>Data mining of metal ion environments present in protein structures.</b>
          </a></td></tr>
          </table>




          <!-- start zabazwy -->
          <p></p>
          <table width="650">
            <tr>
              <th colspan="2">
                Contact Us
              </th>
            </tr>
            <tr>
              <td width="120">
                <b>Problem report</b>
              </td>
              <td width="200">
                <a href="#bug-report-anchor">See below &dArr;</a>
              </td>
            </tr>
            <tr>
              <td width="120">
                <b>Bulletin board</b>
              </td>
              <td width="200">
                Under construction
              </td>
            </tr>
            <tr>
              <td width="120">
                <b>Model request</b>
              </td>
              <td width="200">
                <a href=\"mailto:dust@iwonka.med.virginia.edu\">Emails</a> are usually answered within 3 business days
              </td>
            </tr>
          </table>

          <?php
          $wladek=0;
          if(preg_match('/^128\.143\.(16|44)\./',$_SERVER['REMOTE_ADDR']) or preg_match('/^172.26.11.206/',$_SERVER['REMOTE_ADDR']) or preg_match('/^127.0.0.1/',$_SERVER['REMOTE_ADDR'])) {
            $wladek=1;
          }
          if($wladek) { ?>

            <p></p>
            <table width="650">
              <?=$this->Html->tableHeaders(['Usage stat (Internal, invisible outside Minor lab)','Quick stat ('.$_SERVER['REMOTE_ADDR'].')']);?>
              <tr>
                <td>
                  <table>
                    <tr>
                      <td>
                        <?php
                          echo $this->Form->Create(null, ['url'=>['action'=>'statistics'], 'type'=>'post']);
                          $options=[
                            'users'       =>'Users',
                            'entries'     =>'Entries',
                            'comments'    =>'Comments',
                            'stalkers'    =>'Stalkers',
                            'visitors'    =>'Visitors',
                            'browsers'    =>'Browsers',
                            'systems'     =>'Operating Systems'];
                          echo $this->Form->select('type', $options,['label'=>'']);
                        ?>
                      </td>
                      <td>
                        <?php
                          $options=[
                            '1'=>'of all time',
                            '2'=>'last 365 days',
                            '3'=>'last 30 days',
                            '4'=>'last 7 days',
                            '5'=>'yesterday',
                            '6'=>'today'
                          ];
                          echo $this->Form->select('limit', $options,['label'=>'']);
                        ?>

                      </td>
                      <input type="hidden" name="example" value="0">
                      <td>
                        <?=$this->Form->button('Stat',['name'=>'submitbtn']);?>
                        <?=$this->Form->end();?>
                      </td>
                    </tr>
                  </table>
                </td>
                <td>
                  <table>
                    <tr>
                      <?php
                        stat_button("Users",$this->Form);
                        stat_button("Entries",$this->Form);
                        stat_button("Stalkers",$this->Form);
                      ?>
                    </tr>
                  </table>
                </td>
              </tr>
            </table>

          <?php } ?>

          <BR><HR><BR>
          <div id="bug-report-anchor"></div>
          <H3 style="text-align: left">Question, feedback or bug report</H3>

          <p></p>

          <table width="650">
            <?=$this->Html->tableHeaders(['Track previously submitted request by ticket #']);?>
            <tr>
              <td>
                <table>
                  <tr>
                    <td width="150">
                      <?=$this->Form->Create(null, ['url'=>['action'=>'bugreport'], 'type'=>'post']);?>
                      <b>Ticket #:&nbsp;&nbsp;</b>
                      <?=$this->Form->input('comment',['size'=>'6','label'=>'Ticket #:&nbsp;&nbsp;'])?>
                    </td>
                    <input type="hidden" name="track" value="1">
                    <td width="60">
                      <?=$this->Form->button('Track',['name'=>'submitbtn']);?>
                      <?=$this->Form->end();?>
                    </td>
                    <td>
                      <a href="#home-anchor">CMM Home &uArr;</a>
                    </td>
                  </tr>
                </table>
              </td>
            </tr>
          </table>

          <p></p>
          <LI>Use the following form to ask a question, report bug or request new feature (question may go to server FAQ after answered):
          <p></p>
          <table width="650">
            <?=$this->Html->tableHeaders(['Firstname','Lastname','Affiliation','']);?>
            <?=$this->Form->Create(null, ['url'=>['action'=>'bugreport'], 'type'=>'file']);?>
            <tr>
              <td>
                <?=$this->Form->input('firstname', array('size'=>'11', 'label'=>''))?>
              </td>
              <td>
                <?=$this->Form->input('lasname', array('size'=>'11', 'label'=>''))?>
              </td>
              <td colspan="1">
                <b>Institution:&nbsp;&nbsp;</b>
                <?=$this->Form->input('institution', array('size'=>'11', 'label'=>'Institution: '))?>
              </td>
              <td>
                <?php
                  $options=[
                    'US'=>'United States',
                    'AF'=>'Africa',
                    'AS'=>'Asia',
                    'CA'=>'Canada',
                    'EU'=>'Europe',
                    'MX'=>'Mexico',
                    'OC'=>'Oceania',
                    'SA'=>'South America'
                  ];
                  echo $this->Form->select('area', $options,['label'=>'']);
                ?>
              </td>
            </tr>
            <tr>
              <td colspan="2">
                <b>Email:&nbsp;&nbsp;</b>
                <?=$this->Form->input('email', array('size'=>'21', 'label'=>'Email:&nbsp;&nbsp;'))?>
              </td>
              <td>
                <b>Request:&nbsp;&nbsp;</b>
                <?php
                  $options=[
                    '1'=>'question',
                    '2'=>'bug',
                    '3'=>'feature',
                    '4'=>'suggestion',
                    '5'=>'feedback',
                    '7'=>'like',
                    '8'=>'dislike',
                    '9'=>'other comment'
                  ];
                  echo $this->Form->select('type', $options,['label'=>'Request: ']);
                ?>
              </td>
              <td>
                <?=$this->Form->checkbox('anonymous', ['label'=>' anonymous','value'=>'0']);?>
                &nbsp;&nbsp;anonymous
              </td>
            </tr>
            <tr>
              <td colspan="4", align='center'>
                <?=$this->Form->input('comment',array('label'=>'','type'=>'textarea','cols'=>'72','rows'=>'8'))?>
              </td>
            </tr>
            <tr>
              <td colspan="3">
                Screenshot or attachment:
                <?=$this->Form->file('screenshot')?>
              </td>
              <input type="hidden" name="track" value="0">
              <td>
                <?=$this->Form->button('Report',['name'=>'submitbtn']);?>
                <?=$this->Form->end();?>
              </td>
            </tr>
          </table>

          <!-- TODO check divs -->

          <p>
          <LI>Maintained by: Heping Zheng &lt;<a href="mailto:dust@iwonka.med.virginia.edu">dust@iwonka.med.virginia.edu</a>&gt;


    <?php } else {?>
        <div id='topnav'><?=$_REQUEST['pdbid']?> submitted...</div>
        <ol>
        <!-- TODO this below -->
        <?php //$data = MetalSite::query_metal_site($_REQUEST['pdbid']); ?>
        <table>
          <?php for($i=0; $i<count($data); $i++) { ?>
            <dt>
              <tr>
                <td>
                  <?=$data[$i]['pdbfileid']?>
                </td>
                <td>
                  <?=$data[$i]['resname_ion']?>
                </td>
                <td>
                  <?=$data[$i]['distances']?>
                </td>
              </tr>
            </dt>
          <?php } ?>
        </table>
      </ol>
    <?php }?>


  </body>
</html>
