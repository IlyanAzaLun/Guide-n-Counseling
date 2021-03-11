<!-- content.php -->
<!-- Data Users -->
<?php 
if (sizeof($data['users']) > 0) {
	foreach ($data['users'] as $key) { 
	   if($key['class']==="staff"){
	      view_ribbon('bg-danger', 'Staff', $key);
	   }elseif($key['class']==="0"){
	      view_ribbon('bg-warning', 'New User', $key);
	   }else{
	      view_ribbon('bg-info', 'Teacher', $key);
	   }
	}
}else{
	?>
  <div class="col col-md-4 offset-md-4 d-flex align-items-stretch">
	  <h3><i class="fas fa-exclamation-triangle text-warning"></i> Oops! Page not found.</h3>
  </div>
	<?
}

function view_ribbon($color, $text, $key){ ?>
    <div class="col-12 col-sm-6 col-md-4 d-flex align-items-stretch">
      <div class="card bg-light">
        <!-- RIBBON -->
        <div class="ribbon-wrapper ribbon-lg">
          <div class="ribbon <?=$color?>">
            <?=$text?>
          </div>
        </div>
        <!-- RIBBON -->
        <div class="card-header text-muted border-bottom-0"><b>NIP : </b><?=$key['NIP']?></div>
        <div class="card-body pt-0">
          <div class="row">
            <div class="col-7">
              <h2 class="lead"><b><?=$key['homeroom_teacher']?></b></h2>
              <p class="text-muted text-xs">Homeroom teacher class: <b><?=$key['class']?></b></p>
              <!-- <p class="text-muted text-sm"><b>About: </b> Web Designer / UX / Graphic Artist / Coffee Lover </p> -->
            </div>
            <div class="col-5 text-center">
              <img src="<?=BASEURL?>/_assets/dist/img/default-150x150.png" alt="user-avatar" class="img-circle img-fluid">
            </div>
          </div>
        </div>
        <div class="card-footer">
          <div class="text-right">
            <? if ($_SESSION['user']['class'] === "1"): ?>
            <a href="<?=BASEURL?>/users/edit/<?=$key['NIP']?>" class="btn btn-sm bg-teal">
              <i class="fas fa-cog"></i>
            </a>
            <? endif ?>
            
            <a href="<?=BASEURL?>/users/profile/<?=$key['NIP']?>" class="btn btn-sm btn-primary">
              <i class="fas fa-user"></i> View Profile
            </a>
          </div>
        </div>
      </div>
    </div>
  <?}
?>
<!-- Data Users -->