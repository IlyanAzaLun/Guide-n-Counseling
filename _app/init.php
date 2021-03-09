<?php 
	require_once 'config/config.php';
	require 'vendor/autoload.php';
	
	spl_autoload_register(function($class){
		$class = explode('\\', $class);
		$class = end($class);
		require_once __DIR__.'/core/'.$class.'.php';
	});
