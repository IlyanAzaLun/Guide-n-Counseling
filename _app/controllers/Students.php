<?php
use Ramsey\Uuid\Uuid;
require_once dirname(__FILE__) . '/../vendor/phpoffice/phpexcel/Classes/PHPExcel/IOFactory.php';
/**
 * section on main page.
 */
class Students extends Controller
{
	private $request;
	function __construct()
	{
		$this->validator($_SESSION['user'], 'auth');
		$this->validator(!($_SESSION['user']['class'] === ""||$_SESSION['user']['class'] === null), '');
		
		$this->request = $this->model('M_home');
		foreach ($this->request->load_configuration() as $key) {
			if("title"==$key['variable']){
				$this->title = $key['value'];
			};
		}
	}

	public function index($class = 0)
	{
		$this->validator($class, '');
		# code...
		$data['students'] = $this->model('M_students')->render($class);
		$data['class'] = $this->request->load_class();
		$this->page['title'] = 'Students';
		$this->view('components/_header');

		//  summernote
		// $this->style('plugins/summernote/summernote-bs4');
		$this->style('plugins/datatables-bs4/css/dataTables.bootstrap4.min');
		$this->style('plugins/datatables-responsive/css/responsive.bootstrap4.min');
		$this->style('plugins/datatables-buttons/css/buttons.bootstrap4.min');

		$this->view('components/sidebar');
		$this->view('components/content-header');
		//view
		$this->view('student/index', $data);
		$this->view('student/modal', $data);
		//view
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
	}

	public function insert() // create page for promotion or event
	{
		if ($_POST) {
			if ($this->model('M_students')->insert_student($_POST) > 0) {
				Flasher::setFlash('success', ',Success !', ',to add student');
				header('Location: '.$_SERVER['HTTP_REFERER']);
				exit;
			}else{
				Flasher::setFlash('error', ',Failed !', ',to add student');
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

	public function import()
	{
		$file = $_FILES['file']['name'];
		$ekstensi = explode(".", $file);
		$file_name = "file-".round(microtime(true)).".".end($ekstensi);
		$sumber = $_FILES['file']['tmp_name'];
		$target_dir = getcwd()."/_assets/files/";
		$target_file = $target_dir.$file_name;
		move_uploaded_file($sumber, $target_file);

		$exce = PHPExcel_IOFactory::load($target_file);
		$data = $exce->getActiveSheet()->toArray(null, true, true, true);

		if($this->model('M_students')->insert_multiple_student($data) > 0){
			Flasher::setFlash('success', ',Success !', ',to add your students');
			header('Location: '.$_SERVER['HTTP_REFERER']);
			exit;
		}else{
			Flasher::setFlash('warning', ',Error !', ',check again your data if updateed don\'t worry');
			header('Location: '.$_SERVER['HTTP_REFERER']);
			exit;
		}
		unlink($target_file);
	}


// FOR PRODUCT
	public function info($id=0)
	{
		$this->validator($id, 'section');
		$data['page'] = $this->model('M_section')->select_page($id);
		$data['page']['exist'] = $this->model('M_page')->get_last_index();
		$data['page']['image'] = $this->model('M_banner')->select_image($id);
		$this->page['title'] = 'Update Section';
		$this->view('components/_header');

		//  summernote
		$this->style('plugins/summernote/summernote-bs4');

		$this->style('dist/css/pages/section/style');
		$this->view('components/sidebar');
		$this->view('components/content-header');
		
		if(!@$data['page']['index']){$this->view('components/404');}
		else{$this->view('section/info', $data);}

		$this->view('components/content-footer');

		$this->script('plugins/datatables/jquery.dataTables.min');
		$this->script('plugins/datatables-bs4/js/dataTables.bootstrap4.min');
		$this->script('plugins/datatables-responsive/js/dataTables.responsive.min');
		$this->script('plugins/datatables-responsive/js/responsive.bootstrap4.min');
						//  summernote
		$this->script('plugins/summernote/summernote-bs4.min');
		
		$this->script('plugins/datatables-buttons/js/dataTables.buttons.min');
		$this->script('plugins/datatables-buttons/js/buttons.bootstrap4.min');
		$this->script('dist/js/pages/section/index', 'module');

		$this->view('components/_footer');

	}

	public function update_info()
	{
		$data['page']['image'] = $this->model('M_banner')->select_image($_POST['id']);
		$result = array();
		$image = [];
		$id_image = [];
		$upload = Upload::upload_multiple($this->slugify($_POST['title']));
		
		while (count($upload)) {
			list($key, $value) = array_splice($upload, 0,2);
			$key = $key ? "true" : "false"; 
			$result[$value] = $key; 
		}

		while ($images = current($result)) {
			if ($images == "true") {
				array_push($image, key($result));
			}
			next($result);
		}
		$i = 0 ;
		unset($_POST['id_image']);
		$_POST['id_image'] = [];
		$_POST['image'] = [];
		foreach ($_FILES['image']['error'] as $key => $value) {
			if ($value === 0) {
				$img = explode('/', $data['page']['image'][$key-1]['url']);
				unlink(Upload::destination().end($img));
				array_push($_POST['id_image'], $data['page']['image'][$key-1]['id']);
				array_push($_POST['image'],$image[$i]);
				$i++;
			}
		}
		if($this->model('M_section')->update_page($_POST)){
			Flasher::setFlash('success', ',Success !', ',to update your section');
			header('Location: '.BASEURL.'/section');
			exit;
		}else{
			Flasher::setFlash('warning', ',Error !', ',check again your data if updateed don\'t worry');
			header('Location: '.BASEURL.'/section');
			exit;
		}
	}

	public function remove()
	{
		$data['page']['image'] = $this->model('M_banner')->select_image($_POST['id_content']);
		$data['info']['image'] = $this->model('M_product')->select($_POST['id_content']);

		$image = [];
		foreach ($data['page']['image'] as $key => $value) {
			$image_page = explode('/', $value['url']);
			array_push($image, Upload::destination().end($image_page));
		}
		foreach ($data['info']['image'] as $key => $value) {
			$image_info = explode('/', $value['url']);
			array_push($image, Upload::destination().end($image_info));
		}
		if ($this->model('M_section')->remove_page($_POST['id_content'])) {
			foreach ($image as $value) {
				unlink($value);
			}
			Flasher::setFlash('success', ',Success !', ',to remove your section');
			header('Location: '.BASEURL.'/section');
			exit;
		}else{
			Flasher::setFlash('error', ',Failed !', ',to remove your section');
			header('Location: '.BASEURL.'/section');
			exit;
		}
	}
}

