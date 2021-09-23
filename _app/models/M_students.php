<?php
/**
 * for section page
 */
class M_students
{
	private $db;
	
	function __construct(){
		$this->db = new Database;
	}

	public function count_student()
	{
		$this->db->query('SELECT COUNT(`NISS`) AS total_students 
						  FROM `tbl_student` 
						  LIMIT 1');
		$this->db->execute();
		return $this->db->single();
	}

	public function students()
	{
		$this->db->query('SELECT 
							`NISN`, 
							`NISS`, 
							`fullname`, 
							`gender`, 
							`class` 
						  FROM `tbl_student`');
		$this->db->execute();
		return $this->db->resultSet();
	}

	public function select_studentBy_NISN($NISS)
	{
		$sql = 'SELECT 
					`NISN`, 
					`NISS`, 
					`fullname`, 
					`gender`, 
					`class`, 
					`photo`, 
					`status`, 
					`counseling` 
				FROM `tbl_student` 
				WHERE `NISS` = :NISS ';
		$sql .= ( $_SESSION['user']['class'] !== "staff") ? 'AND `class` =\''.$_SESSION['user']['class'].'\';' : ';';
		$this->db->query($sql);
		$this->db->bind('NISS',$NISS);
		$this->db->execute();
		return $this->db->single();
	}
	
	public function render($class)
	{
		$sql = 'SELECT 
				    student.`NISN`, 
				    student.`NISS`,
				    student.`fullname`, 
				    student.`gender`,  
				    student.`class`, 
				    student.`status`, 
				    student.`counseling`, 
					teacher.`homeroom_teacher`,
				    max(report.date) as date
				FROM tbl_student student 
				LEFT JOIN tbl_reporting report 
				ON student.NISS = report.NISS
				JOIN tbl_teacher teacher
				ON student.class = teacher.class';
		$sql .= ($class !== "YWxs") ? ' WHERE student.class = :class 
				GROUP BY student.NISS;' : '
				GROUP BY student.NISS;';
		$this->db->query($sql);
		if ($class !== "YWxs") {
			$this->db->bind('class', base64_decode($class));
		}
		$this->db->execute();
		return $this->db->resultSet();
	}

	//create page, with title content and date
	public function insert_student($data)
	{
		$this->db->query('
			INSERT INTO `tbl_student`(
			 `NISN`, `NISS`, `fullname`, `gender`, `class`)
			VALUES(
			:NISN, :NISS, :fullname, :gender, :class);
		');
		$this->db->bind('NISN',(int)$data['NISN']);
		$this->db->bind('NISS',(int)$data['NISS']);
		$this->db->bind('fullname',strtoupper($data['fullname']));
		$this->db->bind('gender',$data['gender']);
		$this->db->bind('class',$data['class']);
		$this->db->execute();
		 
		return $this->db->rowCount();
	}

	public function insert_multiple_student($data)
	{
		foreach ($data as $key => $value) {
			if($key == 1) {continue;}
			$this->db->query('INSERT INTO `tbl_student`(`NISN`, `NISS`, `fullname`, `gender`, `class`)
							  VALUES(:NISN, :NISS, :fullname, :gender, :class);');
			$this->db->bind('NISN',(int)$value['A']);
			$this->db->bind('NISS',(int)$value['B']);
			$this->db->bind('fullname',strtoupper($value['C']));
			$this->db->bind('gender',$value['D']);
			$this->db->bind('class',($_SESSION['user']['class'] === "staff" || $_SESSION['user']['class'] === "school") ? $value['E'] : $_SESSION['user']['class']);
			$this->db->execute();

		}
		return $this->db->rowCount();
	}

	public function update($data)
	{
		$this->db->query('UPDATE `tbl_student` 
			              SET `NISN` = :NISN, 
			                  `fullname` = :name, 
			                  `class` = :class, 
			                  `status` = :status, 
			                  `counseling` = :counseling 
			              WHERE `NISS` = :NISS');
		$this->db->bind('NISN', $data['NISN']);
		$this->db->bind('NISS', $data['NISS']);
		$this->db->bind('name', $data['name']);
		$this->db->bind('class', $data['class']);
		$this->db->bind('status', (int)$data['status']);
		$this->db->bind('counseling', (int)$data['counseling']);
		$this->db->execute();
		return $this->db->rowCount();
	}

	public function updatefoto($data)
	{
		$this->db->query('UPDATE `tbl_student` SET`photo` = :url WHERE `NISS` = :NISS');
		$this->db->bind('NISS', $data['NISS']);
		$this->db->bind('url', $data['url']);
		$this->db->execute();
		return $this->db->rowCount();
	}

	public function delete($data)
	{
		$this->db->query('DELETE FROM `tbl_student` WHERE `tbl_student`.`NISS` = :NISS');
		$this->db->bind('NISS', $data['NISS']);
		$this->db->execute();
		return $this->db->rowCount();
	}
}