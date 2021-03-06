<?php 
/**
 * 
 */
class M_criteria
{
	private $db;
	
	function __construct(){
		$this->db = new Database;
	}

	public function select_criteria($type)
	{
		$this->db->query("
		SELECT `id`, `name`, `weight` FROM `tbl_criteria` WHERE `type` = :type ;");
		$this->db->bind('type', $type);
		$this->db->execute();
		return $this->db->resultSet();
	}

	public function insert_criteria($type, $data)
	{
		for ($i=0; $i < count($data['criteria']); $i++) { 
			$this->db->query("
			INSERT INTO `tbl_criteria` (`id`, `name`, `weight`, `type`)VALUES (uuid(), :name, :weight, :type);");
			$this->db->bind('name', $data['criteria'][$i]);
			$this->db->bind('weight', (float)$data['weight'][$i]);
			$this->db->bind('type', $type);
			$this->db->execute();
		}
		return $this->db->rowCount();
	}

	public function remove_all_criteria($type)
	{
		$this->db->query("
			DELETE FROM `tbl_criteria` WHERE `type` = :type;");
		$this->db->bind('type', $type['type']);
		$this->db->execute();
		return $this->db->rowCount();
	}

	public function remove_criteria($type, $data)
	{
		$this->db->query("
			DELETE FROM `tbl_criteria` WHERE id = :id AND `type` = :type;");
		$this->db->bind('id', $data['id']);
		$this->db->bind('type', $type);
		$this->db->execute();
		return $this->db->rowCount();
	}

	public function update_criteria($type, $update, $insert)
	{
		if(!empty($insert['criteria'])){
			 $this->insert_criteria($type, $insert);
		}
		for ($i=0; $i < count($update['criteria']); $i++) { 
			$this->db->query("
			UPDATE `tbl_criteria` SET `name` = :name, `weight` = :weight WHERE id = :id;");
			$this->db->bind('id', $update['id'][$i]);
			$this->db->bind('name', $update['criteria'][$i]);
			$this->db->bind('weight', (float)$update['weight'][$i]);
			$this->db->execute();
		}

		return $this->db->rowCount();
	}
}