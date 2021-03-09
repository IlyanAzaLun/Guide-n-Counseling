</head>
<body class="hold-transition login-page">
<div class="login-box">
  <div class="login-logo">
    <a href="<?=BASEURL?>"><b><?=$this->title?></b></a>
  </div>

  <!-- Flasher -->
  <div class="flash" data-flashType='<?=@Flasher::getFlash()?>'></div>
  <!-- Flasher -->

  <!-- /.login-logo -->
  <div class="card">
    <div class="card-body login-card-body">
      <p class="login-box-msg">Sign in to start your session</p>

      <form action="<?=BASEURL?>/auth/login" method="post" id="login">
        <div class="input-group mb-3">
          <input type="text" name="NIP" class="form-control" placeholder="NIP">
          <div class="input-group-append">
            <div class="input-group-text">
              <span class="fas fa-user"></span>
            </div>
          </div>
        </div>
        <div class="input-group mb-3">
          <input type="password" name="password" class="form-control" placeholder="Password">
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
            <button type="submit" class="btn btn-primary btn-block">Sign In</button>
          </div>
          <!-- /.col -->
        </div>
      </form>

      <div class="social-auth-links text-center mb-3">
        <p>- OR -</p>
        <a href="<?=HOSTURL?>" class="btn btn-block btn-primary">
          <i class="fa fa-arrow-left mr-2"></i> Back to Site
        </a>
      </div>

      <p class="mb-0">
        <a href="<?=BASEURL?>/auth/register" class="text-center">Register a new membership</a>
      </p>
    </div>
    <!-- /.login-card-body -->
  </div>
</div>
<!-- /.login-box -->