<?php 
/**
 * Admin dashboard
 */
class Reports extends Controller
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
		
	}
}