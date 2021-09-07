DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_reportPivot`(IN `tbl_name` VARCHAR(255))
    SQL SECURITY INVOKER
BEGIN
SET @stmt = CONCAT('SELECT GROUP_CONCAT(', 
                                        "CONCAT('SUM(IF(`criteria_name` = ', 
                                         CONCAT('\"', val, '\"'), ', `weight`, 0)) AS ', 
                                         CONCAT('\"', val, '\"'))", ' SEPARATOR \',\') INTO @sums',
                  ' FROM ( ', CONCAT('SELECT DISTINCT ', 'criteria_name', ' AS val ', ' FROM ', tbl_name, ' ORDER BY 1'), ' ) AS top');

-- SELECT @stmt;
PREPARE _sql FROM @stmt;
EXECUTE _sql;                           -- Intermediate step: build SQL for columns
DEALLOCATE PREPARE _sql;

SET @stmt2 =CONCAT(
    'SELECT
        NISS,
        student_name,',
        @sums,
        ',SUM(weight) AS Total 
    FROM ',tbl_name,' 
    GROUP BY student_name 
    WITH ROLLUP');
-- SELECT @stmt2;                       -- The statement that generates the result
PREPARE _sql FROM @stmt2;
EXECUTE _sql;                           -- The resulting pivot table ouput
DEALLOCATE PREPARE _sql;
END$$
DELIMITER ;