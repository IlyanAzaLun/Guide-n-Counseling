  <!-- overlayScrollbars -->
  <link rel="stylesheet" href="<?=BASEURL?>/_assets/dist/css/adminlte.min.css">
  <!-- Google Font: Source Sans Pro -->
  <link href="https://fonts.googleapis.com/css?family=Source+Sans+Pro:300,400,400i,700" rel="stylesheet">
</head>
<body class="hold-transition sidebar-mini layout-fixed pace-danger">
  <!-- Site wrapper -->
  <div class="wrapper">
    <!-- Navbar -->
    <nav class="main-header navbar navbar-expand navbar-white navbar-light">
      <!-- Left navbar links -->
      <ul class="navbar-nav">
        <li class="nav-item">
          <a class="nav-link" data-widget="pushmenu" href="#" role="button"><i class="fas fa-bars"></i></a>
        </li>
      </ul>
      <!-- Right navbar links -->
      <ul class="navbar-nav ml-auto">

        <!-- Notification -->
        <li class="nav-item dropdown">
          <a class="nav-link" data-toggle="dropdown" href="#">
            <i class="far fa-bell"></i>
            <?php if (sizeof($data['notification'])): ?>
            <span class="badge badge-warning navbar-badge"><?=sizeof($data['notification'])?></span>
            <?php endif ?>
          </a>
          <div class="dropdown-menu dropdown-menu-xl dropdown-menu-right">
            <span class="dropdown-item dropdown-header"><?=sizeof($data['notification'])?> Notifications</span>
            <?foreach ($data['notification'] as $key => $value):?>
            <div class="dropdown-divider"></div>
            <a href="<?=BASEURL?>/students/info/<?=$value['NISS']?>" class="dropdown-item">
              <i class="fas fa-<?=($value['type'] == "dutiful" ? 'award' : ($value['type'] == "violation" ? 'ban' : 'exclamation-triangle'))?> mr-2"></i> <?=mb_strimwidth($value['fullname'], 0, 10, '...')?>
              <span class="float-right text-muted text-sm"><?=mb_strimwidth($value['name'], 0, 30, '...')?></span>
            </a>
            <?endforeach;?>
            <div class="dropdown-divider"></div>
            <a href="#" class="dropdown-item dropdown-footer">See All Notifications</a>
          </div>
        </li>
        <!-- Notification -->
        
        <li class="nav-item d-none d-sm-inline-block">
          <a data-toggle="modal" data-target="#logoutModal" class="btn nav-link">Logout <i class="fas fa-sign-out-alt"></i></a>
        </li>
      </ul>

    </nav>
    <!-- /.navbar -->

    <!-- Main Sidebar Container -->
    <aside class="main-sidebar sidebar-dark-primary elevation-4">
      <!-- Brand Logo -->
      <a href="<?=BASEURL?>/" class="brand-link text-center">
        <span class="brand-text font-weight-light"><?=$this->title?></span>
      </a>

      <!-- Sidebar -->
      <div class="sidebar">
        <!-- Sidebar user (optional) -->
        <div class="user-panel mt-3 pb-3 mb-3 d-flex">
          <div class="image">
          </div>
          <div class="info">
            <a href="<?=BASEURL?>" class="d-block"><i class="fa fa-user-graduate"></i>&nbsp;&nbsp;<?=explode(',', $_SESSION['user']['homeroom_teacher'])[0]?></a>
          </div>
        </div>

        <!-- Sidebar Menu -->
        <nav class="mt-2">
          <ul class="nav nav-pills nav-sidebar flex-column" data-widget="treeview" role="menu" data-accordion="false">
          <!-- Add icons to the links using the .nav-icon class
           with font-awesome or any other icon font library -->
           <li class="nav-item has-treeview">
            <a href="<?=BASEURL?>" class="nav-link">
              <i class="nav-icon fas fa-tachometer-alt"></i>
              <p>
                Dashboard
              </p>
            </a>
          </li>
          
          <li class="nav-header">Data</li>
          <?php if ($_SESSION['user']['class'] == "staff" ): ?>
            <li class="nav-item">
              <a href="<?=BASEURL?>/students/<?=base64_encode('all')?>" class="nav-link">
                <i class="nav-icon fas fa-users"></i>
                Semua siswa
              </a>
            </li>
            
            <?php elseif($_SESSION['user']['class'] !== "" || $_SESSION['user']['class'] !== null) :?>
              <li class="nav-item">
                <a href="<?=BASEURL?>/students/<?=base64_encode($_SESSION['user']['class'])?>" class="nav-link">
                  <i class="nav-icon fas fa-users"></i>
                  Siswaku
                </a>
              </li>

            <?php endif ?>

            <li class="nav-item has-treeview">
              <a href="#" class="nav-link">
                <i class="nav-icon fa fa-clipboard-list"></i>
                <p>
                  Laporan
                  <i class="fas fa-angle-left right"></i>
                </p>
              </a>
              <ul class="nav nav-treeview">
                <li class="nav-item">
                  <a href="<?=BASEURL?>/report/tolerance" class="nav-link">
                    <i class="nav-icon fa fa-exclamation-triangle"></i>
                    Toleransi
                  </a>
                </li>
              </ul>

              <ul class="nav nav-treeview">
                <li class="nav-item">
                  <a href="<?=BASEURL?>/report/violation" class="nav-link">
                    <i class="nav-icon fas fa-ban"></i>
                    Buat laporan pelanggaran
                  </a>
                </li>
              </ul>

              <ul class="nav nav-treeview">
                <li class="nav-item">
                  <a href="<?=BASEURL?>/report/dutiful" class="nav-link">
                    <i class="nav-icon fas fa-award"></i>
                    Buat laporan nilai terpuji
                  </a>
                </li>
              </ul>

              <ul class="nav nav-treeview">
                <li class="nav-item">
                  <a href="<?=BASEURL?>/report" class="nav-link">
                    <i class="nav-icon fas fa-clipboard-list"></i>
                    Terlaporkan
                  </a>
                </li>
              </ul>
            </li>

            <?php if ($_SESSION['user']['class'] == "staff" ): ?>

              <li class="nav-header">Konfigurasi</li>
              <li class="nav-item">
                <a href="<?=BASEURL?>/teacher" class="nav-link">
                 <i class="fa fa-user-graduate nav-icon"></i>
                 <p>Guru</p>
               </a>
             </li>
             <li class="nav-item has-treeview">
              <a href="#" class="nav-link">
                <i class="nav-icon fas fa-thumbtack"></i>
                <p>
                  Aturan
                  <i class="fas fa-angle-left right"></i>
                </p>
              </a>
             
              <ul class="nav nav-treeview">
                <!--  -->
                <li class="nav-item has-treeview">
                  <a href="#" class="nav-link">
                    <i class="far fa-circle nav-icon"></i>
                    <p>
                      Pelanggaran
                      <i class="right fas fa-angle-left"></i>
                    </p>
                  </a>
                  <ul class="nav nav-treeview">
                    <li class="nav-item">
                      <a href="<?=BASEURL?>/violation" class="nav-link">
                        <i class="far fa-dot-circle nav-icon"></i>
                        <p>Aturan</p>
                      </a>
                    </li>
                    <li class="nav-item">
                      <a href="#" class="nav-link">
                        <i class="far fa-dot-circle nav-icon"></i>
                        <p>Hukuman</p>
                      </a>
                    </li>
                  </ul>
                </li>

                <li class="nav-item has-treeview">
                  <a href="#" class="nav-link">
                    <i class="far fa-circle nav-icon"></i>
                    <p>
                      Nilai terpuji
                      <i class="right fas fa-angle-left"></i>
                    </p>
                  </a>
                  <ul class="nav nav-treeview">
                    <li class="nav-item">
                      <a href="<?=BASEURL?>/dutiful" class="nav-link">
                        <i class="far fa-dot-circle nav-icon"></i>
                        <p>Aturan</p>
                      </a>
                    </li>
                    <li class="nav-item">
                      <a href="#" class="nav-link">
                        <i class="far fa-dot-circle nav-icon"></i>
                        <p>Apresiasi</p>
                      </a>
                    </li>
                  </ul>
                </li>
                <!--  -->
              </ul>
            </li>
            <li class="nav-item">
                <a href="<?=BASEURL?>/action" class="nav-link">
                 <i class="fa fa-balance-scale nav-icon"></i>
                 <p>Tindakan</p>
               </a>
            </li>
          <?php endif ?>

          <li class="nav-header">INFORMATION</li>
          <li class="nav-item text-center">
            <a href="#" class="btn btn-primary btn-block">
              <i class="fa fa-rocket nav-icon"></i>
              Documentation
            </a>
          </li>
        </ul>
      </nav>
      <!-- /.sidebar-menu -->
    </div>
    <!-- /.sidebar -->
  </aside>