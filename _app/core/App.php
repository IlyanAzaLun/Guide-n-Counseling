<?php 
/**
 * Class ini digunakan untuk Routing URL agar penggunaan url menjadi rapih. 
 * <!-- App.php -->
 */
class App
{
	protected $controller = 'Home';
	protected $method = 'index';
	protected $params = [];

	function __construct(){
		$url = $this->parseURL();
		// menggambil array pertama[0] dari url dijadikan controller
		if (isset($url[0])) {
			if (file_exists('_app/controllers/'.ucwords($url[0]).'.php')) {
				$this->controller = ucwords($url[0]);
				// var_dump($url);
				unset($url[0]);
			}
		}
		require_once '_app/controllers/'.$this->controller.'.php';
		$this->controller = new $this->controller;

		// menggambil array kedua[1] dari url, dijadikan method
		if (isset($url[1])) {
			if (method_exists($this->controller, $url[1])) {
				$this->method = $url[1];
				unset($url[1]);
			}
		}

		// menggambil parameter terakhir jika ada, menjadikannnya parameter
		if (!empty($url)) {
			$this->params = array_values($url);
		}
		// jalankan controler dan method, kirim parameter jika ada
		call_user_func_array([$this->controller, $this->method], $this->params);
	}

	public function parseURL(){
		if(isset($_GET['url'])){
			$url = rtrim($_GET['url'],'/');
			$url = filter_var($url, FILTER_SANITIZE_URL);
			$url = explode('/', $url);
			return $url;
		}
	}
}