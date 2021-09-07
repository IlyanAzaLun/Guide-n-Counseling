<?php 
function countPersentase($type, $data){
  return ((int)$data[$type]*100)/((int)$data['total_violation']+(int)$data['total_dutiful']);
}
?>
<!-- Main content -->
<section class="content">

  <div class="container-fluid">
    <div class="row">
      <div class="col-12">

        <!-- Default box -->
        <div class="row">
          <div class="col-12 col-sm-6 col-md-3">
            <div class="info-box">
              <span class="info-box-icon bg-info elevation-1"><i class="fas fa-users"></i></span>

              <div class="info-box-content">
                <span class="info-box-text">Total Student</span>
                <span class="info-box-number"><?=$data['type']['total_student']?></span>
              </div>
              <!-- /.info-box-content -->
            </div>
            <!-- /.info-box -->
          </div>
          <!-- /.col -->
          <div class="col-12 col-sm-6 col-md-3">
            <div class="info-box mb-3">
              <span class="info-box-icon bg-success elevation-1"><i class="fas fa-award"></i></span>

              <div class="info-box-content">
                <span class="info-box-text">Positive</span>
                <span class="info-box-number"><?=@countPersentase('total_dutiful', $data['type'])?><small>%</small></span>
              </div>
              <!-- /.info-box-content -->
            </div>
            <!-- /.info-box -->
          </div>
          <!-- /.col -->

          <!-- /.col -->
          <div class="col-12 col-sm-6 col-md-3">
            <div class="info-box mb-3">
              <span class="info-box-icon bg-warning elevation-1"><i class="fas fa-exclamation-circle"></i></span>

              <div class="info-box-content">
                <span class="info-box-text">Tolerancy</span>
                <span class="info-box-number"><?=(@$data['type']['total_tolerance'])?$data['type']['total_tolerance']:'NaN'?></span>
              </div>
              <!-- /.info-box-content -->
            </div>
            <!-- /.info-box -->
          </div>

          <!-- fix for small devices only -->
          <div class="clearfix hidden-md-up"></div>

          <div class="col-12 col-sm-6 col-md-3">
            <div class="info-box mb-3">
              <span class="info-box-icon bg-danger elevation-1"><i class="fas fa-ban"></i></span>

              <div class="info-box-content">
                <span class="info-box-text">Negative</span>
                <span class="info-box-number"><?=@countPersentase('total_violation', $data['type'])?><small>%</small></span>
              </div>
              <!-- /.info-box-content -->
            </div>
            <!-- /.info-box -->
          </div>
          <!-- /.col -->
        </div>

        <!-- BAR CHART -->
        <div class="card card-success">
          <div class="card-header">
            <h3 class="card-title">Ratio Dutiful and Violation</h3>

            <div class="card-tools">
              <button type="button" class="btn btn-tool" data-card-widget="collapse"><i class="fas fa-minus"></i>
              </button>
              <button type="button" class="btn btn-tool" data-card-widget="remove"><i class="fas fa-times"></i></button>
            </div>
          </div>
          <div class="card-body">
            <div class="chart">
              <canvas id="barChart" style="min-height: 250px; height: 250px; max-height: 250px; max-width: 100%;"></canvas>
            </div>
          </div>
          <!-- /.card-body -->
        </div>
        <!-- /.card -->

        <div class="card">
          <div class="card-header bg-info">
            <h3 class="card-title">Information</h3>

            <div class="card-tools">
              <button type="button" class="btn btn-tool" data-card-widget="collapse" data-toggle="tooltip" title="Collapse">
                <i class="fas fa-minus"></i></button>
                <button type="button" class="btn btn-tool" data-card-widget="remove" data-toggle="tooltip" title="Remove">
                  <i class="fas fa-times"></i></button>
                </div>
              </div>
              <div class="card-body">
                <?=($_SESSION['user']['class'] == "staff" ) ? 'Hello, Welcome back, '.$_SESSION['user']['homeroom_teacher'] :  'Welcome from this aplication Sir./Ms. '.$_SESSION['user']['homeroom_teacher']?>
              </div>
              <!-- /.card-body -->
              <div class="card-footer">

              </div>
              <!-- /.card-footer-->
            </div>
            <!-- /.card -->
          </div>
        </div>
      </div>

    </section>
<!-- /.content -->