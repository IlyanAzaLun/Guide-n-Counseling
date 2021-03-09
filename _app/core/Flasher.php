<?php 
/**
 * <!-- Flasher.php -->
 */
class Flasher{
	
	public static function setFlash($icon, $title, $text){
		$_SESSION['flash'] = $icon.$title.$text;
	}

	public static function getFlash(){
		if (isset($_SESSION['flash'])) {
			$var = $_SESSION['flash'];
		}
		unset($_SESSION['flash']);
		return $var;
	}

}