<?php
/**
 * 
 */
class M_auth
{
	private $db;
	
	function __construct(){
		$this->db = new Database;
	}
	public function auth($data)	{
		$this->db->query('SELECT * FROM `tbl_teacher` WHERE `NIP`=:NIP AND `password`=:password');
		$this->db->bind('NIP',$data['NIP']);
		$this->db->bind('password',$data['password']);
		$this->db->execute();
		return $this->db->single();
	}

	public function register($data)	{
		$this->db->query('
		INSERT INTO `tbl_teacher`(
			`id`
			, `username`
			, `fullname`
			, `password`
			, `privilege`
		) VALUES (
			uuid()
			, :username
			, :fullname
			, :password
			, :privilege
		)');
		$this->db->bind('username',strip_tags($data['username']));
		$this->db->bind('fullname',strip_tags($data['fullname']));
		$this->db->bind('password',sha1($data['password']));
		$this->db->bind('privilege',"0");
		// $this->db->execute();
		// return $this->db->rowCount();
		return false;
	}
}