<!-- Main content -->
<section class="content">

  <div class="container-fluid">
    <div class="row">
      <div class="col-12">

        <!-- Default box -->
        <div class="card">
          <div class="card-header bg-primary">
            <h3 class="card-title">Tabel Siswa</h3>
          </div>
          <!-- /.card-header -->
          <div class="card-body">
            <table id="tbl_students" class="table table-bordered table-striped table-valign-middle">
              <thead>
                <tr>
                  <div class="float-left">
                    <a href="javascript:void(0)" class="btn btn-sm btn-primary float-left mb-2 mr-2" data-toggle="modal" data-target="#modal-add-student" title="Tambah data"><i class="fa fa-plus fa-fw"></i></a>
                    <a href="javascript:void(0)" class="btn btn-sm btn-success float-left mb-2 mr-2" data-toggle="modal" data-target="#modal-import-student" title="Tambah data dengan Excel"><i class="fa fa-file-excel fa-fw"></i></a>
                  </div>
                </tr>
                <tr>
                  <th>NISS</th>
                  <th>NISN</th>
                  <th>Nama Lengkap</th>
                  <th>Jenis Kelamin</th>
                  <?php if ($_SESSION['user']['class'] === "staff"): ?>
                    <th>Kelas</th>
                    <th>Wali kelas</th>
                  <?php endif ?>
                  <th>Status</th>
                  <th>Options</th>
                </tr>
              </thead>
              <tbody>
                <?foreach ($data['students'] as $student) {?>
                  <tr>
                    <td><?=$student['NISS']?></td>
                    <td><?=$student['NISN']?></td>
                    <td><?=$student['fullname']?></td>
                    <td><?=($student['gender']=="L") ? 'Laki-laki' : 'Perempuan' ;?></td>
                    <?php if ($_SESSION['user']['class'] === "staff"): ?>
                      <td><?=$student['class']?></td>
                      <td><?=$student['homeroom_teacher']?></td>
                    <?php endif ?>
                    <td>
                      <span class="badge badge-<?=($student['status']==="1")?'success':'danger';?>"title="keadaan siswa"><?=($student['status']==="1")?'Aktif':'Pindah';?></span>
                      <span class="badge badge-<?=($student['counseling']==1 ? 'danger' : ($student['counseling']==2 ? 'success': ($student['counseling']==3 ? 'info': 'secondary') ) );?>"title="konseling/bimbingan">
                        <?=($student['counseling']==1 ? 'segera' : ($student['counseling']==2 ? 'sudah': ($student['counseling']==3 ? 'prosess': 'belum') ) );?>
                      </span>
                    </td>
                    <td class="text-center">
                      <!-- INFO -->                      
                      <a href="<?=BASEURL.'/students/info/'.$student['NISS']?>" class="btn btn-sm btn-primary"><i class="fa fa-info-circle"></i></a>  
                      <!-- EDIT -->                      
                      <button type="button" class="btn btn-sm btn-warning" disabled><i class="fa fa-edit fa-inverse"></i></button>  
                    </td>
                  </tr>
                  <?}?>
                </tbody>
                <tfoot>
                  <tr>
                    <th>NISS</th>
                    <th>NISN</th>
                    <th>Full Name</th>
                    <th>Gender</th>
                    <?php if ($_SESSION['user']['class'] === "staff"): ?>
                      <th>Class</th>
                      <th>Homeroom Teacher</th>
                    <?php endif ?>
                    <th>Status</th>
                    <th>Options</th>
                  </tr>
                </tfoot>
              </table>
            </div>
            <!-- /.card-body -->
          </div>
          <!-- /.card -->
        </div>
      </div>
    </div>

  </section>
<!-- /.content -->