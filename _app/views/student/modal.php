<div class="modal fade" id="modal-add-student" tabindex="-1" role="dialog" aria-labelledby="modal-student" aria-hidden="true">
  <div class="modal-dialog" role="document">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="modal-student">Add new student</h5>
        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
      <form action="<?=BASEURL?>/students/insert" method="POST">
        <div class="modal-body">
          <div class="row">
            <div class="col-6 mb-2">

              <div class="input-group">
                <div class="custom-file">
                  <input type="number" class="form-control" name="NISS" aria-label="Text input with segmented dropdown button" required placeholder="NISS">
                </div>
              </div>

            </div>
            <div class="col-6">

              <div class="input-group">
                <div class="custom-file">
                  <input type="number" class="form-control" name="NISN" aria-label="Text input with segmented dropdown button" required placeholder="NISN">
                </div>
              </div>

            </div>
          </div>
          <div class="row">
            <div class="col-12">
              <div class="input-group">
                <div class="custom-file">
                  <input type="text" class="form-control" name="fullname" aria-label="Text input with segmented dropdown button" required placeholder="Full Name">
                </div>
                <div class="input-group-prepend">
                  <select class="custom-select" name="gender" required>
                    <option selected disabled>Gender</option>
                    <option value="L">Male</option>
                    <option value="P">Fmale</option>
                  </select>
                  <?php if ($_SESSION['user']['class'] === "staff"||$_SESSION['user']['class'] === "school"): ?>
                  <select class="custom-select" name="class" required>
                    <option selected disabled>Class Student</option>
                    <?php foreach ($data['class'] as $key => $name): ?>
                    <option value="<?=$name['class']?>"><?=$name['class']?></option>
                    <?php endforeach ?>
                  </select>
                  <?php else: ?>
                  <input type="hidden" name="class" value="<?=$_SESSION['user']['class']?>">
                  <?php endif ?>
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


  <!-- import student -->
<div class="modal fade" id="modal-import-student" tabindex="-1" role="dialog" aria-labelledby="modal-student" aria-hidden="true">
  <div class="modal-dialog" role="document">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="modal-student">Import data student</h5>
        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
      <form action="<?=BASEURL?>/students/import" method="POST" role="form" enctype="multipart/form-data">
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
            <?php if ($_SESSION['user']['class'] === "staff"||$_SESSION['user']['class'] === "school"): ?>
            <p style="font-size: 12px;">**without change name staff can import!</p>
            <?php else: ?>
            <p style="font-size: 12px;">*change the name file same as your class, example X-1.xls</p>
            <?php endif ?>
          </div>
          <!-- body -->
        </div>
        <div class="modal-footer">

        <?php if ($_SESSION['user']['class'] === "staff"||$_SESSION['user']['class'] === "school"): ?>
        <a href="<?=BASEURL?>/_assets/files/students-example.xls" class="btn btn-success mr-auto">Download Format Excel</a>
        <?php else: ?>
        <a href="<?=BASEURL?>/_assets/files/students-class.xls" class="btn btn-success mr-auto">Download Format Excel</a>
        <?php endif ?>
          <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
          <button type="submit" class="btn btn-primary">Save changes</button>
        </div>
      </form>
    </div>
  </div>
</div>