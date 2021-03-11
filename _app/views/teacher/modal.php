<div class="modal fade" id="modal-add-teacher" tabindex="-1" role="dialog" aria-labelledby="modal-teacher" aria-hidden="true">
  <div class="modal-dialog" role="document">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="modal-teacher">Add new teacher</h5>
        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
      <form action="<?=BASEURL?>/teacher/insert" method="POST" id="insert">
        <div class="modal-body">
          <div class="row">
            <div class="col-12 mb-2">

              <div class="form-group">
                <label for="NIP">NIP</label>
                <input type="number" id="NIP" class="form-control" name="NIP" aria-label="Text input with segmented dropdown button" required placeholder="NIP">
              </div>

            </div>
          </div>
          <div class="row">
            <div class="col-12">

              <div class="form-group">
                <label for="name and class">Homeroom teacher and Class</label>
                <div class="input-group">
                  <div class="custom-file">
                    <input type="text" class="form-control" name="homeroom_teacher" aria-label="Text input with segmented dropdown button" required placeholder="Full Name">
                  </div>
                  <div class="input-group-prepend">
                    <input type="text" class="form-control" name="class" aria-label="Text input with segmented dropdown button" required placeholder="Class Name">
                  </div>
                </div>
              </div>
            </div>

            <div class="col-12 mt-2">
              <div class="form-group">
                <label for="password and re-password">Password</label>

                <div class="input-group">
                  <div class="custom-file">
                    <input type="password" class="form-control" name="password" id="password" aria-label="Text input with segmented dropdown button" required placeholder="Password">
                  </div>
                  <div class="input-group-prepend">
                    <input type="password" class="form-control" name="re_password" aria-label="Text input with segmented dropdown button" required placeholder="re type Password">
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
          <button type="submit" class="btn btn-primary">Save changes</button>
        </div>
      </form>
    </div>
  </div>
</div>


<!-- import teacher -->
<div class="modal fade" id="modal-import-teacher" tabindex="-1" role="dialog" aria-labelledby="modal-teacher" aria-hidden="true">
  <div class="modal-dialog" role="document">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="modal-teacher">Import data teacher</h5>
        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
      <form action="<?=BASEURL?>/teacher/import" method="POST" role="form" enctype="multipart/form-data">
        <div class="modal-body">

          <!-- body -->
          <div class="form-group">
            <label for="file">File Excel</label>
            <div class="input-group">
              <div class="custom-file">
                <input type="file" class="custom-file-input" id="file" name="file">
                <label class="custom-file-label" for="file">Choose file Excel</label>
              </div>
            </div>
            <?php if ($_SESSION['user']['class'] === "staff"): ?>
              <p style="font-size: 12px;">**without change name staff can import!</p>
              <?php else: ?>
                <p style="font-size: 12px;">*change the name file same as your class, example X-1.xls</p>
              <?php endif ?>
            </div>
            <!-- body -->
          </div>
          <div class="modal-footer">

            <a href="<?=BASEURL?>/_assets/files/teacher-example.xls" class="btn btn-success mr-auto">Download Format Excel</a>
            <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
            <button type="submit" class="btn btn-primary">Save changes</button>
          </div>
        </form>
      </div>
    </div>
  </div>


  <!-- truncate teacher -->
  <div class="modal fade" id="modal-conformation-truncate" tabindex="-1" role="dialog" aria-labelledby="modal-teacher" aria-hidden="true">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title" id="modal-teacher">Empty data teacher</h5>
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <span aria-hidden="true">&times;</span>
          </button>
        </div>
        <form action="<?=BASEURL?>/teacher/truncate" method="POST" role="form" enctype="multipart/form-data">
          <div class="modal-body">
            <h6><i class="icon fas fa-exclamation-triangle fa-lg"></i> You sure to empty this data homeroom teacher?</h6>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
            <button type="submit" class="btn btn-danger">Yes do it..</button>
          </div>
        </form>
      </div>
    </div>
  </div>