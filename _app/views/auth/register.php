<!-- register.php -->
</head>
<body class="hold-transition register-page">
  <div class="register-box">
    <div class="register-logo">
      <a href="<?=BASEURL?>"><b><?=$this->title?></a>
      </div>

      <!-- Flasher -->
      <div class="flash" data-flashType='<?=@Flasher::getFlash()?>'></div>
      <!-- Flasher -->

      <div class="card">
        <div class="card-body register-card-body">
          <p class="login-box-msg">Register a new membership</p>

          <form action="<?=BASEURL?>/auth/validation" method="post" id="register">
            <div class="input-group mb-3">
              <input type="text" class="form-control" name="fullname" placeholder="Full name">
              <div class="input-group-append">
                <div class="input-group-text">
                  <span class="fas fa-user"></span>
                </div>
              </div>
            </div>
            <div class="input-group mb-3">
              <input type="text" class="form-control" name="username" placeholder="Username">
              <div class="input-group-append">
                <div class="input-group-text">
                  <span class="fas fa-user"></span>
                </div>
              </div>
            </div>
            <div class="input-group mb-3">
              <input type="password" class="form-control" name="password" id="password" placeholder="Password">
              <div class="input-group-append">
                <div class="input-group-text">
                  <span class="fas fa-lock"></span>
                </div>
              </div>
            </div>
            <div class="input-group mb-3">
              <input type="password" class="form-control" name="re_password" id="re_password" placeholder="Retype password">
              <div class="input-group-append">
                <div class="input-group-text">
                  <span class="fas fa-lock"></span>
                </div>
              </div>
            </div>
            <div class="row">
              <div class="col-8">
              </div>
              <!-- /.col -->
              <div class="col-4">
                <button type="submit" class="btn btn-primary btn-block">Register</button>
              </div>
              <!-- /.col -->
            </div>
          </form>

          <div class="social-auth-links text-center mb-3">
            <p>- OR -</p>
            <a href="<?=BASEURL?>" class="btn btn-block btn-primary">
              <i class="fa fa-arrow-left mr-2"></i> Back to Site
            </a>
          </div>

          <p class="mb-0">
            <a href="<?=BASEURL?>" class="text-center">I already have a membership</a>
          </p>

        </div>
        <!-- /.form-box -->
      </div><!-- /.card -->
    </div>
<!-- /.register-box -->