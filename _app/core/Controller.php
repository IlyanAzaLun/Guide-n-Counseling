<?php 
/**
 * Class ini di gunakan untuk memilih control apa yang akan di gunakan
 *
 */
class Controller
{
	public function View($view, $data = []){
		require_once '_app/views/'.$view.'.php';
	}

	public function Model($model){
		require '_app/models/'.$model.'.php';
		return new $model;
	}

	public function parseURL(){
		if(isset($_GET['url'])){
			$url = rtrim($_GET['url'],'/');
			$url = filter_var($url, FILTER_SANITIZE_URL);
			$url = explode('/', $url);
			return $url;
		}
	}

	public function validator($identifiers, $direct){
		if ($identifiers) {
			return true;
		}else{
			header('Location: '.BASEURL.'/'.$direct);
		}
	}

	public function Style($css){
		echo quoted_printable_decode('=0A  <link href="'.BASEURL.'/_assets/'.$css.'.css" rel="stylesheet">=0A');
	}

	public function Script($javascript, $type = ''){
		echo quoted_printable_decode('=0A  <script type="'.$type.'" src="'.BASEURL.'/_assets/'.$javascript.'.js"></script>=0A');
	}

	public static function slugify($text)
	{
  // replace non letter or digits by -
		$text = preg_replace('~[^\pL\d]+~u', '-', $text);

  // transliterate
		$text = iconv('utf-8', 'us-ascii//TRANSLIT', $text);

  // remove unwanted characters
		$text = preg_replace('~[^-\w]+~', '', $text);

  // trim
		$text = trim($text, '-');

  // remove duplicate -
		$text = preg_replace('~-+~', '-', $text);

  // lowercase
		$text = strtolower($text);

		if (empty($text)) {
			return 'n-a';
		}

		return $text;
	}

	public function isMobile()
	{
		$ua = strtolower($_SERVER['HTTP_USER_AGENT']);
		$isMob = is_numeric(strpos($ua, "mobile"));

		return $isMob;
	}
}