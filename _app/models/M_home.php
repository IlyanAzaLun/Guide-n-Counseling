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

	public function notification()
	{
		$this->db->query('SELECT 
								report.status as report_status
								, report.type
								, report.NISS
								, report.date
								, criteria.name
								, student.fullname
						  FROM tbl_reporting report
						  JOIN tbl_criteria criteria ON report.id_behavior = criteria.id
						  JOIN tbl_student student ON report.NISS = student.NISS
						  WHERE id_confirmation = :confirmation AND report.status = 1');
		$this->db->bind('confirmation', $_SESSION['user']['NIP']);
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

	public function stats_class($type)
	{
		$this->db->query("
			SELECT 	CAST(fromRoman(class)AS UNSIGNED)as tmp1,
					CAST(ExtractNumber(class)AS UNSIGNED)as tmp2
					, class
			        , type
			        , IFNULL(SUM(weight),0) AS total 
			FROM `v_reportStatistic`
			WHERE type = :type
			GROUP BY class

			-- UNION
			-- SELECT 	CAST(fromRoman(class)AS UNSIGNED)as tmp1,
			-- 		CAST(ExtractNumber(class)AS UNSIGNED)as tmp2
			-- 		, class
			--         , :type
			--         , 0 
			-- FROM `v_reportStatistic`
			-- WHERE weight = 0  
			ORDER BY `tmp1` ASC, `tmp2`;
			");
		$this->db->bind('type', $type);
		$this->db->execute();
		return $this->db->resultSet();
	}
}