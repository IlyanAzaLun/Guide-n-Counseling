<section class="content">

  <div class="container-fluid">
    <div class="row">
      <div class="col-12">

        <!-- Default box -->
        <div class="card">
          <div class="card-header bg-primary">
            <h3 class="card-title">Header of <?=$data['page']['title']?></h3>

            <div class="card-tools">
              <button type="button" class="btn btn-tool" data-card-widget="remove" data-toggle="tooltip" title="Back" onclick="window.history.back()">
                <i class="fas fa-times"></i>
              </button>
            </div>
          </div>
          <form action="<?=BASEURL?>/section/update_info" method="POST" enctype="multipart/form-data">
            <div class="card-body">
              <!-- start content -->
              <form role="form">
                <div class="row">

                  <div class="col-sm-6">
                    <div class="row">

                      <div class="col-12 col-sm-12">
                        <label>Title</label>
                        <div class="input-group">
                          <div class="custom-file">
                            <input type="hidden" name="id" class="form-control" value="<?=$data['page']['id_content']?>">
                            <input type="hidden" name="index_current" class="form-control" value="<?=$data['page']['index']?>">
                            <input type="text" name="title" class="form-control" value="<?=$data['page']['title']?>">
                          </div>
                          <div class="input-group-append">
                            <select class="custom-select" name="index" data-toggle="tooltip" title="Index">
                              <?
                              for ($i=1; $i <= $data['page']['exist']['index']+1; $i++) {?>
                                <option value="<?=$i?>" <?=($i==$data['page']['index']) ? 'selected' :'';?>><?=$i?></option>
                                <?}?>
                              </select>
                            </div>
                          </div>
                        </div>
                        <div class="col-12 col-sm-12">
                          <div class="row">
                            <div class="col-4 col-sm-4">
                              <img src="<?=HOSTURL.$data['page']['image'][0]['url']?>"class="preview img-thumbnail mt-2" style="height: 200px;"/>
                              <div class="form-group mt-3">
                                <div class="dropzone-wrapper">
                                  <div class="preview-zone hidden">
                                    <div class="preview-image"></div>
                                  </div>
                                  <div class="dropzone-desc">
                                    <p>Drop image here!</p>
                                  </div>
                                  <input type="file" name="image[1]" class="dropzone">
                                  <input type="hidden" name="id_image[0]" class="dropzone" value="<?=$data['page']['image'][0]['id']?>">
                                </div>
                              </div>
                            </div>
                            <div class="col-4 col-sm-4">
                              <img src="<?=HOSTURL.$data['page']['image'][1]['url']?>" class="preview img-thumbnail mt-2"style="height: 200px;"/>
                              <div class="form-group mt-3">
                                <div class="dropzone-wrapper">
                                  <div class="preview-zone hidden">
                                    <div class="preview-image"></div>
                                  </div>
                                  <div class="dropzone-desc">
                                    <p>Drop image here!</p>
                                  </div>
                                  <input type="file" name="image[2]" class="dropzone">
                                  <input type="hidden" name="id_image[1]" class="dropzone" value="<?=$data['page']['image'][1]['id']?>">
                                </div>
                              </div>
                            </div>
                            <div class="col-4 col-sm-4">
                              <img src="<?=HOSTURL.$data['page']['image'][2]['url']?>" class="preview img-thumbnail mt-2"style="height: 200px;"/>
                              <div class="form-group mt-3">
                                <div class="dropzone-wrapper">
                                  <div class="preview-zone hidden">
                                    <div class="preview-image"></div>
                                  </div>
                                  <div class="dropzone-desc">
                                    <p>Drop image here!</p>
                                  </div>
                                  <input type="file" name="image[3]" class="dropzone">
                                  <input type="hidden" name="id_image[2]" class="dropzone" value="<?=$data['page']['image'][2]['id']?>">
                                </div>
                              </div>
                            </div>

                          </div>
                        </div>
                      </div>
                    </div>
                    <div class="col-sm-6">
                      <!-- textarea -->
                      <div class="form-group">
                        <label>Iformation</label>
                        <textarea class="form-control" rows="1" name="content" placeholder="Produk produk yang dibuat dengan sentuhan seni, menghasilkan karya yang tak ternilai harganya !"><?=$data['page']['content']?></textarea>
                      </div>

                      <div class="form-group">
                        <label>Descriptions</label>
                        <textarea class="form-control" rows="3" name="description" placeholder="Produk produk yang dibuat dengan sentuhan seni, menghasilkan karya yang tak ternilai harganya !"><?=$data['page']['description']?></textarea>
                        <div class="text-right">
                          <span id="maxContentPost"></span>
                        </div>
                      </div>

                    </div>

                  </div>
                  <!-- end content -->
                </div>
                <!-- /.card-body -->
                <div class="card-footer">
                  <button type="reset" class="btn btn-block btn-secondary remove-preview">Reset</button>
                  <button type="sumbit" class="btn btn-block btn-primary">Save</button>
                </div>
              </form>
              <!-- /.card-footer-->
            </div>
            <!-- /.card -->
          </div>
        </div>
      </div>
    </section>