<!-- Main content -->
<section class="content">

  <div class="container-fluid">
    <div class="row">
      <div class="col-12">
        <!-- SELECT2 EXAMPLE -->
        <div class="card card-default">
          <div class="card-header bg-success">
            <h3 class="card-title">Report Student</h3>

            <div class="card-tools">
              <button type="button" class="btn btn-tool" data-card-widget="collapse"><i class="fas fa-minus"></i></button>
              <button type="button" class="btn btn-tool" data-card-widget="remove"><i class="fas fa-times"></i></button>
            </div>
          </div>
            <!-- /.card-header -->

            <div class="card-body">
              <div class="row">

                <div class="col-md-12">
                  <!-- /.form-group -->
                  <table id="tbl_students" class="table table-bordered table-striped">
                    <thead>
                      <tr>
                        <th>Student Name</th>
                        <th>NISS</th>
                        <?php foreach ($data['criteria'] as $key => $value): ?>
                        <th title="<?=$value['name']?>">C<?=$key+1?></th>
                        <?php endforeach ?>
                        <th>Total</th>
                      </tr>
                    </thead>
                    <tbody>
                      <?php foreach ($data['report'] as $key => $value):?>
                        <?php if (@$value['student_name'] != NULL): ?>
                      <tr class="<?=($value['Total']>=((int)($data['tmp']/sizeof($data['criteria']))))?'bg-danger':''?>">
                        <td><?=$value['student_name']?></td>
                        <td><?=($key !== (sizeof($data['report'])-1))?$value['NISS']:'<b>Total</b>'?></td>
                        <?php foreach ($data['criteria'] as $criteria): ?>
                        <td><?=(@$value[$criteria['name']])?$value[$criteria['name']]:0?></td>
                        <?php endforeach ?>
                        <td><?=$value['Total']?></td>
                      </tr>
                        <?php endif ?>
                      <?php endforeach ?>
                    </tbody>
                    <tfoot>
                      <?php foreach (($data['report']) as $key => $value):?>
                        <?php if ($key == @sizeof($data['report'])-1): ?>
                      <tr>
                        <th colspan='2' class="text-center">Total</th>
                        <?php foreach ($data['criteria'] as $criteria): ?>
                        <th title="<?=$criteria['name']?>"><?=(@$value[$criteria['name']])?$value[$criteria['name']]:'0'?></th>
                        <?php endforeach ?>
                        <th><?=(@$value['Total'])?$value['Total']:'0'?></th>
                      </tr>
                        <?php endif ?>
                      <?php endforeach ?>
                    </tfoot>
                  </table>
                </div>

              </div>
              <!-- /.row -->
            </div>
            <!-- /.card-body -->
            <div class="card-footer">
              <div class="float-right">
              </div>
            </div>
        </div>
        <!-- /.card -->
      </div>
    </div>
  </div>
</section>
<!-- /.content -->