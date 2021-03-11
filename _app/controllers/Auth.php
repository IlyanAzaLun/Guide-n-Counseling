<?php 
/**
 * Auth user.
 */
class Auth extends Controller
{
	private $username;
	private $password;
	private $tmp;
	private $result;

	function __construct()
	{
		$this->validator(!isset($_SESSION['user']), '');
		$request = $this->model('M_home')->load_configuration();
		$value = null;
		foreach ($request as $key) {
			if("title"==$key['variable']){
				$this->title = $key['value'];
			};
			if("contact"==$key['variable']){
				$this->contact = $key['value'];
			};
			if("logo"==$key['variable']){
				$this->logo = $key['value'];
			};
		}
	}

	public function index()
	{
		$this->view('components/_auth_header');
		$this->view('auth/index');
		$this->view('components/_auth_footer');
	}

	public function login()
	{
		$this->NIP = $_POST['NIP'];
		$this->password = sha1($_POST['password']);
		$this->tmp = array(
			'NIP' => $this->NIP,
			'password' => $this->password,
		);

		$this->result = $this->model('M_auth')->auth($this->tmp);
		if ($this->result) {
			$_SESSION['user'] = array(
				'NIP' 	=> $this->result['NIP'],
				'homeroom_teacher' 	=> $this->result['homeroom_teacher'],
				'class' => $this->result['class']
			);
		header('Location: '.BASEURL);
		}else{
			$this->index();
			echo("
				<script>

					Swal.fire({
						icon: 'error',
						title: 'Oops... ',
						text: 'Your Username or Password incorrect.!'
					})
				</script>");
		}
	}

	public function register()
	{
		$this->view('components/_auth_header');
		$this->view('auth/register');
		$this->view('components/_auth_footer');
	}

	public function validation()
	{
		// if(@$_POST['NIP']){
		if(false){
			try {
				$this->result = $this->model('M_auth')->register($_POST);
				$this->setFlash($this->result);
			} catch (Exception $e) {
				Flasher::setFlash('error', ',Failed !', $e);
				header('Location: '.BASEURL.'/auth/register');
				exit;
			}
		}else{
			header('Location: '.BASEURL.'/');
			exit;
		}
	}

	public function setFlash($data){
		if ($data > 0) {
			Flasher::setFlash('success', ',Success !', ',to create account');
			header('Location: '.BASEURL.'/');
			exit;
		}else{
			Flasher::setFlash('error', ',Failed !', ',to create account');
			header('Location: '.BASEURL.'/');
			exit;
		}
	}

	public function logout(){
		session_destroy();
		header('Location: '.BASEURL);
	}
}