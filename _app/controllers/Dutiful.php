<?php 

class Dutiful extends Controller
{	
	private $data;
	private $limit = 6;
	private $pageing  = 1;
	private $request;
	function __construct()
	{
		$this->validator($_SESSION['user'], 'auth');
		$this->validator(($_SESSION['user']['class'] === "staff"), '');
		
		$this->request = $this->model('M_home');
		foreach ($this->request->load_configuration() as $key) {
			if("title"==$key['variable']){
				$this->title = $key['value'];
			};
		}
	}

	public function index()
	{
		$data['dutiful'] = $this->model('M_criteria')->select_criteria('dutiful');
		$this->page['title'] = 'List rule of Dutiful';
		$this->view('components/_header');
				//  datatabels		
		$this->style('plugins/datatables-bs4/css/dataTables.bootstrap4.min');
		$this->style('plugins/datatables-responsive/css/responsive.bootstrap4.min');
		$this->style('plugins/datatables-buttons/css/buttons.bootstrap4.min');

		$this->view('components/sidebar');
		$this->view('components/content-header');
		$this->view('criteria/dutiful/index', $data);
		$this->view('criteria/dutiful/modal', $data);
		$this->view('components/content-footer');
				//  datatabels

		$this->script('plugins/datatables/jquery.dataTables.min');
		$this->script('plugins/datatables-bs4/js/dataTables.bootstrap4.min');
		$this->script('plugins/datatables-responsive/js/dataTables.responsive.min');
		$this->script('plugins/datatables-responsive/js/responsive.bootstrap4.min');
		$this->script('plugins/datatables-buttons/js/dataTables.buttons.min');
		$this->script('plugins/datatables-buttons/js/buttons.bootstrap4.min');

		$this->script('dist/js/pages/criteria/index', 'module');
		$this->view('components/_footer');
	}

	public function insert()
	{
		if($this->model('M_criteria')->insert_criteria('dutiful', $_POST)){
			Flasher::setFlash('success', ',Success !', ',to add rule');
			header('Location: '.$_SERVER['HTTP_REFERER']);
			exit;
		}else{
			Flasher::setFlash('error', ',Failed !', ',to add rule');
			header('Location: '.$_SERVER['HTTP_REFERER']);
			exit;
		}
	}

	public function delete()
	{
		$this->validator(!empty($_POST), 'dutiful');
		if($this->model('M_criteria')->remove_all_criteria($_POST)){
			Flasher::setFlash('success', ',Success !', ',to remove rule');
			header('Location: '.$_SERVER['HTTP_REFERER']);
			exit;
		}else{
			Flasher::setFlash('error', ',Failed !', ',to remove rule');
			header('Location: '.$_SERVER['HTTP_REFERER']);
			exit;
		}
	}

	public function get_data_dutiful()
	{
		$this->validator(!empty($_POST), 'dutiful');
		try {
			echo json_encode($this->model('M_criteria')->select_criteria($_POST['type']));
		} catch (Exception $e) {
			echo $e;
		}
	}

	public function delete_criteria()
	{
		$this->validator(!empty($_POST), 'dutiful');
		if($this->model('M_criteria')->remove_criteria('dutiful', $_POST)){
			Flasher::setFlash('success', ',Success !', ',to remove criteria');
			header('Location: '.$_SERVER['HTTP_REFERER']);
			exit;
		}else{
			Flasher::setFlash('error', ',Failed !', ',to remove criteria');
			header('Location: '.$_SERVER['HTTP_REFERER']);
			exit;
		}
	}

	public function update()
	{
		$this->validator(!empty($_POST), 'dutiful');
		$insert['criteria'] = [];
		$update['criteria'] = [];
		$insert['weight'] = [];
		$update['weight'] = [];
		$update['id'] = [];
		foreach ($_POST['criteria'] as $key => $values) {
			if(@$_POST['id'][$key]==NULL){
				array_push($insert['criteria'], $values);
				array_push($insert['weight'], $_POST['weight'][$key]);
			}else{
				array_push($update['criteria'], $values);
				array_push($update['weight'], $_POST['weight'][$key]);
				array_push($update['id'], $_POST['id'][$key]);
			}
		}
		if($this->model('M_criteria')->update_criteria('dutiful', $update, $insert)){
			Flasher::setFlash('success', ',Success !', ',to remove criteria');
			header('Location: '.$_SERVER['HTTP_REFERER']);
			exit;
		}else{
			Flasher::setFlash('error', ',Failed !', ',to remove criteria');
			header('Location: '.$_SERVER['HTTP_REFERER']);
			exit;
		}
	}
}