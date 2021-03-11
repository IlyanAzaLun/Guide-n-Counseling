<!-- Main content -->
<section class="content">

  <div class="container-fluid">
    <div class="row">
      <div class="col-12">


        <!-- Default box -->
        <div class="card <?=(empty($data['dutiful'])?'collapse':'')?>">
          <div class="card-header bg-success">
            <h3 class="card-title">Table rule of dutiful</h3>
            <div class="card-tools">
              <button type="button" class="btn btn-tool" data-card-widget="collapse"><i class="fas fa-minus"></i></button>
            </div>
          </div>
          <!-- /.card-header -->
          <div class="card-body">
            <table id="tbl_criteria" class="table table-bordered table-striped">
              <thead>
                <tr>
                  <th>Criteria</th>
                  <?php foreach ($data['dutiful'] as $key => $value): ?>
                  <th title="<?=$value['name']?>">C<?=$key+1?></th>
                  <?php endforeach ?>
                  <th>Options</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <th>Weight</th>
                  <?php foreach ($data['dutiful'] as $key => $value): ?>
                  <th><?=$value['weight']?></th>
                  <?php endforeach ?>
                  <td class="text-center">
                    <!-- EDIT -->                      
                    <button type="button" class="btn btn-sm btn-warning" id="update" data-toggle="collapse" data-target="#field_rules" aria-expanded="false" aria-controls="field_rules"><i class="fa fa-edit fa-inverse"></i></button>  
                    <button type="button" class="btn btn-sm btn-danger" data-toggle="modal" data-target="#modal-conformation-delete"><i class="fa fa-trash fa-inverse"></i></button>  
                  </td>
                </tr>
              </tbody>
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