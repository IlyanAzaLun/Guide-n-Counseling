<?php
/**
 * 
 */
class M_teacher
{
	private $db;
	
	function __construct(){
		$this->db = new Database;
	}
	public function readAll($data, $start, $limit)	{
		$this->db->query('SELECT * FROM `tbl_teacher` WHERE NIP != :NIP LIMIT :start, :limit');
		$this->db->bind('NIP',$data);		
		$this->db->bind('start',$start);
		$this->db->bind('limit',$limit);
		$this->db->execute();
		return $this->db->resultSet();
	}
	public function read($data){
		$this->db->query('SELECT * FROM `tbl_teacher` WHERE NIP != :NIP');
		$this->db->bind('NIP',$data);
		$this->db->execute();
		return $this->db->resultSet();
	}

	public function readMe($data){
		$this->db->query('SELECT * FROM `tbl_teacher` WHERE NIP = :NIP');
		$this->db->bind('NIP',$data);
		$this->db->execute();
		return $this->db->resultSet();
	}

	public function readLike($like, $data, $start, $limit)	{
		$this->db->query('SELECT * FROM `tbl_teacher` WHERE homeroom_teacher LIKE :query AND NIP != :NIP LIMIT :start, :limit');
		$this->db->bind('NIP',$data);
		$this->db->bind('query',$like);
		$this->db->bind('start',$start);
		$this->db->bind('limit',$limit);
		$this->db->execute();
		return $this->db->resultSet();
	}

	//create page, with title content and date
	public function insert_teacher($data)
	{
		$this->db->query('
			INSERT INTO `tbl_teacher`(
			 `NIP`, `homeroom_teacher`, `class`, `password`)
			VALUES(
			:NIP, :homeroom_teacher, :class, :password);
		');
		$this->db->bind('NIP',(int)$data['NIP']);
		$this->db->bind('homeroom_teacher',$data['homeroom_teacher']);
		$this->db->bind('class',strtoupper($data['class']));
		$this->db->bind('password',sha1($data['password']));
		$this->db->execute();
		 
		return $this->db->rowCount();
	}

	public function insert_multiple_teacher($data)
	{
		foreach ($data as $key => $value) {
			if($key == 1) {continue;}
			$this->db->query('INSERT INTO `tbl_teacher`(`NIP`, `homeroom_teacher`, `class`, `password`)VALUES(:NIP, :homeroom_teacher, :class, :password);');
			$this->db->bind('NIP',(int)$value['A']);
			$this->db->bind('homeroom_teacher',$value['B']);
			$this->db->bind('class',strtoupper($value['C']));
			$this->db->bind('password',sha1($value['D']));
			$this->db->execute();

		}
		return $this->db->rowCount();
	}

	public function truncate_teacher()
	{
		$this->db->query('
			DELETE FROM `tbl_teacher` WHERE NIP != :NIP
		');
		$this->db->bind('NIP',$_SESSION['user']['NIP']);
		$this->db->execute();
		return $this->db->rowCount();
	}

	public function update_teacher($data){
		$this->db->query('
		UPDATE `tbl_teacher` SET 
			`homeroom_teacher`=:homeroom_teacher
			,`class`=:class
		WHERE `NIP`=:NIP');
		$this->db->bind('homeroom_teacher', $data['homeroom_teacher']);
		$this->db->bind('class', $data['class']);
		$this->db->bind('NIP', $data['NIP']);
		$this->db->execute();
		return $this->db->rowCount();
	}
}