<!-- remove rule violation -->
<div class="modal fade" id="modal-conformation-delete" tabindex="-1" role="dialog" aria-labelledby="modal-violation" aria-hidden="true">
  <div class="modal-dialog" role="document">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="modal-violation">Remove the rule</h5>
        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
      <form action="<?=BASEURL?>/violation/delete" method="POST" role="form" enctype="multipart/form-data">
        <div class="modal-body">
          <input type="hidden" name="type" value="violation">
          <h6><i class="icon fas fa-exclamation-triangle fa-lg"></i> You sure to empty this data rule of violation?</h6>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
          <button type="submit" class="btn btn-danger">Yes do it..</button>
        </div>
      </form>
    </div>
  </div>
</div>

<!-- remove rule violation -->
<div class="modal fade" id="modal-conformation-delete-criteria" tabindex="-1" role="dialog" aria-labelledby="modal-violation" aria-hidden="true">
  <div class="modal-dialog" role="document">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="modal-violation">Remove the criteria on rule</h5>
        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
      <form action="<?=BASEURL?>/violation/delete_criteria" method="POST" role="form" enctype="multipart/form-data">
        <div class="modal-body">
          <input type="text" name="id" value="">
          <h6><i class="icon fas fa-exclamation-triangle fa-lg"></i> You sure to empty this data criteria on rule of violation?</h6>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
          <button type="submit" class="btn btn-danger">Yes do it..</button>
        </div>
      </form>
    </div>
  </div>
</div>