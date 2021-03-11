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

	public function select_typeCriteriaAnd_value($class)
	{
		$this->db->query("
		SELECT 
		(SELECT COUNT(tbl_reporting.type) FROM tbl_reporting 
			 JOIN tbl_student ON tbl_reporting.NISS = tbl_student.NISS  
			 WHERE tbl_reporting.type = 'tolerance') as total_tolerance
		,(SELECT SUM(tbl_criteria.weight) FROM tbl_reporting 
			 JOIN tbl_criteria ON tbl_reporting.id_behavior = tbl_criteria.id  
			 JOIN tbl_student ON tbl_reporting.NISS = tbl_student.NISS  
			 WHERE tbl_reporting.type = 'violation') as total_violation
		,(SELECT SUM(tbl_criteria.weight) FROM tbl_reporting 
			 JOIN tbl_criteria ON tbl_reporting.id_behavior = tbl_criteria.id
			 JOIN tbl_student ON tbl_reporting.NISS = tbl_student.NISS
			 WHERE tbl_reporting.type = 'dutiful') as total_dutiful
		FROM `tbl_reporting` 
		JOIN tbl_student ON tbl_reporting.NISS = tbl_student.NISS
		GROUP BY tbl_student.class LIMIT 1
			");
		// $this->db->bind();
		$this->db->execute();
		return $this->db->single();
		/**
		SELECT 
		(SELECT COUNT(tbl_reporting.type) FROM tbl_reporting 
			 JOIN tbl_student ON tbl_reporting.NISS = tbl_student.NISS  
			 WHERE tbl_reporting.type = 'tolerance' AND tbl_student.class = 'X-1') as total_tolerance
		,(SELECT SUM(tbl_criteria.weight) FROM tbl_reporting 
			 JOIN tbl_criteria ON tbl_reporting.id_behavior = tbl_criteria.id  
			 JOIN tbl_student ON tbl_reporting.NISS = tbl_student.NISS  
			 WHERE tbl_reporting.type = 'violation' AND tbl_student.class = 'X-1') as total_violation
		,(SELECT SUM(tbl_criteria.weight) FROM tbl_reporting 
			 JOIN tbl_criteria ON tbl_reporting.id_behavior = tbl_criteria.id
			 JOIN tbl_student ON tbl_reporting.NISS = tbl_student.NISS
			 WHERE tbl_reporting.type = 'dutiful' AND tbl_student.class = 'X-1') as total_dutiful
		FROM `tbl_reporting` 
		JOIN tbl_student ON tbl_reporting.NISS = tbl_student.NISS
		GROUP BY tbl_student.class
		**/
	}
}