<!DOCTYPE html>
<html lang="en">
  <head>
    <title>
      <?php
        echo "Check My Metal Server";
        // TODO i dont know what belows do
        // if ($title_for_layout != "Home") echo " - $title_for_layout";
      ?>
    </title>

    <?php
        //TODO i dont know what belows do
        // include(UNITRACK . '/views/elements/unitrack_layout_pragmas.ctp');


        echo $this->Html->meta('icon');
        //TODO i dont know hw
        // if(isset($javascript)) {
        //     include(UNITRACK.'/views/elements/unitrack_layout_js_libs.ctp');
        // 	echo $javascript->link('csgid.js')."\n";
        //     echo $html->script('csgid-ga.js')."\n";
        //     include(UNITRACK.'/views/elements/unitrack_layout_js_by_action.ctp');
        // }
    ?>

    <!-- Latest compiled and minified CSS -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css" integrity="sha384-1q8mTJOASx8j1Au+a5WDVnPi2lkFfwwEAa8hDDdjZlpLegxhjVME1fgjWPGmkzs7" crossorigin="anonymous">
    <!-- Latest compiled and minified JavaScript -->
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/js/bootstrap.min.js" integrity="sha384-0mSbJDEHialfmuBBQP6A4Qrprq5OVfW37PRR3j5ELqxss1yVqOtnepnHVP9aJ7xS" crossorigin="anonymous"></script>

    <?php
        // Main CSGID CSS file
        echo $this->Html->css('csgid');

        echo "<!--[if IE]>";
        echo $this->Html->css('csgid_ie');
        echo "<!--[if IE 6]>";
        echo "<link rel='stylesheet' href='/css/inc/screennings/ie6style.css' type='text/css' />";
        echo "<![endif]-->";
        echo "<![endif]-->";

        //TODO i dont know what belows do
        // include(UNITRACK.'/views/elements/unitrack_layout_css_by_action.ctp');
        // echo $scripts_for_layout;
    ?>

  </head>
  <body>

    <!-- Horizontal navbar -->
    <nav class="navbar navbar-default navbar-fixed-top">
        <div class="container-fluid">
            <!-- Brand and toggle get grouped for better mobile display -->
            <div class="navbar-header">
              <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#bs-example-navbar-collapse-1" aria-expanded="false">
                <span class="sr-only">Toggle navigation</span>
                <span class="icon-bar"></span>
                <span class="icon-bar"></span>
                <span class="icon-bar"></span>
              </button>
            </div>

            <H3 style="text-align: left">CheckMyMetal (CMM): Metal Binding Site Validation Server </H3>
            <!-- Collect the nav links, forms, and other content for toggling -->
            </div><!-- /.navbar-collapse -->
          </div><!-- /.container-fluid -->
    </nav>
    <!-- End of the horizontal navbar -->

    <!-- Website alerts, content and footer -->
    <div class="nopadding footerless-length" style="width: 100%;">
      <!-- Website alerts -->
      <div class="row content">
          <div class="col-md-4">
              <?php
              // quick way to put an alert message at the top of the page, if needed
              $dberror = false;
              if ($dberror) {
              ?>
              <style>
              div.alert {
                  font-weight: bold;
                  font-size: large;
                  padding: 0.3em;
                  border-style: solid;
                  border-width: 1px;
                  background: #ffcccc;
              }
              </style>
              <div class="alert">ALERT: The database used to generate data on this site is temporarily down. We are working to solve the problem ASAP. We apologize for the inconvenience.</div>
              <?php
              }
              ?>
          </div>
      </div>
      <!-- End of the website alerts -->


      <div class="row content-row fullscreen-length background">
        <!-- Vertical navbar -->
        <!-- End of the vertical navbar -->

        <!-- Website content -->
        <div class="col-xs-8 col-sm-8 col-md-9 col-lg-10 nopadding fullscreen-length background">
            <div class="panel panel-default fullscreen-length">
                <div class="panel-body">
                    <?php

                    //TODO check if this is correct
                    //because I am commenting this out and leaving only first outcome from if statemnt

                    // if ($session->check('Message.flash')) {
                    //     // echo '<div class="alert alert-success" role="alert">';
                    //     echo $session->flash();
                    //     // echo '</div>';
                    // }
                    // if ($session->check('Message.auth')) {
                    //     //echo '<div class="alert alert-success" role="alert">';
                    //     echo $session->flash('auth');
                    //     echo '</div>';
                    // }

                    echo $this->Flash->render();
                    echo $this->fetch('content');
                    ### Website content ###
                    //TODO i dont know from where it is
                    // echo $content_for_layout;
                    ?>
                </div>
            </div>
        </div>
        <div style="clear: both;"></div>
        <footer class="panel-footer text-center" style="background: #888888;">
          <span>For any help please contact <?=$this->Html->link('support@csgid.org', 'mailto:support@csgid.org')?>.</span>
        </footer>
        <!-- End of the website content -->
        <iframe name='plogout' id='plogout' style="display:none;"></iframe>
        <script type="text/javascript">

        function logout(){
            document.getElementById('plogout').src = 'http://olenka.med.virginia.edu/psi/users/logout/';
            setTimeout(logout_redirect, 1000);
        }

        function logout_redirect(){
          window.location = <?php echo '\'http://'.$_SERVER['SERVER_NAME'].$this->Url->webroot.'users/logout\'';?>
        }
        </script>
    </div>
  </div>
  </body>
</html>

<?php
  //todo IDK
  // echo $this->element('sql_dump');
?>
