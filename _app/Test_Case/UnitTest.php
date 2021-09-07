<?php 
use PHPUnit\Framework\TestCase;
spl_autoload_register(function($class){
	$class = explode('\\', $class);
	$class = end($class);
	require_once $class.'.php';
});
/**
 * Unit-unit untuk Test Uji
 * To run
 * ../vendor/bin/phpunit UnitTest.php
 */
class UnitTest extends TestCase
{
    // public function testStudent_index(){
    // 	$this->assertEquals(true,Students::index());
    // }
    // public function testStudent_insert(){
    // 	$this->assertEquals(true,Students::insert(true));
    // }
    // public function testStudent_update(){
    // 	$this->assertEquals(true,Students::update(true));
    // }
    // public function testStudent_delete(){
    //     $data = array('user' => "Staff" );
    // 	$this->assertEquals(true,Students::delete($data));
    // }


    protected function dataUser($type){
        return array('type' => $type);
    }
    public function testTeacher_index(){
    	$this->assertEquals(true,Teacher::index());
    }
    public function testTeacher_insert(){
    	$this->assertEquals(true,Teacher::insert($this->dataUser(true)));
    }
    public function testTeacher_update(){
    	$this->assertEquals(true,Teacher::update($this->dataUser(true)));
    }
    public function testTeacher_delete(){
    	$this->assertEquals(true,Teacher::delete($this->dataUser(true)));
    }


    // public function testRule_index(){
    // 	$this->assertEquals(true,Rules::index());
    // }
    // public function testRule_insert(){
    // 	$this->assertEquals(true,Rules::insert(true));
    // }
    // public function testRule_update(){
    // 	$this->assertEquals(true,Rules::update(true));
    // }
    // public function testRule_delete(){
    // 	$this->assertEquals(true,Rules::delete(true));
    // }


    // public function testReport(){
    //     $this->assertEquals(true,Report::index()); 
    // }
    // public function testReport_insert(){
    // 	$this->assertEquals(true,Report::insert(true));
    // }
    // public function testReport_prosess(){
    // 	$this->assertEquals(true,Report::prosess(true));
    // }
}