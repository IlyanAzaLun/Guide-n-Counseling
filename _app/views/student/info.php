<?php 
function countPersentase($type, $data){
  // return ((int)$data[$type]*100)/((int)$data['total_violation']+(int)$data['total_dutiful']);
  $result = (!empty($data)) ? ((int)$data[$type]*100)/((int)$data['total_violation']+(int)$data['total_dutiful']) : 'Null' ;
  return $result;
}
?>
<section class="content">

  <div class="container-fluid">
    <div class="row">
      <div class="col-3">

        <!-- Profile Image -->
        <div class="card card-primary card-outline">
          <div class="card-body box-profile">
            <div class="text-center">
              <img class="profile-user-img img-fluid img-circle"
              src="<?=BASEURL?>/_assets/dist/img/default-150x150.png"
              alt="User profile picture">
            </div>

            <h3 class="profile-username text-center"><?=$data['student']['fullname']?> <small>(<?=$data['student']['gender']?>)</small></h3>

            <p class="text-muted text-center"><small><b>NISN</b></small>/<small>NISS</small> <b><?=$data['student']['NISN']?></b>/<?=$data['student']['NISS']?></p>

            <h4 class="profile-username text-center">Class: <b><?=$data['student']['class']?></b></h4>
            <ul class="list-group list-group-unbordered mb-3">
              <li class="list-group-item">
                <b>Tolerance</b> <a class="float-right"><?=($data['type'])?$data['type']['total_tolerance']:'Null'?></a>
              </li>
              <li class="list-group-item">
                <b>Violation</b> <a class="float-right"><?=@countPersentase('total_violation', @$data['type'])?><small>%</small></a>
              </li>
              <li class="list-group-item">
                <b>Dutiful</b> <a class="float-right"><?=@countPersentase('total_dutiful', @$data['type'])?><small>%</small></a>
              </li>
            </ul>
          </div>
          <!-- /.card-body -->
        </div>
        <!-- /.card -->

      </div>
      <!-- /.col -->
      <div class="col-md-9">
        <div class="card">
          <div class="card-header p-2">
            <ul class="nav nav-pills">
              <li class="nav-item"><a class="nav-link active" href="#timeline" data-toggle="tab">Timeline</a></li>
              <li class="nav-item"><a class="nav-link" href="#activity" data-toggle="tab">Activity</a></li>
              <li class="nav-item"><a class="nav-link" href="#settings" data-toggle="tab">Settings</a></li>
            </ul>
          </div><!-- /.card-header -->
          <div class="card-body">
            <div class="tab-content">
              <div class="tab-pane" id="activity">                    
                <!-- Post -->
                <div class="post">
                  <div class="user-block">
                    <img class="img-circle img-bordered-sm" src="<?=BASEURL?>/_assets/dist/img/user6-128x128.jpg" alt="User Image">
                    <span class="username">
                      <a href="#">Adam Jones</a>
                      <a href="#" class="float-right btn-tool"><i class="fas fa-times"></i></a>
                    </span>
                    <span class="description">Posted 5 photos - 5 days ago</span>
                  </div>
                  <!-- /.user-block -->
                  <div class="row mb-3">
                    <div class="col-sm-6">
                      <img class="img-fluid" src="<?=BASEURL?>/_assets/dist/img/photo1.png" alt="Photo">
                    </div>
                    <!-- /.col -->
                    <div class="col-sm-6">
                      <div class="row">
                        <div class="col-sm-6">
                          <img class="img-fluid mb-3" src="<?=BASEURL?>/_assets/dist/img/photo2.png" alt="Photo">
                          <img class="img-fluid" src="<?=BASEURL?>/_assets/dist/img/photo3.jpg" alt="Photo">
                        </div>
                        <!-- /.col -->
                        <div class="col-sm-6">
                          <img class="img-fluid mb-3" src="<?=BASEURL?>/_assets/dist/img/photo4.jpg" alt="Photo">
                          <img class="img-fluid" src="<?=BASEURL?>/_assets/dist/img/photo1.png" alt="Photo">
                        </div>
                        <!-- /.col -->
                      </div>
                      <!-- /.row -->
                    </div>
                    <!-- /.col -->
                  </div>
                  <!-- /.row -->

                  <p>
                    <a href="#" class="link-black text-sm mr-2"><i class="fas fa-share mr-1"></i> Share</a>
                    <a href="#" class="link-black text-sm"><i class="far fa-thumbs-up mr-1"></i> Like</a>
                    <span class="float-right">
                      <a href="#" class="link-black text-sm">
                        <i class="far fa-comments mr-1"></i> Comments (5)
                      </a>
                    </span>
                  </p>

                  <input class="form-control form-control-sm" type="text" placeholder="Type a comment">
                </div>
                <!-- /.post -->
              </div>
              <!-- /.tab-pane -->
              <div class="active tab-pane" id="timeline">
                <!-- The timeline -->
                <div class="timeline timeline-inverse">
                  <!-- timeline time label -->
                  <?php if (!empty($data['report'])): ?>

                    
                  <?php foreach ($data['date'] as $keys => $values): ?>
                    <div class="time-label">
                      <span class="bg-info">
                        <?=$values['date']?>
                      </span>
                    </div>
                    <?php foreach ($data['report'] as $key => $value): ?>
                      <?php if ($values['date']==$value['date']): ?>
                     <div>
                      <i class="fas fa-<?=($value['type']=='tolerance')?'exclamation-triangle':(($value['type']=='violation')?'ban':'award')?> bg-<?=($value['type']=='tolerance')?'warning':(($value['type']=='violation')?'danger':'success')?>"></i>

                      <div class="timeline-item">

                        <h3 class="timeline-header"><a href="<?=BASEURL?>/report/<?=$value['type']?>"><?=$value['name']?></a></h3>
                        <?php if ($value['type']=='violation'): ?>
                        <div class="timeline-body">
                          <small>report by : <?=$value['reporter']?></small>
                        </div>
                        <?php endif ?>

                        <?php if ($value['type']=='violation'): ?>
                        <div class="timeline-footer text-right">
                          <span><small><i class="fa fa-check fa-sm"></i> confirmation by: <?=$value['confirmation']?></small></span>
                        </div>
                        <?php endif ?>

                      </div>
                    </div>
                      <?php endif ?>
                    <?php endforeach ?>

                  <?php endforeach ?>
                  <!-- /.timeline-label -->
                  <?php else: ?>
                  <div>
                    <i class="fas fa-clipboard-list bg-info"></i>

                    <div class="timeline-item">
                      <span class="time"><i class="far fa-clock"></i></span>

                      <h3 class="timeline-header border-0"><a href="<?=BASEURL?>">Data is empty</a>, try to input report
                      </h3>
                    </div>
                  </div>
                  <?php endif ?>
                  <div>
                    <i class="far fa-clock bg-gray"></i>
                  </div>
                </div>
              </div>
              <!-- /.tab-pane -->

              <div class="tab-pane" id="settings">
                <form class="form-horizontal">
                  <div class="form-group row">
                    <label for="inputName" class="col-sm-2 col-form-label">Name</label>
                    <div class="col-sm-10">
                      <input type="email" class="form-control" id="inputName" placeholder="Name">
                    </div>
                  </div>
                  <div class="form-group row">
                    <label for="inputEmail" class="col-sm-2 col-form-label">Email</label>
                    <div class="col-sm-10">
                      <input type="email" class="form-control" id="inputEmail" placeholder="Email">
                    </div>
                  </div>
                  <div class="form-group row">
                    <div class="offset-sm-2 col-sm-10">
                      <button type="submit" class="btn btn-danger">Submit</button>
                    </div>
                  </div>
                </form>
              </div>
              <!-- /.tab-pane -->
            </div>
            <!-- /.tab-content -->
          </div><!-- /.card-body -->
        </div>
        <!-- /.nav-tabs-custom -->
      </div>
    </div>
  </div>
</section>