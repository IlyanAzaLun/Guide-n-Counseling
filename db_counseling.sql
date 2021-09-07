-- phpMyAdmin SQL Dump
-- version 5.1.0
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Aug 23, 2021 at 01:03 PM
-- Server version: 10.4.18-MariaDB
-- PHP Version: 7.3.27

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `db_counseling`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `LoopDemo` ()  BEGIN
	DECLARE x  INT;
	DECLARE str  VARCHAR(255);
        
	SET x = 1;
	SET str =  '';
        
	loop_label:  LOOP
		IF  x > 10 THEN 
			LEAVE  loop_label;
		END  IF;
            
		SET  x = x + 1;
		IF  (x mod 2) THEN
			ITERATE  loop_label;
		ELSE
			SET  str = CONCAT(str,x,',');
		END  IF;
	END LOOP;
	SELECT str;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_pivot` (IN `tbl_name` VARCHAR(99), IN `base_cols` VARCHAR(99), IN `pivot_col` VARCHAR(64), IN `tally_col` VARCHAR(64), IN `where_clause` VARCHAR(99), IN `order_by` VARCHAR(99))  READS SQL DATA
BEGIN
	SET @subq = CONCAT('SELECT DISTINCT ', pivot_col, ' AS val ',
                    ' FROM ', tbl_name, ' ', where_clause, ' ORDER BY 1');
    -- select @subq;

    SET @cc1 = "CONCAT('SUM(IF(&p = ', &v, ', &t, 0)) AS ', &v)";
    SET @cc2 = REPLACE(@cc1, '&p', pivot_col);
    SET @cc3 = REPLACE(@cc2, '&t', tally_col);
    -- select @cc2, @cc3;
    SET @qval = CONCAT("'\"', val, '\"'");
    -- select @qval;
    SET @cc4 = REPLACE(@cc3, '&v', @qval);
    -- select @cc4;

    SET SESSION group_concat_max_len = 10000;   -- just in case
    SET @stmt = CONCAT(
            'SELECT  GROUP_CONCAT(', @cc4, ' SEPARATOR ",\n")  INTO @sums',
            ' FROM ( ', @subq, ' ) AS top');
     select @stmt;
    PREPARE _sql FROM @stmt;
    EXECUTE _sql;                      -- Intermediate step: build SQL for columns
    DEALLOCATE PREPARE _sql;
    -- Construct the query and perform it
    SET @stmt2 = CONCAT(
            'SELECT ',
                base_cols, ',\n',
                @sums,
                ',\n SUM(', tally_col, ') AS Total'
            '\n FROM ', tbl_name, ' ',
            where_clause,
            ' GROUP BY ', base_cols,
            '\n WITH ROLLUP',
            '\n', order_by
        );
    select @stmt2;                    -- The statement that generates the result
    PREPARE _sql FROM @stmt2;
    EXECUTE _sql;                     -- The resulting pivot table ouput
    DEALLOCATE PREPARE _sql;
    -- For debugging / tweaking, SELECT the various @variables after CALLing.
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_report` (IN `type` VARCHAR(30) CHARSET utf8mb4)  READS SQL DATA
BEGIN
	SELECT 
            report.date
          , student.NISS
          , student.NISN
          , student.fullname student_name
          , criteria.name criteria_name
          , criteria.weight
          , reporter.homeroom_teacher reporter_teacher
          , homeroom.homeroom_teacher confirmation_teacher
    FROM tbl_reporting report
    JOIN tbl_student student ON report.NISS = student.NISS
    JOIN ( SELECT * 
           FROM tbl_criteria 
           WHERE tbl_criteria.type = type) criteria 
        ON report.id_behavior = criteria.id
    JOIN tbl_teacher reporter ON report.id_reporter = reporter.NIP
    JOIN tbl_teacher homeroom ON report.id_confirmation = homeroom.NIP
    UNION ALL
    SELECT NULL, student.NISS, student.NISN, student.fullname, NULL, 0, NULL, NULL
    FROM tbl_student student
    WHERE NOT EXISTS ( SELECT NULL
                       FROM tbl_reporting report
                       WHERE report.NISS = student.NISS )

    UNION ALL
    SELECT NULL, NULL, NULL, NULL, criteria.name, 0, NULL, NULL
    FROM tbl_criteria criteria
    WHERE NOT EXISTS ( SELECT NULL
                       FROM tbl_reporting report
                       WHERE report.id_behavior = criteria.id)
                     AND criteria.type = type;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_reportPivot` (IN `tbl_name` VARCHAR(255))  SQL SECURITY INVOKER
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

--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `ExtractNumber` (`in_string` VARCHAR(50)) RETURNS INT(11) NO SQL
BEGIN
    DECLARE ctrNumber VARCHAR(50);
    DECLARE finNumber VARCHAR(50) DEFAULT '';
    DECLARE sChar VARCHAR(1);
    DECLARE inti INTEGER DEFAULT 1;
    IF LENGTH(in_string) > 0 THEN
        WHILE(inti <= LENGTH(in_string)) DO
            SET sChar = SUBSTRING(in_string, inti, 1);
            SET ctrNumber = FIND_IN_SET(sChar, '0,1,2,3,4,5,6,7,8,9'); 
            IF ctrNumber > 0 THEN
                SET finNumber = CONCAT(finNumber, sChar);
            END IF;
            SET inti = inti + 1;
        END WHILE;
        RETURN CAST(finNumber AS UNSIGNED);
    ELSE
        RETURN 0;
    END IF;    
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `FromRoman` (`inRoman` VARCHAR(15)) RETURNS INT(11) BEGIN

    DECLARE numeral CHAR(7) DEFAULT 'IVXLCDM';

    DECLARE digit TINYINT;
    DECLARE previous INT DEFAULT 0;
    DECLARE current INT;
    DECLARE sum INT DEFAULT 0;

    SET inRoman = UPPER(inRoman);

    WHILE LENGTH(inRoman) > 0 DO
        SET digit := LOCATE(RIGHT(inRoman, 1), numeral) - 1;
        SET current := POW(10, FLOOR(digit / 2)) * POW(5, MOD(digit, 2));
        SET sum := sum + POW(-1, current < previous) * current;
        SET previous := current;
        SET inRoman = LEFT(inRoman, LENGTH(inRoman) - 1);
    END WHILE;

    RETURN sum;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `tbl_configuration`
--

CREATE TABLE `tbl_configuration` (
  `variable` varchar(255) NOT NULL,
  `value` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `tbl_configuration`
--

INSERT INTO `tbl_configuration` (`variable`, `value`) VALUES
('title', 'Konselng dan Bimbingan');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_criteria`
--

CREATE TABLE `tbl_criteria` (
  `id` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `type` varchar(255) NOT NULL,
  `weight` float NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `tbl_criteria`
--

INSERT INTO `tbl_criteria` (`id`, `name`, `type`, `weight`) VALUES
('4b882221-81b9-11eb-851a-bca60c4b53c0', 'Membantu membersihkan lingkungan sekolah', 'dutiful', 12),
('4b984c7c-81b9-11eb-851a-bca60c4b53c0', 'Melaporkan tindakan pelanggaran', 'dutiful', 3),
('763698fc-81ab-11eb-851a-bca60c4b53c0', 'Mengikuti Ekstrakulikuler', 'dutiful', 5),
('764746ea-81ab-11eb-851a-bca60c4b53c0', 'Membantu membersihkan ruangan kelas', 'dutiful', 10),
('764e04b6-81ab-11eb-851a-bca60c4b53c0', 'Salam Sapa Hormat kepada para guru ketika bertemu', 'dutiful', 4),
('7663e9ba-81ab-11eb-851a-bca60c4b53c0', 'Membantu teman dalam menerangkan materi pelajaran', 'dutiful', 15),
('7674c9f6-81ab-11eb-851a-bca60c4b53c0', 'Membantu Teman dalam belajar', 'dutiful', 20),
('767b8195-81ab-11eb-851a-bca60c4b53c0', 'Menghentikan penindasan', 'dutiful', 31),
('a7f1ea88-a43d-11eb-84ab-4d58cf0ac0a8', 'Mencuri', 'violation', 10),
('a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'Tidak memakai atribut sekolah', 'violation', 5),
('a7fc2ccf-a43d-11eb-84ab-4d58cf0ac0a8', 'Tidak masuk kelas', 'violation', 4),
('a80135b2-a43d-11eb-84ab-4d58cf0ac0a8', 'Tidak mengikuti pelajaran per matapelajaran', 'violation', 2),
('a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'Tidak Hormat Kepada guru', 'violation', 5),
('a8157bf1-a43d-11eb-84ab-4d58cf0ac0a8', 'Tidak Sopan Kepada guru', 'violation', 6),
('a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'Melukai Teman', 'violation', 10),
('a81f9b94-a43d-11eb-84ab-4d58cf0ac0a8', 'Membawa senjata tajam', 'violation', 6),
('a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'Membuang Sampah sembarangan', 'violation', 5),
('a829bb9e-a43d-11eb-84ab-4d58cf0ac0a8', 'Membuat keributan di lingkungan sekolah', 'violation', 7),
('a82eca78-a43d-11eb-84ab-4d58cf0ac0a8', 'Membuli', 'violation', 20),
('a833e07b-a43d-11eb-84ab-4d58cf0ac0a8', 'Merokok di lingkungan sekolah', 'violation', 20);

-- --------------------------------------------------------

--
-- Table structure for table `tbl_reporting`
--

CREATE TABLE `tbl_reporting` (
  `id` varchar(255) NOT NULL,
  `id_behavior` varchar(255) NOT NULL,
  `type` varchar(255) NOT NULL,
  `NISS` varchar(255) NOT NULL,
  `id_reporter` varchar(255) NOT NULL,
  `id_confirmation` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `date` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `tbl_reporting`
--

INSERT INTO `tbl_reporting` (`id`, `id_behavior`, `type`, `NISS`, `id_reporter`, `id_confirmation`, `message`, `date`) VALUES
('011a6641-031e-11ec-8e5b-69d1dde1d170', 'a7fc2ccf-a43d-11eb-84ab-4d58cf0ac0a8', 'tolerance', '18112015', '10010', '1920152001', 'Terlambat !', '2021-08-16'),
('01251879-031e-11ec-8e5b-69d1dde1d170', 'a7fc2ccf-a43d-11eb-84ab-4d58cf0ac0a8', 'tolerance', '18112016', '10010', '1920152001', 'Terlambat !', '2021-08-16'),
('012bcdbd-031e-11ec-8e5b-69d1dde1d170', 'a7fc2ccf-a43d-11eb-84ab-4d58cf0ac0a8', 'tolerance', '18112017', '10010', '1920152001', 'Terlambat !', '2021-08-16'),
('790c3ce1-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '1920', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('79112237-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '23746683', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('79162b12-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '26818920', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('791b4289-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '30434620', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('79204b6f-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '30652308', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7941fdd9-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '33233215', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('794706fc-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '34838416', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('794c18b6-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '38750566', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7952d8dd-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '41488358', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7959961a-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '44054582', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('79604978-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '181910003', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('796dc5a1-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '181910004', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('797b4a49-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '181910007', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('798206b3-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '181910008', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7988c06f-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '181910011', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('798f7ed9-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '181910012', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('79963b2b-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '181910013', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('799cf7d9-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '181910018', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('79a3bb7d-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '181910019', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('79aa755d-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '181910020', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('79b13150-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '181910021', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('79b7eede-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '181910028', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('79d7f741-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '181910029', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('79f991a9-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '181910034', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7a0055ca-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '181910035', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7a071429-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '181910048', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7a0dce66-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '181910213', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7a1491d9-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '181910216', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7a1b4d1a-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '181910223', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7a2207d2-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '181910224', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7a28c6c5-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '181910237', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7a2f80e7-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '192010001', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7a363f2f-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '192010002', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7a3b4aa2-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '192010006', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7a405f6f-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '192010007', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7a4579cb-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '192010011', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7a4a8497-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '192010012', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7a4f9297-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '192010013', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7a568432-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '192010014', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7a5b915c-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '192010015', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7a609cec-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '192010016', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7a65b1f8-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '192010018', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7a6fcce2-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '192010019', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7a74ddd8-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '192010024', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7a79f073-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '192010025', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7a7eff59-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '192010026', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7a840ec0-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '192010027', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7a891d2e-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '192010031', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7a8e2ac8-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '192010037', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7a9335a1-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '192010038', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7a995690-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '192010042', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7abb9f78-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '192010207', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7ac0aec7-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '192010209', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7ac5b98d-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '192010211', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7acacd50-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '192010214', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7acfeb4f-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '192010216', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7ad4fc15-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '192010219', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7ada0aac-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '192010220', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('7adf180e-031a-11ec-8e5b-69d1dde1d170', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '192010223', '10010', '1920152001', 'Terlibat perkelahian atar group', '2021-08-17'),
('a14a4691-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '18112015', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('a14f1109-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '18112016', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('a1540dcf-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '18112017', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('a16baebf-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '56285983', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('a17c8241-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '202110036', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('a1833fb9-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '202110037', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('a189fd8d-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '202110041', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('a190ba8b-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '202110042', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('a197738a-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '202110043', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('a19e3563-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '202110044', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('a1a4f25b-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '202110045', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('a1abacbf-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '202110070', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('a1b26b04-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '202110072', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('a1b923a9-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '202110073', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('a1bfe7b8-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '202110074', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('a1c6aa69-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '202110104', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('a1cd651b-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '202110108', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('a1d4204f-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '202110109', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('a1daddde-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '202110110', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('a1e19e13-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '202110138', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('a1e859db-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '202110140', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('a1ef0ff4-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '202110141', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('a20f0e60-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '202110173', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('a2234763-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '202110174', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('a235d444-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '202110175', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('a23ae1a4-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '202110206', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('a23ff482-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '202110209', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('a2450078-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '202110210', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('a24a158f-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '202110242', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('a24f22db-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '202110244', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('a2543250-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '202110245', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('a25943b1-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '202110278', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('a26035a4-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '202110281', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('a265419d-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '202110282', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('a26a55ef-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '202110315', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('a26f5dd1-0319-11ec-8e5b-69d1dde1d170', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '202110317', '10010', '1920152001', 'atibut sekolah tidak lengkap pada hari senin upacara', '2021-08-16'),
('f5fe1207-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '18112015', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f604c951-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '18112016', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f60b83f4-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '18112017', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f6309228-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '56285983', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f6375144-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '202110036', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f63e0c6a-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '202110037', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f644c435-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '202110039', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f6575d25-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '202110040', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f6632ae1-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '202110041', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f66836d0-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '202110042', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f66d4551-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '202110070', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f6725391-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '202110071', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f67764cc-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '202110073', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f67c7385-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '202110104', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f6818363-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '202110106', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f686916a-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '202110138', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f68ba471-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '202110141', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f690b3ac-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '202110173', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f695c866-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '202110206', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f69ad843-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '202110209', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f69fe573-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '202110210', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f6a7157c-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '202110242', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f6b2e153-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '202110244', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f6c1a327-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '202110245', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f6d0dc44-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '202110246', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f6d5e4ac-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '202110247', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f6daf9d8-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '202110248', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f6e00857-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '202110249', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f6e5167c-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '202110278', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f6ea2810-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '202110280', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f6ef33f8-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '202110314', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f6f44919-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '202110315', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f6f95a88-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '202110316', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f6fe6a44-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '202110317', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f70376fe-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '202110318', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f70883e5-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '202110319', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('f70d960e-0319-11ec-8e5b-69d1dde1d170', '763698fc-81ab-11eb-851a-bca60c4b53c0', 'dutiful', '202110320', '10010', '1920152001', 'Eksul sekolah paskibra', '2021-08-12'),
('fa9d15cb-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '1920', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('faa2ffca-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '23746683', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('faa9bcd4-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '26818920', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fab07981-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '30434620', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fab73909-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '30652308', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fabdf5d4-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '33233215', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fac4b522-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '34838416', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fae2f16c-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '38750566', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fafde5a0-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '41488358', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fb07fd14-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '44054582', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fb0eb42a-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910002', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fb157644-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910003', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fb1c2ee7-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910004', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fb22e885-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910006', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fb29aedf-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910007', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fb307012-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910008', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fb371f56-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910009', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fb44a124-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910010', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fb522475-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910011', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fb572e80-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910012', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fb5fa6ad-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910013', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fb680f39-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910015', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fb6d2665-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910017', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fb7230f1-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910018', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fb773f97-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910019', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fb7c4684-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910020', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fb8161d8-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910023', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fb8666a1-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910029', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fb90851d-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910033', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fb959858-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910035', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fb9aa798-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910038', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fb9fb33a-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910039', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fba4c353-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910042', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fba9d753-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910043', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fbaee4b2-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910048', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fbb3f119-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910052', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fbb90277-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910068', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fbbe125f-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910069', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fbc3237a-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910214', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fbc83377-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910215', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fbcd4029-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910216', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fbd5b720-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910220', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fbdac63f-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910222', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fbdfd5b0-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910223', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fbe4e3dc-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910224', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fbe9f435-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910226', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fbef035f-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910227', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fbf4177b-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910228', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fbf92cb7-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910230', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fbfe2f01-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910231', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fc034493-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910232', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fc0856b5-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910233', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fc0f15b8-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910234', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fc194be5-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910235', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fc21a4ff-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910236', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fc26b600-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910237', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fc30d258-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910238', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fc379318-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910240', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fc3e4eaa-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '181910241', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fc4542e0-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010001', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fc4c0373-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010002', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fc52be8f-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010003', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fc597962-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010006', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fc60367f-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010008', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fc66f5be-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010009', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fc6db094-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010010', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fc747205-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010011', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fc7b2a11-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010012', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fc81e4c4-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010013', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fc88a84f-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010014', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fc8f6193-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010015', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fc962025-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010016', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fc9cdf8b-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010017', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fca70584-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010018', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fcadc20a-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010019', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fcb7d664-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010020', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fcc39b0d-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010021', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fcca61ef-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010022', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fcd62630-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010023', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fcdb3858-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010024', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fce04093-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010025', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fce559a9-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010027', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fcea6824-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010028', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fcef7454-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010029', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fcf48441-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010031', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fcf993c6-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010032', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fcfe9e85-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010036', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fd03b2d7-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010037', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fd08bbcc-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010038', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fd0dd0b4-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010039', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fd12dd32-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010041', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fd17efee-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010042', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fd1d0108-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010043', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fd221141-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010044', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fd2720df-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010045', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fd2c2df0-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010046', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fd313ae6-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010047', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fd36517f-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010048', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fd3b5de5-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010049', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fd406cb4-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010052', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fd457deb-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010053', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fd4a8a79-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010054', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fd4f9ea4-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010055', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fd54aa6b-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010057', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fd7302a5-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010058', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fd83dbcb-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010062', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fda8dfd9-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010064', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fdb9bb1d-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010071', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fdd4a232-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010077', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fdd9ae47-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010207', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fddebbf6-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010210', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fde3cc17-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010211', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fde8dfe5-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010214', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fdede6a1-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010215', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fdf4a95f-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010216', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fe0a88bd-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010217', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fe114ba0-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010221', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fe2ad035-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010222', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fe318f8e-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010223', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fe384ced-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010224', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17');
INSERT INTO `tbl_reporting` (`id`, `id_behavior`, `type`, `NISS`, `id_reporter`, `id_confirmation`, `message`, `date`) VALUES
('fe40b7ac-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010225', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fe477824-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010226', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fe4e3138-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010227', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fe641655-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010228', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fe6ad0f2-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010229', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fe7192a8-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010234', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fe79fe5b-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010235', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fe8267fd-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010236', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fe8ad42d-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010237', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fe933f87-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010241', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('fe9bad2b-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010242', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17'),
('feb34060-031a-11ec-8e5b-69d1dde1d170', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '192010246', '10010', '1920152001', 'perwakilan siswa kebersihan (ikut kerja bakti di lingkungan sekolah)', '2021-08-17');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_student`
--

CREATE TABLE `tbl_student` (
  `NISS` int(11) NOT NULL,
  `NISN` bigint(20) DEFAULT NULL,
  `fullname` varchar(40) DEFAULT NULL,
  `gender` varchar(1) DEFAULT NULL,
  `class` varchar(6) DEFAULT NULL,
  `photo` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `tbl_student`
--

INSERT INTO `tbl_student` (`NISS`, `NISN`, `fullname`, `gender`, `class`, `photo`) VALUES
(1920, 30434321, 'NUR AULIA', 'P', 'XII-3', ''),
(18112015, 18112015, 'IYANG AGUNG SUPRIATNA', 'L', 'X-1', '/_assets/photos/student-1619331569.png'),
(18112016, 18112016, 'NANDA AGUSTINA RAHAYU', 'P', 'X-1', '/_assets/photos/student-1623118854.png'),
(18112017, 18112017, 'AGUS NUFATUROHMAN', 'L', 'X-1', ''),
(23746683, 23746684, 'AZZAHRA AZKA TSAQOFA', 'P', 'XII-1', ''),
(26818920, 26818921, 'ZAHRA PUTRI NABILAH', 'P', 'XII-8', ''),
(30434620, 30434621, 'AUDY VIOLAN AULVIAN', 'L', 'XII-7', ''),
(30652308, 30652309, 'MUHAMMAD RIZQI AGUNG NURKAYA', 'L', 'XII-4', ''),
(33233215, 33233216, 'ANGGARA GUSTIKA', 'L', 'XII-2', ''),
(34838416, 34838417, 'REGITHA CAHYANI PUTRI', 'P', 'XI-10', ''),
(35361016, 35361017, 'MOHAMAD RIZKY ANUGRAH RAMADHAN', 'L', 'XII-3', ''),
(38750566, 38750567, 'ANITA MELAWATI', 'p', 'XI-6', ''),
(41488358, 41488359, 'NURUL FAUZIAH AGUSTINI', 'P', 'XI-5', ''),
(44054582, 44054583, 'KAILA MELANIA', 'P', 'XI-4', ''),
(48136393, 48136394, 'WILDAN HIZRI ABDILLAH', 'L', 'XI-4', ''),
(56285983, 56285984, 'SASKIYA WINDI FEBRIYANTI', 'P', 'X-6', ''),
(56506062, 56506063, 'SALSABILA ALIA SAFARIYAH', 'P', 'X-6', ''),
(181910001, 24697579, 'AI MILA KARMILA', 'P', 'XII-3', ''),
(181910002, 32091890, 'AI ROHAYATIN', 'P', 'XII-4', ''),
(181910003, 30434422, 'AJENG MUSTIKA AYU', 'P', 'XII-5', ''),
(181910004, 30434980, 'ANDRE MUHAMMAD RIZKI', 'L', 'XII-3', ''),
(181910005, 26456826, 'ANGGA ANDIKA LESMANA', 'L', 'XII-4', ''),
(181910006, 34061289, 'ANGGI NABILLA SURYANI', 'P', 'XII-5', ''),
(181910007, 28648280, 'ANGGI SEPTIANI', 'P', 'XII-6', ''),
(181910008, 28310262, 'ANITA NURMALA', 'P', 'XII-5', ''),
(181910009, 31684338, 'ANNISYA HAENUR RAHMAH', 'P', 'XII-5', ''),
(181910010, 24458110, 'AULIYA SYAWALANY PUTRI', 'P', 'XII-5', ''),
(181910011, 23348535, 'BERLYANA ULIA ARIFIN', 'P', 'XII-3', ''),
(181910012, 30434725, 'DELLA GESAFHIRA SUDRADJAT', 'P', 'XII-3', ''),
(181910013, 31507386, 'DESTIANA LISTIAWATI', 'P', 'XII-4', ''),
(181910014, 24391761, 'ELLA NURHAYATI', 'P', 'XII-2', ''),
(181910015, 35747932, 'FENNY MAHARANI', 'P', 'XII-5', ''),
(181910016, 24391613, 'FITRIA WIDIANI', 'P', 'XII-2', ''),
(181910017, 24696975, 'GUNTUR KUSNAWAN PUTRA', 'L', 'XII-1', ''),
(181910018, 25520558, 'HANIP WARMAN RAMDHANI', 'L', 'XII-3', ''),
(181910019, 40030970, 'HANNAZA FEBI YUNALDI', 'P', 'XII-4', ''),
(181910020, 35155473, 'INSANI NUR MAJIIDA', 'P', 'XII-4', ''),
(181910021, 25659618, 'LILIS ENDAH NURKOMALASARI', 'P', 'XII-3', ''),
(181910022, 24890193, 'MELANI MUSTIKA SARI', 'P', 'XII-5', ''),
(181910023, 24392105, 'MILA NURULITA', 'P', 'XII-1', ''),
(181910024, 27828313, 'MOHAMMAD RIZKY NURYAMIHARJA', 'L', 'XII-6', ''),
(181910026, 30434714, 'NISA NUR ERNI', 'P', 'XII-5', ''),
(181910027, 30434780, 'NURUL AWANIS', 'P', 'XII-5', ''),
(181910028, 39834183, 'PRATUDHITA PUTRI PAMBAYUN', 'P', 'XII-3', ''),
(181910029, 24697410, 'RENI OKTAVIANI', 'P', 'XII-1', ''),
(181910030, 26456980, 'RHEZA MEYLA SUNARMA', 'P', 'XII-1', ''),
(181910031, 47513596, 'SESILIA INDAH SABILA', 'P', 'XII-5', ''),
(181910032, 28310344, 'TIA ELIANA PUTRI', 'P', 'XII-5', ''),
(181910033, 30850806, 'YENI ROSA DAMAYANTI', 'P', 'XII-6', ''),
(181910034, 30434427, 'YUNITA AGUSTIANI', 'P', 'XII-4', ''),
(181910035, 30693127, 'AGUSTINA NABABAN', 'P', 'XII-2', ''),
(181910036, 30910200, 'ANGGA GUMELAR', 'L', 'XII-5', ''),
(181910037, 24696949, 'ANGGRAENI', 'P', 'XII-1', ''),
(181910038, 28310342, 'ANISA NURHAYATI', 'P', 'XII-2', ''),
(181910039, 35411003, 'ANNISA FITRI WIDIESTA', 'P', 'XII-6', ''),
(181910040, 26457010, 'ANNISA WIDYA', 'P', 'XII-4', ''),
(181910042, 30534252, 'AZMALIA NATRIANA KHELWA', 'P', 'XII-2', ''),
(181910043, 30434765, 'DENNI NURDIANSYAH', 'L', 'XII-2', ''),
(181910044, 27708008, 'DINA APRIYANTI', 'P', 'XII-1', ''),
(181910045, 31945900, 'DINI ANISA', 'P', 'XII-3', ''),
(181910046, 33014812, 'DINI PUTRI MEILANI', 'P', 'XII-5', ''),
(181910047, 27295646, 'ERRLY APRILINA', 'P', 'XII-4', ''),
(181910048, 24391731, 'FAISAL NUGRAHA', 'L', 'XII-6', ''),
(181910049, 30850904, 'GILANG KOMARA', 'L', 'XII-5', ''),
(181910050, 24819073, 'HAMDAN RODIANSYAH', 'L', 'XII-2', ''),
(181910051, 35846038, 'INDRIYANI DWI LESTARI', 'P', 'XII-3', ''),
(181910052, 30434289, 'IRMA RAHAYU', 'P', 'XII-6', ''),
(181910053, 30672101, 'LESTARY JUNGJUNAN EFFENDY', 'P', 'XII-2', ''),
(181910055, 29695617, 'MOH. FAUZIE RACHMAN SETIAHADI', 'L', 'XII-4', ''),
(181910056, 40210164, 'MELSA BERLIANA HERAWATI', 'P', 'XII-6', ''),
(181910059, 32321371, 'NADYA DWI PRAMESTI', 'P', 'XII-5', ''),
(181910060, 26457017, 'NENDEN VERA DEVI ANGGRAENI', 'P', 'XII-2', ''),
(181910061, 28310340, 'NURHOLIS SAADAH', 'P', 'XII-4', ''),
(181910062, 30851350, 'PENI APRIANI', 'P', 'XII-2', ''),
(181910063, 33032925, 'PUTRI AGLEN ANGGRAENI', 'P', 'XII-4', ''),
(181910064, 27335221, 'RESTA SANDRI TANAYA PUTRI', 'P', 'XII-2', ''),
(181910065, 30434888, 'RISSA ISMAYA', 'P', 'XII-6', ''),
(181910066, 30434686, 'SATRIA ARYA DHEEVA', 'L', 'XII-4', ''),
(181910067, 21281778, 'SHADIQ MUBARAK GUNAWAN', 'L', 'XII-5', ''),
(181910068, 24697402, 'TAUFIK GIFARI', 'L', 'XII-1', ''),
(181910069, 33179191, 'TIWI AINI', 'P', 'XII-1', ''),
(181910070, 30851027, 'WINDY DIKA LESTARI', 'P', 'XII-4', ''),
(181910071, 24458125, 'YULAN NAFILAH', 'P', 'XII-1', ''),
(181910072, 24578921, 'ADELIA OCTAVIANI RAHADIAN', 'P', 'XII-6', ''),
(181910073, 25416225, 'AHMAD HADI NUGRAHA', 'L', 'XII-1', ''),
(181910074, 24392092, 'AHMAD SYAHRIL AZKA', 'L', 'XII-2', ''),
(181910075, 30434629, 'ANNISA NUR APRILIA', 'P', 'XII-1', ''),
(181910076, 24391997, 'ANNISYA NUR RIZKY', 'P', 'XII-6', ''),
(181910077, 32351547, 'ARIEL REGINA', 'P', 'XII-3', ''),
(181910078, 36785355, 'CHINTYA DWI AJENG HASNA FAUZIAH', 'P', 'XII-5', ''),
(181910079, 24392113, 'DEDEN', 'L', 'XII-4', ''),
(181910080, 28310407, 'DENDI WAHYU RENALDI', 'L', 'XII-5', ''),
(181910081, 28462793, 'DENDY IMAN LESMANA', 'L', 'XII-1', ''),
(181910082, 25244317, 'DICKY ANGGARA PERMANA', 'L', 'XII-5', ''),
(181910083, 24392084, 'DUBY NUR KOMARA', 'L', 'XII-1', ''),
(181910084, 34293294, 'DZIKRI NURFATAH', 'L', 'XII-2', ''),
(181910085, 26456872, 'EGI ANDRIAN MULYANA', 'L', 'XII-3', ''),
(181910086, 30434891, 'FAUZAN ALIF NURFIKRI', 'L', 'XII-3', ''),
(181910087, 24578790, 'HANIFA NABILLA', 'P', 'XII-3', ''),
(181910088, 30434736, 'GILANG PERMANA', 'L', 'XII-6', ''),
(181910089, 24391998, 'IHSANUDDIN AKBAR', 'L', 'XII-4', ''),
(181910090, 24819072, 'INDAH LESTARI', 'P', 'XII-1', ''),
(181910091, 30434458, 'LARAS NATALISA', 'P', 'XII-1', ''),
(181910092, 33323292, 'LUCKY NURHIKMATULLOH', 'L', 'XII-3', ''),
(181910093, 35361018, 'MUHAMMAD RECKY ALFIRDAUS', 'L', 'XII-3', ''),
(181910094, 35567837, 'MUHAMMAD RIDWAN RIZKY ANUGERAH PRAYANA', 'L', 'XII-4', ''),
(181910095, 28864648, 'MUHAMMAD VIRGYAWAN', 'L', 'XII-5', ''),
(181910096, 25438585, 'NUR RAMANITA DINI', 'P', 'XII-3', ''),
(181910097, 31831380, 'PANCAMUKTI FAJAR PRAKOSO', 'L', 'XII-6', ''),
(181910098, 24391979, 'RANIA SALSABILA', 'P', 'XII-6', ''),
(181910099, 30434927, 'RIO DIANDRA', 'L', 'XII-1', ''),
(181910100, 28583600, 'ROQIYUL MA\'ARIP', 'L', 'XII-1', ''),
(181910101, 24458258, 'SILVIA VALENTINA', 'P', 'XII-1', ''),
(181910102, 30851341, 'SITI NUR KIKI ATIKA', 'P', 'XII-2', ''),
(181910103, 31630908, 'SRI DEWI APRILIANI', 'P', 'XII-5', ''),
(181910104, 27563044, 'SULISTRIANI', 'P', 'XII-2', ''),
(181910105, 35155445, 'WILDAN ANHAR FAUZAN', 'L', 'XII-3', ''),
(181910106, 24392061, 'YUDHA NUR FAUZAN', 'L', 'XII-4', ''),
(181910107, 24697062, 'YUDI HERMANSYAH', 'L', 'XII-5', ''),
(181910108, 30851242, 'A. IKBAL KHOIRULLOH', 'L', 'XII-6', ''),
(181910109, 30851235, 'ADISTY SRI NUROHMAH', 'P', 'XII-1', ''),
(181910110, 30534336, 'ALVIANA INDRIYANI SURACHMAN', 'P', 'XII-6', ''),
(181910111, 30534104, 'ALYA FAHIRA', 'P', 'XII-1', ''),
(181910112, 30692871, 'AMANDA RETNONINGTYAS', 'P', 'XII-2', ''),
(181910113, 30851320, 'AMELIA SHINTASUCI', 'P', 'XII-3', ''),
(181910114, 30850830, 'ANISA RAHMA AULIA', 'P', 'XII-3', ''),
(181910115, 31739525, 'ANNISA NURUL FISABILLA HERYADIE PUTRI', 'P', 'XII-2', ''),
(181910116, 24697110, 'ANNISYA PARASWATI SUTARYAT', 'P', 'XII-1', ''),
(181910117, 30434862, 'ASYEU ANUGRAH', 'L', 'XII-1', ''),
(181910118, 24458137, 'AZHAR SALSABILAH', 'P', 'XII-1', ''),
(181910120, 24697141, 'CITRA ADISTI', 'P', 'XII-1', ''),
(181910121, 24697255, 'DEZAN TRIANDI HIDAYAT', 'L', 'XII-3', ''),
(181910122, 30851241, 'DWI IMELDA TALIA', 'P', 'XII-6', ''),
(181910123, 30434428, 'ERLANGGA PUTRA PAMUNGKAS HENDRAYANA', 'L', 'XII-4', ''),
(181910124, 30996597, 'FAJAR GUMILAR', 'L', 'XII-1', ''),
(181910125, 24697108, 'FITRI HANDAYANI', 'P', 'XII-6', ''),
(181910126, 28310389, 'FITRI RIZKY LISDIADI', 'L', 'XII-4', ''),
(181910127, 30434413, 'PUTRI MAHARANI', 'P', 'XII-5', ''),
(181910128, 26456814, 'PUTRI SANIA SALWA KUSUMAWARDANI', 'P', 'XII-6', ''),
(181910129, 28310232, 'REVIANI', 'P', 'XII-3', ''),
(181910130, 30434361, 'REYNATE FIRYAL', 'P', 'XII-4', ''),
(181910131, 30434349, 'RHEVATA ANANDA PUTRI', 'P', 'XII-5', ''),
(181910132, 30434348, 'RHEVITA ANINDYA PUTRI', 'P', 'XII-6', ''),
(181910133, 24716573, 'RIANIVA LAELA PERMANA', 'P', 'XII-2', ''),
(181910135, 30851041, 'SALSABILA DIAZ FATHIYAH', 'P', 'XII-4', ''),
(181910136, 30434346, 'SHINTA NUR ISMAYA', 'P', 'XII-6', ''),
(181910137, 25310942, 'SONI RAGIL KRISTOFER', 'L', 'XII-6', ''),
(181910138, 24716638, 'SUCI HERDIANTI IRAWAN', 'P', 'XII-6', ''),
(181910139, 30434699, 'TIAN FITRIYANI', 'P', 'XII-6', ''),
(181910140, 24558714, 'VENA OKTAVIANI', 'P', 'XII-3', ''),
(181910141, 30534232, 'ZAHRA AULIA FATIMAH', 'P', 'XII-6', ''),
(181910142, 32338762, 'ANDEANA MAHARANI', 'P', 'XII-4', ''),
(181910143, 28310210, 'ANNISA SITI NURJANAH', 'P', 'XII-3', ''),
(181910144, 30534337, 'ASTRIDYA SYAHADA PUTRI HERMAWAN', 'P', 'XII-4', ''),
(181910145, 34202087, 'AYU LESTARI', 'P', 'XII-6', ''),
(181910146, 30434863, 'CILVIANIAR HASMANITA', 'P', 'XII-6', ''),
(181910147, 31012338, 'DEDE ERNI ERLITA', 'P', 'XII-2', ''),
(181910148, 30534160, 'DENDRY SUARGANA SUTISNA', 'L', 'XII-6', ''),
(181910149, 24392015, 'DHIVA TANIA LUTHFIANIE', 'P', 'XII-6', ''),
(181910150, 30434452, 'DINDA DUPALANTU', 'P', 'XII-2', ''),
(181910151, 24458109, 'DIVA PRAMUDYA PUTRI PRATIWI', 'L', 'XII-6', ''),
(181910152, 27296711, 'ERICKA SINTA NURLAELA', 'P', 'XII-3', ''),
(181910153, 32132879, 'FAJAR KAMALLUL IKHSAN', 'L', 'XII-4', ''),
(181910154, 24817509, 'FITRI KAMILIA AZZAHRA', 'P', 'XII-1', ''),
(181910155, 30434345, 'HAYKAL INDRA PERKASA ANUGRAH S.', 'L', 'XII-5', ''),
(181910156, 24391695, 'INDAH RESTI FAUZI', 'P', 'XII-2', ''),
(181910157, 24697396, 'IVAN FATURAHMAN', 'L', 'XII-6', ''),
(181910158, 30851184, 'IYYAKA DZAL\'FA PUTRA ADRIS RUHIMAT', 'L', 'XII-1', ''),
(181910159, 24458309, 'LADOVA DAMARA PUTRA', 'L', 'XII-2', ''),
(181910161, 30434978, 'NAHDA MUFIDA DIYATI', 'P', 'XII-6', ''),
(181910162, 30997932, 'NAJLA DIPAKIRANI NABILA', 'P', 'XII-1', ''),
(181910163, 34110888, 'NUR CANTIKA UTAMI', 'P', 'XII-6', ''),
(181910164, 24392045, 'NUR FADILA', 'P', 'XII-2', ''),
(181910165, 28310206, 'OKTAVIA DRUPADA', 'P', 'XII-6', ''),
(181910166, 24697512, 'PAULA HELVINA MARGARETHA', 'P', 'XII-1', ''),
(181910167, 30434626, 'RAHMA KAMILA', 'P', 'XII-2', ''),
(181910168, 26456939, 'RAHMAWATI MAMONTO', 'P', 'XII-4', ''),
(181910169, 33932350, 'RINANDA SUKMAWATI', 'P', 'XII-3', ''),
(181910170, 26456883, 'RINRIN ALVA ARIELLA', 'P', 'XII-4', ''),
(181910171, 30434744, 'SAIQA FATUR KHAIRI', 'L', 'XII-3', ''),
(181910172, 32112649, 'SOFA NURFAUJIAH', 'P', 'XII-3', ''),
(181910173, 25197289, 'SOPHIA KHOERUNNISA', 'P', 'XII-4', ''),
(181910174, 26457015, 'THALISA REVINA HENDRAYAN', 'P', 'XII-4', ''),
(181910175, 24391845, 'WAWAN TARYANA', 'L', 'XII-2', ''),
(181910176, 30534387, 'YUNI NUR ADILAH', 'P', 'XII-2', ''),
(181910177, 32059098, 'YURIKA NUR ANNISA', 'P', 'XII-5', ''),
(181910178, 38978737, 'ANISSA TRI LAHITANI', 'P', 'XII-4', ''),
(181910179, 25293449, 'ARI ABDUL MUGHNI', 'L', 'XII-6', ''),
(181910180, 26291838, 'AYDUL FIKRI RAMADHANI', 'L', 'XII-2', ''),
(181910181, 31129559, 'CHICI PIDATUNNISA', 'P', 'XII-4', ''),
(181910182, 28310365, 'DEWI SEPTIA', 'P', 'XII-5', ''),
(181910183, 38982120, 'DHYA MAITSA SABILA WILDAN', 'L', 'XII-4', ''),
(181910184, 28310367, 'DINI NOVATUROHMAH SUNARYA', 'P', 'XII-4', ''),
(181910185, 33179499, 'ELIVARWATI', 'P', 'XII-1', ''),
(181910186, 24458242, 'FADLY RAHMAT ROSYADA', 'L', 'XII-5', ''),
(181910187, 30996596, 'FAJRI FAUZAN AZHARI', 'L', 'XII-2', ''),
(181910189, 24558702, 'HAWDHIYA KAYLA PRADINA ZAHRA', 'P', 'XII-5', ''),
(181910190, 32054533, 'ILMA NURUL AULIA', 'P', 'XII-6', ''),
(181910191, 30434728, 'INTAN ROSDIANA', 'P', 'XII-5', ''),
(181910192, 22667281, 'IQBAL CHENDRIAWAN', 'L', 'XII-5', ''),
(181910193, 24391757, 'KHARISMA MUNGGARAN PUDJAMASGANTAKA', 'L', 'XII-1', ''),
(181910194, 32294894, 'MOHAMAD RICO PRIBAWAN WIBISONO', 'L', 'XII-5', ''),
(181910195, 31621181, 'MUTIA NURFADILLAH', 'P', 'XII-3', ''),
(181910197, 30434320, 'NIDA LATIFAH', 'P', 'XII-3', ''),
(181910198, 35155335, 'NINA ROSALINA', 'P', 'XII-4', ''),
(181910199, 24817520, 'NUR DEVIANA', 'P', 'XII-1', ''),
(181910200, 24392400, 'RAHIL AZAHRA', 'P', 'XII-1', ''),
(181910201, 24485002, 'RAHMA NABILLA SUBARNA PUTRI', 'P', 'XII-3', ''),
(181910202, 30434275, 'RANI ANGGRAENI', 'P', 'XII-5', ''),
(181910203, 24391697, 'REZA GUSTOFA', 'L', 'XII-2', ''),
(181910204, 30434941, 'RISNA MELIANDA', 'P', 'XII-5', ''),
(181910205, 33014911, 'ROBBY ISMAIL FASYA', 'L', 'XII-2', ''),
(181910207, 32071575, 'SUCI RAMADHAN SETIAWAN', 'P', 'XII-1', ''),
(181910208, 34198693, 'SULTAN AULYA RACHMAN', 'L', 'XII-3', ''),
(181910209, 30435003, 'SYIFA SHOFIYAH ISLAMI', 'P', 'XII-3', ''),
(181910210, 26619577, 'VADILLAH NURUL FAJRIN', 'P', 'XII-2', ''),
(181910211, 24697392, 'WITA MEILASARY', 'P', 'XII-5', ''),
(181910212, 24391601, 'YUNI RAHMAWATI', 'P', 'XII-3', ''),
(181910213, 30434954, 'ANDI SOPIAN', 'L', 'XII-8', ''),
(181910214, 30434784, 'ARI GUNAWAN', 'L', 'XII-7', ''),
(181910215, 35155355, 'CICI SUMIATI', 'P', 'XII-7', ''),
(181910216, 24391977, 'DINI SAHNUR', 'P', 'XII-10', ''),
(181910217, 20494189, 'FARHAN MUBAROK', 'L', 'XII-7', ''),
(181910219, 30434635, 'HAMZAH', 'L', 'XII-10', ''),
(181910220, 32709463, 'IMAS SUSILAWATI', 'P', 'XII-8', ''),
(181910221, 33014937, 'K. FAJAR AZIZ RAMADHAN', 'L', 'XII-10', ''),
(181910222, 30434637, 'LEONARDO SEIRERA SIRINGO RINGO', 'L', 'XII-8', ''),
(181910223, 24697332, 'MAULADY RAHMAN', 'L', 'XII-9', ''),
(181910224, 30434362, 'MIRA PUTRI HAYATI', 'P', 'XII-10', ''),
(181910225, 23467293, 'MISBACHHUDDIN ROISYULLWATTON', 'L', 'XII-7', ''),
(181910226, 36961269, 'MUHAMMAD ADIB ABDULFAQIH', 'L', 'XII-8', ''),
(181910227, 30434392, 'MUHAMMAD FAISHAL FATURROHMAN', 'L', 'XII-7', ''),
(181910228, 30434731, 'MUHAMMAD NASRUL FALAH', 'L', 'XII-10', ''),
(181910229, 32143371, 'NENG SUSI SOFIAH', 'P', 'XII-9', ''),
(181910230, 30434429, 'NURFADILAH', 'P', 'XII-8', ''),
(181910231, 30434351, 'PAHRIZAL HIDAYAT', 'L', 'XII-10', ''),
(181910232, 30434634, 'PUTRI DIAN PURNAMA', 'P', 'XII-7', ''),
(181910233, 24391927, 'RANI AINI', 'P', 'XII-7', ''),
(181910234, 24697094, 'RHAKHEAN KANDIAS', 'L', 'XII-9', ''),
(181910235, 33014923, 'SAHDA DINAH SABRINA', 'P', 'XII-8', ''),
(181910236, 21227564, 'SENDI SETIANA', 'L', 'XII-9', ''),
(181910237, 30434694, 'SITI YULIANI UTAMI PUTRI', 'P', 'XII-9', ''),
(181910238, 30434661, 'SONA SONIA NURFADILAH', 'P', 'XII-9', ''),
(181910239, 37791139, 'TESA SRI RAHAYU', 'P', 'XII-10', ''),
(181910240, 24697266, 'TRIANA NOVIANTY', 'P', 'XII-7', ''),
(181910241, 27130320, 'VENY SEVIANTY', 'P', 'XII-9', ''),
(181910242, 24391700, 'WIDI SEPTIADI', 'L', 'XII-7', ''),
(181910244, 24697262, 'YASHINTA AUDREYA BUDIMAN', 'P', 'XII-10', ''),
(181910245, 24391751, 'YAYANG DIAN SETYA', 'L', 'XII-7', ''),
(181910246, 30658023, 'ZAMIE LAUREN', 'L', 'XII-8', ''),
(181910247, 30434741, 'ABDILLAH ZAIDAN GUNAWAN', 'L', 'XII-9', ''),
(181910248, 30850986, 'AMEL LIA PUTRI', 'P', 'XII-10', ''),
(181910249, 22868673, 'ANISA APRIANA NABABAN', 'P', 'XII-7', ''),
(181910250, 24697344, 'ANNISA BARKAH', 'P', 'XII-8', ''),
(181910251, 24391779, 'DEA NUR RAHMAWATI', 'P', 'XII-9', ''),
(181910252, 24391739, 'DEDE REZA HERDIANA', 'L', 'XII-8', ''),
(181910253, 24392017, 'DINI JULIANI', 'P', 'XII-7', ''),
(181910254, 24696998, 'DINI ZAHARA', 'P', 'XII-10', ''),
(181910256, 30434350, 'FARIDAH', 'P', 'XII-8', ''),
(181910257, 24697183, 'FATHIA SYIFA FARHANI', 'P', 'XII-7', ''),
(181910258, 28102668, 'GHIANI NOVIANTI', 'P', 'XII-9', ''),
(181910259, 39968793, 'INTAN NURMALA FAIRUZYAH', 'P', 'XII-9', ''),
(181910260, 30851038, 'LAURA RAMDANI', 'P', 'XII-10', ''),
(181910261, 24391911, 'LILIYANASARI INDRAYANA', 'P', 'XII-7', ''),
(181910262, 30434774, 'MIRA MEILANI', 'P', 'XII-10', ''),
(181910263, 30434311, 'NABILAH NUR AZIZAH', 'P', 'XII-8', ''),
(181910265, 21240315, 'NUR PAULINDA', 'P', 'XII-9', ''),
(181910266, 25654423, 'NURMALASARI', 'P', 'XII-8', ''),
(181910267, 32091323, 'OKTI HERAWATI', 'P', 'XII-9', ''),
(181910268, 28468556, 'PURI NURDIANTI', 'P', 'XII-10', ''),
(181910269, 35155526, 'PUTRI NUR AZIZAH RAHMAWATI', 'P', 'XII-7', ''),
(181910270, 30434718, 'RANI AYU MAHARANI', 'P', 'XII-10', ''),
(181910271, 38587766, 'RATIH SRI RAHAYU', 'P', 'XII-8', ''),
(181910272, 37123924, 'RENDY BAGAS', 'L', 'XII-7', ''),
(181910274, 24391773, 'SELPINA INTANI', 'P', 'XII-7', ''),
(181910275, 30434953, 'SIBI RIBIAN', 'P', 'XII-10', ''),
(181910276, 24945848, 'SITI RAHMAH NURAENI', 'P', 'XII-7', ''),
(181910277, 35155452, 'SRI WAHYUNI FAUZIAH', 'P', 'XII-9', ''),
(181910278, 33014935, 'SYAHRUL NUR RIZKI', 'L', 'XII-8', ''),
(181910279, 30850711, 'TASYA SALSABILA DARMAWAN', 'P', 'XII-8', ''),
(181910280, 36538888, 'ADILLA RAHMA DIANISA', 'P', 'XII-9', ''),
(181910281, 30434388, 'ANISHA RAHMA WATIE', 'P', 'XII-9', ''),
(181910282, 31634309, 'ANNISA AGUSTINA', 'P', 'XII-10', ''),
(181910283, 24697574, 'AZHAR SURYA FADHILLAH', 'L', 'XII-9', ''),
(181910284, 28568388, 'DESY FITRIANI', 'P', 'XII-10', ''),
(181910285, 24391725, 'DIKI LESMANA', 'L', 'XII-8', ''),
(181910286, 35406169, 'ELI YULIANA', 'P', 'XII-8', ''),
(181910287, 30434983, 'FIRNA NAHWA FIRDAUSI', 'P', 'XII-9', ''),
(181910288, 30434287, 'FITRI NURJANAH', 'P', 'XII-8', ''),
(181910289, 24558658, 'HERLINA ENZELIKA PASARIBU', 'P', 'XII-9', ''),
(181910290, 25293476, 'IDA WIDIAWATI', 'P', 'XII-8', ''),
(181910291, 26630710, 'IIS RISKA MULYANI', 'P', 'XII-8', ''),
(181910292, 30434394, 'IMEY PUJI NIRWANA', 'P', 'XII-8', ''),
(181910293, 30658182, 'KARTIKA PURNAMA DEWI', 'P', 'XII-10', ''),
(181910294, 30434308, 'MEILANI NUR FAUZIAH', 'P', 'XII-7', ''),
(181910295, 24697488, 'MELISA FARIDAH', 'P', 'XII-8', ''),
(181910296, 40030949, 'MUHAMMAD RIZKY', 'L', 'XII-9', ''),
(181910297, 39149835, 'NABILA JULIANTIKA PUTRI', 'P', 'XII-7', ''),
(181910298, 24697464, 'NOVA SOPIA', 'P', 'XII-10', ''),
(181910299, 30434640, 'NOVITA ANDINI', 'P', 'XII-10', ''),
(181910300, 30693122, 'PUTRI HARIANI SIREGAR', 'P', 'XII-9', ''),
(181910301, 24391740, 'RAHADIAN SUGIHBANDANA', 'L', 'XII-10', ''),
(181910303, 22727629, 'RITA SULASWATI', 'P', 'XII-9', ''),
(181910304, 31878577, 'SHAKILA ADELIA SAFITR', 'P', 'XII-10', ''),
(181910305, 30434614, 'SHERINA BIRLIAN YANUAR', 'P', 'XII-9', ''),
(181910306, 24391937, 'SUCI MAULIDDINA', 'P', 'XII-7', ''),
(181910307, 30851332, 'SURATMAN MULYADI', 'L', 'XII-10', ''),
(181910308, 40039484, 'TANIA PUTRI NADILA', 'P', 'XII-7', ''),
(181910309, 34085944, 'TITA AULIA', 'P', 'XII-10', ''),
(181910310, 30434288, 'ULSAN YULIA', 'P', 'XII-8', ''),
(181910311, 35515264, 'WIDYA RAHMA LIZARNI', 'P', 'XII-8', ''),
(181910312, 30434638, 'ALFI AHMAD PRATAMA', 'L', 'XII-8', ''),
(181910313, 24578918, 'ALGIE RAHMAWAN HIDAYAT', 'L', 'XII-10', ''),
(181910314, 24697268, 'ANANDA UAIS ALKORNI', 'L', 'XII-9', ''),
(181910315, 24391623, 'ARIF BUDIANSYAH', 'L', 'XII-10', ''),
(181910316, 30434390, 'CHELSEA FELLMA CAHAYA PUTRI', 'P', 'XII-7', ''),
(181910317, 30658757, 'DEWI NURA\'ENI GUNAWAN', 'L', 'XII-8', ''),
(181910318, 30434397, 'DHIMAS RAHARDIAN WIDIARTO', 'L', 'XII-7', ''),
(181910319, 27826428, 'DIKI RAMDANI', 'L', 'XII-9', ''),
(181910320, 30434730, 'FARIDA ZAHRA ARINDRA', 'P', 'XII-7', ''),
(181910321, 24476477, 'FITRA DANDI MAYO', 'L', 'XII-9', ''),
(181910322, 26175010, 'HANA NUR AINI', 'P', 'XII-8', ''),
(181910323, 40030952, 'HIDAYA HILMI ARISTAWIDYA', 'P', 'XII-7', ''),
(181910324, 30434979, 'HILDA ASHYA IMANIAR', 'P', 'XII-10', ''),
(181910325, 34754358, 'LUTHFI FADHIIL ROIHANSYAH', 'L', 'XII-10', ''),
(181910326, 24391931, 'MAHESA DWI PUTRA', 'L', 'XII-9', ''),
(181910327, 31623841, 'MOCH. HIKMAL AL FARIZI', 'L', 'XII-7', ''),
(181910328, 33014922, 'MUHAMMAD BENTAR R ROYYAS FADHALAH', 'L', 'XII-8', ''),
(181910329, 24391898, 'PERGIWA JAYANTI WIDI UTAMI', 'P', 'XII-7', ''),
(181910330, 30435022, 'RELLIAWAN', 'L', 'XII-10', ''),
(181910331, 24391948, 'RENDI OKTORA', 'L', 'XII-9', ''),
(181910332, 30851232, 'RENNI NURHALISA AMELIA', 'P', 'XII-8', ''),
(181910333, 30434612, 'RIJQI SUCIPTO PRATAMA', 'L', 'XII-10', ''),
(181910334, 30434672, 'RIMBA SUHERMAWAN', 'L', 'XII-7', ''),
(181910335, 30434719, 'RINA AYU MAHARANI', 'P', 'XII-7', ''),
(181910336, 24391910, 'RITA RAHMAWATI', 'P', 'XII-7', ''),
(181910337, 26456819, 'RIYAN AGUSTIANSYAH', 'L', 'XII-7', ''),
(181910338, 22363906, 'SAIDAH FITRI PURNAMA', 'P', 'XII-10', ''),
(181910339, 24697331, 'SYIFA APRILLIA SUDIANA', 'P', 'XII-8', ''),
(181910340, 26456928, 'TIANITA FITRI LIANTO', 'P', 'XII-9', ''),
(181910341, 30434636, 'TIRAYANTI', 'P', 'XII-9', ''),
(181910342, 37114090, 'WIDYA PARAMITA', 'P', 'XII-9', ''),
(181910343, 24392025, 'WILDAN RAMADAN', 'L', 'XII-10', ''),
(181910344, 33014900, 'WINDA HERLINA', 'P', 'XII-10', ''),
(181910345, 28310346, 'YULIA SITI FATONAH NURCHOER', 'L', 'XII-8', ''),
(181910346, 30850938, 'ZENDRA PUJA HERA ASMARA', 'L', 'XII-9', ''),
(192010001, 40692918, 'ADELIA GIAN PHALOSA', 'P', 'XI-1', ''),
(192010002, 40796586, 'ADITIA RAKA IRWANSYAH', 'L', 'XI-2', ''),
(192010003, 35033472, 'ALFI AZWAR DZULHARNA', 'L', 'XI-4', ''),
(192010004, 40693519, 'ANANDHA NOVIA ARDHANI', 'P', 'XI-6', ''),
(192010005, 35056693, 'BILAL BIAGI', 'L', 'XI-5', ''),
(192010006, 35032564, 'BUNGA FITRIANA', 'P', 'XI-1', ''),
(192010007, 35031903, 'DHEA FITRYAN', 'P', 'XI-2', ''),
(192010008, 35032397, 'DIAN NUR FAUZI', 'L', 'XI-4', ''),
(192010009, 40693098, 'DIANA FADHILAH MACHJAR', 'P', 'XI-5', ''),
(192010010, 35031820, 'FANY DESTANIA', 'P', 'XI-5', ''),
(192010011, 40693009, 'FEBRINA NUR AZIZAH', 'P', 'XI-1', ''),
(192010012, 40693643, 'FRIMA MARISTIANDHANU PERKASA', 'L', 'XI-3', ''),
(192010013, 50530157, 'HELSY AZZAHRA', 'P', 'XI-4', ''),
(192010014, 43346605, 'HUD JIBRAN AR RASYIQ', 'L', 'XI-5', ''),
(192010015, 35031799, 'JAJANG SANJAYA', 'L', 'XI-6', ''),
(192010016, 42274309, 'KHAIRUNNISA NURTSAQIFA', 'P', 'XI-1', ''),
(192010017, 35033659, 'MIMIS SITI AISYIAH', 'P', 'XI-3', ''),
(192010018, 52872807, 'MOCHAMAD FARCHAN AWALLUDIN', 'L', 'XI-4', ''),
(192010019, 40732233, 'MUHAMMAD KANTAQA', 'L', 'XI-5', ''),
(192010020, 40693099, 'NADYA KANIA DEWI', 'P', 'XI-6', ''),
(192010021, 40693109, 'NASYA KHAILA AZZAHRA YUDHISTIRA', 'P', 'XI-1', ''),
(192010022, 35033477, 'NOVI AULIA ROSSYALIAH', 'P', 'XI-3', ''),
(192010023, 40693025, 'PANDU DWI PRATAMA', 'L', 'XI-4', ''),
(192010024, 45872496, 'PUTRI KOMALA DEWI KENCANA SUMIRAT', 'P', 'XI-5', ''),
(192010025, 40693640, 'REISSYA HAWWA AQILA', 'P', 'XI-5', ''),
(192010026, 42270885, 'RESKI NURHIDAYAT', 'L', 'XI-2', ''),
(192010027, 37053802, 'RINI ANGGRAENI', 'P', 'XI-3', ''),
(192010028, 43816220, 'ROLIA NELSA MEIRA', 'P', 'XI-4', ''),
(192010029, 43774805, 'RYAN GUNAWAN', 'L', 'XI-6', ''),
(192010031, 40694764, 'SITI SARAH NABILA', 'P', 'XI-5', ''),
(192010032, 40692319, 'SRI WULAN', 'P', 'XI-5', ''),
(192010033, 50391524, 'SYNDI SOFIA RISTIANA', 'P', 'XI-5', ''),
(192010034, 37053542, 'TUTI LATIFAH', 'P', 'XI-5', ''),
(192010036, 40693836, 'ADRIAN RAMADAN', 'L', 'XI-1', ''),
(192010037, 45373307, 'AFDILLA ZAHRA JULIAN NURAHMAT', 'P', 'XI-2', ''),
(192010038, 40693096, 'ANISSA MARDIANI HERMAWAN', 'P', 'XI-3', ''),
(192010039, 35033595, 'ANUGRAH SEPTIANSYAH', 'L', 'XI-4', ''),
(192010040, 35033103, 'AULIYA ZUYYINA', 'P', 'XI-5', ''),
(192010041, 31187310, 'CECILLYA DESTA PUTRI FIRMANSYAH', 'P', 'XI-1', ''),
(192010042, 35032563, 'CHANDRA SUKMA GUMELAR', 'L', 'XI-2', ''),
(192010043, 30434622, 'DIANA MARTIA SARI', 'P', 'XI-3', ''),
(192010044, 30434619, 'DIMAS DZAKI ARDIANSYAH', 'L', 'XI-4', ''),
(192010045, 35033475, 'FASYA DINDA OCTAVIA PUTERI', 'P', 'XI-6', ''),
(192010046, 42291171, 'FIRYAL SYAQRA LABIBAH', 'P', 'XI-1', ''),
(192010047, 43556685, 'GIBRAN FAKHRIAN TUPASKAH', 'L', 'XI-2', ''),
(192010048, 37375149, 'HERLIN ANISA SYA`BANI', 'P', 'XI-3', ''),
(192010049, 37053969, 'HUSNIAJI', 'L', 'XI-6', ''),
(192010050, 40732230, 'LAKSAMANA KUMBARA REIGIF', 'L', 'XI-5', ''),
(192010051, 40692919, 'MIRA JULIANTI', 'P', 'XI-1', ''),
(192010052, 35033658, 'MOHAMAD IQBAL', 'L', 'XI-2', ''),
(192010053, 43516595, 'MUHAMMAD KHAIRUL FIKRI', 'L', 'XI-3', ''),
(192010054, 40732256, 'NAHDA AIRIL LISTIA', 'P', 'XI-4', ''),
(192010055, 35031815, 'NAURA AMELIA', 'P', 'XI-6', ''),
(192010056, 40732282, 'NUR HADA JUNIAR', 'P', 'XI-1', ''),
(192010057, 40693027, 'PUTRI NUR MARLENI', 'P', 'XI-2', ''),
(192010058, 64951634, 'RADHITYA JAYA YUSUF KURNIAWAN', 'L', 'XI-3', ''),
(192010059, 40694769, 'RESTI RINJANI', 'P', 'XI-4', ''),
(192010060, 40694205, 'RIFAL NA SUTIAN', 'L', 'XI-5', ''),
(192010061, 37053652, 'RINI SULASTRI', 'P', 'XI-1', ''),
(192010062, 44995760, 'SALSABILA KHOIRUNISA', 'P', 'XI-2', ''),
(192010063, 33192303, 'SANDI YUDHA PRATAMA', 'L', 'XI-3', ''),
(192010064, 40693653, 'SHAFIRA PRIMAWATI JUNAEDI', 'P', 'XI-6', ''),
(192010065, 35753247, 'SITI ZAHRAH NURHASANAH', 'P', 'XI-6', ''),
(192010066, 40694901, 'TIARA DITA OKTAVIANI', 'P', 'XI-6', ''),
(192010067, 37389498, 'VANYA DHIAS RAHADYANNOVA', 'P', 'XI-6', ''),
(192010068, 35033652, 'WINA SULISTIAN', 'P', 'XI-5', ''),
(192010069, 37053587, 'YULIANTI AGUSTIN', 'P', 'XI-6', ''),
(192010070, 41431145, 'AGIM ABDULLAH GIMNASTIAR', 'L', 'XI-1', ''),
(192010071, 39997363, 'AGUSTINE TRYNA NINGROOM JUANA', 'P', 'XI-2', ''),
(192010072, 44561435, 'ANISSA SRI ROHMAWATI', 'P', 'XI-3', ''),
(192010073, 41412851, 'ARTHUR MUHAMAD DIANSYAH', 'L', 'XI-4', ''),
(192010074, 41339435, 'AURA ZAHRA AMIN', 'P', 'XI-6', ''),
(192010075, 49721127, 'CINDY TRI INDAH LESTARI', 'P', 'XI-5', ''),
(192010076, 43371341, 'DAFFA PUTRA EMERALD', 'L', 'XI-1', ''),
(192010077, 47935950, 'DINDA OKTA NUR ABRI', 'P', 'XI-2', ''),
(192010078, 33314247, 'DIO JOSUA PURBA', 'L', 'XI-3', ''),
(192010079, 46352235, 'FATIMA ZAMZAM', 'P', 'XI-4', ''),
(192010080, 37258252, 'FITRIA NURAENI', 'P', 'XI-6', ''),
(192010081, 40693633, 'HADAYA FIKRI NUR AQILLAH', 'L', 'XI-6', ''),
(192010082, 35033193, 'IKHSAN NANDY FIRMANSYAH', 'L', 'XI-1', ''),
(192010083, 43371549, 'INA SITI ATIKAH', 'P', 'XI-2', ''),
(192010084, 40692998, 'LEGA DIRGANTINI PUTRI', 'P', 'XI-3', ''),
(192010085, 37893317, 'LIA SINTAWATI', 'P', 'XI-4', ''),
(192010086, 46670179, 'LUFFI MUHAMAD IRAWAN', 'L', 'XI-4', ''),
(192010088, 36781756, 'MUHAMMAD NUR MUDZAKKI', 'L', 'XI-6', ''),
(192010089, 40693016, 'MUTHIA NURAZIZAH', 'P', 'XI-5', ''),
(192010090, 33046796, 'NAILA FATHIRANI ZAIN', 'P', 'XI-1', ''),
(192010091, 35513630, 'NELI NUR AULIA', 'P', 'XI-2', ''),
(192010092, 35430216, 'NURBAITYA DWI DENDA', 'P', 'XI-3', ''),
(192010093, 40693651, 'PUTRI PUSPITA SARI', 'P', 'XI-4', ''),
(192010094, 38472316, 'RAMADHAN AL FIKRI', 'L', 'XI-6', ''),
(192010095, 44077735, 'REZA AULIA RAHMASARI', 'P', 'XI-6', ''),
(192010096, 36892991, 'RIFQI ADITYA SAPUTRA', 'L', 'XI-1', ''),
(192010097, 55372697, 'RISKA FEBRIYANTI. S.', 'P', 'XI-2', ''),
(192010098, 33386213, 'SELLA SAHRINI', 'P', 'XI-3', ''),
(192010099, 40693834, 'SHELA NUR HERLINA', 'P', 'XI-4', ''),
(192010100, 40692995, 'SUCI RAHMAWATI', 'P', 'XI-6', ''),
(192010101, 35056689, 'SYAHNUR FAUZI', 'L', 'XI-5', ''),
(192010102, 36179184, 'TIARA SANDI', 'P', 'XI-1', ''),
(192010103, 44534917, 'WADDYAMILLA WILADAHAUFA', 'P', 'XI-2', ''),
(192010104, 40693017, 'YUNIA KARTIKA', 'P', 'XI-3', ''),
(192010105, 41578341, 'ADENAN KHAIRUL THORIQ RUHIMAT', 'L', 'XI-1', ''),
(192010106, 35033478, 'AHMAD YUSUF', 'L', 'XI-2', ''),
(192010107, 45485401, 'AI ALIYATU SYADIAH KOSWARA', 'P', 'XI-3', ''),
(192010108, 35033189, 'ANJAR EKA RAHAYU', 'P', 'XI-4', ''),
(192010109, 29944443, 'AYANG RENDY RISMA HIDAYAT', 'L', 'XI-5', ''),
(192010111, 43314597, 'DAVINA BELVA FIDELA', 'P', 'XI-6', ''),
(192010112, 33003325, 'DEDDY IQBAL', 'L', 'XI-1', ''),
(192010113, 35056670, 'DINDA SUCI RAHAYU', 'P', 'XI-2', ''),
(192010114, 35032403, 'FAHMI MOCHAMAD RIZKI', 'L', 'XI-3', ''),
(192010115, 37053984, 'FATIMAH NURHAIDA', 'P', 'XI-4', ''),
(192010116, 47249570, 'GINA DWI ARISTA', 'P', 'XI-5', ''),
(192010117, 40732281, 'HAIKAL PUTRA  HABIBIE ALIFA', 'L', 'XI-5', ''),
(192010118, 42291257, 'ILHAM ALY ABDILLAH', 'L', 'XI-1', ''),
(192010119, 49425432, 'IRA TRI ANANDA DIANA SARI', 'P', 'XI-2', ''),
(192010120, 49050345, 'LITA ANGGHIA ANGGRHAENI', 'P', 'XI-3', ''),
(192010121, 49870131, 'LUTHFI IRHAM ZULAFA', 'L', 'XI-4', ''),
(192010122, 33702205, 'MUHAMAD RIFKI ZAELANI', 'L', 'XI-6', ''),
(192010123, 35033600, 'MUHAMMAD RAKA FADLILLAH', 'L', 'XI-5', ''),
(192010124, 46418880, 'NABILA YASFA AZAHRA', 'P', 'XI-1', ''),
(192010125, 41245706, 'NAJLA DHIYA ARDIAN', 'P', 'XI-2', ''),
(192010126, 44197699, 'NICKY JAMEELA', 'P', 'XI-3', ''),
(192010127, 40694737, 'NURI SALSABILAH', 'P', 'XI-4', ''),
(192010128, 35032304, 'PUTRI SEPTIANI', 'P', 'XI-6', ''),
(192010129, 36163127, 'RAMADHAN SATRIA PRAWIRA', 'L', 'XI-6', ''),
(192010130, NULL, 'RIANA JANIE FATONAH', 'P', 'XI-2', ''),
(192010131, 37600892, 'RIFQI RAMDANI', 'L', 'XI-2', ''),
(192010132, 39031591, 'RISKA KARTIKA DEWI', 'P', 'XI-3', ''),
(192010133, 37487900, 'SENIA SARI', 'P', 'XI-6', ''),
(192010134, 49922375, 'SHINTYA DEWI SHAFARIYAH', 'P', 'XI-6', ''),
(192010135, 46787039, 'SYABILA AURELLIA PUTRI K.', 'P', 'XI-1', ''),
(192010136, 43616885, 'TIKA NURMALASARI', 'P', 'XI-2', ''),
(192010137, 37913692, 'WINDA WIDYA NURLATIFAH', 'P', 'XI-3', ''),
(192010138, 45527168, 'YUNIAR DWI SULAESTHI', 'P', 'XI-4', ''),
(192010139, 40694201, 'AI ALVI OKTAVIA', 'P', 'XI-1', ''),
(192010140, 32542763, 'AKMAL KOMARA TRISNA JAYA SANTIKA JATNIKA', 'L', 'XI-2', ''),
(192010141, NULL, 'ANDREA ILHAM', 'L', 'XI-3', ''),
(192010142, 44934460, 'BAGUS RIYADI', 'L', 'XI-4', ''),
(192010143, 42274312, 'BERLIANDA RAHMAWATI', 'P', 'XI-5', ''),
(192010144, 40692994, 'DEDE CAHYADI', 'L', 'XI-6', ''),
(192010145, 40693110, 'DENISSA RACHMA PUTRI', 'P', 'XI-1', ''),
(192010146, 48592914, 'EGA FAIRUZ HABIBAH', 'P', 'XI-2', ''),
(192010147, 54156918, 'FATHURRAHMAN', 'L', 'XI-3', ''),
(192010148, 40693649, 'FAUDZIAH NURROHMAH', 'P', 'XI-4', ''),
(192010149, 35033594, 'HARY SUMITRA WARDANA', 'L', 'XI-6', ''),
(192010150, 42291302, 'IMAM ARDHIANSYAH', 'L', 'XI-5', ''),
(192010151, 40693650, 'JULIA PUSPA ANGRUM', 'P', 'XI-1', ''),
(192010152, 40693499, 'LUTHFI SUKMANA ABDI', 'L', 'XI-2', ''),
(192010153, 40393498, 'MELITA DEWITA SARI', 'P', 'XI-3', ''),
(192010154, 35056667, 'MUHAMMAD DIMAS TRISDYA YUDHA GUMILANG', 'L', 'XI-4', ''),
(192010155, 33083051, 'NADHILAH HANIFFITHRIYAH', 'P', 'XI-5', ''),
(192010156, 47026770, 'NAJWA KAYLA KUSUMAPUTRI', 'P', 'XI-5', ''),
(192010157, 41737589, 'NARAYANA KHAMIL', 'L', 'XI-1', ''),
(192010158, 40694816, 'NIHLAH SOFIANA', 'P', 'XI-2', ''),
(192010159, 35033771, 'PUSPITA SARI NINGRUM', 'P', 'XI-3', ''),
(192010160, 55090721, 'RANDI JUNIAR ARIF', 'L', 'XI-4', ''),
(192010161, 45622686, 'RD. LINDA KHAIRUNISA', 'P', 'XI-5', ''),
(192010162, 42314146, 'RIFQI ZAHRAN MUTAWAKKIL', 'L', 'XI-6', ''),
(192010163, 40694196, 'RIKA WULAN', 'P', 'XI-1', ''),
(192010164, 48647239, 'RISQIA TAMIMI', 'P', 'XI-2', ''),
(192010165, 37374000, 'SEPTIANI SYINTIA PUTRI', 'P', 'XI-3', ''),
(192010166, 37609870, 'SILMI AINUN ASHAFANI', 'P', 'XI-4', ''),
(192010167, 36858948, 'SYAHWAL REGINA PUTRI SULAEMAN', 'P', 'XI-5', ''),
(192010168, 37852039, 'TITIN SULASTRI', 'P', 'XI-6', ''),
(192010169, 37054427, 'WINDY JULYANTINI ZULFA', 'P', 'XI-1', ''),
(192010170, 42273727, 'ZAKY NAUFAL KOSWARA', 'L', 'XI-2', ''),
(192010171, 40694246, 'ZULIANTI DWI NURJANNAH', 'P', 'XI-3', ''),
(192010173, 43371257, 'AI NINDA MARLIANI', 'P', 'XI-1', ''),
(192010174, 37897265, 'ALFATH RABBANI', 'L', 'XI-2', ''),
(192010175, 40970874, 'ATI KURNIATI', 'P', 'XI-3', ''),
(192010176, 50317724, 'BHAGAS YUDHA NOER ARIFIN', 'L', 'XI-4', ''),
(192010177, 11064466, 'BILQIS ZAINAB MUJAHIDAH', 'P', 'XI-6', ''),
(192010178, 37836074, 'DEVAN NADIF RIZKI HIDAYAT', 'L', 'XI-5', ''),
(192010179, 39236191, 'DEVI FAUZIAH', 'P', 'XI-1', ''),
(192010180, 24104103, 'FAUZI SEPTIANA PAMUNGKAS', 'L', 'XI-2', ''),
(192010181, 40693100, 'FAZA ASHIFA FRISNAWATI PRAMUSTAVIA', 'P', 'XI-3', ''),
(192010182, NULL, 'FEBRYA BAGUS SAPUTRA', 'L', 'XI-4', ''),
(192010183, 46527600, 'HAIFA NURJANAH', 'P', 'XI-6', ''),
(192010184, 44469933, 'HENDRIYANA PUTRA PAMUNGKAS', 'L', 'XI-6', ''),
(192010185, 40732274, 'IQBAL MAULANA SUHENDAR', 'L', 'XI-1', ''),
(192010186, 40693102, 'KARISMA TITA ULFANA', 'P', 'XI-2', ''),
(192010187, 35031807, 'M. ZAENAL AL FATTAAKH', 'L', 'XI-3', ''),
(192010188, 49076373, 'MILKA ALIYYAJANNAH', 'P', 'XI-4', ''),
(192010189, 48855491, 'MUHAMMAD FAKHRI HUSAINI', 'L', 'XI-5', ''),
(192010190, 42022500, 'NADYA ARIFANI', 'P', 'XI-1', ''),
(192010191, 40692997, 'NAKITA DINOVAN', 'P', 'XI-2', ''),
(192010192, NULL, 'NISSRINA SALSABILA FAUZIYYAH', 'P', 'XI-3', ''),
(192010193, 43371310, 'NURRIZKY FAUZHI', 'L', 'XI-4', ''),
(192010194, 48607826, 'PUTRI KARTIKA DEWI', 'P', 'XI-6', ''),
(192010195, 35032294, 'REDI HIDAYAT', 'L', 'XI-5', ''),
(192010196, 35032290, 'REGINA JULIA', 'P', 'XI-1', ''),
(192010197, 40693637, 'RIMA KUSUMA DEWI', 'P', 'XI-2', ''),
(192010198, 40694180, 'RIO FEBRIAN', 'L', 'XI-3', ''),
(192010199, 37913141, 'RIZKA NABILAH', 'P', 'XI-4', ''),
(192010200, 38472317, 'SHAFA AGHNIYA TSURAYYA', 'P', 'XI-5', ''),
(192010201, 40694176, 'SHIFA SHALSABILA', 'P', 'XI-5', ''),
(192010202, 49251817, 'SITI HAZAR NURLATIFAH', 'P', 'XI-1', ''),
(192010203, 35032312, 'SYALSYA LAILA KHODARIAH', 'P', 'XI-2', ''),
(192010205, 40694669, 'YANTI SEPTIANI', 'P', 'XI-3', ''),
(192010206, 35032565, 'ZAMMIL', 'L', 'XI-4', ''),
(192010207, 35216683, 'ALIFIA FAUZAN', 'L', 'XI-10', ''),
(192010208, 35032616, 'ALIN NURHASANAH', 'P', 'XI-10', ''),
(192010209, 33503885, 'ANING FITRI', 'P', 'XI-9', ''),
(192010210, 40694184, 'ARGYAN MOCHAMAD RIZKY HIDAYAT', 'L', 'XI-9', ''),
(192010211, 40732244, 'AURA AGRARIANA FITRIANI', 'P', 'XI-7', ''),
(192010212, 41577222, 'DEDEN AHMAD RIANTO', 'L', 'XI-7', ''),
(192010213, 35031821, 'DELA SHAFITRI', 'P', 'XI-7', ''),
(192010214, 40694192, 'DZIKRA FATHISYA', 'P', 'XI-7', ''),
(192010215, 43371299, 'ENDANG CITRA', 'P', 'XI-9', ''),
(192010216, 35033601, 'FARHAN TAUFIK AL HAKIM', 'L', 'XI-8', ''),
(192010217, 35031837, 'FITRIA FINDIAWATI', 'P', 'XI-8', ''),
(192010218, 35033750, 'GILANG PERMANA SIDIQ', 'L', 'XI-10', ''),
(192010219, 38472318, 'HANIFA AULIA BIRRI', 'P', 'XI-10', ''),
(192010220, 44194779, 'ICHSAN FADILAH', 'L', 'XI-10', ''),
(192010221, 40694333, 'IVO FARDILLAH ANGGRAENI', 'P', 'XI-9', ''),
(192010222, 40693092, 'JIHAN QONITA', 'P', 'XI-8', ''),
(192010223, 35032744, 'JUJUN JUNAEDI', 'L', 'XI-9', ''),
(192010224, 28256546, 'LISNA SITI HOLIYAH', 'P', 'XI-8', ''),
(192010225, 44858944, 'MUHAMMAD ARRY BUDIMAN', 'L', 'XI-8', ''),
(192010226, 42251297, 'NADHYA SETYANINGRUM', 'P', 'XI-9', ''),
(192010227, 39989424, 'NUR FITRI', 'P', 'XI-9', ''),
(192010228, 40732284, 'PUSPA MUSTIKA', 'P', 'XI-8', ''),
(192010229, 40030955, 'PUTRI INKAN KANIA', 'P', 'XI-9', ''),
(192010230, 43556669, 'R. ARIA DIVA RISJUNARKO', 'L', 'XI-9', ''),
(192010231, 43778384, 'REVI ALVIRA NURMALASARI', 'P', 'XI-8', ''),
(192010232, 38472311, 'RIFKI ABDILAH AKBAR', 'L', 'XI-8', ''),
(192010234, 43774807, 'SALSABILLA MAHA PUTRI', 'P', 'XI-10', ''),
(192010235, 25514586, 'SINTIA SEPTIANI PUTRI', 'P', 'XI-10', ''),
(192010236, 44461363, 'SITI NUR AZIZAH', 'P', 'XI-10', ''),
(192010237, 40693001, 'SUCIANTI SABITA SALSABILA', 'P', 'XI-10', ''),
(192010238, 35032338, 'TIA ROSMAWATI', 'P', 'XI-10', ''),
(192010240, 40694182, 'WIDIGUSTI MULYASAJATI', 'L', 'XI-10', ''),
(192010241, 40376370, 'YAYAH KARMILA', 'P', 'XI-7', ''),
(192010242, 40694187, 'ZIO WIKAGO', 'L', 'XI-7', ''),
(192010243, 37748267, 'ADINDA TALYA NABILA', 'P', 'XI-10', ''),
(192010244, 48229624, 'ADITYA KUSUMAWARDANA', 'L', 'XI-10', ''),
(192010245, 35033657, 'AMALIA RAHMA DARMAWAN', 'P', 'XI-8', ''),
(192010246, 40694974, 'ANDRA CHOERUL FACHRURROZI', 'L', 'XI-7', ''),
(192010247, 37053661, 'ANNISA NUR RAHMAWATI', 'P', 'XI-7', ''),
(192010248, 35033599, 'AUFAR BILAL FAKHRI', 'L', 'XI-8', ''),
(192010249, 43742885, 'BULAN MAHARANI', 'P', 'XI-7', ''),
(192010250, 40694727, 'DENISA NAURA APRILLIANI', 'P', 'XI-7', ''),
(192010251, 40030973, 'DILLA NURFADILLAH PERMANA', 'P', 'XI-8', ''),
(192010252, 35753132, 'DIMAS HARTANDI', 'L', 'XI-10', ''),
(192010253, 35898234, 'ERGIA NASUA RAMADHANI', 'P', 'XI-8', ''),
(192010254, 45232205, 'FEBRIANSYAH', 'L', 'XI-9', ''),
(192010255, 40693520, 'GADISTI NUR MARANTIKA', 'P', 'XI-9', ''),
(192010256, 43756113, 'HASBI REZA APRIANA', 'L', 'XI-8', ''),
(192010257, 48195663, 'HUSNUL PARHANIMULYA', 'P', 'XI-10', ''),
(192010258, 41197541, 'IQBAL RIZKI PRATAMA', 'L', 'XI-10', ''),
(192010259, 40694206, 'JESSICA INDRIYANI NABABAN', 'P', 'XI-8', ''),
(192010260, 43371311, 'KARTIKA', 'P', 'XI-8', ''),
(192010261, 43371447, 'MEISYA RIA PRATAMA', 'P', 'XI-8', ''),
(192010264, 40694245, 'NAZWA MAULIDA PUTRI', 'P', 'XI-10', ''),
(192010265, 40692325, 'NURAENI JUNIAR', 'P', 'XI-10', ''),
(192010266, 40732285, 'PUSPITA DHAMARWATI ANGGRAENI', 'P', 'XI-10', ''),
(192010267, 40694261, 'RACHMA ALYA GUSMIARNI', 'P', 'XI-10', ''),
(192010269, 40694257, 'RIFA FADHILA ZAIDAN SAFITRI', 'P', 'XI-7', ''),
(192010270, 41290879, 'RIKO GANTIRA SEPTIAWAN', 'L', 'XI-7', ''),
(192010271, 33523180, 'SEFTYANI NURLIS GUSTIAN', 'P', 'XI-7', ''),
(192010272, 38508402, 'SISKA DESTIA MILANDI', 'P', 'XI-7', ''),
(192010273, 48880062, 'SITI NURKHOLIFAH', 'P', 'XI-7', ''),
(192010274, 35033190, 'SKE QIRAKA DINTENRAJA', 'L', 'XI-7', ''),
(192010275, 37091302, 'SYIFA AWALIAH', 'P', 'XI-7', ''),
(192010276, 40693655, 'TIARA SETIA WULANDARI', 'P', 'XI-7', ''),
(192010278, 35033107, 'WILDAN FIRDAUS', 'L', 'XI-7', ''),
(192010279, 43373809, 'ADITYA NUGRAHA', 'L', 'XI-10', ''),
(192010280, 40694733, 'AMARA APRILIANI', 'P', 'XI-9', ''),
(192010281, 9443702, 'ANDRI FADILAH', 'L', 'XI-8', ''),
(192010282, 44213062, 'ARIELLA TALITHA WARDHANI', 'P', 'XI-8', ''),
(192010283, 41414047, 'AZKA SAPUTRA', 'L', 'XI-7', ''),
(192010284, 40694264, 'CHIKA TIARA AZ-ZAHRA', 'P', 'XI-7', ''),
(192010285, 40643706, 'DIAN SIFA KHAERUNISA', 'P', 'XI-7', ''),
(192010286, 43371287, 'DINDA NABILA FEBRIYAN', 'P', 'XI-7', ''),
(192010287, 47856382, 'DZIKRILAHI ANBIYA KARTA PUTRA', 'L', 'XI-9', ''),
(192010288, 35032351, 'ERNI AFENTI', 'P', 'XI-9', ''),
(192010289, 37193457, 'GIANITA NUR PERMATA SRI', 'P', 'XI-8', ''),
(192010290, 35032402, 'HATTA UTWUN BILLAH', 'L', 'XI-10', ''),
(192010291, 40693702, 'INDRI FUJI MEILANI', 'P', 'XI-10', ''),
(192010292, 35033095, 'IVAN SOPIAN', 'L', 'XI-8', ''),
(192010293, 37239757, 'JESSICA RIZKI JULIANA', 'P', 'XI-9', ''),
(192010294, 40693004, 'KREZHA PUJAYANTI', 'P', 'XI-9', ''),
(192010295, 35032741, 'MITA MUTIARA RAHAYU', 'P', 'XI-9', ''),
(192010296, 40694666, 'MUHAMAD REZA FEBRIAN', 'L', 'XI-8', ''),
(192010297, 47399757, 'MUHAMMAD YASIN FADHILAH', 'L', 'XI-9', ''),
(192010298, 35361998, 'NESTA LITA AGISNA', 'P', 'XI-8', ''),
(192010299, 40694243, 'NURDINI HASTIANINGSIH', 'P', 'XI-8', ''),
(192010300, 29533179, 'PUTRI AGUSTIEN', 'P', 'XI-9', ''),
(192010301, 35033144, 'RAHAYU ABDILLAH', 'P', 'XI-8', ''),
(192010302, 35496454, 'RICKY SEPTIAN SUTARYANA', 'L', 'XI-8', ''),
(192010304, 44995762, 'RIO AHMAD DARMAWAN', 'L', 'XI-10', ''),
(192010305, 37913698, 'SHERLLY NANDA NURLYANI', 'P', 'XI-10', ''),
(192010306, 43149843, 'SITI AMARA DAVAINA', 'P', 'XI-10', ''),
(192010307, NULL, 'SRI NANDA NURHALISA', 'P', 'XI-10', ''),
(192010308, 40694188, 'SULTAN MAULIDAN\'SYAH', 'L', 'XI-10', ''),
(192010309, 33669356, 'SYIFA RHAMADANI', 'P', 'XI-10', ''),
(192010310, 40692329, 'TRILIANI ALFIRA', 'P', 'XI-10', ''),
(192010311, 37894729, 'YEN YEN NURLAELA GUNAWAN', 'P', 'XI-7', ''),
(192010312, 40694171, 'YOGA NUR FATURROHMAN', 'L', 'XI-7', ''),
(192010313, 40732287, 'ZIHAN LAILA RAMADHANTY', 'P', 'XI-7', ''),
(192010314, 35033195, 'AJI DESTIAN', 'L', 'XI-10', ''),
(192010315, 40694244, 'ALIFIA NOERSHIDDIQ', 'P', 'XI-10', ''),
(192010316, 43411395, 'ANDRI SETIAWAN', 'L', 'XI-8', ''),
(192010317, 48735868, 'ANGGI TIEN ROSLYANI', 'P', 'XI-8', ''),
(192010318, 44995751, 'ARINI GINA AFIFAH', 'P', 'XI-9', ''),
(192010319, 43061095, 'CINDY AULIA', 'P', 'XI-7', ''),
(192010320, 46978800, 'DEAN NICYA MORENO', 'L', 'XI-7', ''),
(192010321, 31421049, 'DIAN SUKRIA RISTIANTI', 'P', 'XI-7', ''),
(192010322, 35033109, 'DITA PUSPITA', 'P', 'XI-7', ''),
(192010323, 35032302, 'FAISAL HARUN SEPTIANSYAH', 'L', 'XI-7', ''),
(192010324, 40692080, 'FARIDA DINI AGUSTIN', 'P', 'XI-7', ''),
(192010325, 43452184, 'GENTA RIANA', 'L', 'XI-7', ''),
(192010326, 57799676, 'GISCHA FATHYA ALIFA DITAATMADJA', 'P', 'XI-9', ''),
(192010327, 40694728, 'ICHLAS TRINATA NUR', 'L', 'XI-9', ''),
(192010328, 40732283, 'INDRI JULIYANTI SOBANDI', 'P', 'XI-8', ''),
(192010329, 37233583, 'JANNI AGASTYA MADHANI', 'L', 'XI-9', ''),
(192010330, 45564559, 'JIHAN ADIENDA PUTRI', 'P', 'XI-9', ''),
(192010331, 40694894, 'LINGGA DEA AULIA', 'P', 'XI-9', ''),
(192010333, 40694202, 'MUHAMAD FARHAN ALFARIZY', 'L', 'XI-8', ''),
(192010334, 41468957, 'MUHAMAD THONI BAEHAKI PRATAMA', 'L', 'XI-9', ''),
(192010335, 47559802, 'NOVITA RAHMADANI NAKUL', 'P', 'XI-8', ''),
(192010336, 40694181, 'PEBI INDRI HERDIANI', 'P', 'XI-9', ''),
(192010337, 40694200, 'PUTRI ELIDA MAWAR INDAH', 'P', 'XI-8', ''),
(192010338, 35033098, 'RAHESTA ARDHYA PRAMESTI', 'P', 'XI-9', ''),
(192010340, 48874681, 'RIDWAN MAULANA SIDIK', 'L', 'XI-9', ''),
(192010341, 39840249, 'RISMA FADILLA', 'P', 'XI-8', ''),
(192010342, 40694721, 'RYAN SAPUTRA', 'L', 'XI-9', ''),
(192010343, 43797287, 'SILVI ERLI NURHAVILAH', 'P', 'XI-9', ''),
(192010344, 40694186, 'SITI KARLINA', 'P', 'XI-8', ''),
(192010345, 40694729, 'TANJUNG SANDY PUTRA', 'L', 'XI-8', ''),
(192010346, 20041340, 'TETI NURPADILAH', 'P', 'XI-9', ''),
(192010347, 44995759, 'VANI NURSYAMSIAH PIRDAYANTI', 'P', 'XI-8', ''),
(192010348, 37452103, 'WULAN PUSPITA DEWI', 'P', 'XI-9', ''),
(192010349, 40694174, 'YOGI CAHYA YOGASWARA', 'L', 'XI-9', ''),
(202110036, 58197270, 'ADHISTI RESTI GAYANTRI NURAHMAN', 'P', 'X-2', ''),
(202110037, 44950272, 'AGNI ANDRIANI', 'P', 'X-2', ''),
(202110038, 49378117, 'AMELIA OKTAVIANI', 'P', 'X-2', ''),
(202110039, 51075198, 'ANDINI MEYLANI NURWULAN', 'P', 'X-2', ''),
(202110040, 44091572, 'AYESSA F J GUNDARA', 'P', 'X-2', ''),
(202110041, 51073648, 'BAYU DARMAWAN', 'L', 'X-2', ''),
(202110042, 51074244, 'DANI AFRILIAN MAULUDDIN', 'L', 'X-2', ''),
(202110043, 56589435, 'DEVINA SALSABILLA', 'P', 'X-2', ''),
(202110044, 59547598, 'ELNA KURAENI', 'p', 'X-2', ''),
(202110045, 44950350, 'FADILATUL MAULA', 'P', 'X-2', ''),
(202110046, 42273728, 'FARRELL KHAYRU KUMARAHARDI', 'L', 'X-2', ''),
(202110047, 43923441, 'FIKRI NOVIANSYAH', 'L', 'X-2', ''),
(202110048, 3048454297, 'GHEFIRA SONIYA ANANTA', 'P', 'X-2', ''),
(202110049, 42066058, 'HAFIDZ MUHAMMAD NUGRAHA', 'L', 'X-2', ''),
(202110050, 44062693, 'IKA PRASAUMA', 'P', 'X-2', ''),
(202110051, 44994835, 'INTAN AWALLIA', 'P', 'X-2', ''),
(202110052, 52138543, 'ISNI AMALLYA RAHMATTIKA', 'P', 'X-2', ''),
(202110053, 45295032, 'KAMELIA DEWI', 'P', 'X-2', ''),
(202110054, 44993939, 'KHAIRUNNISA', 'P', 'X-2', ''),
(202110055, 47965765, 'LUFIANA KURNIA', 'L', 'X-2', ''),
(202110056, 55828621, 'MAULIDA SALSABILA', 'P', 'X-2', ''),
(202110057, 43989244, 'MISHA ARYANTI', 'P', 'X-2', ''),
(202110058, 51073430, 'MUHAMAD FARHAN ARFARIZKY', 'L', 'X-2', ''),
(202110059, 3045126280, 'NADILLAH NUR SABRINA', 'P', 'X-2', ''),
(202110060, 57218530, 'NISSA AMELIA', 'P', 'X-2', ''),
(202110061, 44950273, 'PUTRI ALIVIA NURHABIBAH', 'P', 'X-2', ''),
(202110062, 51953908, 'RAKA AHMAD FAUZI PUTRA', 'L', 'X-2', ''),
(202110063, 51074252, 'RIKA MEILAWATI', 'P', 'X-2', ''),
(202110064, 52052902, 'SAHIRA NURGUSTINI SALSABILA', 'P', 'X-2', ''),
(202110065, 56925805, 'SALVA FAKHIRA', 'P', 'X-2', ''),
(202110066, 55693517, 'SINDI NUR\'AZIZAH', 'P', 'X-2', ''),
(202110067, 51073769, 'SRI WULAN APRILIA', 'P', 'X-2', ''),
(202110068, 33103551, 'TIARA RENATA SEPTINI', 'P', 'X-2', ''),
(202110069, 54574399, 'YELLY AMBARWATI', 'P', 'X-2', ''),
(202110070, 44994842, 'ADI SAPUTRA SIHOMBING', 'L', 'X-3', ''),
(202110071, 51075322, 'AGNIA FITRI LESTARI', 'P', 'X-3', ''),
(202110072, 48725057, 'AMELIA PUTRI GUNAWAN', 'P', 'X-3', ''),
(202110073, 51074960, 'ANGGITA ERIKA PUTRI SUSANTO', 'P', 'X-3', ''),
(202110074, 51074856, 'AZHAR RIZQILLAH FAUZY', 'L', 'X-3', ''),
(202110075, 51074865, 'BRESYA NUR SALSABILA SUPRIADI', 'P', 'X-3', ''),
(202110076, 45473782, 'DARA NOVIANTICA', 'P', 'X-3', ''),
(202110077, 44954550, 'DIAN NURLELA', 'P', 'X-3', ''),
(202110078, 44994212, 'ELSA DELIA FITRI', 'P', 'X-3', ''),
(202110079, 51074697, 'FAHRYAN JUNAEDI', 'L', 'X-3', ''),
(202110080, 51073646, 'FAULINAWATI RAHMAWIGUNA', 'P', 'X-3', ''),
(202110081, 51074839, 'GEMA SUKMA IBRAHIM', 'L', 'X-3', ''),
(202110082, 46016954, 'GILANG SANGGA RAMADHAN', 'L', 'X-3', ''),
(202110083, 48694602, 'HAWWA ULLA GHALIYAH', 'P', 'X-3', ''),
(202110084, 51073510, 'ILHAM MAULANA', 'L', 'X-3', ''),
(202110085, 56342826, 'INTAN FUJI ANDINI', 'P', 'X-3', ''),
(202110086, 44128325, 'IVAN FATHURROHMAN', 'L', 'X-3', ''),
(202110087, 45082944, 'KAMILA NURFAJRINA', 'P', 'X-3', ''),
(202110088, 49992379, 'KHAITSA ZAHIRA AGUSTINA', 'P', 'X-3', ''),
(202110089, 43389438, 'M. IQBAL ZULFIKAR', 'L', 'X-3', ''),
(202110090, 58247056, 'MEILANI EKARISTI', 'P', 'X-3', ''),
(202110091, 57543596, 'MUCH FIKRI AHNAF', 'L', 'X-3', ''),
(202110092, 48136692, 'MUHAMAD RENDI SEPRIATNA', 'L', 'X-3', ''),
(202110093, 44494197, 'NABILAH AZ ZAHRA', 'P', 'X-3', ''),
(202110094, 52301180, 'NISSA AULIYA', 'P', 'X-3', ''),
(202110095, 42383303, 'RACHMA ABILLAH KUSDIANA', 'L', 'X-3', ''),
(202110096, 51074257, 'RAKHA SALSABILA JAUZA', 'P', 'X-3', ''),
(202110097, 51074247, 'RITA NUR SUSILAWATI', 'P', 'X-3', ''),
(202110098, 44969153, 'SALMA KHAIRUNNISA', 'P', 'X-3', ''),
(202110099, 47260263, 'SHAFA DESTITA ULINNUHA', 'P', 'X-3', ''),
(202110100, 44995170, 'SITI NURANGGRAENI', 'P', 'X-3', ''),
(202110101, 51074844, 'SUCI RAHAYU', 'P', 'X-3', ''),
(202110102, 58519497, 'VANESSA TRAVIATA', 'P', 'X-3', ''),
(202110103, 44993591, 'YOSAN SONJAYA', 'L', 'X-3', ''),
(202110104, 41102027, 'ADINDA NABILA MAHARANI', 'P', 'X-4', ''),
(202110105, 41028890, 'ALDY AGUSTIANA', 'L', 'X-4', ''),
(202110106, 48111058, 'AMELIA PUTRI LATIFAH', 'P', 'X-4', ''),
(202110107, 51075193, 'ANGGUN PUTRI ALYANTI', 'P', 'X-4', ''),
(202110108, 51074855, 'AZKA AZKIA TAWKAL', 'L', 'X-4', ''),
(202110109, 56440467, 'CHAIRIL GIBRAN', 'L', 'X-4', ''),
(202110110, 47821427, 'DESINTA AKBAR', 'P', 'X-4', ''),
(202110111, 51017754, 'DINDA HAMIDAH', 'P', 'X-4', ''),
(202110112, 51166056, 'EUIS RANA', 'P', 'X-4', ''),
(202110113, 41204101, 'FANISYA DWI ERIAANTI', 'P', 'X-4', ''),
(202110114, 51073404, 'Fauzan Abdul Fiqri', 'L', 'X-4', ''),
(202110115, 51073488, 'GENNY GITA GESELA', 'P', 'X-4', ''),
(202110116, 59106687, 'GINA PEBRIANTI', 'P', 'X-4', ''),
(202110117, 43385638, 'HESTY NOVIANA NURAENI', 'P', 'X-4', ''),
(202110118, 51073788, 'ILHAM TAUFIK FEBRIANA HANAFIAH', 'L', 'X-4', ''),
(202110119, 51760278, 'INTAN NUR\'AENI', 'P', 'X-4', ''),
(202110120, 55420212, 'JOSUA TUA PRATAMA NAINGGOLAN', 'L', 'X-4', ''),
(202110121, 51072931, 'KANIA SITI RAHMAYANTI', 'P', 'X-4', ''),
(202110122, 51399254, 'LAFADHYA MUNGGARAN WILANTARA', 'P', 'X-4', ''),
(202110123, 3047632254, 'M. RAMDAN EKA PERMANA', 'L', 'X-4', ''),
(202110124, 44995218, 'MELANI NUR INDAH', 'P', 'X-4', ''),
(202110125, 51174763, 'MUHAMAD BINTANG DWI MAULANA', 'L', 'X-4', ''),
(202110126, 49191989, 'MUHAMMAD FAJAR UTAMA', 'L', 'X-4', ''),
(202110127, 51075196, 'NANDINI PUSPA DEWI', 'P', 'X-4', ''),
(202110128, 54359601, 'NURLITA DHEINA PUTRIA', 'P', 'X-4', ''),
(202110129, 45697409, 'RAIHAN JAUHAR IBRAHIM', 'L', 'X-4', ''),
(202110130, 52314009, 'REGINA RESTA AZALEA UTAMI', 'P', 'X-4', ''),
(202110131, 48957574, 'RIZKI GHIFARI NUGRAHA', 'L', 'X-4', ''),
(202110132, 49384415, 'SALSA AMALIA AFIFI', 'P', 'X-4', ''),
(202110133, 57962711, 'SHELINA HERLYANTI', 'P', 'X-4', ''),
(202110134, 49861288, 'SITI ROKAYAH', 'P', 'X-4', ''),
(202110135, 44995342, 'SYARIFAH FADILLAH', 'P', 'X-4', ''),
(202110136, 51072932, 'VINA RAHAYU', 'P', 'X-4', ''),
(202110137, 51074233, 'ZAHRA NEDILFIANA PUTRI', 'P', 'X-4', ''),
(202110138, 57266631, 'ANI RAHMAWATI', 'P', 'X-5', ''),
(202110139, 51012959, 'ASSYFA FAUZIA', 'P', 'X-5', ''),
(202110140, 44954178, 'AZFA MAHARDIKA S', 'L', 'X-5', ''),
(202110141, 44995459, 'DAHLIA PURGANANTI', 'P', 'X-5', ''),
(202110142, 51759574, 'DEWI NUR BAROKAH YULIANA', 'P', 'X-5', ''),
(202110143, 51075120, 'FANNY SETIA PEBRIANTI', 'P', 'X-5', ''),
(202110144, 51074971, 'FUJI AMELIA AINNUNISHA', 'P', 'X-5', ''),
(202110145, 54284779, 'HALIMAH TUSSADI\'AH', 'P', 'X-5', ''),
(202110146, 59204143, 'INDRI YULIANI', 'P', 'X-5', ''),
(202110147, 44978226, 'LADIVA MAHAPUTRI FAHRUDIN', 'P', 'X-5', ''),
(202110148, 48149982, 'METHA DWI NUR ADESTI', 'P', 'X-5', ''),
(202110149, 51074254, 'MUHAMAD FADRI HARUNSYAH', 'L', 'X-5', ''),
(202110150, 63362765, 'MUHAMMAD ZIDANE', 'L', 'X-5', ''),
(202110151, 48121492, 'NABILA APRILLIANI', 'P', 'X-5', ''),
(202110152, 51012974, 'NAURA JANNAH MAULIDA', 'P', 'X-5', ''),
(202110153, 51072934, 'NIMAS DEWI SEKARJAGAT', 'P', 'X-5', ''),
(202110154, 43776201, 'NIZAR RHEIVANI RAMADINA SUPRIADI', 'P', 'X-5', ''),
(202110155, 56768424, 'NURHAYATI', 'P', 'X-5', ''),
(202110156, 45213023, 'PUTRI AYU NURMALASARI', 'P', 'X-5', ''),
(202110157, 41506549, 'PUTRI FITRIANA NUR SYIFA', 'P', 'X-5', ''),
(202110158, 51072953, 'RANDIKA CANDRA WIJAYA', 'L', 'X-5', ''),
(202110159, 39136385, 'REINA FITRIANI PRABOWO', 'P', 'X-5', ''),
(202110160, 50831094, 'RICKA AMALIA', 'P', 'X-5', ''),
(202110161, 46812156, 'RIZKIA UMMAMI AULIYA TAQWA', 'P', 'X-5', ''),
(202110162, 53483072, 'SALMA NABILAH', 'P', 'X-5', ''),
(202110163, 3046812654, 'SENDI MUHAMAD', 'L', 'X-5', ''),
(202110164, 48875576, 'SHELVA AULIA NURSHABRINA', 'P', 'X-5', ''),
(202110165, 44994503, 'SHINTYASARI HADI KARMILA', 'P', 'X-5', ''),
(202110166, 51073343, 'SILVIA ALLYA PUTRI', 'P', 'X-5', ''),
(202110167, 3040481850, 'SYAKIR FADHILLAH', 'L', 'X-5', ''),
(202110168, 3054598896, 'TAUFIQ MAULANA', 'L', 'X-5', ''),
(202110169, 51074700, 'VANNI FEBIANI PUTRI', 'P', 'X-5', ''),
(202110170, 47932865, 'WILDAN NUGRAHA', 'L', 'X-5', ''),
(202110171, 58467288, 'ZAKY RIBAS SAEPUDIN', 'L', 'X-5', ''),
(202110172, 51073345, 'ANISAH NURJANAH', 'P', 'X-6', ''),
(202110173, 53716458, 'AURELLIA PUTRI WIDWIUTAMI', 'P', 'X-6', ''),
(202110174, 51098586, 'CANTIKA SARI NURFALAH', 'P', 'X-6', ''),
(202110175, 3053739898, 'DELLA PUSPITA ANGGRAENI', 'P', 'X-6', ''),
(202110176, 56758858, 'FALAH NURFADILAH', 'P', 'X-6', ''),
(202110177, 48144811, 'FITRI NURHAYATI', 'P', 'X-6', '');
INSERT INTO `tbl_student` (`NISS`, `NISN`, `fullname`, `gender`, `class`, `photo`) VALUES
(202110178, 44993639, 'GHAIDA FAUZIAH', 'P', 'X-6', ''),
(202110179, 46673233, 'ILYA MARIA ULFAH', 'P', 'X-6', ''),
(202110180, 48331912, 'ISFIHANY LESTARI', 'P', 'X-6', ''),
(202110181, 54985394, 'MELA AGUSTIN', 'P', 'X-6', ''),
(202110182, 51399600, 'MITA DZAKIRAH KURNIA', 'P', 'X-6', ''),
(202110183, 45213629, 'MOCHAMAD AKBAR RAMADHAN', 'L', 'X-6', ''),
(202110184, 58004540, 'MUHAMAD FARID ABDULLOH', 'L', 'X-6', ''),
(202110185, 3055963726, 'NABILA KHAERUNISA BUDIMAN', 'P', 'X-6', ''),
(202110186, 57855301, 'NAUFAL LUTHFI BARIZKI', 'L', 'X-6', ''),
(202110187, 58150233, 'NENDEN SITI MEILANI', 'P', 'X-6', ''),
(202110188, 51449687, 'NISSA HANIN DITA', 'P', 'X-6', ''),
(202110189, 46268366, 'NORIKA MARLIANA', 'P', 'X-6', ''),
(202110190, 44954171, 'NURUL RIZKY BAITI', 'P', 'X-6', ''),
(202110191, 44993694, 'PUTRI EKA APRILIA', 'P', 'X-6', ''),
(202110192, 44954186, 'RAIHAN BISYRI RABBANI', 'L', 'X-6', ''),
(202110193, 51017661, 'REBINA NURHASANAH', 'P', 'X-6', ''),
(202110194, 43522371, 'RENI FITRIYANI', 'P', 'X-6', ''),
(202110195, 54756115, 'RISMA RENGGANIS', 'P', 'X-6', ''),
(202110196, 43909085, 'SALMA HAYNUR FADILAH', 'P', 'X-6', ''),
(202110197, 52072962, 'SALSA BAHARANI FUTRI NURELASENSA', 'P', 'X-6', ''),
(202110198, 44995211, 'SHANAZ YUNIAR', 'P', 'X-6', ''),
(202110199, 44242780, 'SHELYNA MARDIANA PUTRI', 'P', 'X-6', ''),
(202110200, 51074696, 'SILVI SELVIA RIYANY', 'P', 'X-6', ''),
(202110201, 53590175, 'SUCI NUR\'AINI', 'P', 'X-6', ''),
(202110202, 47271945, 'TASYA FADILLA', 'P', 'X-6', ''),
(202110203, 51072942, 'TOYIB ABDUL RAHMAN', 'L', 'X-6', ''),
(202110204, 44995427, 'VIONA ZULFA ADRIANE', 'P', 'X-6', ''),
(202110205, 51017755, 'ZAHRA NABILA PERMANA', 'P', 'X-6', ''),
(202110206, 51074861, 'AFUZA LAUTAN NAJATIN', 'P', 'X-7', ''),
(202110207, 42622556, 'ELDY FIRMANSYAH GUSTIAN', 'L', 'X-7', ''),
(202110208, 48259469, 'FIRMAN MAULANA', 'L', 'X-7', ''),
(202110209, 46198072, 'HANI NURYANI', 'P', 'X-7', ''),
(202110210, 43905468, 'HARTATI AGUSTINA', 'P', 'X-7', ''),
(202110211, 46844479, 'HUSEN NURUL IMAN', 'L', 'X-7', ''),
(202110212, 51074601, 'LUCKY ANUGRAH', 'L', 'X-7', ''),
(202110213, 51765922, 'MOCH. ZACKY RIFANSYAH', 'L', 'X-7', ''),
(202110214, 44602105, 'MUHAMAD AKMAL RAFSANZHANI', 'L', 'X-7', ''),
(202110215, 51074262, 'MUHAMAD RIZKY OKTAVIAN', 'L', 'X-7', ''),
(202110216, 51073429, 'MUHAMMAD RAMDAN', 'L', 'X-7', ''),
(202110217, 44994195, 'MUHAMMAD RIFKI HIDAYAT', 'L', 'X-7', ''),
(202110218, 44993596, 'NABIL HAIDAR WAPID', 'L', 'X-7', ''),
(202110219, 57919330, 'NADHIL IKHWAN ASHSHIBA WALUYA', 'L', 'X-7', ''),
(202110220, 44784449, 'NADILA OKTAPIANI', 'P', 'X-7', ''),
(202110221, 44994850, 'NAURA NUR ZAHRA', 'P', 'X-7', ''),
(202110222, 3041757032, 'RAFI MANSYUR RASYID', 'L', 'X-7', ''),
(202110223, 51075199, 'RAHMA LARAS SAEPADILAH', 'P', 'X-7', ''),
(202110224, 51073502, 'RAINI RAHMADANI', 'P', 'X-7', ''),
(202110225, 40732231, 'RENDI FAJAR FIRMANSYAH', 'L', 'X-7', ''),
(202110226, 41765914, 'REVALIA SAFITRI', 'P', 'X-7', ''),
(202110227, 44428032, 'REZA SRI DALIESTA', 'P', 'X-7', ''),
(202110228, 46868707, 'RINI SURYANI', 'P', 'X-7', ''),
(202110229, 58618094, 'RISMA DWI APRILIYANA', 'P', 'X-7', ''),
(202110230, 55016641, 'RONI ROMANSYAH', 'L', 'X-7', ''),
(202110231, 54428312, 'SALSA KHOERUNISSA', 'P', 'X-7', ''),
(202110232, 51074592, 'SAVITRI SALSABILA', 'P', 'X-7', ''),
(202110233, 46714591, 'SOFIA RAHMA', 'P', 'X-7', ''),
(202110234, 58932795, 'SUSAN RIZKI SAHBUDIN', 'P', 'X-7', ''),
(202110235, 51074265, 'SYEILA THABITA S', 'P', 'X-7', ''),
(202110236, 51075211, 'TASYA AMALIA', 'P', 'X-7', ''),
(202110237, 3044774498, 'TIARA LESTARI', 'P', 'X-7', ''),
(202110238, 51075180, 'TRISA AYUDIA', 'P', 'X-7', ''),
(202110239, 3051025441, 'WAHIDIN SETIAJI PUTRA', 'L', 'X-7', ''),
(202110240, 44995434, 'YENI MASRIFAH', 'P', 'X-7', ''),
(202110241, 51073791, 'ZAENAL MUSTAFA', 'L', 'X-7', ''),
(202110242, 57679370, 'ALEYA AZZAHRA', 'P', 'X-8', ''),
(202110243, 44994071, 'ALYSSA ZAFFINA', 'P', 'X-8', ''),
(202110244, 44995677, 'ANGGA RAMADAN', 'L', 'X-8', ''),
(202110245, 51722258, 'ANNISA NUR AZIZAH', 'P', 'X-8', ''),
(202110246, 63808870, 'ASRI AIDA SUSANTIKA', 'P', 'X-8', ''),
(202110247, 53954055, 'AZZAHRA KIREINA', 'P', 'X-8', ''),
(202110248, 51074256, 'CINDY BERLIYANI', 'P', 'X-8', ''),
(202110249, 51098558, 'DEDE ROSADI', 'L', 'X-8', ''),
(202110250, 3059348632, 'DENISA YUNIARTI', 'P', 'X-8', ''),
(202110251, 49270639, 'EKA GUNTARA', 'L', 'X-8', ''),
(202110252, 55801999, 'ESRA WASTI HUTASOIT', 'P', 'X-8', ''),
(202110253, 44994073, 'FAUZAN AZZARIA HAFIEDZ', 'L', 'X-8', ''),
(202110254, 45426953, 'FEBI HERMAWAN', 'L', 'X-8', ''),
(202110255, 52622856, 'FRANS AGUNG FRAMONO PASARIBU', 'L', 'X-8', ''),
(202110256, 3058196034, 'GALANG MERDIKA IBNU MUTAQIEN', 'L', 'X-8', ''),
(202110257, 48248517, 'GESYA FELISHA LAURA', 'P', 'X-8', ''),
(202110258, 58463444, 'HAIKAL FAISAL RASYID', 'L', 'X-8', ''),
(202110259, 51075335, 'HILDA KURNIA', 'P', 'X-8', ''),
(202110260, 41663841, 'ILHAM AKBAR MAULANA', 'L', 'X-8', ''),
(202110261, 48124676, 'INA SARTIKA MAELANI', 'P', 'X-8', ''),
(202110262, 56946116, 'KAMIL RIZIK FAZIRIN', 'L', 'X-8', ''),
(202110263, 51073491, 'KIRANA DI SECHAN', 'P', 'X-8', ''),
(202110264, 55997703, 'LAISYA ARIANTY UTAMI', 'P', 'X-8', ''),
(202110265, 44994072, 'MAHRUNISA', 'P', 'X-8', ''),
(202110266, 3049662868, 'MUGHNI RAMDANI', 'L', 'X-8', ''),
(202110267, 35031638, 'MUHAMMAD RAMDHAN', 'L', 'X-8', ''),
(202110268, 53438840, 'NASYWA ATHALIA', 'P', 'X-8', ''),
(202110269, 44994856, 'RAHAYU KARYADI NINGRAT', 'L', 'X-8', ''),
(202110270, 41909622, 'RESTU AKSA NAYA', 'P', 'X-8', ''),
(202110271, 33780988, 'RISTA BAKTI PERTIWI', 'P', 'X-8', ''),
(202110272, 3056687695, 'SALMAN MAULANA', 'L', 'X-8', ''),
(202110273, 51730112, 'SHAREL FATURAHMAN', 'L', 'X-8', ''),
(202110274, 57982988, 'SURYANI', 'P', 'X-8', ''),
(202110275, 44994014, 'TARIS BARIKAN', 'L', 'X-8', ''),
(202110276, 51074259, 'TULIS KHALIS PURWAKA', 'P', 'X-8', ''),
(202110277, 3051527312, 'YUDA EKA PRASETYA', 'L', 'X-8', ''),
(202110278, 48208655, 'ALIF DWI NUGRAHA', 'L', 'X-9', ''),
(202110279, 53279511, 'AMELIA ROSSIANA', 'P', 'X-9', ''),
(202110280, 44994858, 'ANISA RODIAH RAHAYU', 'P', 'X-9', ''),
(202110281, 45590151, 'ANNISA NUR AZZAHRA', 'P', 'X-9', ''),
(202110282, 43685631, 'AULIA NURJAHIDAH', 'P', 'X-9', ''),
(202110283, 48348336, 'BELLA FITRI NURHASANAH', 'P', 'X-9', ''),
(202110284, 45473772, 'DADAN MUSYAROPUL', 'L', 'X-9', ''),
(202110285, 56215320, 'DEDEN NURMANSYAH', 'L', 'X-9', ''),
(202110286, 46798273, 'DESTYA PUTRI LESTARI', 'P', 'X-9', ''),
(202110287, 3047842800, 'ELANGGA YUDISTIRA', 'L', 'X-9', ''),
(202110288, 36504486, 'FAISAL SALMAN ALFARIZ', 'L', 'X-9', ''),
(202110289, 51073397, 'FAUZIA NURPADILAH', 'P', 'X-9', ''),
(202110290, 47682812, 'FITRI ARYANTI', 'P', 'X-9', ''),
(202110291, 45814911, 'FUJI NURZAMAN', 'L', 'X-9', ''),
(202110292, 57177717, 'GARRY PUTRA PAMUNGKAS', 'L', 'X-9', ''),
(202110293, 51074849, 'GHAZIYA MILADIAH KHOERUNISA', 'P', 'X-9', ''),
(202110294, 47220681, 'HANI OKTAVIANI NURFALLAH', 'P', 'X-9', ''),
(202110295, 56925946, 'ICAS MULYANA', 'L', 'X-9', ''),
(202110296, 52856382, 'IMA NURHAYATI', 'P', 'X-9', ''),
(202110297, 48058755, 'INDAH NURFAUZIAH J.', 'P', 'X-9', ''),
(202110298, 44940967, 'KARTIKA DITA AZZAHRA', 'P', 'X-9', ''),
(202110299, 51073400, 'KOMALA', 'P', 'X-9', ''),
(202110300, 42181363, 'LITTA NURJANAH', 'P', 'X-9', ''),
(202110301, 53861620, 'MELA KOESMAYANTI', 'P', 'X-9', ''),
(202110302, 43533818, 'MUHAMAD BINTANG RIZAQI', 'L', 'X-9', ''),
(202110303, 3048179917, 'MUHAMMAD RIVALDY', 'L', 'X-9', ''),
(202110304, 53760374, 'NATASYA BENING HANURANI. F', 'P', 'X-9', ''),
(202110305, 3041050380, 'RAHMAT HIDAYAT', 'L', 'X-9', ''),
(202110306, 54536071, 'REVA NATAMA', 'L', 'X-9', ''),
(202110307, 51074246, 'RIZKI ANDREA', 'L', 'X-9', ''),
(202110308, 52738828, 'SALSHA NURUL AINA', 'P', 'X-9', ''),
(202110309, 54069230, 'SITI MASHFUFAH NURAENI', 'P', 'X-9', ''),
(202110310, 51074586, 'SYAHRANI LISNIAWATI ROHMAH', 'P', 'X-9', ''),
(202110311, 44304112, 'TIA DESTRIANA RACHMAT', 'P', 'X-9', ''),
(202110312, 43008452, 'UTARI NURHAMIDAH', 'P', 'X-9', ''),
(202110313, 59823141, 'ZAKIAH DARAJAT', 'P', 'X-9', ''),
(202110314, 44994846, 'AKHMAD MUKHTAR AJI PRASETYA', 'L', 'X-10', ''),
(202110315, 51074234, 'ALYA ATHIYAH NURFAIZAH', 'P', 'X-10', ''),
(202110316, 51533580, 'ANDRIANSYAH ADYTYA NUGRAHA', 'L', 'X-10', ''),
(202110317, 51074436, 'ANITA WULAN SARI', 'P', 'X-10', ''),
(202110318, 59716985, 'ASMALA AZHARI PUTRI', 'P', 'X-10', ''),
(202110319, 52399341, 'AUREL MAURA DEWI', 'P', 'X-10', ''),
(202110320, 31128621, 'CEPI RAMADANI', 'L', 'X-10', ''),
(202110321, 52893444, 'DEAN ZISKA MAULIDYA', 'P', 'X-10', ''),
(202110322, 51074847, 'DEGA GEZA AL MIFDHIL WAL MUSLIM', 'L', 'X-10', ''),
(202110323, 51075252, 'DINI NURJANAH', 'P', 'X-10', ''),
(202110324, 51073492, 'ELVAN NUR APRILIANSYAH', 'L', 'X-10', ''),
(202110325, 44995279, 'FAKHRY RAHMAN', 'L', 'X-10', ''),
(202110326, 51892885, 'FAZIDA AQLUDINA', 'P', 'X-10', ''),
(202110327, 44994070, 'FITRIANA ANANDA OCKTAVIANI', 'P', 'X-10', ''),
(202110328, 3054964498, 'GALANG ERLANGGA', 'L', 'X-10', ''),
(202110329, 59261228, 'GEOVANY PUTRA TRI PAMUNGKAS', 'L', 'X-10', ''),
(202110330, 3056360391, 'GILANG SAGARA', 'L', 'X-10', ''),
(202110331, 51639291, 'HASHFI RAHMAN', 'L', 'X-10', ''),
(202110332, 44994207, 'IKHSAN RAHAYU', 'L', 'X-10', ''),
(202110333, 51074231, 'IMELDA RELYANI VEGA', 'P', 'X-10', ''),
(202110334, 51075330, 'INTAN NATALIA', 'P', 'X-10', ''),
(202110335, 58890579, 'KIKI RIYANTI', 'P', 'X-10', ''),
(202110336, 49330937, 'LAILA VENADHITA', 'P', 'X-10', ''),
(202110337, 56592289, 'MAGFIRA NURQOLBU ARDIANSYAH', 'P', 'X-10', ''),
(202110338, 46175153, 'MUHAMMAD IQBAL ALGHIFFARI', 'L', 'X-10', ''),
(202110339, 59472145, 'MUTIARA KHODIJAH', 'P', 'X-10', ''),
(202110340, 44022567, 'PERI RUSLI HAMDI', 'L', 'X-10', ''),
(202110341, 40694185, 'RAKA PRASASTA', 'L', 'X-10', ''),
(202110342, 51074232, 'RIO LINGGA ADHARI', 'L', 'X-10', ''),
(202110343, 38471923, 'ROHMANA', 'L', 'X-10', ''),
(202110344, 67024854, 'SAYYIDATUL ADAWIYYAH', 'P', 'X-10', ''),
(202110345, 3042004757, 'SUCI AULIAUSHOLIHAH', 'P', 'X-10', ''),
(202110346, 42586118, 'TALITHA LUTFI BUCHARI', 'P', 'X-10', ''),
(202110347, 42586119, 'TRIA HERMAYANTY', 'P', 'X-10', ''),
(202110348, 42586120, 'WIRYA SANTANA INDRAYANA', 'L', 'X-10', '');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_teacher`
--

CREATE TABLE `tbl_teacher` (
  `NIP` int(11) NOT NULL,
  `homeroom_teacher` varchar(29) DEFAULT NULL,
  `class` varchar(32) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `tbl_teacher`
--

INSERT INTO `tbl_teacher` (`NIP`, `homeroom_teacher`, `class`, `password`) VALUES
(10010, 'Iyang Agung Supriatna', 'staff', 'd033e22ae348aeb5660fc2140aec35850c4da997'),
(1920152001, 'Banni Satria Nugraha, S.Pd.', 'X-1', 'f136fffd5a2abfa12fb6cf8a46d81e9cba3aba63'),
(1920152002, 'Yanty Wina Sondari, S.Pd.', 'X-2', 'f0136dadf30202addd9569b43f7394b2431a4568'),
(1920152003, 'Hj. Euis Nanih, S.Sos.,M.SI.', 'X-3', 'acf1f964774a877a59fef3d6a5966870c8f34b21'),
(1920152004, 'Meri Siti Maryam, S.Pd.', 'X-4', '03aa309f3af1ed9e5fcbddc0dc9adc3c3ea83323'),
(1920152005, 'Etty Supartini, S.Pd.', 'X-5', '08ebdba88770bb0b12bff4cc3372a1880855bfa1'),
(1920152006, 'Octaviani Awalia Putri, S.Pd.', 'X-6', 'df08f18ab893a660e48c860c48c7d37df84945f1'),
(1920152007, 'Iis Nurdiah, S.Pd.', 'X-7', '99dc9d765a883b77bdc7ead9605a2dc567ca2098'),
(1920152008, 'Lena Ropsah Budiarti, S.IP.', 'X-8', 'c4540280e89b03803d9cb008e4166d4f183e1985'),
(1920152009, 'Yaya Sunarya, S.Pd.', 'X-9', '4bbd1ef8b913594f394f072caf86b9c110b693d6'),
(1920152010, 'Jajang Nurjaman, S.Pd.', 'X-10', '248c2393b8d5d8ec8718013d197bd2645348ba62'),
(1920152011, 'Aries Eka Wandiana, S.Pd ', 'XI-1', 'bc703f465642f74bd5156352c653fef10269ee9c'),
(1920152012, 'Yuyum Siti Rodiyah, S.Pd ', 'XI-2', 'd0d79e06ec59efe2870b3c38d86dfede7e21384d'),
(1920152013, 'Hj. Komala Rochmawati, S.Pd ', 'XI-3', '12db45fd8df0ceebcb1b1649434c2f081bceb5de'),
(1920152014, 'Dra. Etoy Suhayati', 'XI-4', 'f02d49890bab95bbca754bf787f85ebbaca7b9c4'),
(1920152015, 'Ratih Cahyani, S.Pd ', 'XI-5', 'c98d882e6b6afcbfa09ce29c2f7aa40e2299dcd4'),
(1920152016, 'Dra. Hj. Lilis Yuliawati', 'XI-6', '4fd160a8b89249518b3bd2aea61c435bccde303e'),
(1920152017, 'Yeni Mariani, S.Pd ', 'XI-7', 'b9a923b1327c09e000e426835432927c33d3c21b'),
(1920152018, 'Jajang Kuswandi, S.Pd ', 'XI-8', '2e827d2cb13f65b790b42c786ca7b585d8fbac86'),
(1920152019, 'Ana Ristiana, S.Pd ', 'XI-9', 'e0e1693718708d4d1a44e65cc2afb7f35b380e57'),
(1920152020, 'Dra. N Ecih Sukaesih', 'XI-10', '30cb4d311077c204e63dc7e161d7375583a43ba4'),
(1920152021, 'Erty Ristiaty Juendang, S.H.', 'XII-1', '0cc8b57eb4b483389d77b514a9ff80b25469aa04'),
(1920152022, 'Empong Rosita, S.Pd.', 'XII-2', '18ace52b7093173a0c7c7dcd403812d1260ba93a'),
(1920152023, 'Hj. Dedeh Kurniasih, S.Pd.', 'XII-3', '27fba5bc88b77b468f79622e62a051cfe1669861'),
(1920152024, 'Dian Henriana, S.Pd.', 'XII-4', '22f62110c33a20d980148fd1978bb85708d42e66'),
(1920152025, 'Euis Mulyananingsih, S.Pd.', 'XII-5', '2c30a0eae1af1536467f93d397b622dc11e26bcf'),
(1920152026, 'Noneng Siti Roswati, S.Pd.', 'XII-6', '5aacc911009b10bf3c5c2ac4bc1ad4294156d2ce'),
(1920152027, 'Rohayati, S.Pd.', 'XII-7', 'bd89430c98a7220e3d88d525b538c8600a676575'),
(1920152028, 'Dra. Euis Sriharyati', 'XII-8', '4fe991583d680ec093092137cca06087d61338db'),
(1920152029, 'Suci Lestari, S.Pd.', 'XII-9', '1e9f0377cc35dfd25ac62a3d2f5c705b87e4e946'),
(1920152030, 'Hj. Ety Suhaeti, S.Pd.', 'XII-10', '81ff6c56f0f33e5d1c977a20ca2485ddbf6407a1');

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_reportDutiful`
-- (See below for the actual view)
--
CREATE TABLE `v_reportDutiful` (
`date` date
,`NISS` int(11)
,`NISN` bigint(20)
,`student_name` varchar(40)
,`criteria_name` varchar(255)
,`weight` double
,`type` varchar(255)
,`reporter_teacher` varchar(29)
,`confirmation_teacher` varchar(29)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_reportStatistic`
-- (See below for the actual view)
--
CREATE TABLE `v_reportStatistic` (
`date` date
,`class` varchar(6)
,`weight` double
,`type` varchar(255)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_reportViolation`
-- (See below for the actual view)
--
CREATE TABLE `v_reportViolation` (
`date` date
,`NISS` int(11)
,`NISN` bigint(20)
,`student_name` varchar(40)
,`criteria_name` varchar(255)
,`weight` double
,`reporter_teacher` varchar(29)
,`confirmation_teacher` varchar(29)
);

-- --------------------------------------------------------

--
-- Structure for view `v_reportDutiful`
--
DROP TABLE IF EXISTS `v_reportDutiful`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_reportDutiful`  AS SELECT `report`.`date` AS `date`, `student`.`NISS` AS `NISS`, `student`.`NISN` AS `NISN`, `student`.`fullname` AS `student_name`, `criteria`.`name` AS `criteria_name`, `criteria`.`weight` AS `weight`, `report`.`type` AS `type`, `reporter`.`homeroom_teacher` AS `reporter_teacher`, `homeroom`.`homeroom_teacher` AS `confirmation_teacher` FROM (`tbl_teacher` `homeroom` left join (`tbl_teacher` `reporter` left join ((select `tbl_criteria`.`id` AS `id`,`tbl_criteria`.`name` AS `name`,`tbl_criteria`.`type` AS `type`,`tbl_criteria`.`weight` AS `weight` from `tbl_criteria` where `tbl_criteria`.`type` = 'dutiful') `criteria` left join (`tbl_student` `student` left join `tbl_reporting` `report` on(`report`.`NISS` = `student`.`NISS`)) on(`report`.`id_behavior` = `criteria`.`id`)) on(`report`.`id_reporter` = `reporter`.`NIP`)) on(`report`.`id_confirmation` = `homeroom`.`NIP`)) ;

-- --------------------------------------------------------

--
-- Structure for view `v_reportStatistic`
--
DROP TABLE IF EXISTS `v_reportStatistic`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_reportStatistic`  AS SELECT `report`.`date` AS `date`, `student`.`class` AS `class`, `criteria`.`weight` AS `weight`, `report`.`type` AS `type` FROM (((((select `tbl_reporting`.`id` AS `id`,`tbl_reporting`.`id_behavior` AS `id_behavior`,`tbl_reporting`.`type` AS `type`,`tbl_reporting`.`NISS` AS `NISS`,`tbl_reporting`.`id_reporter` AS `id_reporter`,`tbl_reporting`.`id_confirmation` AS `id_confirmation`,`tbl_reporting`.`message` AS `message`,`tbl_reporting`.`date` AS `date` from `tbl_reporting` where `tbl_reporting`.`type` <> 'tolerance') `report` join `tbl_student` `student` on(`report`.`NISS` = `student`.`NISS`)) join (select `tbl_criteria`.`id` AS `id`,`tbl_criteria`.`name` AS `name`,`tbl_criteria`.`type` AS `type`,`tbl_criteria`.`weight` AS `weight` from `tbl_criteria` where `tbl_criteria`.`type` <> 'tolerance') `criteria` on(`report`.`id_behavior` = `criteria`.`id`)) join `tbl_teacher` `reporter` on(`report`.`id_reporter` = `reporter`.`NIP`)) join `tbl_teacher` `homeroom` on(`report`.`id_confirmation` = `homeroom`.`NIP`)) ;

-- --------------------------------------------------------

--
-- Structure for view `v_reportViolation`
--
DROP TABLE IF EXISTS `v_reportViolation`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_reportViolation`  AS SELECT `report`.`date` AS `date`, `student`.`NISS` AS `NISS`, `student`.`NISN` AS `NISN`, `student`.`fullname` AS `student_name`, `criteria`.`name` AS `criteria_name`, `criteria`.`weight` AS `weight`, `reporter`.`homeroom_teacher` AS `reporter_teacher`, `homeroom`.`homeroom_teacher` AS `confirmation_teacher` FROM (((((select `tbl_reporting`.`id` AS `id`,`tbl_reporting`.`id_behavior` AS `id_behavior`,`tbl_reporting`.`type` AS `type`,`tbl_reporting`.`NISS` AS `NISS`,`tbl_reporting`.`id_reporter` AS `id_reporter`,`tbl_reporting`.`id_confirmation` AS `id_confirmation`,`tbl_reporting`.`date` AS `date` from `tbl_reporting` where `tbl_reporting`.`type` = 'violation') `report` join `tbl_student` `student` on(`report`.`NISS` = `student`.`NISS`)) join (select `tbl_criteria`.`id` AS `id`,`tbl_criteria`.`name` AS `name`,`tbl_criteria`.`type` AS `type`,`tbl_criteria`.`weight` AS `weight` from `tbl_criteria` where `tbl_criteria`.`type` = 'violation') `criteria` on(`report`.`id_behavior` = `criteria`.`id`)) join `tbl_teacher` `reporter` on(`report`.`id_reporter` = `reporter`.`NIP`)) join `tbl_teacher` `homeroom` on(`report`.`id_confirmation` = `homeroom`.`NIP`)) ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `tbl_configuration`
--
ALTER TABLE `tbl_configuration`
  ADD PRIMARY KEY (`variable`);

--
-- Indexes for table `tbl_criteria`
--
ALTER TABLE `tbl_criteria`
  ADD PRIMARY KEY (`id`),
  ADD KEY `Index` (`name`,`type`) USING BTREE;

--
-- Indexes for table `tbl_reporting`
--
ALTER TABLE `tbl_reporting`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_behavior` (`id_behavior`),
  ADD KEY `id_student` (`NISS`),
  ADD KEY `id_reporter` (`id_reporter`),
  ADD KEY `id_confirmation` (`id_confirmation`);

--
-- Indexes for table `tbl_student`
--
ALTER TABLE `tbl_student`
  ADD PRIMARY KEY (`NISS`),
  ADD KEY `class` (`class`);

--
-- Indexes for table `tbl_teacher`
--
ALTER TABLE `tbl_teacher`
  ADD PRIMARY KEY (`NIP`),
  ADD KEY `class` (`class`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
