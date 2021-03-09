<?php 
/**
 * Admin dashboard
 */
class Home extends Controller
{
	
	function __construct()
	{
		$this->validator($_SESSION['user'], 'auth');
		
		$request = $this->model('M_home')->load_configuration();
		$value = null;
		foreach ($request as $key) {
			if("title"==$key['variable']){
				$this->title = $key['value'];
			};
		}
	}
	public function index()
	{		
		$this->page['title'] = 'Dashboard';
		$this->view('components/_header');

		$this->view('components/sidebar');
		$this->view('components/content-header');
		$this->view('home/index');
		$this->view('components/content-footer');

		$this->view('components/_footer');
	}
}