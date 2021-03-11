<?php 
/**
 * Admin dashboard
 */
class Home extends Controller
{
	private $request;
	function __construct()
	{
		$this->validator($_SESSION['user'], 'auth');
		
		$this->request = $this->model('M_home');
		$value = null;
		foreach ($this->request->load_configuration() as $key) {
			if("title"==$key['variable']){
				$this->title = $key['value'];
			};
		}
	}
	public function index()
	{	
		$class = $_SESSION['user']['class'];
		$data['type'] = $this->request->select_typeCriteriaAnd_value($class);
		$data['type']['total_student'] = $this->model('M_students')->count_student()['total_students'];
		$this->page['title'] = 'Dashboard';
		$this->view('components/_header');

		$this->view('components/sidebar');
		$this->view('components/content-header');
		$this->view('home/index', $data);
		$this->view('components/content-footer');
		
		//  chart
		$this->script('plugins/chart.js/Chart.min');

		$this->script('dist/js/pages/home/index', 'module');

		$this->view('components/_footer');
	}
}