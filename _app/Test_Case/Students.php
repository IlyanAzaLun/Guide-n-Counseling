<?php 
/**
 * 
 */
abstract class Students{
	public function index(){
		return true;
	}
	public function insert($data){
		return (isset($data))? true: false;
	}
	public function update($data){
		return (isset($data))? true : false;;
	}
	public function delete($data){
		if(bin2hex($data['user'])==='5374616666'){
			return true;
		}else{
			return false;
		}
	}
}