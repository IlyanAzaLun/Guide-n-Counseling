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
		$this->validator($class, 0);
		# code...
		$data['students'] = $this->model('M_students')->render($class);
		$data['class'] = $this->request->load_class();
		$this->page['title'] = 'Siswa';
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

		$this->script('plugins/datatables-buttons/js/dataTables.buttons.min');
		$this->script('plugins/datatables-buttons/js/buttons.bootstrap4.min');
		$this->script('plugins/datatables-buttons/js/buttons.print.min');
		$this->script('plugins/datatables-buttons/js/buttons.html5.min');
		$this->script('plugins/datatables-buttons/js/buttons.flash.min');
		$this->script('plugins/datatables-buttons/js/buttons.colVis.min');
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
			$this->page['title'] = 'Siswa';
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
		if ($_FILES) {
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
				unlink($target_file);
				exit;
			}else{
				Flasher::setFlash('warning', ',Error !', ',check again your data if updateed don\'t worry');
				header('Location: '.$_SERVER['HTTP_REFERER']);
				unlink($target_file);
				exit;
			}
			unlink($target_file);
		}else{
			$this->page['title'] = 'Siswa';
			$this->view('components/_header');
			$this->view('components/sidebar');
			$this->view('components/content-header');
			$this->view('components/500');
			$this->view('components/content-footer');
			$this->view('components/_footer');	

		}
	}

	public function info($NISS = '')
	{
		($NISS == '') ? header('Location: '.$_SERVER['HTTP_REFERER']) : true ;
		$data['student'] = $this->model('M_students')->select_studentBy_NISN($NISS);
		if (!$data['student']) {
			Flasher::setFlash('warning', ',Sorry !', ',this student is not yoour class');
			header('Location: '.BASEURL);
			exit;
		}else{
			$request_report = $this->model('M_report');
			$data['report'] = $request_report->select_reportBy_NISS($NISS);
			$data['date'] = $request_report->select_report_date($NISS);
			$data['type'] = $request_report->select_typeCriteriaAnd_value($NISS);
			$this->page['title'] = 'Informasi Siswa';
			$this->view('components/_header');

			$this->view('components/sidebar');
			$this->view('components/content-header');
			//view
			$this->view('student/info', $data);
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
	}

	public function update()
	{
		var_dump($_POST);

		if($_FILES){
			$file = $_FILES['image']['name'];
			$ekstensi = explode(".", $file);
			if(end($ekstensi) == 'png' || end($ekstensi) == 'jpeg' || end($ekstensi) == 'jpg'){
				$file_name = "student-".round(microtime(true)).".".end($ekstensi);
				$sumber = $_FILES['image']['tmp_name'];
				$target_dir = getcwd()."/_assets/photos/";
				$target_file = $target_dir.$file_name;
				move_uploaded_file($sumber, $target_file);

				$_POST['url'] = "/_assets/photos/".$file_name;

				if($this->model('M_students')->updatefoto($_POST) > 0){
					unlink(getcwd().$_POST['tmp']);
					Flasher::setFlash('success', ',Success !', ',to update your students');
					header('Location: '.$_SERVER['HTTP_REFERER']);
					exit;
				}else{
					Flasher::setFlash('danger', ',Failed !', ',check again your data if updateed don\'t worry');
					header('Location: '.$_SERVER['HTTP_REFERER']);
					exit;
				}
			}else{
				Flasher::setFlash('warning', ',Error !', ',image must .png, check again your type image!');
				header('Location: '.$_SERVER['HTTP_REFERER']);
				return false;
			}
		}else{
			if($this->model('M_students')->update($_POST) > 0){
				Flasher::setFlash('success', ',Success !', ',to update your students');
				header('Location: '.$_SERVER['HTTP_REFERER']);
				exit;
			}else{
				Flasher::setFlash('danger', ',Failed !', ',check again your data if updateed don\'t worry');
				header('Location: '.$_SERVER['HTTP_REFERER']);
				exit;
			}
		}
	}

	public function delete()
	{
		var_dump($_POST);
		if($this->model('M_students')->delete($_POST) > 0){
			unlink(getcwd().$_POST['tmp']);
			Flasher::setFlash('success', ',Success !', ',to update your students');
			header('Location: '.$_SERVER['HTTP_REFERER']);
			exit;
		}else{
			Flasher::setFlash('danger', ',Failed !', ',check again your data if updateed don\'t worry');
			header('Location: '.$_SERVER['HTTP_REFERER']);
			exit;
		}
	}
}