<?php 
require_once dirname(__FILE__) . '/../vendor/phpoffice/phpexcel/Classes/PHPExcel/IOFactory.php';
/**
 * Auth user.
 */
class Teacher extends Controller
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
		$data['total_links'] = ceil(sizeof($this->model('M_teacher')->read($_SESSION['user']['NIP']))/$this->limit);
		$this->page['title'] = 'List Homeroom Teacher';
		$this->view('components/_header');

		$this->view('components/sidebar');
		$this->view('components/content-header');
		$this->view('teacher/index', $data);
		$this->view('teacher/modal');
		$this->view('components/content-footer');
				//  vallidation
		$this->script('plugins/jquery-validation/jquery.validate.min');
		$this->script('plugins/jquery-validation/additional-methods.min');
		$this->script('dist/js/pages/teacher/index', 'module');
		
		$this->view('components/_footer');
	}

	public function req_users(){
		$this->validator($_POST, 'teacher');
		if($_POST['page'] > 1){
			$start = (($_POST['page'] - 1) * $this->limit);
			$this->pageing  = $_POST['page'];
		}else{
			$start = 0;
		}

		if($_POST['query'] != ''){
			$this->data['users'] = $this->req_search($_POST['query'], $start, $this->limit);

		}else{
			$this->data['users'] = $this->model('M_teacher')->readAll($_SESSION['user']['NIP'], $start, $this->limit);
			$this->view('teacher/content', $this->data);
		}

		return $this->data['users'];

	}

	public function req_search($content, $start, $limit){
		try {
			$content = substr_replace($content, '%'.$content.'%', 0, strlen($content));
			$this->data['users'] = $this->model('M_teacher')->readLike($content ,$_SESSION['user']['NIP'], $start, $limit);
			$this->view('teacher/content', $this->data);
		} catch (Exception $e) {
			echo $e;
		}
	}

	public function insert(){ // create page for promotion or event
		if ($_POST) {
			if ($this->model('M_teacher')->insert_teacher($_POST) > 0) {
				Flasher::setFlash('success', ',Success !', ',to add teacher');
				header('Location: '.$_SERVER['HTTP_REFERER']);
				exit;
			}else{
				Flasher::setFlash('error', ',Failed !', ',to add teacher');
				header('Location: '.$_SERVER['HTTP_REFERER']);
				exit;
			}
		}else{
			$this->page['title'] = 'Students';
			$this->view('components/_header');
			$this->view('components/sidebar');
			$this->view('components/content-header');
			$this->view('components/500');
			$this->view('components/content-footer');
			$this->view('components/_footer');	

		}
	}

	public function import(){
		$this->validator($_FILES, 'teacher');

		$file = $_FILES['file']['name'];
		$ekstensi = explode(".", $file);
		$file_name = "file-".round(microtime(true)).".".end($ekstensi);
		$sumber = $_FILES['file']['tmp_name'];
		$target_dir = getcwd()."/_assets/files/";
		$target_file = $target_dir.$file_name;
		move_uploaded_file($sumber, $target_file);

		$exce = PHPExcel_IOFactory::load($target_file);
		$data = $exce->getActiveSheet()->toArray(null, true, true, true);

		if($this->model('M_teacher')->insert_multiple_teacher($data) > 0){
			Flasher::setFlash('success', ',Success !', ',to add homeroom teachers');
			header('Location: '.$_SERVER['HTTP_REFERER']);
			exit;
		}else{
			Flasher::setFlash('warning', ',Error !', ',check again your data if updateed don\'t worry');
			header('Location: '.$_SERVER['HTTP_REFERER']);
			exit;
		}
		unlink($target_file);
	}

	public function truncate()
	{
		if($this->model('M_teacher')->truncate_teacher()){
			Flasher::setFlash('success', ',Success !', ',to empty field teachers');
			header('Location: '.$_SERVER['HTTP_REFERER']);
			exit;
		}else{
			Flasher::setFlash('warning', ',Error !', ',check again your data if updateed don\'t worry');
			header('Location: '.$_SERVER['HTTP_REFERER']);
			exit;
		}
	}
}