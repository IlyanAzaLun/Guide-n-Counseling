<!-- Main content -->
<section class="content">

  <div class="container-fluid">
    <div class="row">
      <div class="col-12">


        <!-- Default box -->
        <div class="card <?=(!empty($data['violation'])?'collapse':'')?>" id="field_rules">
          <div class="card-header bg-primary">
            <h3 class="card-title"><?=(!empty($data['violation'])?'Update':'Create')?> Rules</h3>
            <div class="card-tools">
              <button type="button" class="btn btn-tool" data-toggle="collapse" data-target="#form-field" aria-expanded="true" aria-controls="form-field"><i class="fas fa-minus"></i></button>
              <button type="button" class="btn btn-tool collapsed" data-toggle="collapse" data-target="#field_rules" aria-expanded="false" aria-controls="field_rules"><i class="fas fa-times"></i></button>
            </div>
          </div>
          <form action="<?=BASEURL?>/violation/<?=(!empty($data['violation'])?'update':'insert')?>" method="POST" id="form-field">
            <div class="card-body" id="dynamic_field">
              <div class="row"  id="parent">
                <div class="col-8">
                  <div class="form-group">
                    <label for="">Criteria</label>
                    <input type="text" name="criteria[]" class="form-control" required>
                  </div>
                </div>
                <div class="col-4">
                  <label for="">Weight: <span id="weight"></span></label>
                  <div class="input-group mb-3">
                    <input type="number" name="weight[]" id="weight" class="form-control" required step="0.001">
                    <div class="input-group-append">
                      <button type="button" id="add" class="btn btn-primary"><i class="fa fa-plus"></i></button>
                    </div>
                  </div>
                </div>

              </div>
            </div>
            <div class="card-footer">
              <button type="sumbit" class="btn btn-primary float-right"><i class="fa fa-save"></i></button>  
            </div>
          </form>
        </div>

        <div class="card <?=(empty($data['violation'])?'collapse':'')?>">
          <div class="card-header bg-danger">
            <h3 class="card-title">Table of Rules</h3>
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
                  <?php foreach ($data['violation'] as $key => $value): ?>
                  <th title="<?=$value['name']?>">C<?=$key+1?></th>
                  <?php endforeach ?>
                  <th>Options</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <th>Weight</th>
                  <?php foreach ($data['violation'] as $key => $value): ?>
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