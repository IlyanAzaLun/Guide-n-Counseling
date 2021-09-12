<?php 
/**
 * 
 */
class M_report
{
	private $db;
	
	function __construct(){
		$this->db = new Database;
	}


	/*  SELLECT REPORT BY NISS
		**dignakan dihalaman student info
	*/
	public function select_reportBy_NISS($NISS)
	{
		$this->db->query('
			SELECT 
				  `report`.`id`
			    , `report`.`id_behavior`
			    , `criteria`.`name`
			    , `report`.`type`
			    , `report`.`NISS`
			    , `report`.`message`
			    , `student`.`fullname`
			    , `student`.`class`
			    , `teacher_reporter`.`homeroom_teacher` AS `reporter`
			    , `teacher_confirmation`.`homeroom_teacher` AS `confirmation`
			    , `report`.`date` 
			FROM tbl_reporting `report`
			JOIN tbl_criteria `criteria` ON `report`.id_behavior = `criteria`.id
			JOIN tbl_student `student` ON `report`.NISS = `student`.NISS
			JOIN tbl_teacher `teacher_reporter` ON `report`.id_reporter = `teacher_reporter`.NIP
			JOIN tbl_teacher `teacher_confirmation` ON `report`.id_confirmation = `teacher_confirmation`.NIP
			WHERE `report`.NISS = :NISS');
		$this->db->bind('NISS', $NISS);
		$this->db->execute();
		return $this->db->resultSet();

	}


	/*  SELLECT REPORT DATE
		**dignakan dihalaman student info
	*/
	public function select_report_date($NISS)
	{
		$this->db->query('
			SELECT `id`, `date` FROM tbl_reporting WHERE NISS = :NISS GROUP BY date DESC');
		
		$this->db->bind('NISS', $NISS);
		$this->db->execute();
		return $this->db->resultSet();
	}


	/*  SELLECT TYPE CRITERIA dan VALUE
		**dignakan dihalaman student info
	*/
	public function select_typeCriteriaAnd_value($NISS)
	{
		$this->db->query("
			SELECT 
		 	(SELECT COUNT(tbl_reporting.type) FROM tbl_reporting WHERE tbl_reporting.type = 'tolerance' AND tbl_reporting.NISS = :NISS) as total_tolerance
			,(SELECT SUM(tbl_criteria.weight) FROM tbl_reporting 
			    JOIN tbl_criteria ON tbl_reporting.id_behavior = tbl_criteria.id    
			 WHERE tbl_reporting.type = 'violation' AND tbl_reporting.NISS = :NISS) as total_violation
			,(SELECT SUM(tbl_criteria.weight) FROM tbl_reporting 
			    JOIN tbl_criteria ON tbl_reporting.id_behavior = tbl_criteria.id 
			  WHERE tbl_reporting.type = 'dutiful' AND tbl_reporting.NISS = :NISS) as total_dutiful
			FROM `tbl_reporting` WHERE tbl_reporting.NISS = :NISS GROUP BY tbl_reporting.NISS;");
		$this->db->bind('NISS', $NISS);
		$this->db->execute();
		return $this->db->single();
	/**
	SELECT 
 	(SELECT COUNT(tbl_reporting.type) FROM tbl_reporting WHERE tbl_reporting.type = 'tolerance' AND tbl_reporting.NISS = '18112015') as total_tolerance
	,(SELECT SUM(tbl_criteria.weight) FROM tbl_reporting 
	    JOIN tbl_criteria ON tbl_reporting.id_behavior = tbl_criteria.id    
	 WHERE tbl_reporting.type = 'violation' AND tbl_reporting.NISS = '18112015') as total_violation
	,(SELECT SUM(tbl_criteria.weight) FROM tbl_reporting 
	    JOIN tbl_criteria ON tbl_reporting.id_behavior = tbl_criteria.id 
	  WHERE tbl_reporting.type = 'dutiful' AND tbl_reporting.NISS = '18112015') as total_dutiful
	FROM `tbl_reporting` WHERE tbl_reporting.NISS = '18112015' GROUP BY tbl_reporting.NISS
	**/
	}

	/*  INSERT REPORT
		**dignakan dihalaman tiapINSERT REPORT : tolerance, violation, dutiful
	*/
	public function insert_report($data, $type)
	{
		for ($i=0; $i < sizeof($data[$type]); $i++) { 
			for ($j=0; $j < sizeof($data['students']) ; $j++) { 
				$this->db->query("
					INSERT INTO tbl_reporting(`id`, `id_behavior`, `type`, `NISS`, `id_reporter`, `id_confirmation`, `message`,`date`)
					VALUES(uuid(), :id_behavior, :type, :NISS, :id_reporter, :id_confirmation, :message, :date);");
				$this->db->bind('id_behavior', $data[$type][$i]);
				$this->db->bind('type', $data['type']);
				$this->db->bind('NISS', (explode(',', $data['students'][$j])[0]));
				$this->db->bind('id_reporter', $data['reporter']);
				$this->db->bind('id_confirmation', $data['teacher-confirmation']);
				$this->db->bind('message', $data['message']);
				$this->db->bind('date', $data['date']);
				$this->db->execute();
		 
			}
		}
		return $this->db->rowCount();
	}

	public function report($tabel = 'v_reportViolation')
	{
		try {
			$this->db->query("CALL sp_reportPivot2(:tabel);");
			$this->db->bind('tabel', $tabel);
			$this->db->execute();
			return  $this->db->resultSet();
			
		} catch (Exception $e) {
			return $e;
		}
	}
}