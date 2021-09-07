<?php 
/**
 * 
 */
class Rules{	
	public function index(){
		return true;
	}
	public function insert($data){
		return $data;
	}
	public function update($data){
		return $data;
	}
	public function delete($data){
		return $data;
	}
}