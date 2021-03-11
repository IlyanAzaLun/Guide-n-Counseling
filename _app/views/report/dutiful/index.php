<!-- Main content -->
<section class="content">

  <div class="container-fluid">
    <div class="row">
      <div class="col-12">
        <!-- SELECT2 EXAMPLE -->
        <div class="card card-default">
          <div class="card-header bg-success">
            <h3 class="card-title">Add data student Dutiful</h3>

            <div class="card-tools">
              <button type="button" class="btn btn-tool" data-card-widget="collapse"><i class="fas fa-minus"></i></button>
              <button type="button" class="btn btn-tool" data-card-widget="remove"><i class="fas fa-times"></i></button>
            </div>
          </div>
          <form action="<?=BASEURL?>/report/insert/dutiful" method="POST">
            <!-- /.card-header -->

            <div class="card-body">
              <div class="row">

                <div class="col-md-12">
                  <div class="form-group">
                    <label>Dutiful</label>
                    <input type="hidden" name="type" value="dutiful">
                    <input type="hidden" name="reporter" value="<?=$_SESSION['user']['NIP']?>">
                    <div class="select2-success">

                      <select class="form-control select2" multiple="multiple" data-placeholder="Select a dutiful to dutiful" data-dropdown-css-class="select2-success" name="dutiful[]" required>
                        <?php foreach ($data['dutiful'] as $key => $value): ?>
                          <option value="<?=$value['id']?>"><?=$value['name']?></option>
                        <?php endforeach ?>
                      </select>
                    </div>
                  </div>
                  <!-- /.form-group -->
                </div>
                <!-- /.col -->
                <div class="col-12">
                  <div class="form-group">
                    <label>Students</label>
                    <select class="duallistbox" multiple="multiple" name="students[]" required>
                      <?php foreach ($data['students'] as $key => $value): ?>
                        <option value="<?=$value['NISS']?>,<?=$value['NISN']?>" ><?=$value['fullname']?> - <?=$value['class']?></option>
                      <?php endforeach ?>
                    </select>
                  </div>
                  <!-- /.form-group -->
                </div>
                <!-- /.col -->

                <div class="col-md-6">
                  <div class="form-group">
                    <label>Teacher Confirmation</label>
                    <select class="form-control select2" style="width: 100%;" name="teacher-confirmation" required>
                      <option selected="selected">Confirmation to homeroom Teacher</option>
                      <?php foreach ($data['teacher'] as $key => $value): ?>
                      <option value="<?=$value['NIP']?>"><?=$value['homeroom_teacher']?> - <?=$value['class']?></option>                        
                      <?php endforeach ?>
                    </select>
                  </div>
                  <!-- /.form-group -->
                </div>

                <div class="col-md-6">
                  <!-- Date -->
                  <div class="form-group">
                    <label>Date:</label>
                      <input type="date" name="date" class="form-control" required>
                  </div>
                </div>

              </div>
              <!-- /.row -->
            </div>
            <!-- /.card-body -->
            <div class="card-footer">
              <div class="float-right">
                <button class="btn btn-primary"><i class="fa fa-save"></i></button>
              </div>
            </div>
          </form>
        </div>
        <!-- /.card -->
      </div>
    </div>
  </div>
</section>
<!-- /.content -->