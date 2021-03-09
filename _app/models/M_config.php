<?php 
/**
 * 
 */
class M_config
{
	private $db;
	
	function __construct(){
		$this->db = new Database;
	}

	public function update_config($data)
	{
		foreach ($data as $key => $value) {
			$this->db->query("
			UPDATE `tbl_configuration` SET `value`= :value WHERE `variable` = :variable ;");
			$this->db->bind('variable', $key );
			$this->db->bind('value', $value);

			$this->db->execute();
		}
		return $this->db->rowCount();
	}
}