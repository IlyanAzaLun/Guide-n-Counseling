  <!-- Content Wrapper. Contains page content -->
  <div class="flash" data-flashType='<?=@Flasher::getFlash()?>'></div>
  <div class="content-wrapper">
    <!-- Content Header (Page header) -->
    <section class="content-header">
      <div class="container-fluid">
        <div class="row mb-2">
          <div class="col-sm-6">
            <h1><?=$this->page['title']?></h1>
          </div>
          <div class="col-sm-6">
            <ol class="breadcrumb float-sm-right">
              <li class="breadcrumb-item"><a href="<?=BASEURL?>">Home</a></li>
              <?if($_SERVER['REQUEST_URI'] != "/hide-me/" ){?>
              <li class="breadcrumb-item active"><?=$this->page['title']?></li>
              <?}?>
            </ol>
          </div>
        </div>
      </div><!-- /.container-fluid -->
    </section>
