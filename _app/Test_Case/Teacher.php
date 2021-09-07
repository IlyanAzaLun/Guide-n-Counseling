<?php 
/**
 * 
 */
class Teacher{
	public function index(){
		return true;
	}
	public function insert($data){
		return ($data['type'])?true:false;
	}
	public function update($data){
		return ($data['type'])?true:false;
	}
	public function delete($data){
		return ($data['type'])?true:false;
	}
}