<!-- Main content -->
<section class="content">

  <div class="container-fluid">
    <div class="row">
      <div class="col-12">

        <!-- Default box -->
        <div class="card">
          <div class="card-header bg-primary">
            <h3 class="card-title">Table My Students</h3>
          </div>
          <!-- /.card-header -->
          <div class="card-body">
            <table id="tbl_students" class="table table-bordered table-striped">
              <thead>
                <tr>
                  <div class="float-left">
                    <a href="javascript:void(0)" class="btn btn-sm btn-primary float-left mb-2 mr-2" data-toggle="modal" data-target="#modal-add-student" title="Add Student"><i class="fa fa-plus fa-fw"></i></a>
                    <a href="javascript:void(0)" class="btn btn-sm btn-success float-left mb-2 mr-2" data-toggle="modal" data-target="#modal-import-student" title="Add Student with Excel"><i class="fa fa-file-excel fa-fw"></i></a>
                  </div>
                </tr>
                <tr>
                  <th>NISS</th>
                  <th>NISN</th>
                  <th>Full Name</th>
                  <th>Gender</th>
                  <?php if ($_SESSION['user']['class'] === "staff"): ?>
                    <th>Class</th>
                    <th>Homeroom Teacher</th>
                  <?php endif ?>
                  <th>Options</th>
                </tr>
              </thead>
              <tbody>
                <?foreach ($data['students'] as $student) {?>
                  <tr>
                    <td><?=$student['NISS']?></td>
                    <td><?=$student['NISN']?></td>
                    <td><?=$student['fullname']?></td>
                    <td><?=($student['gender']=="L") ? 'Male' : 'Fmale' ;?></td>
                    <?php if ($_SESSION['user']['class'] === "staff"): ?>
                      <td><?=$student['class']?></td>
                      <td><?=$student['homeroom_teacher']?></td>
                    <?php endif ?>
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