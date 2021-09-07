DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_report-pivot`(IN `tbl_name` VARCHAR(255))
    SQL SECURITY INVOKER
BEGIN

    --
    SET @stmt = CONCAT('SELECT GROUP_CONCAT(', 
                                            "CONCAT('SUM(IF(`criteria_name` = ', 
                                             CONCAT('\"', val, '\"'), ', `weight`, 0)) AS ', 
                                             CONCAT('\"', val, '\"'))", ' SEPARATOR \',\') INTO @sums',
                      ' FROM ( ', CONCAT('SELECT ', 'criteria_name', ' AS val ', ' FROM ', 'v_reportDutiful', ' GROUP BY criteria_name'), ' ) AS top');

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
        FROM ','v_reportDutiful',' 
        GROUP BY student_name 
        WITH ROLLUP');
    -- SELECT @stmt2;                       -- The statement that generates the result
    PREPARE _sql FROM @stmt2;
    EXECUTE _sql;                           -- The resulting pivot table ouput
    DEALLOCATE PREPARE _sql;
--

END$$
DELIMITER ;