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
      <div class="col-3 col-lg-3 col-sm-5">

        <!-- Profile Image -->
        <div class="card card-primary card-outline">
          <div class="card-body box-profile">
            <div class="text-center">
              <img class="profile-user-img img-fluid img-circle"
              src="<?=($data['student']['photo']!='')?BASEURL.'/'.$data['student']['photo']:BASEURL.'/_assets/dist/img/default-150x150.png'?>"
              style="width: 100px; height: 100px" alt="User profile picture">
            </div>

            <h3 class="profile-username text-center"><?=$data['student']['fullname']?> <small>(<?=$data['student']['gender']?>)</small></h3>

            <p class="text-muted text-center"><small><b>NISN</b></small>/<small>NISS</small> <b><?=$data['student']['NISN']?></b>/<?=$data['student']['NISS']?></p>

            <h4 class="profile-username text-center">Kelas: <b><?=$data['student']['class']?></b><?=($data['student']['status']==="1")?' Aktif':' Pindah'?></h4>
            <ul class="list-group list-group-unbordered mb-3">
              <li class="list-group-item">
                <b>Toleransi</b> <a class="float-right"><?=($data['type'])?$data['type']['total_tolerance']:'Null'?></a>
              </li>
              <li class="list-group-item">
                <b>Pelanggaran</b> <a class="float-right"><?=@countPersentase('total_violation', @$data['type'])?><small>%</small></a>
              </li>
              <li class="list-group-item">
                <b>Kepatuhan</b> <a class="float-right"><?=@countPersentase('total_dutiful', @$data['type'])?><small>%</small></a>
              </li>
            </ul>
          </div>
          <!-- /.card-body -->
        </div>
        <!-- /.card -->

      </div>
      <!-- /.col -->
      <div class="col-9 col-lg-9 col-sm-7">
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
                       
                        <!-- message -->
                        <?php if ($values['id']==$value['id']): ?>
                        <div class="timeline-body">
                          <?=$value['message']?>
                        </div>
                        <?php endif ?>
                        <!-- ./message -->

                        <?php if ($value['type']=='violation'): ?>
                        <div class="timeline-footer text-right bg-info">
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
                <!-- Settings -->
                <form class="form-horizontal" method="POST" action="<?=BASEURL?>/students/update" enctype="multipart/form-data">
                  <div class="card card-warning">
                    <div class="card-header">
                      <h3 class="card-title">Ubah informasi siswa</h3>
                    </div>
                  <div class="card-body">
                    <div class="form-group row">
                      <label for="inputName" class="col-lg-2 col-form-label">Nama</label>
                      <div class="col-10 col-lg-10 col-sm">
                        <input type="text" class="form-control" id="inputName" name="name" placeholder="Name" value="<?=$data['student']['fullname']?>" required>
                      </div>
                    </div>
                    <div class="form-group row">
                      <label for="inputNISS" class="col-lg-2 col-form-label">NISN/ Kelas</label>
                      <div class="col-10 col-lg-5 col-sm-8">
                        <input type="text" class="form-control" id="inputNISN" name="NISN" placeholder="NISN" value="<?=$data['student']['NISN']?>" required>
                      </div>

                      <div class="col-10 col-lg-5 col-sm">
                        <input type="text" class="form-control" id="inputClass" name="class" placeholder="Class" value="<?=$data['student']['class']?>" required>
                      </div>

                      <div class="col-10 col-lg-5 col-sm">
                        <input type="hidden" class="form-control" id="inputNISS" name="NISS" placeholder="NISS" value="<?=$data['student']['NISS']?>">
                      </div>
                    </div>

                  <!--  -->
                    <div class="form-group row">
                      <label class="col-lg-2 col-form-label">Status</label>
                      <!-- RADIO -->
                      <div class="form-group clearfix col-lg-10 mt-2">
                        <div class="icheck-primary d-inline">
                          <input type="radio" id="radioPrimary1" name="r1" checked="">
                          <label for="radioPrimary1">
                            Belum
                          </label>
                        </div>
                        <div class="icheck-primary d-inline">
                          <input type="radio" id="radioPrimary2" name="r1">
                          <label for="radioPrimary2">
                            Segera
                          </label>
                        </div>
                        <div class="icheck-primary d-inline">
                          <input type="radio" id="radioPrimary3" name="r1">
                          <label for="radioPrimary3">
                            Prosess
                          </label>
                        </div>
                        <div class="icheck-primary d-inline">
                          <input type="radio" id="radioPrimary4" name="r1">
                          <label for="radioPrimary4">
                            Sudah
                          </label>
                        </div>
                        <label class="float-right">Bimbingan</label>
                      </div>
                      <!-- RADIO -->
                      <div class="col-lg-2"></div>
                      <div class="custom-control custom-switch custom-switch-off-danger custom-switch-on-success ml-2">
                        <input type="checkbox" class="custom-control-input" id="status" name="status" <?=($data['student']['status']==="1")?'checked value="1"':'value="0"'?>>
                        <label class="custom-control-label" for="status"><?=($data['student']['status']==="1")?'Aktif':'Pindah'?> </label>
                      </div>
                    </div>
                   <!--  -->

                    <div class="form-group row">
                      <div class="offset-sm-2 col-sm-10">
                        <button type="submit" class="btn btn-primary float-right">Simpan</button>
                      </div>
                    </div>
                <!-- Settings -->
                </div>
                </div>
                </form>
                <!--  -->
                <div class="card card-success">
                  <div class="card-header">
                    <h3 class="card-title">Ubah foto siswa</h3>
                  </div>
                  <form class="form-horizontal" method="POST" action="<?=BASEURL?>/students/update" enctype="multipart/form-data">
                    <div class="card-body">
                      <input type="hidden" class="form-control" id="inputNISS" name="NISS" placeholder="NISS" value="<?=$data['student']['NISS']?>">
                      <input type="hidden" name="tmp" value="<?=$data['student']['photo']?>">
                      <div class="form-group row">
                        <label for="inputPhoto" class="col-lg-2 col-form-label">Foto</label>
                        <div class="input-group col-10 col-lg-10 col-sm-10">
                          <div class="custom-file">
                            <input type="file" class="custom-file-input" id="inputPhoto" name="image" required>
                            <label class="custom-file-label" for="inputPhoto">Choose file</label>
                          </div>
                          <div class="input-group-append">
                            <span class="input-group-text" id="">Upload</span>
                          </div>
                        </div>
                      </div>
                      <div class="form-group row">
                        <div class="offset-sm-2 col-sm-10">
                          <button type="submit" class="btn btn-primary float-right">Simpan</button>
                        </div>
                      </div>

                    </div>
                  </form>
                  <!-- /.card-body -->
                </div>

                <div class="callout callout-info bg-danger pb-5">
                  <h5><i class="fas fa-info"></i> Hapus data siswa</h5>
                  <button type="submit" class="btn btn-primary float-right" data-toggle="modal" data-target="#modal-delete-student">Hapus</button>
                </div>
                <!--  -->
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