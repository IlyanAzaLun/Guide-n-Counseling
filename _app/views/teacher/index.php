<section class="content">
  <div class="container-fluid">
    <div class="card card-solid">
      <div class="card-body pb-0">
        <div class="form-group">
          <div class="row">
            <div class="col-2">
              <button type="button" class="btn btn-primary btn-sm" data-toggle="modal" data-target="#modal-add-teacher" title="Add Teacher"><i class="fa fa-plus fa-fw"></i></button>
              <button type="button" class="btn btn-success btn-sm" data-toggle="modal" data-target="#modal-import-teacher" title="Add Teacher with Excel"><i class="fa fa-file-excel fa-fw"></i></button>
              <button type="button" class="btn btn-danger btn-sm" data-toggle="modal" data-target="#modal-conformation-truncate" title="Remove all Teacher"><i class="fa fa-trash fa-fw"></i></button>
              <button type="button" class="btn btn-secondary btn-sm" onclick="alert('Can\'t backup, cause maintainance')"><i class="fa fa- fa-fw"></i>CSV<i class="fa fa- fa-fw"></i></button>
            </div>
            <div class="ml-auto">
              <input type="text" name="search_box" id="search_box" class="form-control" placeholder="search by name" />
            </div>
          </div>
        </div>
        <div class="row d-flex align-items-stretch" id="dynamic_content">
          <!-- Data Users -->

          <!-- Data Users -->
        </div>
      </div>
      <div class="card-footer">
        <nav aria-label="Contacts Page Navigation">
          <ul class="pagination justify-content-center m-0" id="pagination">
            <!-- Pagination -->
            <?
            for ($i=1; $i <= $data['total_links']; $i++) { 
              $page_array[] = $i;
            }

            for ($i=0; $i < @count(@$page_array); $i++) {               
              if ($i==0) {
                ?>
                <li class="page-item active"><button type="button" class="page-link" href="javascript:void(0)" data-page_number="<?=$page_array[$i]?>"><?=$page_array[$i]?></button></li>
                <?
              }else{
                ?>
                <li class="page-item"><button type="button" class="page-link" href="javascript:void(0)" data-page_number="<?=$page_array[$i]?>"><?=$page_array[$i]?></button></li>
                <?
              }
            }
            ?>
            <!-- Pagination -->
          </ul>
        </nav>
      </div>
      <!-- /.card-body -->
    </div>
    <!-- /.card -->
  </div>
  <!-- /.container-fluid -->
</section>