<?php 
/**
 * <!-- M_home.php -->
 */
class M_home{
	private $db;
	
	function __construct(){
		$this->db = new Database;
	}

	public function load_configuration(){
		$this->db->query('SELECT * FROM tbl_configuration');
		$this->db->execute();
		return $this->db->resultSet();
	}

	public function load_class()
	{
		$this->db->query('SELECT class FROM tbl_teacher WHERE class != "school" OR "staff"');
		$this->db->execute();
		return $this->db->resultSet();
	}
}