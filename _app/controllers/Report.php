<?php 
/**
 * Admin dashboard
 */
class Report extends Controller
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
		$data['report'] = $this->model('M_report')->report();
		$data['criteria'] = $this->model('M_criteria')->select_criteria('violation');
	
        foreach (($data['report']) as $key => $value) {
        	$data['tmp'] = ($key == @sizeof($data['report'])-1) ? $value['Total'] : '0' ;
        }
	
		$this->page['title'] = 'Report';
		$this->view('components/_header');

		$this->style('plugins/datatables-bs4/css/dataTables.bootstrap4.min');
		$this->style('plugins/datatables-responsive/css/responsive.bootstrap4.min');
		$this->style('plugins/datatables-buttons/css/buttons.bootstrap4.min');

		$this->view('components/sidebar');
		$this->view('components/content-header');
		$this->view('report/index', $data);
		$this->view('components/content-footer');

		$this->script('plugins/datatables/jquery.dataTables.min');
		$this->script('plugins/datatables-bs4/js/dataTables.bootstrap4.min');
		$this->script('plugins/datatables-responsive/js/dataTables.responsive.min');
		$this->script('plugins/datatables-responsive/js/responsive.bootstrap4.min');
						//  summernote
		// $this->script('plugins/summernote/summernote-bs4.min');
		
		$this->script('plugins/datatables-buttons/js/dataTables.buttons.min');
		$this->script('plugins/datatables-buttons/js/buttons.bootstrap4.min');
		
		$this->script('dist/js/pages/student/index', 'module');
		$this->view('components/_footer');
		// echo "<pre>";
		// var_dump($data['report']);
		// echo "<pre>";
	}

	public function tolerance()
	{	
		$data['students'] = $this->model('M_students')->students();
		$data['violation'] = $this->model('M_criteria')->select_criteria('violation');
		$data['teacher'] = $this->model('M_teacher')->read($_SESSION['user']['NIP']);
		$this->page['title'] = 'Tolerance to students';
		$this->view('components/_header');

		$this->style('plugins/select2/css/select2.min');
		$this->style('plugins/bootstrap4-duallistbox/bootstrap-duallistbox.min');

		$this->view('components/sidebar');
		$this->view('components/content-header');
		$this->view('report/tolerance/index', $data);
		$this->view('components/content-footer');
		
		//select2
		$this->script('plugins/select2/js/select2.full.min');
		$this->script('plugins/bootstrap4-duallistbox/jquery.bootstrap-duallistbox.min');
		$this->script('dist/js/pages/report/index', 'module');

		$this->view('components/_footer');
	}

	public function violation()
	{	
		$data['students'] = $this->model('M_students')->students();
		$data['violation'] = $this->model('M_criteria')->select_criteria('violation');
		$data['teacher'] = $this->model('M_teacher')->read($_SESSION['user']['NIP']);
		$this->page['title'] = 'Behavior Report';
		$this->view('components/_header');

		$this->style('plugins/select2/css/select2.min');
		$this->style('plugins/bootstrap4-duallistbox/bootstrap-duallistbox.min');

		$this->view('components/sidebar');
		$this->view('components/content-header');
		$this->view('report/violation/index', $data);
		$this->view('components/content-footer');
		
		//select2
		$this->script('plugins/select2/js/select2.full.min');
		$this->script('plugins/bootstrap4-duallistbox/jquery.bootstrap-duallistbox.min');
		$this->script('dist/js/pages/report/index', 'module');

		$this->view('components/_footer');
	}

	public function dutiful()
	{
		$data['students'] = $this->model('M_students')->students();
		$data['dutiful'] = $this->model('M_criteria')->select_criteria('dutiful');
		$data['teacher'] = $this->model('M_teacher')->read($_SESSION['user']['NIP']);
		$this->page['title'] = 'Behavior Report';
		$this->view('components/_header');

		$this->style('plugins/select2/css/select2.min');
		$this->style('plugins/bootstrap4-duallistbox/bootstrap-duallistbox.min');

		$this->view('components/sidebar');
		$this->view('components/content-header');
		$this->view('report/dutiful/index', $data);
		$this->view('components/content-footer');
		
		//select2
		$this->script('plugins/select2/js/select2.full.min');
		$this->script('plugins/bootstrap4-duallistbox/jquery.bootstrap-duallistbox.min');
		$this->script('dist/js/pages/report/index', 'module');

		$this->view('components/_footer');
	}

	public function insert($type)
	{
		if($this->model('M_report')->insert_report($_POST, $type)){
			Flasher::setFlash('success', ',Success !', ',to add repor tolerance');
			header('Location: '.$_SERVER['HTTP_REFERER']);
			exit;
		}else{
			Flasher::setFlash('error', ',Failed !', ',to add repor tolerance');
			header('Location: '.$_SERVER['HTTP_REFERER']);
			exit;
		}
	}
}