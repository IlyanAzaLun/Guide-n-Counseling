-- phpMyAdmin SQL Dump
-- version 5.1.0
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Sep 28, 2021 at 05:04 AM
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_reportPivot2` (IN `tbl_name` VARCHAR(255))  SQL SECURITY INVOKER
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
        ',SUM(weight) AS Total,
        max(date) AS date
    FROM ',tbl_name,' 
    GROUP BY student_name 
    WITH ROLLUP');
-- SELECT @stmt2;                       -- The statement that generates the result
PREPARE _sql FROM @stmt2;
EXECUTE _sql;                           -- The resulting pivot table ouput
DEALLOCATE PREPARE _sql;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_reportPivot3` (IN `tbl_name` VARCHAR(255))  SQL SECURITY INVOKER
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
        student_name,
        counseling,',
        @sums,
        ',SUM(weight) AS Total,
        max(date) AS date
    FROM ',tbl_name,'
    GROUP BY student_name 
    WITH ROLLUP');
-- SELECT @stmt2;                         -- The statement that generates the result
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
  `date` date NOT NULL,
  `status` tinyint(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `tbl_reporting`
--

INSERT INTO `tbl_reporting` (`id`, `id_behavior`, `type`, `NISS`, `id_reporter`, `id_confirmation`, `message`, `date`, `status`) VALUES
('0e32bbda-1d41-11ec-a452-f0c1f382afe6', '4b984c7c-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '18112016', '10010', '1920152001', 'Melaporkan membantu tindakan iyang', '2021-09-24', 0),
('2a79a225-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '18112015', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2a7f0571-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '18112016', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2a840f03-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '18112017', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2a8e2fee-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '58989595', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2a99fe1d-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '52918798', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2aaadb47-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '52309950', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2abf1438-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '42963308', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2ac5d1b1-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '58197270', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2acc904b-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '44950272', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2ad34c09-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '49378117', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2ada0cf2-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '51075198', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2ae0ccce-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '44091572', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2ae78ceb-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '51073648', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2aee4a04-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '51074244', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2af51279-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '56589435', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2b078913-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '44994842', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2b0e49bc-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '51075322', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2b150861-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '48725057', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2b1bc441-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '51074960', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2b228526-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '51074856', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2b294499-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '51074865', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2b2ffdbf-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '45473782', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2b38a0f7-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '44954550', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2b3db0d9-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '44994212', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2b55531f-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '41102027', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2b67de90-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '41028890', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2b8110fe-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '48111058', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2b8622c1-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '51075193', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2b8b3284-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '51074855', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2b90452b-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '56440467', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2b95552b-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '57266631', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2b9a6b32-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '51012959', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2b9f759c-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '44954178', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2ba4862f-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '44995459', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2ba995b4-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '51759574', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2baea5e9-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '51074861', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2bb3b44c-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '42622556', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2bb8c4f2-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '48259469', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2bbdd2fe-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '46198072', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2bc2e64b-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '43905468', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2bc7f9f7-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '46844479', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2bcd089c-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '57679370', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2bd21819-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '44994071', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2bd726d4-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '44995677', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2bdc3860-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '51722258', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2be14ab2-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '63808870', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2beebf09-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '48208655', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2bf5808b-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '53279511', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2bfd07b4-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '44994858', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2c080f33-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '45590151', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2c107fbe-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '43685631', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2c159065-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '48348336', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2c1a9f28-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '44994846', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2c215e07-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '51074234', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2c281c5f-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '51533580', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2c2ed827-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '51074436', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2c3596fd-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '59716985', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('2c3c501d-1c4d-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '52399341', '10010', '1920152001', 'Tidak pakai atribut saat hari kamis', '2021-09-23', 0),
('3017f091-1c4e-11ec-9ed7-5cac4cba0f32', 'a7fc2ccf-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '57266631', '10010', '1920152008', 'Tidak masuk kelas, dan tidak mengikuti pelajaran, pada hari rabu', '2021-09-22', 0),
('301d9934-1c4e-11ec-9ed7-5cac4cba0f32', 'a7fc2ccf-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '51012959', '10010', '1920152008', 'Tidak masuk kelas, dan tidak mengikuti pelajaran, pada hari rabu', '2021-09-22', 0),
('3022ab19-1c4e-11ec-9ed7-5cac4cba0f32', 'a7fc2ccf-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '44954178', '10010', '1920152008', 'Tidak masuk kelas, dan tidak mengikuti pelajaran, pada hari rabu', '2021-09-22', 0),
('3027bdd8-1c4e-11ec-9ed7-5cac4cba0f32', 'a7fc2ccf-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '44995459', '10010', '1920152008', 'Tidak masuk kelas, dan tidak mengikuti pelajaran, pada hari rabu', '2021-09-22', 0),
('302ccba6-1c4e-11ec-9ed7-5cac4cba0f32', 'a7fc2ccf-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '51759574', '10010', '1920152008', 'Tidak masuk kelas, dan tidak mengikuti pelajaran, pada hari rabu', '2021-09-22', 0),
('3031d408-1c4e-11ec-9ed7-5cac4cba0f32', 'a7fc2ccf-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '51075120', '10010', '1920152008', 'Tidak masuk kelas, dan tidak mengikuti pelajaran, pada hari rabu', '2021-09-22', 0),
('3036e69b-1c4e-11ec-9ed7-5cac4cba0f32', 'a7fc2ccf-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '51074971', '10010', '1920152008', 'Tidak masuk kelas, dan tidak mengikuti pelajaran, pada hari rabu', '2021-09-22', 0),
('303dacb7-1c4e-11ec-9ed7-5cac4cba0f32', 'a7fc2ccf-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '54284779', '10010', '1920152008', 'Tidak masuk kelas, dan tidak mengikuti pelajaran, pada hari rabu', '2021-09-22', 0),
('30446559-1c4e-11ec-9ed7-5cac4cba0f32', 'a7fc2ccf-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '57679370', '10010', '1920152008', 'Tidak masuk kelas, dan tidak mengikuti pelajaran, pada hari rabu', '2021-09-22', 0),
('3051dcf5-1c4e-11ec-9ed7-5cac4cba0f32', 'a7fc2ccf-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '44994071', '10010', '1920152008', 'Tidak masuk kelas, dan tidak mengikuti pelajaran, pada hari rabu', '2021-09-22', 0),
('305f62cd-1c4e-11ec-9ed7-5cac4cba0f32', 'a7fc2ccf-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '44995677', '10010', '1920152008', 'Tidak masuk kelas, dan tidak mengikuti pelajaran, pada hari rabu', '2021-09-22', 0),
('3066214f-1c4e-11ec-9ed7-5cac4cba0f32', 'a7fc2ccf-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '51722258', '10010', '1920152008', 'Tidak masuk kelas, dan tidak mengikuti pelajaran, pada hari rabu', '2021-09-22', 0),
('306ee4eb-1c4e-11ec-9ed7-5cac4cba0f32', 'a7fc2ccf-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '63808870', '10010', '1920152008', 'Tidak masuk kelas, dan tidak mengikuti pelajaran, pada hari rabu', '2021-09-22', 0),
('3087d3a5-1c4e-11ec-9ed7-5cac4cba0f32', 'a7fc2ccf-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '53954055', '10010', '1920152008', 'Tidak masuk kelas, dan tidak mengikuti pelajaran, pada hari rabu', '2021-09-22', 0),
('309db9c0-1c4e-11ec-9ed7-5cac4cba0f32', 'a7fc2ccf-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '51074256', '10010', '1920152008', 'Tidak masuk kelas, dan tidak mengikuti pelajaran, pada hari rabu', '2021-09-22', 0),
('30a477c8-1c4e-11ec-9ed7-5cac4cba0f32', 'a7fc2ccf-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '51098558', '10010', '1920152008', 'Tidak masuk kelas, dan tidak mengikuti pelajaran, pada hari rabu', '2021-09-22', 0),
('30ab32b6-1c4e-11ec-9ed7-5cac4cba0f32', 'a7fc2ccf-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '3059348632', '10010', '1920152008', 'Tidak masuk kelas, dan tidak mengikuti pelajaran, pada hari rabu', '2021-09-22', 0),
('30b1f281-1c4e-11ec-9ed7-5cac4cba0f32', 'a80135b2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '57266631', '10010', '1920152008', 'Tidak masuk kelas, dan tidak mengikuti pelajaran, pada hari rabu', '2021-09-22', 0),
('30b8af54-1c4e-11ec-9ed7-5cac4cba0f32', 'a80135b2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '51012959', '10010', '1920152008', 'Tidak masuk kelas, dan tidak mengikuti pelajaran, pada hari rabu', '2021-09-22', 0),
('30bf6c11-1c4e-11ec-9ed7-5cac4cba0f32', 'a80135b2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '44954178', '10010', '1920152008', 'Tidak masuk kelas, dan tidak mengikuti pelajaran, pada hari rabu', '2021-09-22', 0),
('30c62d3e-1c4e-11ec-9ed7-5cac4cba0f32', 'a80135b2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '44995459', '10010', '1920152008', 'Tidak masuk kelas, dan tidak mengikuti pelajaran, pada hari rabu', '2021-09-22', 0),
('30cce8db-1c4e-11ec-9ed7-5cac4cba0f32', 'a80135b2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '51759574', '10010', '1920152008', 'Tidak masuk kelas, dan tidak mengikuti pelajaran, pada hari rabu', '2021-09-22', 0),
('30d3a750-1c4e-11ec-9ed7-5cac4cba0f32', 'a80135b2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '51075120', '10010', '1920152008', 'Tidak masuk kelas, dan tidak mengikuti pelajaran, pada hari rabu', '2021-09-22', 0),
('30da65aa-1c4e-11ec-9ed7-5cac4cba0f32', 'a80135b2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '51074971', '10010', '1920152008', 'Tidak masuk kelas, dan tidak mengikuti pelajaran, pada hari rabu', '2021-09-22', 0),
('30e12a4a-1c4e-11ec-9ed7-5cac4cba0f32', 'a80135b2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '54284779', '10010', '1920152008', 'Tidak masuk kelas, dan tidak mengikuti pelajaran, pada hari rabu', '2021-09-22', 0),
('30e7df3d-1c4e-11ec-9ed7-5cac4cba0f32', 'a80135b2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '57679370', '10010', '1920152008', 'Tidak masuk kelas, dan tidak mengikuti pelajaran, pada hari rabu', '2021-09-22', 0),
('30eea0b1-1c4e-11ec-9ed7-5cac4cba0f32', 'a80135b2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '44994071', '10010', '1920152008', 'Tidak masuk kelas, dan tidak mengikuti pelajaran, pada hari rabu', '2021-09-22', 0),
('30f561e4-1c4e-11ec-9ed7-5cac4cba0f32', 'a80135b2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '44995677', '10010', '1920152008', 'Tidak masuk kelas, dan tidak mengikuti pelajaran, pada hari rabu', '2021-09-22', 0),
('30fc1ac2-1c4e-11ec-9ed7-5cac4cba0f32', 'a80135b2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '51722258', '10010', '1920152008', 'Tidak masuk kelas, dan tidak mengikuti pelajaran, pada hari rabu', '2021-09-22', 0),
('3102da1f-1c4e-11ec-9ed7-5cac4cba0f32', 'a80135b2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '63808870', '10010', '1920152008', 'Tidak masuk kelas, dan tidak mengikuti pelajaran, pada hari rabu', '2021-09-22', 0),
('31099c79-1c4e-11ec-9ed7-5cac4cba0f32', 'a80135b2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '53954055', '10010', '1920152008', 'Tidak masuk kelas, dan tidak mengikuti pelajaran, pada hari rabu', '2021-09-22', 0),
('310ea7d2-1c4e-11ec-9ed7-5cac4cba0f32', 'a80135b2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '51074256', '10010', '1920152008', 'Tidak masuk kelas, dan tidak mengikuti pelajaran, pada hari rabu', '2021-09-22', 0),
('3113bba2-1c4e-11ec-9ed7-5cac4cba0f32', 'a80135b2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '51098558', '10010', '1920152008', 'Tidak masuk kelas, dan tidak mengikuti pelajaran, pada hari rabu', '2021-09-22', 0),
('3124971f-1c4e-11ec-9ed7-5cac4cba0f32', 'a80135b2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '3059348632', '10010', '1920152008', 'Tidak masuk kelas, dan tidak mengikuti pelajaran, pada hari rabu', '2021-09-22', 0),
('44ecc38b-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '1920', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('44f240d4-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '18112015', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('44fac33a-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '18112016', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('44ffcfa2-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '18112017', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('4504e39e-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '58989595', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('4509f021-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '52918798', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('450efeb9-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '58197270', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('4515bd9f-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '44950272', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('451c7e94-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '49378117', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('4523389f-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '51075198', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('4529fbfe-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '44091572', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('4535d444-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '44994842', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('453ccc6d-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '51075322', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('454a4987-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '48725057', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('4557cf3e-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '51074960', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('455e876c-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '51074856', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('4566f774-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '51074865', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('45812018-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '45473782', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('458d3cef-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '41102027', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('459e9534-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '41028890', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('45aa66f4-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '48111058', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('45af7a22-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '51075193', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('45b48afc-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '51074855', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('45b99a6f-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '57266631', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('45bea67d-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '51012959', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('45c3bc27-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '44954178', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('45c8cc4c-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '44995459', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('45cdd6f4-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '51759574', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('45d2eaed-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '51073345', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('45d7f9ea-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '51074861', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('45dd0b4a-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '42622556', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('45e21cf8-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '48259469', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('45e73152-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '46198072', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('45ec41b1-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '43905468', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('45f151f2-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '57679370', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('45f654aa-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '44994071', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('45fed7c5-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '44995677', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('4603e6a6-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '51722258', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('4608f5b9-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '63808870', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('460e04d5-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '53954055', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('46182b40-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '48208655', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('461d3d7e-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '53279511', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('462409da-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '44994858', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('462f4d3a-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '45590151', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('46517b60-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '43685631', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('46583c81-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '48348336', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('465efafa-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '44994846', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('4665b436-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '51074234', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('466c7953-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '51533580', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('46733747-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '51074436', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('4679ed92-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '40692918', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('4680aaa8-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '41578341', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('468771eb-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '40693836', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('468e2957-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '41431145', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('4694ed40-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '40796586', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('469ba500-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '45373307', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('46a26850-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '39997363', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('46a927a2-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '35033478', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('46afec18-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '45485401', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('46bf3d99-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '40693096', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('46c600b5-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '35033472', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('46ccc4a1-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '35033189', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('46d1d612-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '35033595', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('46f02c72-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '41412851', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('46fbf2a0-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '44934460', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('47010150-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '35033103', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('47061315-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '29944443', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('470b2026-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '42274312', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('47103127-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '35056693', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('471542ed-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '40693519', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('471a4ec6-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '38750567', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('471f6222-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '41339435', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('4724726a-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '11064466', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('472987b7-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '43314597', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('472e91f8-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '40694974', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('4733a23f-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '37053661', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('4738b335-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '40732244', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('473dc348-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '41414047', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('4742d560-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '43742885', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('4747e2c5-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '35033657', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('474cf287-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '9443702', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('47520429-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '43411395', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('475c298d-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '48735868', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('4761335b-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '44213062', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('47664ac6-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '40694733', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('476b5482-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '33503885', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('47706446-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '40694184', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('477572e1-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '44995751', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('477a873c-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '47856382', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('477f9bba-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '37748267', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('4784a689-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '48229624', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('4789b920-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '43373809', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('479c4a5e-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '30851235', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('47b3e355-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '25416225', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('47e3035b-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '30534104', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('4818e597-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '24696949', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('482b6ef8-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '30434629', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('483594f1-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '30693127', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('483c51ff-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '24392092', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('484312bc-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '30692871', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('4849cc73-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '33233216', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('48508f8b-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '28310342', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('48592dee-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '31739525', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('485e3da8-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '24697579', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('48634e77-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '30851320', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('48685c05-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '30434980', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('4870d5c9-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '30850830', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('4875e402-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '32091890', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('487af488-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '32338762', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('4880059c-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '26456826', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('48851612-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '38978737', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('488a2639-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '30434422', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('488f3e68-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '30910200', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('48944a07-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '34061289', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('48995414-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '28310262', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('489e63f7-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '31684338', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('48a3793e-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '30851242', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('48a8851c-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '24578921', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('48ad957d-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '30534336', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('48b2a400-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '28648280', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('48b7b622-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '35411003', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('48bcc5fb-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '22868673', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('48c1d84d-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '30434784', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('48cbf8e7-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '30434621', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('48d10866-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '30434390', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('48d6197f-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '35155355', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('48de92e8-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '30434397', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('48ef80b0-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '30434638', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('4906deb8-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '30434954', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('49149de3-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '24697344', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('491d123a-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '24391739', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('4923cdc2-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '30658757', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('492a8b2d-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '24391725', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('49314be8-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '30434741', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('49380c47-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '36538888', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('493ec8b2-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '24697268', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('4945871c-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '30434388', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('494c4299-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '24697574', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('49530d52-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '24391779', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('4959c09e-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '24578918', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('49608106-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '30850986', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('496dfd14-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '31634309', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('4974ba66-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '24391623', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('497b7c56-1c4f-11ec-9ed7-5cac4cba0f32', '4b882221-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '28568388', '10010', '1920152001', 'menjaga lingkungan sekolah bersama', '2021-09-23', 0),
('78dadfad-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '40692918', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('78e07bf3-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '41578341', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('78e58dc0-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '40693836', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('78ea9f45-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '41431145', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('78efac00-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '40694201', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('78f4c186-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '40796586', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('78f9cf3a-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '45373307', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('78fee2f6-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '39997363', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('7903ed88-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '35033478', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('790904d3-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '32542763', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('790e11c2-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '45485401', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('7915f7a8-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '0', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('792abc3e-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '40693096', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('7942603c-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '44561435', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('79477918-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '40970874', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('794c828a-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '30434622', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('795193a3-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '35033472', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('7956a4a2-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '35033189', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('795bb159-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '35033595', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('7960bea0-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '41412851', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('7965d082-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '44934460', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('796b158c-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '50317724', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('7970235b-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '35033103', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('7976eb06-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '29944443', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('797da3f2-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '42274312', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('79845d79-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '35056693', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('798b2082-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '49721127', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('799386e4-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '37836074', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('799bf669-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '40693519', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('79a46228-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '38750567', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('79accf6b-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '41339435', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('79b1df16-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '11064466', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0);
INSERT INTO `tbl_reporting` (`id`, `id_behavior`, `type`, `NISS`, `id_reporter`, `id_confirmation`, `message`, `date`, `status`) VALUES
('79b6eccb-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '40694974', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('79bbfdc9-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '37053661', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('79c61d3d-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '40732244', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('79ccdb9a-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '41414047', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('79d39964-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '43742885', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('79da58f1-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '40694264', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('79e48264-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '35033657', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('79eb4255-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '9443702', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('79f1fda9-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '43411395', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('79f8bc5e-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '48735868', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('79ff7697-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '44213062', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('7a063164-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '40694733', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('7a0cf08c-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '33503885', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('7a13ad89-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '40694184', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('7a1a6e79-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '44995751', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('7a212cbc-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '47856382', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('7a27ef35-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '37748267', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('7a2eae52-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '48229624', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('7a356a0c-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '43373809', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('7a3c2537-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '35033195', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('7a42e39d-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '35216683', '10010', '1920152012', 'Membuang sampah sembarangan', '2021-09-23', 0),
('a01ad2a9-1c4f-11ec-9ed7-5cac4cba0f32', '4b984c7c-81b9-11eb-851a-bca60c4b53c0', 'dutiful', '18112015', '10010', '1920152001', 'melaporakan pelanggaran', '2021-09-23', 0),
('b4c804fe-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '1920', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b4ce23b9-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '30851235', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b4d4e557-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '25416225', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b4d9f276-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '30534104', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b4defd24-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '24696949', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b4e413e6-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '30434629', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b4e92602-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '30693127', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b4ee3228-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '24392092', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b4f346d1-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '30692871', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b4f8512f-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '33233216', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b4fd5e8f-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '28310342', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b5026aac-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '24697579', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b50a0ae5-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '30851320', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b51d6d12-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '30434980', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b52ff934-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '30850830', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b5350af3-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '28310210', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b53a15ca-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '32091890', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b53f298a-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '32338762', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b5443227-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '26456826', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b54e54cb-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '38978737', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b5587a14-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '26457010', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b55d866f-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '30434422', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b5629a2c-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '30910200', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b567a980-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '34061289', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b56cbacc-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '28310262', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b571cdd0-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '31684338', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b578c39b-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '30851242', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b57dd3ad-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '24578921', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b582e029-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '30534336', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b5899f4a-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '28648280', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b5905fb1-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '35411003', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b5971cc2-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '22868673', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b59dd89f-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '30434784', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b5a497f7-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '30434621', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b5ab5444-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '30434390', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b5b3c1f8-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '35155355', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b5da78c2-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '30434397', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b5e1396d-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '30434638', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b5e7f87e-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '30434954', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b5eeb783-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '24697344', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b5f5762d-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '24391739', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b5fc3454-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '30658757', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b602f245-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '30434741', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b609b317-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '36538888', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b610718c-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '24697268', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b6172ef3-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '30434388', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b61deb55-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '24697574', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b624a81c-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '24391779', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b62b6599-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '24578918', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b6322461-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '30850986', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b638e3dd-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '31634309', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b63fa144-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '24391623', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('b64666e5-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '28568388', '10010', '1920152030', 'siswa yang tidak sopan', '2021-09-24', 0),
('d7125757-1c4e-11ec-9ed7-5cac4cba0f32', 'a7f1ea88-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '18112015', '10010', '1920152001', 'Paket komplit', '2021-09-23', 0),
('d718e283-1c4e-11ec-9ed7-5cac4cba0f32', 'a7f725f2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '18112015', '10010', '1920152001', 'Paket komplit', '2021-09-23', 0),
('d71fa006-1c4e-11ec-9ed7-5cac4cba0f32', 'a7fc2ccf-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '18112015', '10010', '1920152001', 'Paket komplit', '2021-09-23', 0),
('d7265b5b-1c4e-11ec-9ed7-5cac4cba0f32', 'a80135b2-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '18112015', '10010', '1920152001', 'Paket komplit', '2021-09-23', 0),
('d72d1a87-1c4e-11ec-9ed7-5cac4cba0f32', 'a80b54f5-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '18112015', '10010', '1920152001', 'Paket komplit', '2021-09-23', 0),
('d733dded-1c4e-11ec-9ed7-5cac4cba0f32', 'a8157bf1-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '18112015', '10010', '1920152001', 'Paket komplit', '2021-09-23', 0),
('d73a9650-1c4e-11ec-9ed7-5cac4cba0f32', 'a81a8a04-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '18112015', '10010', '1920152001', 'Paket komplit', '2021-09-23', 0),
('d744c14b-1c4e-11ec-9ed7-5cac4cba0f32', 'a81f9b94-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '18112015', '10010', '1920152001', 'Paket komplit', '2021-09-23', 0),
('d74b7b05-1c4e-11ec-9ed7-5cac4cba0f32', 'a824ab0b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '18112015', '10010', '1920152001', 'Paket komplit', '2021-09-23', 0),
('d75237d9-1c4e-11ec-9ed7-5cac4cba0f32', 'a829bb9e-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '18112015', '10010', '1920152001', 'Paket komplit', '2021-09-23', 0),
('d758f876-1c4e-11ec-9ed7-5cac4cba0f32', 'a82eca78-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '18112015', '10010', '1920152001', 'Paket komplit', '2021-09-23', 0),
('d75fb965-1c4e-11ec-9ed7-5cac4cba0f32', 'a833e07b-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '18112015', '10010', '1920152001', 'Paket komplit', '2021-09-23', 0),
('f3f0b083-1d3f-11ec-a452-f0c1f382afe6', 'a7fc2ccf-a43d-11eb-84ab-4d58cf0ac0a8', 'violation', '18112015', '10010', '1920152001', 'Tidak masuk kelas', '2021-09-24', 0);

-- --------------------------------------------------------

--
-- Table structure for table `tbl_student`
--

CREATE TABLE `tbl_student` (
  `NISS` bigint(20) DEFAULT NULL,
  `NISN` bigint(20) DEFAULT NULL,
  `fullname` varchar(40) DEFAULT NULL,
  `gender` varchar(1) DEFAULT NULL,
  `class` varchar(6) DEFAULT NULL,
  `photo` varchar(255) DEFAULT NULL,
  `status` tinyint(1) NOT NULL DEFAULT 1,
  `counseling` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `tbl_student`
--

INSERT INTO `tbl_student` (`NISS`, `NISN`, `fullname`, `gender`, `class`, `photo`, `status`, `counseling`) VALUES
(1920, 30434321, 'NUR AULIA', 'P', 'XII-3', '', 1, 0),
(18112015, 18112015, 'IYANG AGUNG SUPRIATNA', 'L', 'X-1', '/_assets/photos/student-1632388185.jpg', 1, 3),
(18112016, 18112016, 'NANDA AGUSTINA RAHAYU', 'P', 'X-1', '/_assets/photos/student-1631417392.png', 0, 0),
(18112017, 18112017, 'AGUS NUFATUROHMAN', 'L', 'X-1', '', 1, 0),
(58989595, 202110001, 'ADAM MALIK MAULANA', 'L', 'X-1', NULL, 1, 0),
(52918798, 202110002, 'ADITYA NURDIANSYAH HELSHINKY', 'L', 'X-1', NULL, 1, 0),
(52309950, 202110003, 'ALPHINO PRADIFTA NUGRAHA', 'L', 'X-1', NULL, 1, 0),
(42963308, 202110004, 'ANDI MUHAMMAD ULYA FITROH', 'L', 'X-1', NULL, 1, 0),
(51073281, 202110005, 'ASTRI APRILLIA MULYANI', 'P', 'X-1', NULL, 1, 0),
(48620776, 202110006, 'BALDY MALLIKA', 'P', 'X-1', NULL, 1, 0),
(44994857, 202110007, 'CLARIZA ARDHIA GARIANI', 'P', 'X-1', NULL, 1, 0),
(44995706, 202110008, 'DESTI NUR FADILILLAH', 'P', 'X-1', NULL, 1, 0),
(51075206, 202110009, 'EKA SITI MULYANI', 'P', 'X-1', NULL, 1, 0),
(44249846, 202110010, 'EVITHA DWI RAHAYU', 'P', 'X-1', NULL, 1, 0),
(58989595, 202110001, 'ADAM MALIK MAULANA', 'L', 'X-1', NULL, 1, 0),
(52918798, 202110002, 'ADITYA NURDIANSYAH HELSHINKY', 'L', 'X-1', NULL, 1, 0),
(52309950, 202110003, 'ALPHINO PRADIFTA NUGRAHA', 'L', 'X-1', NULL, 1, 0),
(42963308, 202110004, 'ANDI MUHAMMAD ULYA FITROH', 'L', 'X-1', NULL, 1, 0),
(51073281, 202110005, 'ASTRI APRILLIA MULYANI', 'P', 'X-1', NULL, 1, 0),
(48620776, 202110006, 'BALDY MALLIKA', 'P', 'X-1', NULL, 1, 0),
(44994857, 202110007, 'CLARIZA ARDHIA GARIANI', 'P', 'X-1', NULL, 1, 0),
(44995706, 202110008, 'DESTI NUR FADILILLAH', 'P', 'X-1', NULL, 1, 0),
(51075206, 202110009, 'EKA SITI MULYANI', 'P', 'X-1', NULL, 1, 0),
(44249846, 202110010, 'EVITHA DWI RAHAYU', 'P', 'X-1', NULL, 1, 0),
(3049277376, 202110011, 'FANNY AGUSTINA FITRIYANI', 'P', 'X-1', NULL, 1, 0),
(51015804, 202110012, 'FAWWAZ HILMI AULIA', 'L', 'X-1', NULL, 1, 0),
(46010204, 202110013, 'GHEA AYSKA NABILA', 'P', 'X-1', NULL, 1, 0),
(51074238, 202110014, 'HABIBULLAH SIDDIQ PERMANA', 'L', 'X-1', NULL, 1, 0),
(44994843, 202110015, 'IHZAN DWI SATRIA', 'L', 'X-1', NULL, 1, 0),
(55496105, 202110016, 'IMELDA NUR FADILLAH', 'P', 'X-1', NULL, 1, 0),
(44994068, 202110017, 'IQBAL AZHAR FIRMANSYAH', 'L', 'X-1', NULL, 1, 0),
(3051135155, 202110018, 'KAKA KOMARA SETIADI', 'P', 'X-1', NULL, 1, 0),
(53870759, 202110019, 'KAYLA IFFANA MELIA PUTRI', 'P', 'X-1', NULL, 1, 0),
(3058424984, 202110020, 'LINDA MAULIDAH', 'P', 'X-1', NULL, 1, 0),
(51074746, 202110021, 'M. RIFKY ALFARITSY', 'L', 'X-1', NULL, 1, 0),
(3046855487, 202110022, 'MIEFTAH NITHANNIA HANA', 'P', 'X-1', NULL, 1, 0),
(58370365, 202110023, 'MUHAMAD FAHRUL HENDRAWAN', 'L', 'X-1', NULL, 1, 0),
(48390444, 202110024, 'MUHAMMAD HUSAIN FAUZAN', 'L', 'X-1', NULL, 1, 0),
(54898578, 202110025, 'NENENG TASYA SRI NADIRA', 'P', 'X-1', NULL, 1, 0),
(51073501, 202110026, 'NURMALA MUSTOPA', 'P', 'X-1', NULL, 1, 0),
(54272219, 202110027, 'RAISSA FEBRIANA DAMAYANTI', 'P', 'X-1', NULL, 1, 0),
(51074263, 202110028, 'REGITA AYU REVALINA SIRINGO RINGO', 'P', 'X-1', NULL, 1, 0),
(54893324, 202110029, 'SAGITA JASMINE HEDIYANTI ZALEHA', 'P', 'X-1', NULL, 1, 0),
(59613753, 202110030, 'SALSABILA MAHARANI', 'P', 'X-1', NULL, 1, 0),
(56622987, 202110031, 'SILMI KHOIRUN NAFISA', 'P', 'X-1', NULL, 1, 0),
(56948949, 202110032, 'SRI DHINI FEBRIANI', 'P', 'X-1', NULL, 1, 0),
(44774498, 202110033, 'TIARA LESTARI', 'P', 'X-1', NULL, 1, 0),
(3044776612, 202110034, 'WILANDIANA VELA', 'L', 'X-1', NULL, 1, 0),
(46075216, 202110035, 'ZCINTIA FITRI KHOERUN NISAA', 'P', 'X-1', NULL, 1, 0),
(58197270, 202110036, 'ADHISTI RESTI GAYANTRI NURAHMAN', 'P', 'X-2', NULL, 1, 0),
(44950272, 202110037, 'AGNI ANDRIANI', 'P', 'X-2', NULL, 1, 0),
(49378117, 202110038, 'AMELIA OKTAVIANI', 'P', 'X-2', NULL, 1, 0),
(51075198, 202110039, 'ANDINI MEYLANI NURWULAN', 'P', 'X-2', NULL, 1, 0),
(44091572, 202110040, 'AYESSA F J GUNDARA', 'P', 'X-2', NULL, 1, 0),
(51073648, 202110041, 'BAYU DARMAWAN', 'L', 'X-2', NULL, 1, 0),
(51074244, 202110042, 'DANI AFRILIAN MAULUDDIN', 'L', 'X-2', NULL, 1, 0),
(56589435, 202110043, 'DEVINA SALSABILLA', 'P', 'X-2', NULL, 1, 0),
(59547598, 202110044, 'ELNA KURAENI', 'p', 'X-2', NULL, 1, 0),
(44950350, 202110045, 'FADILATUL MAULA', 'P', 'X-2', NULL, 1, 0),
(42273728, 202110046, 'FARRELL KHAYRU KUMARAHARDI', 'L', 'X-2', NULL, 1, 0),
(43923441, 202110047, 'FIKRI NOVIANSYAH', 'L', 'X-2', NULL, 1, 0),
(3048454297, 202110048, 'GHEFIRA SONIYA ANANTA', 'P', 'X-2', NULL, 1, 0),
(42066058, 202110049, 'HAFIDZ MUHAMMAD NUGRAHA', 'L', 'X-2', NULL, 1, 0),
(44062693, 202110050, 'IKA PRASAUMA', 'P', 'X-2', NULL, 1, 0),
(44994835, 202110051, 'INTAN AWALLIA', 'P', 'X-2', NULL, 1, 0),
(52138543, 202110052, 'ISNI AMALLYA RAHMATTIKA', 'P', 'X-2', NULL, 1, 0),
(45295032, 202110053, 'KAMELIA DEWI', 'P', 'X-2', NULL, 1, 0),
(44993939, 202110054, 'KHAIRUNNISA', 'P', 'X-2', NULL, 1, 0),
(47965765, 202110055, 'LUFIANA KURNIA', 'L', 'X-2', NULL, 1, 0),
(55828621, 202110056, 'MAULIDA SALSABILA', 'P', 'X-2', NULL, 1, 0),
(43989244, 202110057, 'MISHA ARYANTI', 'P', 'X-2', NULL, 1, 0),
(51073430, 202110058, 'MUHAMAD FARHAN ARFARIZKY', 'L', 'X-2', NULL, 1, 0),
(3045126280, 202110059, 'NADILLAH NUR SABRINA', 'P', 'X-2', NULL, 1, 0),
(57218530, 202110060, 'NISSA AMELIA', 'P', 'X-2', NULL, 1, 0),
(44950273, 202110061, 'PUTRI ALIVIA NURHABIBAH', 'P', 'X-2', NULL, 1, 0),
(51953908, 202110062, 'RAKA AHMAD FAUZI PUTRA', 'L', 'X-2', NULL, 1, 0),
(51074252, 202110063, 'RIKA MEILAWATI', 'P', 'X-2', NULL, 1, 0),
(52052902, 202110064, 'SAHIRA NURGUSTINI SALSABILA', 'P', 'X-2', NULL, 1, 0),
(56925805, 202110065, 'SALVA FAKHIRA', 'P', 'X-2', NULL, 1, 0),
(55693517, 202110066, 'SINDI NUR\'AZIZAH', 'P', 'X-2', NULL, 1, 0),
(51073769, 202110067, 'SRI WULAN APRILIA', 'P', 'X-2', NULL, 1, 0),
(33103551, 202110068, 'TIARA RENATA SEPTINI', 'P', 'X-2', NULL, 1, 0),
(54574399, 202110069, 'YELLY AMBARWATI', 'P', 'X-2', NULL, 1, 0),
(44994842, 202110070, 'ADI SAPUTRA SIHOMBING', 'L', 'X-3', NULL, 1, 0),
(51075322, 202110071, 'AGNIA FITRI LESTARI', 'P', 'X-3', NULL, 1, 0),
(48725057, 202110072, 'AMELIA PUTRI GUNAWAN', 'P', 'X-3', NULL, 1, 0),
(51074960, 202110073, 'ANGGITA ERIKA PUTRI SUSANTO', 'P', 'X-3', NULL, 1, 0),
(51074856, 202110074, 'AZHAR RIZQILLAH FAUZY', 'L', 'X-3', NULL, 1, 0),
(51074865, 202110075, 'BRESYA NUR SALSABILA SUPRIADI', 'P', 'X-3', NULL, 1, 0),
(45473782, 202110076, 'DARA NOVIANTICA', 'P', 'X-3', NULL, 1, 0),
(44954550, 202110077, 'DIAN NURLELA', 'P', 'X-3', NULL, 1, 0),
(44994212, 202110078, 'ELSA DELIA FITRI', 'P', 'X-3', NULL, 1, 0),
(51074697, 202110079, 'FAHRYAN JUNAEDI', 'L', 'X-3', NULL, 1, 0),
(51073646, 202110080, 'FAULINAWATI RAHMAWIGUNA', 'P', 'X-3', NULL, 1, 0),
(51074839, 202110081, 'GEMA SUKMA IBRAHIM', 'L', 'X-3', NULL, 1, 0),
(46016954, 202110082, 'GILANG SANGGA RAMADHAN', 'L', 'X-3', NULL, 1, 0),
(48694602, 202110083, 'HAWWA ULLA GHALIYAH', 'P', 'X-3', NULL, 1, 0),
(51073510, 202110084, 'ILHAM MAULANA', 'L', 'X-3', NULL, 1, 0),
(56342826, 202110085, 'INTAN FUJI ANDINI', 'P', 'X-3', NULL, 1, 0),
(44128325, 202110086, 'IVAN FATHURROHMAN', 'L', 'X-3', NULL, 1, 0),
(45082944, 202110087, 'KAMILA NURFAJRINA', 'P', 'X-3', NULL, 1, 0),
(49992379, 202110088, 'KHAITSA ZAHIRA AGUSTINA', 'P', 'X-3', NULL, 1, 0),
(43389438, 202110089, 'M. IQBAL ZULFIKAR', 'L', 'X-3', NULL, 1, 0),
(58247056, 202110090, 'MEILANI EKARISTI', 'P', 'X-3', NULL, 1, 0),
(57543596, 202110091, 'MUCH FIKRI AHNAF', 'L', 'X-3', NULL, 1, 0),
(48136692, 202110092, 'MUHAMAD RENDI SEPRIATNA', 'L', 'X-3', NULL, 1, 0),
(44494197, 202110093, 'NABILAH AZ ZAHRA', 'P', 'X-3', NULL, 1, 0),
(52301180, 202110094, 'NISSA AULIYA', 'P', 'X-3', NULL, 1, 0),
(42383303, 202110095, 'RACHMA ABILLAH KUSDIANA', 'L', 'X-3', NULL, 1, 0),
(51074257, 202110096, 'RAKHA SALSABILA JAUZA', 'P', 'X-3', NULL, 1, 0),
(51074247, 202110097, 'RITA NUR SUSILAWATI', 'P', 'X-3', NULL, 1, 0),
(44969153, 202110098, 'SALMA KHAIRUNNISA', 'P', 'X-3', NULL, 1, 0),
(47260263, 202110099, 'SHAFA DESTITA ULINNUHA', 'P', 'X-3', NULL, 1, 0),
(44995170, 202110100, 'SITI NURANGGRAENI', 'P', 'X-3', NULL, 1, 0),
(51074844, 202110101, 'SUCI RAHAYU', 'P', 'X-3', NULL, 1, 0),
(58519497, 202110102, 'VANESSA TRAVIATA', 'P', 'X-3', NULL, 1, 0),
(44993591, 202110103, 'YOSAN SONJAYA', 'L', 'X-3', NULL, 1, 0),
(41102027, 202110104, 'ADINDA NABILA MAHARANI', 'P', 'X-4', NULL, 1, 0),
(41028890, 202110105, 'ALDY AGUSTIANA', 'L', 'X-4', NULL, 1, 0),
(48111058, 202110106, 'AMELIA PUTRI LATIFAH', 'P', 'X-4', NULL, 1, 0),
(51075193, 202110107, 'ANGGUN PUTRI ALYANTI', 'P', 'X-4', NULL, 1, 0),
(51074855, 202110108, 'AZKA AZKIA TAWKAL', 'L', 'X-4', NULL, 1, 0),
(56440467, 202110109, 'CHAIRIL GIBRAN', 'L', 'X-4', NULL, 1, 0),
(47821427, 202110110, 'DESINTA AKBAR', 'P', 'X-4', NULL, 1, 0),
(51017754, 202110111, 'DINDA HAMIDAH', 'P', 'X-4', NULL, 1, 0),
(51166056, 202110112, 'EUIS RANA', 'P', 'X-4', NULL, 1, 0),
(41204101, 202110113, 'FANISYA DWI ERIAANTI', 'P', 'X-4', NULL, 1, 0),
(51073404, 202110114, 'FAUZAN ABDUL FIQRI', 'L', 'X-4', NULL, 1, 0),
(51073488, 202110115, 'GENNY GITA GESELA', 'P', 'X-4', NULL, 1, 0),
(59106687, 202110116, 'GINA PEBRIANTI', 'P', 'X-4', NULL, 1, 0),
(43385638, 202110117, 'HESTY NOVIANA NURAENI', 'P', 'X-4', NULL, 1, 0),
(51073788, 202110118, 'ILHAM TAUFIK FEBRIANA HANAFIAH', 'L', 'X-4', NULL, 1, 0),
(51760278, 202110119, 'INTAN NUR\'AENI', 'P', 'X-4', NULL, 1, 0),
(55420212, 202110120, 'JOSUA TUA PRATAMA NAINGGOLAN', 'L', 'X-4', NULL, 1, 0),
(51072931, 202110121, 'KANIA SITI RAHMAYANTI', 'P', 'X-4', NULL, 1, 0),
(51399254, 202110122, 'LAFADHYA MUNGGARAN WILANTARA', 'P', 'X-4', NULL, 1, 0),
(3047632254, 202110123, 'M. RAMDAN EKA PERMANA', 'L', 'X-4', NULL, 1, 0),
(44995218, 202110124, 'MELANI NUR INDAH', 'P', 'X-4', NULL, 1, 0),
(51174763, 202110125, 'MUHAMAD BINTANG DWI MAULANA', 'L', 'X-4', NULL, 1, 0),
(49191989, 202110126, 'MUHAMMAD FAJAR UTAMA', 'L', 'X-4', NULL, 1, 0),
(51075196, 202110127, 'NANDINI PUSPA DEWI', 'P', 'X-4', NULL, 1, 0),
(54359601, 202110128, 'NURLITA DHEINA PUTRIA', 'P', 'X-4', NULL, 1, 0),
(45697409, 202110129, 'RAIHAN JAUHAR IBRAHIM', 'L', 'X-4', NULL, 1, 0),
(52314009, 202110130, 'REGINA RESTA AZALEA UTAMI', 'P', 'X-4', NULL, 1, 0),
(48957574, 202110131, 'RIZKI GHIFARI NUGRAHA', 'L', 'X-4', NULL, 1, 0),
(49384415, 202110132, 'SALSA AMALIA AFIFI', 'P', 'X-4', NULL, 1, 0),
(57962711, 202110133, 'SHELINA HERLYANTI', 'P', 'X-4', NULL, 1, 0),
(49861288, 202110134, 'SITI ROKAYAH', 'P', 'X-4', NULL, 1, 0),
(44995342, 202110135, 'SYARIFAH FADILLAH', 'P', 'X-4', NULL, 1, 0),
(51072932, 202110136, 'VINA RAHAYU', 'P', 'X-4', NULL, 1, 0),
(51074233, 202110137, 'ZAHRA NEDILFIANA PUTRI', 'P', 'X-4', NULL, 1, 0),
(57266631, 202110138, 'ANI RAHMAWATI', 'P', 'X-5', NULL, 1, 0),
(51012959, 202110139, 'ASSYFA FAUZIA', 'P', 'X-5', NULL, 1, 0),
(44954178, 202110140, 'AZFA MAHARDIKA S', 'L', 'X-5', NULL, 1, 0),
(44995459, 202110141, 'DAHLIA PURGANANTI', 'P', 'X-5', NULL, 1, 0),
(51759574, 202110142, 'DEWI NUR BAROKAH YULIANA', 'P', 'X-5', NULL, 1, 0),
(51075120, 202110143, 'FANNY SETIA PEBRIANTI', 'P', 'X-5', NULL, 1, 0),
(51074971, 202110144, 'FUJI AMELIA AINNUNISHA', 'P', 'X-5', NULL, 1, 0),
(54284779, 202110145, 'HALIMAH TUSSADI\'AH', 'P', 'X-5', NULL, 1, 0),
(59204143, 202110146, 'INDRI YULIANI', 'P', 'X-5', NULL, 1, 0),
(44978226, 202110147, 'LADIVA MAHAPUTRI FAHRUDIN', 'P', 'X-5', NULL, 1, 0),
(48149982, 202110148, 'METHA DWI NUR ADESTI', 'P', 'X-5', NULL, 1, 0),
(51074254, 202110149, 'MUHAMAD FADRI HARUNSYAH', 'L', 'X-5', NULL, 1, 0),
(63362765, 202110150, 'MUHAMMAD ZIDANE', 'L', 'X-5', NULL, 1, 0),
(48121492, 202110151, 'NABILA APRILLIANI', 'P', 'X-5', NULL, 1, 0),
(51012974, 202110152, 'NAURA JANNAH MAULIDA', 'P', 'X-5', NULL, 1, 0),
(51072934, 202110153, 'NIMAS DEWI SEKARJAGAT', 'P', 'X-5', NULL, 1, 0),
(43776201, 202110154, 'NIZAR RHEIVANI RAMADINA SUPRIADI', 'P', 'X-5', NULL, 1, 0),
(56768424, 202110155, 'NURHAYATI', 'P', 'X-5', NULL, 1, 0),
(45213023, 202110156, 'PUTRI AYU NURMALASARI', 'P', 'X-5', NULL, 1, 0),
(41506549, 202110157, 'PUTRI FITRIANA NUR SYIFA', 'P', 'X-5', NULL, 1, 0),
(51072953, 202110158, 'RANDIKA CANDRA WIJAYA', 'L', 'X-5', NULL, 1, 0),
(39136385, 202110159, 'REINA FITRIANI PRABOWO', 'P', 'X-5', NULL, 1, 0),
(50831094, 202110160, 'RICKA AMALIA', 'P', 'X-5', NULL, 1, 0),
(46812156, 202110161, 'RIZKIA UMMAMI AULIYA TAQWA', 'P', 'X-5', NULL, 1, 0),
(53483072, 202110162, 'SALMA NABILAH', 'P', 'X-5', NULL, 1, 0),
(3046812654, 202110163, 'SENDI MUHAMAD', 'L', 'X-5', NULL, 1, 0),
(48875576, 202110164, 'SHELVA AULIA NURSHABRINA', 'P', 'X-5', NULL, 1, 0),
(44994503, 202110165, 'SHINTYASARI HADI KARMILA', 'P', 'X-5', NULL, 1, 0),
(51073343, 202110166, 'SILVIA ALLYA PUTRI', 'P', 'X-5', NULL, 1, 0),
(3040481850, 202110167, 'SYAKIR FADHILLAH', 'L', 'X-5', NULL, 1, 0),
(3054598896, 202110168, 'TAUFIQ MAULANA', 'L', 'X-5', NULL, 1, 0),
(51074700, 202110169, 'VANNI FEBIANI PUTRI', 'P', 'X-5', NULL, 1, 0),
(47932865, 202110170, 'WILDAN NUGRAHA', 'L', 'X-5', NULL, 1, 0),
(58467288, 202110171, 'ZAKY RIBAS SAEPUDIN', 'L', 'X-5', NULL, 1, 0),
(51073345, 202110172, 'ANISAH NURJANAH', 'P', 'X-6', NULL, 1, 0),
(53716458, 202110173, 'AURELLIA PUTRI WIDWIUTAMI', 'P', 'X-6', NULL, 1, 0),
(51098586, 202110174, 'CANTIKA SARI NURFALAH', 'P', 'X-6', NULL, 1, 0),
(3053739898, 202110175, 'DELLA PUSPITA ANGGRAENI', 'P', 'X-6', NULL, 1, 0),
(56758858, 202110176, 'FALAH NURFADILAH', 'P', 'X-6', NULL, 1, 0),
(48144811, 202110177, 'FITRI NURHAYATI', 'P', 'X-6', NULL, 1, 0),
(44993639, 202110178, 'GHAIDA FAUZIAH', 'P', 'X-6', NULL, 1, 0),
(46673233, 202110179, 'ILYA MARIA ULFAH', 'P', 'X-6', NULL, 1, 0),
(48331912, 202110180, 'ISFIHANY LESTARI', 'P', 'X-6', NULL, 1, 0),
(54985394, 202110181, 'MELA AGUSTIN', 'P', 'X-6', NULL, 1, 0),
(51399600, 202110182, 'MITA DZAKIRAH KURNIA', 'P', 'X-6', NULL, 1, 0),
(45213629, 202110183, 'MOCHAMAD AKBAR RAMADHAN', 'L', 'X-6', NULL, 1, 0),
(58004540, 202110184, 'MUHAMAD FARID ABDULLOH', 'L', 'X-6', NULL, 1, 0),
(3055963726, 202110185, 'NABILA KHAERUNISA BUDIMAN', 'P', 'X-6', NULL, 1, 0),
(57855301, 202110186, 'NAUFAL LUTHFI BARIZKI', 'L', 'X-6', NULL, 1, 0),
(58150233, 202110187, 'NENDEN SITI MEILANI', 'P', 'X-6', NULL, 1, 0),
(51449687, 202110188, 'NISSA HANIN DITA', 'P', 'X-6', NULL, 1, 0),
(46268366, 202110189, 'NORIKA MARLIANA', 'P', 'X-6', NULL, 1, 0),
(44954171, 202110190, 'NURUL RIZKY BAITI', 'P', 'X-6', NULL, 1, 0),
(44993694, 202110191, 'PUTRI EKA APRILIA', 'P', 'X-6', NULL, 1, 0),
(44954186, 202110192, 'RAIHAN BISYRI RABBANI', 'L', 'X-6', NULL, 1, 0),
(51017661, 202110193, 'REBINA NURHASANAH', 'P', 'X-6', NULL, 1, 0),
(43522371, 202110194, 'RENI FITRIYANI', 'P', 'X-6', NULL, 1, 0),
(54756115, 202110195, 'RISMA RENGGANIS', 'P', 'X-6', NULL, 1, 0),
(43909085, 202110196, 'SALMA HAYNUR FADILAH', 'P', 'X-6', NULL, 1, 0),
(52072962, 202110197, 'SALSA BAHARANI FUTRI NURELASENSA', 'P', 'X-6', NULL, 1, 0),
(56506063, 56506062, 'SALSABILA ALIA SAFARIYAH', 'P', 'X-6', NULL, 1, 0),
(56285984, 56285983, 'SASKIYA WINDI FEBRIYANTI', 'P', 'X-6', NULL, 1, 0),
(44995211, 202110198, 'SHANAZ YUNIAR', 'P', 'X-6', NULL, 1, 0),
(44242780, 202110199, 'SHELYNA MARDIANA PUTRI', 'P', 'X-6', NULL, 1, 0),
(51074696, 202110200, 'SILVI SELVIA RIYANY', 'P', 'X-6', NULL, 1, 0),
(53590175, 202110201, 'SUCI NUR\'AINI', 'P', 'X-6', NULL, 1, 0),
(47271945, 202110202, 'TASYA FADILLA', 'P', 'X-6', NULL, 1, 0),
(51072942, 202110203, 'TOYIB ABDUL RAHMAN', 'L', 'X-6', NULL, 1, 0),
(44995427, 202110204, 'VIONA ZULFA ADRIANE', 'P', 'X-6', NULL, 1, 0),
(51017755, 202110205, 'ZAHRA NABILA PERMANA', 'P', 'X-6', NULL, 1, 0),
(51074861, 202110206, 'AFUZA LAUTAN NAJATIN', 'P', 'X-7', NULL, 1, 0),
(42622556, 202110207, 'ELDY FIRMANSYAH GUSTIAN', 'L', 'X-7', NULL, 1, 0),
(48259469, 202110208, 'FIRMAN MAULANA', 'L', 'X-7', NULL, 1, 0),
(46198072, 202110209, 'HANI NURYANI', 'P', 'X-7', NULL, 1, 0),
(43905468, 202110210, 'HARTATI AGUSTINA', 'P', 'X-7', NULL, 1, 0),
(46844479, 202110211, 'HUSEN NURUL IMAN', 'L', 'X-7', NULL, 1, 0),
(51074601, 202110212, 'LUCKY ANUGRAH', 'L', 'X-7', NULL, 1, 0),
(51765922, 202110213, 'MOCH. ZACKY RIFANSYAH', 'L', 'X-7', NULL, 1, 0),
(44602105, 202110214, 'MUHAMAD AKMAL RAFSANZHANI', 'L', 'X-7', NULL, 1, 0),
(51074262, 202110215, 'MUHAMAD RIZKY OKTAVIAN', 'L', 'X-7', NULL, 1, 0),
(51073429, 202110216, 'MUHAMMAD RAMDAN', 'L', 'X-7', NULL, 1, 0),
(44994195, 202110217, 'MUHAMMAD RIFKI HIDAYAT', 'L', 'X-7', NULL, 1, 0),
(44993596, 202110218, 'NABIL HAIDAR WAPID', 'L', 'X-7', NULL, 1, 0),
(57919330, 202110219, 'NADHIL IKHWAN ASHSHIBA WALUYA', 'L', 'X-7', NULL, 1, 0),
(44784449, 202110220, 'NADILA OKTAPIANI', 'P', 'X-7', NULL, 1, 0),
(44994850, 202110221, 'NAURA NUR ZAHRA', 'P', 'X-7', NULL, 1, 0),
(3041757032, 202110222, 'RAFI MANSYUR RASYID', 'L', 'X-7', NULL, 1, 0),
(51075199, 202110223, 'RAHMA LARAS SAEPADILAH', 'P', 'X-7', NULL, 1, 0),
(51073502, 202110224, 'RAINI RAHMADANI', 'P', 'X-7', NULL, 1, 0),
(40732231, 202110225, 'RENDI FAJAR FIRMANSYAH', 'L', 'X-7', NULL, 1, 0),
(41765914, 202110226, 'REVALIA SAFITRI', 'P', 'X-7', NULL, 1, 0),
(44428032, 202110227, 'REZA SRI DALIESTA', 'P', 'X-7', NULL, 1, 0),
(46868707, 202110228, 'RINI SURYANI', 'P', 'X-7', NULL, 1, 0),
(58618094, 202110229, 'RISMA DWI APRILIYANA', 'P', 'X-7', NULL, 1, 0),
(55016641, 202110230, 'RONI ROMANSYAH', 'L', 'X-7', NULL, 1, 0),
(54428312, 202110231, 'SALSA KHOERUNISSA', 'P', 'X-7', NULL, 1, 0),
(51074592, 202110232, 'SAVITRI SALSABILA', 'P', 'X-7', NULL, 1, 0),
(46714591, 202110233, 'SOFIA RAHMA', 'P', 'X-7', NULL, 1, 0),
(58932795, 202110234, 'SUSAN RIZKI SAHBUDIN', 'P', 'X-7', NULL, 1, 0),
(51074265, 202110235, 'SYEILA THABITA S', 'P', 'X-7', NULL, 1, 0),
(51075211, 202110236, 'TASYA AMALIA', 'P', 'X-7', NULL, 1, 0),
(3044774498, 202110237, 'TIARA LESTARI', 'P', 'X-7', NULL, 1, 0),
(51075180, 202110238, 'TRISA AYUDIA', 'P', 'X-7', NULL, 1, 0),
(3051025441, 202110239, 'WAHIDIN SETIAJI PUTRA', 'L', 'X-7', NULL, 1, 0),
(44995434, 202110240, 'YENI MASRIFAH', 'P', 'X-7', NULL, 1, 0),
(51073791, 202110241, 'ZAENAL MUSTAFA', 'L', 'X-7', NULL, 1, 0),
(57679370, 202110242, 'ALEYA AZZAHRA', 'P', 'X-8', NULL, 1, 0),
(44994071, 202110243, 'ALYSSA ZAFFINA', 'P', 'X-8', NULL, 1, 0),
(44995677, 202110244, 'ANGGA RAMADAN', 'L', 'X-8', NULL, 1, 0),
(51722258, 202110245, 'ANNISA NUR AZIZAH', 'P', 'X-8', NULL, 1, 0),
(63808870, 202110246, 'ASRI AIDA SUSANTIKA', 'P', 'X-8', NULL, 1, 0),
(53954055, 202110247, 'AZZAHRA KIREINA', 'P', 'X-8', NULL, 1, 0),
(51074256, 202110248, 'CINDY BERLIYANI', 'P', 'X-8', NULL, 1, 0),
(51098558, 202110249, 'DEDE ROSADI', 'L', 'X-8', NULL, 1, 0),
(3059348632, 202110250, 'DENISA YUNIARTI', 'P', 'X-8', NULL, 1, 0),
(49270639, 202110251, 'EKA GUNTARA', 'L', 'X-8', NULL, 1, 0),
(55801999, 202110252, 'ESRA WASTI HUTASOIT', 'P', 'X-8', NULL, 1, 0),
(44994073, 202110253, 'FAUZAN AZZARIA HAFIEDZ', 'L', 'X-8', NULL, 1, 0),
(45426953, 202110254, 'FEBI HERMAWAN', 'L', 'X-8', NULL, 1, 0),
(52622856, 202110255, 'FRANS AGUNG FRAMONO PASARIBU', 'L', 'X-8', NULL, 1, 0),
(3058196034, 202110256, 'GALANG MERDIKA IBNU MUTAQIEN', 'L', 'X-8', NULL, 1, 0),
(48248517, 202110257, 'GESYA FELISHA LAURA', 'P', 'X-8', NULL, 1, 0),
(58463444, 202110258, 'HAIKAL FAISAL RASYID', 'L', 'X-8', NULL, 1, 0),
(51075335, 202110259, 'HILDA KURNIA', 'P', 'X-8', NULL, 1, 0),
(41663841, 202110260, 'ILHAM AKBAR MAULANA', 'L', 'X-8', NULL, 1, 0),
(48124676, 202110261, 'INA SARTIKA MAELANI', 'P', 'X-8', NULL, 1, 0),
(56946116, 202110262, 'KAMIL RIZIK FAZIRIN', 'L', 'X-8', NULL, 1, 0),
(51073491, 202110263, 'KIRANA DI SECHAN', 'P', 'X-8', NULL, 1, 0),
(55997703, 202110264, 'LAISYA ARIANTY UTAMI', 'P', 'X-8', NULL, 1, 0),
(44994072, 202110265, 'MAHRUNISA', 'P', 'X-8', NULL, 1, 0),
(3049662868, 202110266, 'MUGHNI RAMDANI', 'L', 'X-8', NULL, 1, 0),
(35031638, 202110267, 'MUHAMMAD RAMDHAN', 'L', 'X-8', NULL, 1, 0),
(53438840, 202110268, 'NASYWA ATHALIA', 'P', 'X-8', NULL, 1, 0),
(44994856, 202110269, 'RAHAYU KARYADI NINGRAT', 'L', 'X-8', NULL, 1, 0),
(41909622, 202110270, 'RESTU AKSA NAYA', 'P', 'X-8', NULL, 1, 0),
(33780988, 202110271, 'RISTA BAKTI PERTIWI', 'P', 'X-8', NULL, 1, 0),
(3056687695, 202110272, 'SALMAN MAULANA', 'L', 'X-8', NULL, 1, 0),
(51730112, 202110273, 'SHAREL FATURAHMAN', 'L', 'X-8', NULL, 1, 0),
(57982988, 202110274, 'SURYANI', 'P', 'X-8', NULL, 1, 0),
(44994014, 202110275, 'TARIS BARIKAN', 'L', 'X-8', NULL, 1, 0),
(51074259, 202110276, 'TULIS KHALIS PURWAKA', 'P', 'X-8', NULL, 1, 0),
(3051527312, 202110277, 'YUDA EKA PRASETYA', 'L', 'X-8', NULL, 1, 0),
(48208655, 202110278, 'ALIF DWI NUGRAHA', 'L', 'X-9', NULL, 1, 0),
(53279511, 202110279, 'AMELIA ROSSIANA', 'P', 'X-9', NULL, 1, 0),
(44994858, 202110280, 'ANISA RODIAH RAHAYU', 'P', 'X-9', NULL, 1, 0),
(45590151, 202110281, 'ANNISA NUR AZZAHRA', 'P', 'X-9', NULL, 1, 0),
(43685631, 202110282, 'AULIA NURJAHIDAH', 'P', 'X-9', NULL, 1, 0),
(48348336, 202110283, 'BELLA FITRI NURHASANAH', 'P', 'X-9', NULL, 1, 0),
(45473772, 202110284, 'DADAN MUSYAROPUL', 'L', 'X-9', NULL, 1, 0),
(56215320, 202110285, 'DEDEN NURMANSYAH', 'L', 'X-9', NULL, 1, 0),
(46798273, 202110286, 'DESTYA PUTRI LESTARI', 'P', 'X-9', NULL, 1, 0),
(3047842800, 202110287, 'ELANGGA YUDISTIRA', 'L', 'X-9', NULL, 1, 0),
(36504486, 202110288, 'FAISAL SALMAN ALFARIZ', 'L', 'X-9', NULL, 1, 0),
(51073397, 202110289, 'FAUZIA NURPADILAH', 'P', 'X-9', NULL, 1, 0),
(47682812, 202110290, 'FITRI ARYANTI', 'P', 'X-9', NULL, 1, 0),
(45814911, 202110291, 'FUJI NURZAMAN', 'L', 'X-9', NULL, 1, 0),
(57177717, 202110292, 'GARRY PUTRA PAMUNGKAS', 'L', 'X-9', NULL, 1, 0),
(51074849, 202110293, 'GHAZIYA MILADIAH KHOERUNISA', 'P', 'X-9', NULL, 1, 0),
(47220681, 202110294, 'HANI OKTAVIANI NURFALLAH', 'P', 'X-9', NULL, 1, 0),
(56925946, 202110295, 'ICAS MULYANA', 'L', 'X-9', NULL, 1, 0),
(52856382, 202110296, 'IMA NURHAYATI', 'P', 'X-9', NULL, 1, 0),
(48058755, 202110297, 'INDAH NURFAUZIAH J.', 'P', 'X-9', NULL, 1, 0),
(44940967, 202110298, 'KARTIKA DITA AZZAHRA', 'P', 'X-9', NULL, 1, 0),
(51073400, 202110299, 'KOMALA', 'P', 'X-9', NULL, 1, 0),
(42181363, 202110300, 'LITTA NURJANAH', 'P', 'X-9', NULL, 1, 0),
(53861620, 202110301, 'MELA KOESMAYANTI', 'P', 'X-9', NULL, 1, 0),
(43533818, 202110302, 'MUHAMAD BINTANG RIZAQI', 'L', 'X-9', NULL, 1, 0),
(3048179917, 202110303, 'MUHAMMAD RIVALDY', 'L', 'X-9', NULL, 1, 0),
(53760374, 202110304, 'NATASYA BENING HANURANI. F', 'P', 'X-9', NULL, 1, 0),
(3041050380, 202110305, 'RAHMAT HIDAYAT', 'L', 'X-9', NULL, 1, 0),
(54536071, 202110306, 'REVA NATAMA', 'L', 'X-9', NULL, 1, 0),
(51074246, 202110307, 'RIZKI ANDREA', 'L', 'X-9', NULL, 1, 0),
(52738828, 202110308, 'SALSHA NURUL AINA', 'P', 'X-9', NULL, 1, 0),
(54069230, 202110309, 'SITI MASHFUFAH NURAENI', 'P', 'X-9', NULL, 1, 0),
(51074586, 202110310, 'SYAHRANI LISNIAWATI ROHMAH', 'P', 'X-9', NULL, 1, 0),
(44304112, 202110311, 'TIA DESTRIANA RACHMAT', 'P', 'X-9', NULL, 1, 0),
(43008452, 202110312, 'UTARI NURHAMIDAH', 'P', 'X-9', NULL, 1, 0),
(59823141, 202110313, 'ZAKIAH DARAJAT', 'P', 'X-9', NULL, 1, 0),
(44994846, 202110314, 'AKHMAD MUKHTAR AJI PRASETYA', 'L', 'X-10', NULL, 1, 0),
(51074234, 202110315, 'ALYA ATHIYAH NURFAIZAH', 'P', 'X-10', NULL, 1, 0),
(51533580, 202110316, 'ANDRIANSYAH ADYTYA NUGRAHA', 'L', 'X-10', NULL, 1, 0),
(51074436, 202110317, 'ANITA WULAN SARI', 'P', 'X-10', NULL, 1, 0),
(59716985, 202110318, 'ASMALA AZHARI PUTRI', 'P', 'X-10', NULL, 1, 0),
(52399341, 202110319, 'AUREL MAURA DEWI', 'P', 'X-10', NULL, 1, 0),
(31128621, 202110320, 'CEPI RAMADANI', 'L', 'X-10', NULL, 1, 0),
(52893444, 202110321, 'DEAN ZISKA MAULIDYA', 'P', 'X-10', NULL, 1, 0),
(51074847, 202110322, 'DEGA GEZA AL MIFDHIL WAL MUSLIM', 'L', 'X-10', NULL, 1, 0),
(51075252, 202110323, 'DINI NURJANAH', 'P', 'X-10', NULL, 1, 0),
(51073492, 202110324, 'ELVAN NUR APRILIANSYAH', 'L', 'X-10', NULL, 1, 0),
(44995279, 202110325, 'FAKHRY RAHMAN', 'L', 'X-10', NULL, 1, 0),
(51892885, 202110326, 'FAZIDA AQLUDINA', 'P', 'X-10', NULL, 1, 0),
(44994070, 202110327, 'FITRIANA ANANDA OCKTAVIANI', 'P', 'X-10', NULL, 1, 0),
(3054964498, 202110328, 'GALANG ERLANGGA', 'L', 'X-10', NULL, 1, 0),
(59261228, 202110329, 'GEOVANY PUTRA TRI PAMUNGKAS', 'L', 'X-10', NULL, 1, 0),
(3056360391, 202110330, 'GILANG SAGARA', 'L', 'X-10', NULL, 1, 0),
(51639291, 202110331, 'HASHFI RAHMAN', 'L', 'X-10', NULL, 1, 0),
(44994207, 202110332, 'IKHSAN RAHAYU', 'L', 'X-10', NULL, 1, 0),
(51074231, 202110333, 'IMELDA RELYANI VEGA', 'P', 'X-10', NULL, 1, 0),
(51075330, 202110334, 'INTAN NATALIA', 'P', 'X-10', NULL, 1, 0),
(58890579, 202110335, 'KIKI RIYANTI', 'P', 'X-10', NULL, 1, 0),
(49330937, 202110336, 'LAILA VENADHITA', 'P', 'X-10', NULL, 1, 0),
(56592289, 202110337, 'MAGFIRA NURQOLBU ARDIANSYAH', 'P', 'X-10', NULL, 1, 0),
(46175153, 202110338, 'MUHAMMAD IQBAL ALGHIFFARI', 'L', 'X-10', NULL, 1, 0),
(59472145, 202110339, 'MUTIARA KHODIJAH', 'P', 'X-10', NULL, 1, 0),
(44022567, 202110340, 'PERI RUSLI HAMDI', 'L', 'X-10', NULL, 1, 0),
(40694185, 202110341, 'RAKA PRASASTA', 'L', 'X-10', NULL, 1, 0),
(51074232, 202110342, 'RIO LINGGA ADHARI', 'L', 'X-10', NULL, 1, 0),
(38471923, 202110343, 'ROHMANA', 'L', 'X-10', NULL, 1, 0),
(67024854, 202110344, 'SAYYIDATUL ADAWIYYAH', 'P', 'X-10', NULL, 1, 0),
(3042004757, 202110345, 'SUCI AULIAUSHOLIHAH', 'P', 'X-10', NULL, 1, 0),
(42586118, 202110346, 'TALITHA LUTFI BUCHARI', 'P', 'X-10', NULL, 1, 0),
(42586119, 202110347, 'TRIA HERMAYANTY', 'P', 'X-10', NULL, 1, 0),
(42586120, 202110348, 'WIRYA SANTANA INDRAYANA', 'L', 'X-10', NULL, 1, 0),
(40692918, 192010001, 'ADELIA GIAN PHALOSA', 'P', 'XI-1', NULL, 1, 0),
(41578341, 192010105, 'ADENAN KHAIRUL THORIQ RUHIMAT', 'L', 'XI-1', NULL, 1, 0),
(40693836, 192010036, 'ADRIAN RAMADAN', 'L', 'XI-1', NULL, 1, 0),
(41431145, 192010070, 'AGIM ABDULLAH GIMNASTIAR', 'L', 'XI-1', NULL, 1, 0),
(40694201, 192010139, 'AI ALVI OKTAVIA', 'P', 'XI-1', NULL, 1, 0),
(43371257, 192010173, 'AI NINDA MARLIANI', 'P', 'XI-1', NULL, 1, 0),
(35032564, 192010006, 'BUNGA FITRIANA', 'P', 'XI-1', NULL, 1, 0),
(31187310, 192010041, 'CECILLYA DESTA PUTRI FIRMANSYAH', 'P', 'XI-1', NULL, 1, 0),
(43371341, 192010076, 'DAFFA PUTRA EMERALD', 'L', 'XI-1', NULL, 1, 0),
(33003325, 192010112, 'DEDDY IQBAL', 'L', 'XI-1', NULL, 1, 0),
(40693110, 192010145, 'DENISSA RACHMA PUTRI', 'P', 'XI-1', NULL, 1, 0),
(39236191, 192010179, 'DEVI FAUZIAH', 'P', 'XI-1', NULL, 1, 0),
(40693009, 192010011, 'FEBRINA NUR AZIZAH', 'P', 'XI-1', NULL, 1, 0),
(42291171, 192010046, 'FIRYAL SYAQRA LABIBAH', 'P', 'XI-1', NULL, 1, 0),
(35033193, 192010082, 'IKHSAN NANDY FIRMANSYAH', 'L', 'XI-1', NULL, 1, 0),
(42291257, 192010118, 'ILHAM ALY ABDILLAH', 'L', 'XI-1', NULL, 1, 0),
(40732274, 192010185, 'IQBAL MAULANA SUHENDAR', 'L', 'XI-1', NULL, 1, 0),
(40693650, 192010151, 'JULIA PUSPA ANGRUM', 'P', 'XI-1', NULL, 1, 0),
(42274309, 192010016, 'KHAIRUNNISA NURTSAQIFA', 'P', 'XI-1', NULL, 1, 0),
(40692919, 192010051, 'MIRA JULIANTI', 'P', 'XI-1', NULL, 1, 0),
(46418880, 192010124, 'NABILA YASFA AZAHRA', 'P', 'XI-1', NULL, 1, 0),
(42022500, 192010190, 'NADYA ARIFANI', 'P', 'XI-1', NULL, 1, 0),
(33046796, 192010090, 'NAILA FATHIRANI ZAIN', 'P', 'XI-1', NULL, 1, 0),
(41737589, 192010157, 'NARAYANA KHAMIL', 'L', 'XI-1', NULL, 1, 0),
(40693109, 192010021, 'NASYA KHAILA AZZAHRA YUDHISTIRA', 'P', 'XI-1', NULL, 1, 0),
(40732282, 192010056, 'NUR HADA JUNIAR', 'P', 'XI-1', NULL, 1, 0),
(35032290, 192010196, 'REGINA JULIA', 'P', 'XI-1', NULL, 1, 0),
(36892991, 192010096, 'RIFQI ADITYA SAPUTRA', 'L', 'XI-1', NULL, 1, 0),
(40694196, 192010163, 'RIKA WULAN', 'P', 'XI-1', NULL, 1, 0),
(37053652, 192010061, 'RINI SULASTRI', 'P', 'XI-1', NULL, 1, 0),
(49251817, 192010202, 'SITI HAZAR NURLATIFAH', 'P', 'XI-1', NULL, 1, 0),
(46787039, 192010135, 'SYABILA AURELLIA PUTRI K.', 'P', 'XI-1', NULL, 1, 0),
(36179184, 192010102, 'TIARA SANDI', 'P', 'XI-1', NULL, 1, 0),
(37054427, 192010169, 'WINDY JULYANTINI ZULFA', 'P', 'XI-1', NULL, 1, 0),
(40796586, 192010002, 'ADITIA RAKA IRWANSYAH', 'L', 'XI-2', NULL, 1, 0),
(45373307, 192010037, 'AFDILLA ZAHRA JULIAN NURAHMAT', 'P', 'XI-2', NULL, 1, 0),
(39997363, 192010071, 'AGUSTINE TRYNA NINGROOM JUANA', 'P', 'XI-2', NULL, 1, 0),
(35033478, 192010106, 'AHMAD YUSUF', 'L', 'XI-2', NULL, 1, 0),
(32542763, 192010140, 'AKMAL KOMARA TRISNA JAYA SANTIKA JATNIKA', 'L', 'XI-2', NULL, 1, 0),
(37897265, 192010174, 'ALFATH RABBANI', 'L', 'XI-2', NULL, 1, 0),
(35032563, 192010042, 'CHANDRA SUKMA GUMELAR', 'L', 'XI-2', NULL, 1, 0),
(35031903, 192010007, 'DHEA FITRYAN', 'P', 'XI-2', NULL, 1, 0),
(47935950, 192010077, 'DINDA OKTA NUR ABRI', 'P', 'XI-2', NULL, 1, 0),
(35056670, 192010113, 'DINDA SUCI RAHAYU', 'P', 'XI-2', NULL, 1, 0),
(48592914, 192010146, 'EGA FAIRUZ HABIBAH', 'P', 'XI-2', NULL, 1, 0),
(24104103, 192010180, 'FAUZI SEPTIANA PAMUNGKAS', 'L', 'XI-2', NULL, 1, 0),
(43556685, 192010047, 'GIBRAN FAKHRIAN TUPASKAH', 'L', 'XI-2', NULL, 1, 0),
(43371549, 192010083, 'INA SITI ATIKAH', 'P', 'XI-2', NULL, 1, 0),
(49425432, 192010119, 'IRA TRI ANANDA DIANA SARI', 'P', 'XI-2', NULL, 1, 0),
(40693102, 192010186, 'KARISMA TITA ULFANA', 'P', 'XI-2', NULL, 1, 0),
(40693499, 192010152, 'LUTHFI SUKMANA ABDI', 'L', 'XI-2', NULL, 1, 0),
(35033658, 192010052, 'MOHAMAD IQBAL', 'L', 'XI-2', NULL, 1, 0),
(41245706, 192010125, 'NAJLA DHIYA ARDIAN', 'P', 'XI-2', NULL, 1, 0),
(40692997, 192010191, 'NAKITA DINOVAN', 'P', 'XI-2', NULL, 1, 0),
(35513630, 192010091, 'NELI NUR AULIA', 'P', 'XI-2', NULL, 1, 0),
(40694816, 192010158, 'NIHLAH SOFIANA', 'P', 'XI-2', NULL, 1, 0),
(40693027, 192010057, 'PUTRI NUR MARLENI', 'P', 'XI-2', NULL, 1, 0),
(42270885, 192010026, 'RESKI NURHIDAYAT', 'L', 'XI-2', NULL, 1, 0),
(0, 192010130, 'RIANA JANIE FATONAH', 'P', 'XI-2', NULL, 1, 0),
(37600892, 192010131, 'RIFQI RAMDANI', 'L', 'XI-2', NULL, 1, 0),
(40693637, 192010197, 'RIMA KUSUMA DEWI', 'P', 'XI-2', NULL, 1, 0),
(55372697, 192010097, 'RISKA FEBRIYANTI. S.', 'P', 'XI-2', NULL, 1, 0),
(48647239, 192010164, 'RISQIA TAMIMI', 'P', 'XI-2', NULL, 1, 0),
(44995760, 192010062, 'SALSABILA KHOIRUNISA', 'P', 'XI-2', NULL, 1, 0),
(35032312, 192010203, 'SYALSYA LAILA KHODARIAH', 'P', 'XI-2', NULL, 1, 0),
(43616885, 192010136, 'TIKA NURMALASARI', 'P', 'XI-2', NULL, 1, 0),
(44534917, 192010103, 'WADDYAMILLA WILADAHAUFA', 'P', 'XI-2', NULL, 1, 0),
(42273727, 192010170, 'ZAKY NAUFAL KOSWARA', 'L', 'XI-2', NULL, 1, 0),
(45485401, 192010107, 'AI ALIYATU SYADIAH KOSWARA', 'P', 'XI-3', NULL, 1, 0),
(0, 192010141, 'ANDREA ILHAM', 'L', 'XI-3', NULL, 1, 0),
(40693096, 192010038, 'ANISSA MARDIANI HERMAWAN', 'P', 'XI-3', NULL, 1, 0),
(44561435, 192010072, 'ANISSA SRI ROHMAWATI', 'P', 'XI-3', NULL, 1, 0),
(40970874, 192010175, 'ATI KURNIATI', 'P', 'XI-3', NULL, 1, 0),
(30434622, 192010043, 'DIANA MARTIA SARI', 'P', 'XI-3', NULL, 1, 0),
(33314247, 192010078, 'DIO JOSUA PURBA', 'L', 'XI-3', NULL, 1, 0),
(35032403, 192010114, 'FAHMI MOCHAMAD RIZKI', 'L', 'XI-3', NULL, 1, 0),
(54156918, 192010147, 'FATHURRAHMAN', 'L', 'XI-3', NULL, 1, 0),
(40693100, 192010181, 'FAZA ASHIFA FRISNAWATI PRAMUSTAVIA', 'P', 'XI-3', NULL, 1, 0),
(40693643, 192010012, 'FRIMA MARISTIANDHANU PERKASA', 'L', 'XI-3', NULL, 1, 0),
(37375149, 192010048, 'HERLIN ANISA SYA`BANI', 'P', 'XI-3', NULL, 1, 0),
(40692998, 192010084, 'LEGA DIRGANTINI PUTRI', 'P', 'XI-3', NULL, 1, 0),
(49050345, 192010120, 'LITA ANGGHIA ANGGRHAENI', 'P', 'XI-3', NULL, 1, 0),
(35031807, 192010187, 'M. ZAENAL AL FATTAAKH', 'L', 'XI-3', NULL, 1, 0),
(40393498, 192010153, 'MELITA DEWITA SARI', 'P', 'XI-3', NULL, 1, 0),
(35033659, 192010017, 'MIMIS SITI AISYIAH', 'P', 'XI-3', NULL, 1, 0),
(43516595, 192010053, 'MUHAMMAD KHAIRUL FIKRI', 'L', 'XI-3', NULL, 1, 0),
(44197699, 192010126, 'NICKY JAMEELA', 'P', 'XI-3', NULL, 1, 0),
(0, 192010192, 'NISSRINA SALSABILA FAUZIYYAH', 'P', 'XI-3', NULL, 1, 0),
(35033477, 192010022, 'NOVI AULIA ROSSYALIAH', 'P', 'XI-3', NULL, 1, 0),
(35430216, 192010092, 'NURBAITYA DWI DENDA', 'P', 'XI-3', NULL, 1, 0),
(35033771, 192010159, 'PUSPITA SARI NINGRUM', 'P', 'XI-3', NULL, 1, 0),
(64951634, 192010058, 'RADHITYA JAYA YUSUF KURNIAWAN', 'L', 'XI-3', NULL, 1, 0),
(37053802, 192010027, 'RINI ANGGRAENI', 'P', 'XI-3', NULL, 1, 0),
(40694180, 192010198, 'RIO FEBRIAN', 'L', 'XI-3', NULL, 1, 0),
(39031591, 192010132, 'RISKA KARTIKA DEWI', 'P', 'XI-3', NULL, 1, 0),
(33192303, 192010063, 'SANDI YUDHA PRATAMA', 'L', 'XI-3', NULL, 1, 0),
(33386213, 192010098, 'SELLA SAHRINI', 'P', 'XI-3', NULL, 1, 0),
(37374000, 192010165, 'SEPTIANI SYINTIA PUTRI', 'P', 'XI-3', NULL, 1, 0),
(37913692, 192010137, 'WINDA WIDYA NURLATIFAH', 'P', 'XI-3', NULL, 1, 0),
(40694669, 192010205, 'YANTI SEPTIANI', 'P', 'XI-3', NULL, 1, 0),
(40693017, 192010104, 'YUNIA KARTIKA', 'P', 'XI-3', NULL, 1, 0),
(40694246, 192010171, 'ZULIANTI DWI NURJANNAH', 'P', 'XI-3', NULL, 1, 0),
(35033472, 192010003, 'ALFI AZWAR DZULHARNA', 'L', 'XI-4', NULL, 1, 0),
(35033189, 192010108, 'ANJAR EKA RAHAYU', 'P', 'XI-4', NULL, 1, 0),
(35033595, 192010039, 'ANUGRAH SEPTIANSYAH', 'L', 'XI-4', NULL, 1, 0),
(41412851, 192010073, 'ARTHUR MUHAMAD DIANSYAH', 'L', 'XI-4', NULL, 1, 0),
(44934460, 192010142, 'BAGUS RIYADI', 'L', 'XI-4', NULL, 1, 0),
(50317724, 192010176, 'BHAGAS YUDHA NOER ARIFIN', 'L', 'XI-4', NULL, 1, 0),
(35032397, 192010008, 'DIAN NUR FAUZI', 'L', 'XI-4', NULL, 1, 0),
(30434619, 192010044, 'DIMAS DZAKI ARDIANSYAH', 'L', 'XI-4', NULL, 1, 0),
(46352235, 192010079, 'FATIMA ZAMZAM', 'P', 'XI-4', NULL, 1, 0),
(37053984, 192010115, 'FATIMAH NURHAIDA', 'P', 'XI-4', NULL, 1, 0),
(40693649, 192010148, 'FAUDZIAH NURROHMAH', 'P', 'XI-4', NULL, 1, 0),
(0, 192010182, 'FEBRYA BAGUS SAPUTRA', 'L', 'XI-4', NULL, 1, 0),
(50530157, 192010013, 'HELSY AZZAHRA', 'P', 'XI-4', NULL, 1, 0),
(44054583, 44054582, 'KAILA MELANIA', 'P', 'XI-4', NULL, 1, 0),
(37893317, 192010085, 'LIA SINTAWATI', 'P', 'XI-4', NULL, 1, 0),
(46670179, 192010086, 'LUFFI MUHAMAD IRAWAN', 'L', 'XI-4', NULL, 1, 0),
(49870131, 192010121, 'LUTHFI IRHAM ZULAFA', 'L', 'XI-4', NULL, 1, 0),
(49076373, 192010188, 'MILKA ALIYYAJANNAH', 'P', 'XI-4', NULL, 1, 0),
(52872807, 192010018, 'MOCHAMAD FARCHAN AWALLUDIN', 'L', 'XI-4', NULL, 1, 0),
(35056667, 192010154, 'MUHAMMAD DIMAS TRISDYA YUDHA GUMILANG', 'L', 'XI-4', NULL, 1, 0),
(40732256, 192010054, 'NAHDA AIRIL LISTIA', 'P', 'XI-4', NULL, 1, 0),
(40694737, 192010127, 'NURI SALSABILAH', 'P', 'XI-4', NULL, 1, 0),
(43371310, 192010193, 'NURRIZKY FAUZHI', 'L', 'XI-4', NULL, 1, 0),
(40693025, 192010023, 'PANDU DWI PRATAMA', 'L', 'XI-4', NULL, 1, 0),
(40693651, 192010093, 'PUTRI PUSPITA SARI', 'P', 'XI-4', NULL, 1, 0),
(55090721, 192010160, 'RANDI JUNIAR ARIF', 'L', 'XI-4', NULL, 1, 0),
(40694769, 192010059, 'RESTI RINJANI', 'P', 'XI-4', NULL, 1, 0),
(37913141, 192010199, 'RIZKA NABILAH', 'P', 'XI-4', NULL, 1, 0),
(43816220, 192010028, 'ROLIA NELSA MEIRA', 'P', 'XI-4', NULL, 1, 0),
(40693834, 192010099, 'SHELA NUR HERLINA', 'P', 'XI-4', NULL, 1, 0),
(37609870, 192010166, 'SILMI AINUN ASHAFANI', 'P', 'XI-4', NULL, 1, 0),
(48136394, 48136393, 'WILDAN HIZRI ABDILLAH', 'L', 'XI-4', NULL, 1, 0),
(45527168, 192010138, 'YUNIAR DWI SULAESTHI', 'P', 'XI-4', NULL, 1, 0),
(35032565, 192010206, 'ZAMMIL', 'L', 'XI-4', NULL, 1, 0),
(35033103, 192010040, 'AULIYA ZUYYINA', 'P', 'XI-5', NULL, 1, 0),
(29944443, 192010109, 'AYANG RENDY RISMA HIDAYAT', 'L', 'XI-5', NULL, 1, 0),
(42274312, 192010143, 'BERLIANDA RAHMAWATI', 'P', 'XI-5', NULL, 1, 0),
(35056693, 192010005, 'BILAL BIAGI', 'L', 'XI-5', NULL, 1, 0),
(49721127, 192010075, 'CINDY TRI INDAH LESTARI', 'P', 'XI-5', NULL, 1, 0),
(37836074, 192010178, 'DEVAN NADIF RIZKI HIDAYAT', 'L', 'XI-5', NULL, 1, 0),
(40693098, 192010009, 'DIANA FADHILAH MACHJAR', 'P', 'XI-5', NULL, 1, 0),
(35031820, 192010010, 'FANY DESTANIA', 'P', 'XI-5', NULL, 1, 0),
(47249570, 192010116, 'GINA DWI ARISTA', 'P', 'XI-5', NULL, 1, 0),
(40732281, 192010117, 'HAIKAL PUTRA  HABIBIE ALIFA', 'L', 'XI-5', NULL, 1, 0),
(43346605, 192010014, 'HUD JIBRAN AR RASYIQ', 'L', 'XI-5', NULL, 1, 0),
(42291302, 192010150, 'IMAM ARDHIANSYAH', 'L', 'XI-5', NULL, 1, 0),
(40732230, 192010050, 'LAKSAMANA KUMBARA REIGIF', 'L', 'XI-5', NULL, 1, 0),
(48855491, 192010189, 'MUHAMMAD FAKHRI HUSAINI', 'L', 'XI-5', NULL, 1, 0),
(40732233, 192010019, 'MUHAMMAD KANTAQA', 'L', 'XI-5', NULL, 1, 0),
(35033600, 192010123, 'MUHAMMAD RAKA FADLILLAH', 'L', 'XI-5', NULL, 1, 0),
(40693016, 192010089, 'MUTHIA NURAZIZAH', 'P', 'XI-5', NULL, 1, 0),
(33083051, 192010155, 'NADHILAH HANIFFITHRIYAH', 'P', 'XI-5', NULL, 1, 0),
(47026770, 192010156, 'NAJWA KAYLA KUSUMAPUTRI', 'P', 'XI-5', NULL, 1, 0),
(41488359, 41488358, 'NURUL FAUZIAH AGUSTINI', 'P', 'XI-5', NULL, 1, 0),
(45872496, 192010024, 'PUTRI KOMALA DEWI KENCANA SUMIRAT', 'P', 'XI-5', NULL, 1, 0),
(45622686, 192010161, 'RD. LINDA KHAIRUNISA', 'P', 'XI-5', NULL, 1, 0),
(35032294, 192010195, 'REDI HIDAYAT', 'L', 'XI-5', NULL, 1, 0),
(40693640, 192010025, 'REISSYA HAWWA AQILA', 'P', 'XI-5', NULL, 1, 0),
(40694205, 192010060, 'RIFAL NA SUTIAN', 'L', 'XI-5', NULL, 1, 0),
(38472317, 192010200, 'SHAFA AGHNIYA TSURAYYA', 'P', 'XI-5', NULL, 1, 0),
(40694176, 192010201, 'SHIFA SHALSABILA', 'P', 'XI-5', NULL, 1, 0),
(40694764, 192010031, 'SITI SARAH NABILA', 'P', 'XI-5', NULL, 1, 0),
(40692319, 192010032, 'SRI WULAN', 'P', 'XI-5', NULL, 1, 0),
(35056689, 192010101, 'SYAHNUR FAUZI', 'L', 'XI-5', NULL, 1, 0),
(36858948, 192010167, 'SYAHWAL REGINA PUTRI SULAEMAN', 'P', 'XI-5', NULL, 1, 0),
(50391524, 192010033, 'SYNDI SOFIA RISTIANA', 'P', 'XI-5', NULL, 1, 0),
(37053542, 192010034, 'TUTI LATIFAH', 'P', 'XI-5', NULL, 1, 0),
(35033652, 192010068, 'WINA SULISTIAN', 'P', 'XI-5', NULL, 1, 0),
(40693519, 192010004, 'ANANDHA NOVIA ARDHANI', 'P', 'XI-6', NULL, 1, 0),
(38750567, 38750566, 'ANITA MELAWATI', 'p', 'XI-6', NULL, 1, 0),
(41339435, 192010074, 'AURA ZAHRA AMIN', 'P', 'XI-6', NULL, 1, 0),
(11064466, 192010177, 'BILQIS ZAINAB MUJAHIDAH', 'P', 'XI-6', NULL, 1, 0),
(43314597, 192010111, 'DAVINA BELVA FIDELA', 'P', 'XI-6', NULL, 1, 0),
(40692994, 192010144, 'DEDE CAHYADI', 'L', 'XI-6', NULL, 1, 0),
(35033475, 192010045, 'FASYA DINDA OCTAVIA PUTERI', 'P', 'XI-6', NULL, 1, 0),
(37258252, 192010080, 'FITRIA NURAENI', 'P', 'XI-6', NULL, 1, 0),
(40693633, 192010081, 'HADAYA FIKRI NUR AQILLAH', 'L', 'XI-6', NULL, 1, 0),
(46527600, 192010183, 'HAIFA NURJANAH', 'P', 'XI-6', NULL, 1, 0),
(35033594, 192010149, 'HARY SUMITRA WARDANA', 'L', 'XI-6', NULL, 1, 0),
(44469933, 192010184, 'HENDRIYANA PUTRA PAMUNGKAS', 'L', 'XI-6', NULL, 1, 0),
(37053969, 192010049, 'HUSNIAJI', 'L', 'XI-6', NULL, 1, 0),
(35031799, 192010015, 'JAJANG SANJAYA', 'L', 'XI-6', NULL, 1, 0),
(33702205, 192010122, 'MUHAMAD RIFKI ZAELANI', 'L', 'XI-6', NULL, 1, 0),
(36781756, 192010088, 'MUHAMMAD NUR MUDZAKKI', 'L', 'XI-6', NULL, 1, 0),
(40693099, 192010020, 'NADYA KANIA DEWI', 'P', 'XI-6', NULL, 1, 0),
(35031815, 192010055, 'NAURA AMELIA', 'P', 'XI-6', NULL, 1, 0),
(48607826, 192010194, 'PUTRI KARTIKA DEWI', 'P', 'XI-6', NULL, 1, 0),
(35032304, 192010128, 'PUTRI SEPTIANI', 'P', 'XI-6', NULL, 1, 0),
(38472316, 192010094, 'RAMADHAN AL FIKRI', 'L', 'XI-6', NULL, 1, 0),
(36163127, 192010129, 'RAMADHAN SATRIA PRAWIRA', 'L', 'XI-6', NULL, 1, 0),
(44077735, 192010095, 'REZA AULIA RAHMASARI', 'P', 'XI-6', NULL, 1, 0),
(42314146, 192010162, 'RIFQI ZAHRAN MUTAWAKKIL', 'L', 'XI-6', NULL, 1, 0),
(43774805, 192010029, 'RYAN GUNAWAN', 'L', 'XI-6', NULL, 1, 0),
(37487900, 192010133, 'SENIA SARI', 'P', 'XI-6', NULL, 1, 0),
(40693653, 192010064, 'SHAFIRA PRIMAWATI JUNAEDI', 'P', 'XI-6', NULL, 1, 0),
(49922375, 192010134, 'SHINTYA DEWI SHAFARIYAH', 'P', 'XI-6', NULL, 1, 0),
(35753247, 192010065, 'SITI ZAHRAH NURHASANAH', 'P', 'XI-6', NULL, 1, 0),
(40692995, 192010100, 'SUCI RAHMAWATI', 'P', 'XI-6', NULL, 1, 0),
(40694901, 192010066, 'TIARA DITA OKTAVIANI', 'P', 'XI-6', NULL, 1, 0),
(37852039, 192010168, 'TITIN SULASTRI', 'P', 'XI-6', NULL, 1, 0),
(37389498, 192010067, 'VANYA DHIAS RAHADYANNOVA', 'P', 'XI-6', NULL, 1, 0),
(37053587, 192010069, 'YULIANTI AGUSTIN', 'P', 'XI-6', NULL, 1, 0),
(40694974, 192010246, 'ANDRA CHOERUL FACHRURROZI', 'L', 'XI-7', NULL, 1, 0),
(37053661, 192010247, 'ANNISA NUR RAHMAWATI', 'P', 'XI-7', NULL, 1, 0),
(40732244, 192010211, 'AURA AGRARIANA FITRIANI', 'P', 'XI-7', NULL, 1, 0),
(41414047, 192010283, 'AZKA SAPUTRA', 'L', 'XI-7', NULL, 1, 0),
(43742885, 192010249, 'BULAN MAHARANI', 'P', 'XI-7', NULL, 1, 0),
(40694264, 192010284, 'CHIKA TIARA AZ-ZAHRA', 'P', 'XI-7', NULL, 1, 0),
(43061095, 192010319, 'CINDY AULIA', 'P', 'XI-7', NULL, 1, 0),
(46978800, 192010320, 'DEAN NICYA MORENO', 'L', 'XI-7', NULL, 1, 0),
(41577222, 192010212, 'DEDEN AHMAD RIANTO', 'L', 'XI-7', NULL, 1, 0),
(35031821, 192010213, 'DELA SHAFITRI', 'P', 'XI-7', NULL, 1, 0),
(40694727, 192010250, 'DENISA NAURA APRILLIANI', 'P', 'XI-7', NULL, 1, 0),
(40643706, 192010285, 'DIAN SIFA KHAERUNISA', 'P', 'XI-7', NULL, 1, 0),
(31421049, 192010321, 'DIAN SUKRIA RISTIANTI', 'P', 'XI-7', NULL, 1, 0),
(43371287, 192010286, 'DINDA NABILA FEBRIYAN', 'P', 'XI-7', NULL, 1, 0),
(35033109, 192010322, 'DITA PUSPITA', 'P', 'XI-7', NULL, 1, 0),
(40694192, 192010214, 'DZIKRA FATHISYA', 'P', 'XI-7', NULL, 1, 0),
(35032302, 192010323, 'FAISAL HARUN SEPTIANSYAH', 'L', 'XI-7', NULL, 1, 0),
(40692080, 192010324, 'FARIDA DINI AGUSTIN', 'P', 'XI-7', NULL, 1, 0),
(43452184, 192010325, 'GENTA RIANA', 'L', 'XI-7', NULL, 1, 0),
(40694257, 192010269, 'RIFA FADHILA ZAIDAN SAFITRI', 'P', 'XI-7', NULL, 1, 0),
(41290879, 192010270, 'RIKO GANTIRA SEPTIAWAN', 'L', 'XI-7', NULL, 1, 0),
(33523180, 192010271, 'SEFTYANI NURLIS GUSTIAN', 'P', 'XI-7', NULL, 1, 0),
(38508402, 192010272, 'SISKA DESTIA MILANDI', 'P', 'XI-7', NULL, 1, 0),
(48880062, 192010273, 'SITI NURKHOLIFAH', 'P', 'XI-7', NULL, 1, 0),
(35033190, 192010274, 'SKE QIRAKA DINTENRAJA', 'L', 'XI-7', NULL, 1, 0),
(37091302, 192010275, 'SYIFA AWALIAH', 'P', 'XI-7', NULL, 1, 0),
(40693655, 192010276, 'TIARA SETIA WULANDARI', 'P', 'XI-7', NULL, 1, 0),
(35033107, 192010278, 'WILDAN FIRDAUS', 'L', 'XI-7', NULL, 1, 0),
(40376370, 192010241, 'YAYAH KARMILA', 'P', 'XI-7', NULL, 1, 0),
(37894729, 192010311, 'YEN YEN NURLAELA GUNAWAN', 'P', 'XI-7', NULL, 1, 0),
(40694171, 192010312, 'YOGA NUR FATURROHMAN', 'L', 'XI-7', NULL, 1, 0),
(40732287, 192010313, 'ZIHAN LAILA RAMADHANTY', 'P', 'XI-7', NULL, 1, 0),
(40694187, 192010242, 'ZIO WIKAGO', 'L', 'XI-7', NULL, 1, 0),
(35033657, 192010245, 'AMALIA RAHMA DARMAWAN', 'P', 'XI-8', NULL, 1, 0),
(9443702, 192010281, 'ANDRI FADILAH', 'L', 'XI-8', NULL, 1, 0),
(43411395, 192010316, 'ANDRI SETIAWAN', 'L', 'XI-8', NULL, 1, 0),
(48735868, 192010317, 'ANGGI TIEN ROSLYANI', 'P', 'XI-8', NULL, 1, 0),
(44213062, 192010282, 'ARIELLA TALITHA WARDHANI', 'P', 'XI-8', NULL, 1, 0),
(35033599, 192010248, 'AUFAR BILAL FAKHRI', 'L', 'XI-8', NULL, 1, 0),
(40030973, 192010251, 'DILLA NURFADILLAH PERMANA', 'P', 'XI-8', NULL, 1, 0),
(35898234, 192010253, 'ERGIA NASUA RAMADHANI', 'P', 'XI-8', NULL, 1, 0),
(35033601, 192010216, 'FARHAN TAUFIK AL HAKIM', 'L', 'XI-8', NULL, 1, 0),
(35031837, 192010217, 'FITRIA FINDIAWATI', 'P', 'XI-8', NULL, 1, 0),
(37193457, 192010289, 'GIANITA NUR PERMATA SRI', 'P', 'XI-8', NULL, 1, 0),
(43756113, 192010256, 'HASBI REZA APRIANA', 'L', 'XI-8', NULL, 1, 0),
(40732283, 192010328, 'INDRI JULIYANTI SOBANDI', 'P', 'XI-8', NULL, 1, 0),
(35033095, 192010292, 'IVAN SOPIAN', 'L', 'XI-8', NULL, 1, 0),
(40694206, 192010259, 'JESSICA INDRIYANI NABABAN', 'P', 'XI-8', NULL, 1, 0),
(40693092, 192010222, 'JIHAN QONITA', 'P', 'XI-8', NULL, 1, 0),
(43371311, 192010260, 'KARTIKA', 'P', 'XI-8', NULL, 1, 0),
(28256546, 192010224, 'LISNA SITI HOLIYAH', 'P', 'XI-8', NULL, 1, 0),
(43371447, 192010261, 'MEISYA RIA PRATAMA', 'P', 'XI-8', NULL, 1, 0),
(40694202, 192010333, 'MUHAMAD FARHAN ALFARIZY', 'L', 'XI-8', NULL, 1, 0),
(40694666, 192010296, 'MUHAMAD REZA FEBRIAN', 'L', 'XI-8', NULL, 1, 0),
(44858944, 192010225, 'MUHAMMAD ARRY BUDIMAN', 'L', 'XI-8', NULL, 1, 0),
(35361998, 192010298, 'NESTA LITA AGISNA', 'P', 'XI-8', NULL, 1, 0),
(47559802, 192010335, 'NOVITA RAHMADANI NAKUL', 'P', 'XI-8', NULL, 1, 0),
(40694243, 192010299, 'NURDINI HASTIANINGSIH', 'P', 'XI-8', NULL, 1, 0),
(40732284, 192010228, 'PUSPA MUSTIKA', 'P', 'XI-8', NULL, 1, 0),
(40694200, 192010337, 'PUTRI ELIDA MAWAR INDAH', 'P', 'XI-8', NULL, 1, 0),
(35033144, 192010301, 'RAHAYU ABDILLAH', 'P', 'XI-8', NULL, 1, 0),
(43778384, 192010231, 'REVI ALVIRA NURMALASARI', 'P', 'XI-8', NULL, 1, 0),
(35496454, 192010302, 'RICKY SEPTIAN SUTARYANA', 'L', 'XI-8', NULL, 1, 0),
(38472311, 192010232, 'RIFKI ABDILAH AKBAR', 'L', 'XI-8', NULL, 1, 0),
(39840249, 192010341, 'RISMA FADILLA', 'P', 'XI-8', NULL, 1, 0),
(40694186, 192010344, 'SITI KARLINA', 'P', 'XI-8', NULL, 1, 0),
(40694729, 192010345, 'TANJUNG SANDY PUTRA', 'L', 'XI-8', NULL, 1, 0),
(44995759, 192010347, 'VANI NURSYAMSIAH PIRDAYANTI', 'P', 'XI-8', NULL, 1, 0),
(40694733, 192010280, 'AMARA APRILIANI', 'P', 'XI-9', NULL, 1, 0),
(33503885, 192010209, 'ANING FITRI', 'P', 'XI-9', NULL, 1, 0),
(40694184, 192010210, 'ARGYAN MOCHAMAD RIZKY HIDAYAT', 'L', 'XI-9', NULL, 1, 0),
(44995751, 192010318, 'ARINI GINA AFIFAH', 'P', 'XI-9', NULL, 1, 0),
(47856382, 192010287, 'DZIKRILAHI ANBIYA KARTA PUTRA', 'L', 'XI-9', NULL, 1, 0),
(43371299, 192010215, 'ENDANG CITRA', 'P', 'XI-9', NULL, 1, 0),
(35032351, 192010288, 'ERNI AFENTI', 'P', 'XI-9', NULL, 1, 0),
(45232205, 192010254, 'FEBRIANSYAH', 'L', 'XI-9', NULL, 1, 0),
(40693520, 192010255, 'GADISTI NUR MARANTIKA', 'P', 'XI-9', NULL, 1, 0),
(57799676, 192010326, 'GISCHA FATHYA ALIFA DITAATMADJA', 'P', 'XI-9', NULL, 1, 0),
(40694728, 192010327, 'ICHLAS TRINATA NUR', 'L', 'XI-9', NULL, 1, 0),
(40694333, 192010221, 'IVO FARDILLAH ANGGRAENI', 'P', 'XI-9', NULL, 1, 0),
(37233583, 192010329, 'JANNI AGASTYA MADHANI', 'L', 'XI-9', NULL, 1, 0),
(37239757, 192010293, 'JESSICA RIZKI JULIANA', 'P', 'XI-9', NULL, 1, 0),
(45564559, 192010330, 'JIHAN ADIENDA PUTRI', 'P', 'XI-9', NULL, 1, 0),
(35032744, 192010223, 'JUJUN JUNAEDI', 'L', 'XI-9', NULL, 1, 0),
(40693004, 192010294, 'KREZHA PUJAYANTI', 'P', 'XI-9', NULL, 1, 0),
(40694894, 192010331, 'LINGGA DEA AULIA', 'P', 'XI-9', NULL, 1, 0),
(35032741, 192010295, 'MITA MUTIARA RAHAYU', 'P', 'XI-9', NULL, 1, 0),
(41468957, 192010334, 'MUHAMAD THONI BAEHAKI PRATAMA', 'L', 'XI-9', NULL, 1, 0),
(47399757, 192010297, 'MUHAMMAD YASIN FADHILAH', 'L', 'XI-9', NULL, 1, 0),
(42251297, 192010226, 'NADHYA SETYANINGRUM', 'P', 'XI-9', NULL, 1, 0),
(39989424, 192010227, 'NUR FITRI', 'P', 'XI-9', NULL, 1, 0),
(40694181, 192010336, 'PEBI INDRI HERDIANI', 'P', 'XI-9', NULL, 1, 0),
(29533179, 192010300, 'PUTRI AGUSTIEN', 'P', 'XI-9', NULL, 1, 0),
(40030955, 192010229, 'PUTRI INKAN KANIA', 'P', 'XI-9', NULL, 1, 0),
(43556669, 192010230, 'R. ARIA DIVA RISJUNARKO', 'L', 'XI-9', NULL, 1, 0),
(35033098, 192010338, 'RAHESTA ARDHYA PRAMESTI', 'P', 'XI-9', NULL, 1, 0),
(48874681, 192010340, 'RIDWAN MAULANA SIDIK', 'L', 'XI-9', NULL, 1, 0),
(40694721, 192010342, 'RYAN SAPUTRA', 'L', 'XI-9', NULL, 1, 0),
(43797287, 192010343, 'SILVI ERLI NURHAVILAH', 'P', 'XI-9', NULL, 1, 0),
(20041340, 192010346, 'TETI NURPADILAH', 'P', 'XI-9', NULL, 1, 0),
(37452103, 192010348, 'WULAN PUSPITA DEWI', 'P', 'XI-9', NULL, 1, 0),
(40694174, 192010349, 'YOGI CAHYA YOGASWARA', 'L', 'XI-9', NULL, 1, 0),
(37748267, 192010243, 'ADINDA TALYA NABILA', 'P', 'XI-10', NULL, 1, 0),
(48229624, 192010244, 'ADITYA KUSUMAWARDANA', 'L', 'XI-10', NULL, 1, 0),
(43373809, 192010279, 'ADITYA NUGRAHA', 'L', 'XI-10', NULL, 1, 0),
(35033195, 192010314, 'AJI DESTIAN', 'L', 'XI-10', NULL, 1, 0),
(35216683, 192010207, 'ALIFIA FAUZAN', 'L', 'XI-10', NULL, 1, 0),
(40694244, 192010315, 'ALIFIA NOERSHIDDIQ', 'P', 'XI-10', NULL, 1, 0),
(35032616, 192010208, 'ALIN NURHASANAH', 'P', 'XI-10', NULL, 1, 0),
(35753132, 192010252, 'DIMAS HARTANDI', 'L', 'XI-10', NULL, 1, 0),
(35033750, 192010218, 'GILANG PERMANA SIDIQ', 'L', 'XI-10', NULL, 1, 0),
(38472318, 192010219, 'HANIFA AULIA BIRRI', 'P', 'XI-10', NULL, 1, 0),
(35032402, 192010290, 'HATTA UTWUN BILLAH', 'L', 'XI-10', NULL, 1, 0),
(48195663, 192010257, 'HUSNUL PARHANIMULYA', 'P', 'XI-10', NULL, 1, 0),
(44194779, 192010220, 'ICHSAN FADILAH', 'L', 'XI-10', NULL, 1, 0),
(40693702, 192010291, 'INDRI FUJI MEILANI', 'P', 'XI-10', NULL, 1, 0),
(41197541, 192010258, 'IQBAL RIZKI PRATAMA', 'L', 'XI-10', NULL, 1, 0),
(40694245, 192010264, 'NAZWA MAULIDA PUTRI', 'P', 'XI-10', NULL, 1, 0),
(40692325, 192010265, 'NURAENI JUNIAR', 'P', 'XI-10', NULL, 1, 0),
(40732285, 192010266, 'PUSPITA DHAMARWATI ANGGRAENI', 'P', 'XI-10', NULL, 1, 0),
(40694261, 192010267, 'RACHMA ALYA GUSMIARNI', 'P', 'XI-10', NULL, 1, 0),
(34838417, 34838416, 'REGITHA CAHYANI PUTRI', 'P', 'XI-10', NULL, 1, 0),
(44995762, 192010304, 'RIO AHMAD DARMAWAN', 'L', 'XI-10', NULL, 1, 0),
(43774807, 192010234, 'SALSABILLA MAHA PUTRI', 'P', 'XI-10', NULL, 1, 0),
(37913698, 192010305, 'SHERLLY NANDA NURLYANI', 'P', 'XI-10', NULL, 1, 0),
(25514586, 192010235, 'SINTIA SEPTIANI PUTRI', 'P', 'XI-10', NULL, 1, 0),
(43149843, 192010306, 'SITI AMARA DAVAINA', 'P', 'XI-10', NULL, 1, 0),
(44461363, 192010236, 'SITI NUR AZIZAH', 'P', 'XI-10', NULL, 1, 0),
(0, 192010307, 'SRI NANDA NURHALISA', 'P', 'XI-10', NULL, 1, 0),
(40693001, 192010237, 'SUCIANTI SABITA SALSABILA', 'P', 'XI-10', NULL, 1, 0),
(40694188, 192010308, 'SULTAN MAULIDAN\'SYAH', 'L', 'XI-10', NULL, 1, 0),
(33669356, 192010309, 'SYIFA RHAMADANI', 'P', 'XI-10', NULL, 1, 0),
(35032338, 192010238, 'TIA ROSMAWATI', 'P', 'XI-10', NULL, 1, 0),
(40692329, 192010310, 'TRILIANI ALFIRA', 'P', 'XI-10', NULL, 1, 0),
(40694182, 192010240, 'WIDIGUSTI MULYASAJATI', 'L', 'XI-10', NULL, 1, 0),
(30851235, 181910109, 'ADISTY SRI NUROHMAH', 'P', 'XII-1', NULL, 1, 0),
(25416225, 181910073, 'AHMAD HADI NUGRAHA', 'L', 'XII-1', NULL, 1, 0),
(30534104, 181910111, 'ALYA FAHIRA', 'P', 'XII-1', NULL, 1, 0),
(24696949, 181910037, 'ANGGRAENI', 'P', 'XII-1', NULL, 1, 0),
(30434629, 181910075, 'ANNISA NUR APRILIA', 'P', 'XII-1', NULL, 1, 0),
(24697110, 181910116, 'ANNISYA PARASWATI SUTARYAT', 'P', 'XII-1', NULL, 1, 0),
(30434862, 181910117, 'ASYEU ANUGRAH', 'L', 'XII-1', NULL, 1, 0),
(24458137, 181910118, 'AZHAR SALSABILAH', 'P', 'XII-1', NULL, 1, 0),
(23746684, 23746683, 'AZZAHRA AZKA TSAQOFA', 'P', 'XII-1', NULL, 1, 0),
(24697141, 181910120, 'CITRA ADISTI', 'P', 'XII-1', NULL, 1, 0),
(28462793, 181910081, 'DENDY IMAN LESMANA', 'L', 'XII-1', NULL, 1, 0),
(27708008, 181910044, 'DINA APRIYANTI', 'P', 'XII-1', NULL, 1, 0),
(24392084, 181910083, 'DUBY NUR KOMARA', 'L', 'XII-1', NULL, 1, 0),
(33179499, 181910185, 'ELIVARWATI', 'P', 'XII-1', NULL, 1, 0),
(30996597, 181910124, 'FAJAR GUMILAR', 'L', 'XII-1', NULL, 1, 0),
(24817509, 181910154, 'FITRI KAMILIA AZZAHRA', 'P', 'XII-1', NULL, 1, 0),
(24696975, 181910017, 'GUNTUR KUSNAWAN PUTRA', 'L', 'XII-1', NULL, 1, 0),
(24819072, 181910090, 'INDAH LESTARI', 'P', 'XII-1', NULL, 1, 0),
(30851184, 181910158, 'IYYAKA DZAL\'FA PUTRA ADRIS RUHIMAT', 'L', 'XII-1', NULL, 1, 0),
(24391757, 181910193, 'KHARISMA MUNGGARAN PUDJAMASGANTAKA', 'L', 'XII-1', NULL, 1, 0),
(30434458, 181910091, 'LARAS NATALISA', 'P', 'XII-1', NULL, 1, 0),
(24392105, 181910023, 'MILA NURULITA', 'P', 'XII-1', NULL, 1, 0),
(30997932, 181910162, 'NAJLA DIPAKIRANI NABILA', 'P', 'XII-1', NULL, 1, 0),
(24817520, 181910199, 'NUR DEVIANA', 'P', 'XII-1', NULL, 1, 0),
(24697512, 181910166, 'PAULA HELVINA MARGARETHA', 'P', 'XII-1', NULL, 1, 0),
(24392400, 181910200, 'RAHIL AZAHRA', 'P', 'XII-1', NULL, 1, 0),
(24697410, 181910029, 'RENI OKTAVIANI', 'P', 'XII-1', NULL, 1, 0),
(26456980, 181910030, 'RHEZA MEYLA SUNARMA', 'P', 'XII-1', NULL, 1, 0),
(30434927, 181910099, 'RIO DIANDRA', 'L', 'XII-1', NULL, 1, 0);
INSERT INTO `tbl_student` (`NISS`, `NISN`, `fullname`, `gender`, `class`, `photo`, `status`, `counseling`) VALUES
(28583600, 181910100, 'ROQIYUL MA\'ARIP', 'L', 'XII-1', NULL, 1, 0),
(24458258, 181910101, 'SILVIA VALENTINA', 'P', 'XII-1', NULL, 1, 0),
(32071575, 181910207, 'SUCI RAMADHAN SETIAWAN', 'P', 'XII-1', NULL, 1, 0),
(24697402, 181910068, 'TAUFIK GIFARI', 'L', 'XII-1', NULL, 1, 0),
(33179191, 181910069, 'TIWI AINI', 'P', 'XII-1', NULL, 1, 0),
(24458125, 181910071, 'YULAN NAFILAH', 'P', 'XII-1', NULL, 1, 0),
(30693127, 181910035, 'AGUSTINA NABABAN', 'P', 'XII-2', NULL, 1, 0),
(24392092, 181910074, 'AHMAD SYAHRIL AZKA', 'L', 'XII-2', NULL, 1, 0),
(30692871, 181910112, 'AMANDA RETNONINGTYAS', 'P', 'XII-2', NULL, 1, 0),
(33233216, 33233215, 'ANGGARA GUSTIKA', 'L', 'XII-2', NULL, 1, 0),
(28310342, 181910038, 'ANISA NURHAYATI', 'P', 'XII-2', NULL, 1, 0),
(31739525, 181910115, 'ANNISA NURUL FISABILLA HERYADIE PUTRI', 'P', 'XII-2', NULL, 1, 0),
(26291838, 181910180, 'AYDUL FIKRI RAMADHANI', 'L', 'XII-2', NULL, 1, 0),
(30534252, 181910042, 'AZMALIA NATRIANA KHELWA', 'P', 'XII-2', NULL, 1, 0),
(31012338, 181910147, 'DEDE ERNI ERLITA', 'P', 'XII-2', NULL, 1, 0),
(30434765, 181910043, 'DENNI NURDIANSYAH', 'L', 'XII-2', NULL, 1, 0),
(30434452, 181910150, 'DINDA DUPALANTU', 'P', 'XII-2', NULL, 1, 0),
(34293294, 181910084, 'DZIKRI NURFATAH', 'L', 'XII-2', NULL, 1, 0),
(24391761, 181910014, 'ELLA NURHAYATI', 'P', 'XII-2', NULL, 1, 0),
(30996596, 181910187, 'FAJRI FAUZAN AZHARI', 'L', 'XII-2', NULL, 1, 0),
(24391613, 181910016, 'FITRIA WIDIANI', 'P', 'XII-2', NULL, 1, 0),
(24819073, 181910050, 'HAMDAN RODIANSYAH', 'L', 'XII-2', NULL, 1, 0),
(24391695, 181910156, 'INDAH RESTI FAUZI', 'P', 'XII-2', NULL, 1, 0),
(24458309, 181910159, 'LADOVA DAMARA PUTRA', 'L', 'XII-2', NULL, 1, 0),
(30672101, 181910053, 'LESTARY JUNGJUNAN EFFENDY', 'P', 'XII-2', NULL, 1, 0),
(26457017, 181910060, 'NENDEN VERA DEVI ANGGRAENI', 'P', 'XII-2', NULL, 1, 0),
(24392045, 181910164, 'NUR FADILA', 'P', 'XII-2', NULL, 1, 0),
(30851350, 181910062, 'PENI APRIANI', 'P', 'XII-2', NULL, 1, 0),
(30434626, 181910167, 'RAHMA KAMILA', 'P', 'XII-2', NULL, 1, 0),
(27335221, 181910064, 'RESTA SANDRI TANAYA PUTRI', 'P', 'XII-2', NULL, 1, 0),
(24391697, 181910203, 'REZA GUSTOFA', 'L', 'XII-2', NULL, 1, 0),
(24716573, 181910133, 'RIANIVA LAELA PERMANA', 'P', 'XII-2', NULL, 1, 0),
(33014911, 181910205, 'ROBBY ISMAIL FASYA', 'L', 'XII-2', NULL, 1, 0),
(30851341, 181910102, 'SITI NUR KIKI ATIKA', 'P', 'XII-2', NULL, 1, 0),
(27563044, 181910104, 'SULISTRIANI', 'P', 'XII-2', NULL, 1, 0),
(26619577, 181910210, 'VADILLAH NURUL FAJRIN', 'P', 'XII-2', NULL, 1, 0),
(24391845, 181910175, 'WAWAN TARYANA', 'L', 'XII-2', NULL, 1, 0),
(30534387, 181910176, 'YUNI NUR ADILAH', 'P', 'XII-2', NULL, 1, 0),
(24697579, 181910001, 'AI MILA KARMILA', 'P', 'XII-3', NULL, 1, 0),
(30851320, 181910113, 'AMELIA SHINTASUCI', 'P', 'XII-3', NULL, 1, 0),
(30434980, 181910004, 'ANDRE MUHAMMAD RIZKI', 'L', 'XII-3', NULL, 1, 0),
(30850830, 181910114, 'ANISA RAHMA AULIA', 'P', 'XII-3', NULL, 1, 0),
(28310210, 181910143, 'ANNISA SITI NURJANAH', 'P', 'XII-3', NULL, 1, 0),
(32351547, 181910077, 'ARIEL REGINA', 'P', 'XII-3', NULL, 1, 0),
(23348535, 181910011, 'BERLYANA ULIA ARIFIN', 'P', 'XII-3', NULL, 1, 0),
(30434725, 181910012, 'DELLA GESAFHIRA SUDRADJAT', 'P', 'XII-3', NULL, 1, 0),
(24697255, 181910121, 'DEZAN TRIANDI HIDAYAT', 'L', 'XII-3', NULL, 1, 0),
(31945900, 181910045, 'DINI ANISA', 'P', 'XII-3', NULL, 1, 0),
(26456872, 181910085, 'EGI ANDRIAN MULYANA', 'L', 'XII-3', NULL, 1, 0),
(27296711, 181910152, 'ERICKA SINTA NURLAELA', 'P', 'XII-3', NULL, 1, 0),
(30434891, 181910086, 'FAUZAN ALIF NURFIKRI', 'L', 'XII-3', NULL, 1, 0),
(24578790, 181910087, 'HANIFA NABILLA', 'P', 'XII-3', NULL, 1, 0),
(25520558, 181910018, 'HANIP WARMAN RAMDHANI', 'L', 'XII-3', NULL, 1, 0),
(35846038, 181910051, 'INDRIYANI DWI LESTARI', 'P', 'XII-3', NULL, 1, 0),
(25659618, 181910021, 'LILIS ENDAH NURKOMALASARI', 'P', 'XII-3', NULL, 1, 0),
(33323292, 181910092, 'LUCKY NURHIKMATULLOH', 'L', 'XII-3', NULL, 1, 0),
(35361017, 35361016, 'MOHAMAD RIZKY ANUGRAH RAMADHAN', 'L', 'XII-3', NULL, 1, 0),
(35361018, 181910093, 'MUHAMMAD RECKY ALFIRDAUS', 'L', 'XII-3', NULL, 1, 0),
(31621181, 181910195, 'MUTIA NURFADILLAH', 'P', 'XII-3', NULL, 1, 0),
(30434320, 181910197, 'NIDA LATIFAH', 'P', 'XII-3', NULL, 1, 0),
(30434321, 1920, 'NUR AULIA', 'P', 'XII-3', NULL, 1, 0),
(25438585, 181910096, 'NUR RAMANITA DINI', 'P', 'XII-3', NULL, 1, 0),
(39834183, 181910028, 'PRATUDHITA PUTRI PAMBAYUN', 'P', 'XII-3', NULL, 1, 0),
(24485002, 181910201, 'RAHMA NABILLA SUBARNA PUTRI', 'P', 'XII-3', NULL, 1, 0),
(28310232, 181910129, 'REVIANI', 'P', 'XII-3', NULL, 1, 0),
(33932350, 181910169, 'RINANDA SUKMAWATI', 'P', 'XII-3', NULL, 1, 0),
(30434744, 181910171, 'SAIQA FATUR KHAIRI', 'L', 'XII-3', NULL, 1, 0),
(32112649, 181910172, 'SOFA NURFAUJIAH', 'P', 'XII-3', NULL, 1, 0),
(34198693, 181910208, 'SULTAN AULYA RACHMAN', 'L', 'XII-3', NULL, 1, 0),
(30435003, 181910209, 'SYIFA SHOFIYAH ISLAMI', 'P', 'XII-3', NULL, 1, 0),
(24558714, 181910140, 'VENA OKTAVIANI', 'P', 'XII-3', NULL, 1, 0),
(35155445, 181910105, 'WILDAN ANHAR FAUZAN', 'L', 'XII-3', NULL, 1, 0),
(24391601, 181910212, 'YUNI RAHMAWATI', 'P', 'XII-3', NULL, 1, 0),
(32091890, 181910002, 'AI ROHAYATIN', 'P', 'XII-4', NULL, 1, 0),
(32338762, 181910142, 'ANDEANA MAHARANI', 'P', 'XII-4', NULL, 1, 0),
(26456826, 181910005, 'ANGGA ANDIKA LESMANA', 'L', 'XII-4', NULL, 1, 0),
(38978737, 181910178, 'ANISSA TRI LAHITANI', 'P', 'XII-4', NULL, 1, 0),
(26457010, 181910040, 'ANNISA WIDYA', 'P', 'XII-4', NULL, 1, 0),
(30534337, 181910144, 'ASTRIDYA SYAHADA PUTRI HERMAWAN', 'P', 'XII-4', NULL, 1, 0),
(31129559, 181910181, 'CHICI PIDATUNNISA', 'P', 'XII-4', NULL, 1, 0),
(24392113, 181910079, 'DEDEN', 'L', 'XII-4', NULL, 1, 0),
(31507386, 181910013, 'DESTIANA LISTIAWATI', 'P', 'XII-4', NULL, 1, 0),
(38982120, 181910183, 'DHYA MAITSA SABILA WILDAN', 'L', 'XII-4', NULL, 1, 0),
(28310367, 181910184, 'DINI NOVATUROHMAH SUNARYA', 'P', 'XII-4', NULL, 1, 0),
(30434428, 181910123, 'ERLANGGA PUTRA PAMUNGKAS HENDRAYANA', 'L', 'XII-4', NULL, 1, 0),
(27295646, 181910047, 'ERRLY APRILINA', 'P', 'XII-4', NULL, 1, 0),
(32132879, 181910153, 'FAJAR KAMALLUL IKHSAN', 'L', 'XII-4', NULL, 1, 0),
(28310389, 181910126, 'FITRI RIZKY LISDIADI', 'L', 'XII-4', NULL, 1, 0),
(40030970, 181910019, 'HANNAZA FEBI YUNALDI', 'P', 'XII-4', NULL, 1, 0),
(24391998, 181910089, 'IHSANUDDIN AKBAR', 'L', 'XII-4', NULL, 1, 0),
(35155473, 181910020, 'INSANI NUR MAJIIDA', 'P', 'XII-4', NULL, 1, 0),
(29695617, 181910055, 'MOH. FAUZIE RACHMAN SETIAHADI', 'L', 'XII-4', NULL, 1, 0),
(35567837, 181910094, 'MUHAMMAD RIDWAN RIZKY ANUGERAH PRAYANA', 'L', 'XII-4', NULL, 1, 0),
(30652309, 30652308, 'MUHAMMAD RIZQI AGUNG NURKAYA', 'L', 'XII-4', NULL, 1, 0),
(35155335, 181910198, 'NINA ROSALINA', 'P', 'XII-4', NULL, 1, 0),
(28310340, 181910061, 'NURHOLIS SAADAH', 'P', 'XII-4', NULL, 1, 0),
(33032925, 181910063, 'PUTRI AGLEN ANGGRAENI', 'P', 'XII-4', NULL, 1, 0),
(26456939, 181910168, 'RAHMAWATI MAMONTO', 'P', 'XII-4', NULL, 1, 0),
(30434361, 181910130, 'REYNATE FIRYAL', 'P', 'XII-4', NULL, 1, 0),
(26456883, 181910170, 'RINRIN ALVA ARIELLA', 'P', 'XII-4', NULL, 1, 0),
(30851041, 181910135, 'SALSABILA DIAZ FATHIYAH', 'P', 'XII-4', NULL, 1, 0),
(30434686, 181910066, 'SATRIA ARYA DHEEVA', 'L', 'XII-4', NULL, 1, 0),
(25197289, 181910173, 'SOPHIA KHOERUNNISA', 'P', 'XII-4', NULL, 1, 0),
(26457015, 181910174, 'THALISA REVINA HENDRAYAN', 'P', 'XII-4', NULL, 1, 0),
(30851027, 181910070, 'WINDY DIKA LESTARI', 'P', 'XII-4', NULL, 1, 0),
(24392061, 181910106, 'YUDHA NUR FAUZAN', 'L', 'XII-4', NULL, 1, 0),
(30434427, 181910034, 'YUNITA AGUSTIANI', 'P', 'XII-4', NULL, 1, 0),
(30434422, 181910003, 'AJENG MUSTIKA AYU', 'P', 'XII-5', NULL, 1, 0),
(30910200, 181910036, 'ANGGA GUMELAR', 'L', 'XII-5', NULL, 1, 0),
(34061289, 181910006, 'ANGGI NABILLA SURYANI', 'P', 'XII-5', NULL, 1, 0),
(28310262, 181910008, 'ANITA NURMALA', 'P', 'XII-5', NULL, 1, 0),
(31684338, 181910009, 'ANNISYA HAENUR RAHMAH', 'P', 'XII-5', NULL, 1, 0),
(24458110, 181910010, 'AULIYA SYAWALANY PUTRI', 'P', 'XII-5', NULL, 1, 0),
(36785355, 181910078, 'CHINTYA DWI AJENG HASNA FAUZIAH', 'P', 'XII-5', NULL, 1, 0),
(28310407, 181910080, 'DENDI WAHYU RENALDI', 'L', 'XII-5', NULL, 1, 0),
(28310365, 181910182, 'DEWI SEPTIA', 'P', 'XII-5', NULL, 1, 0),
(25244317, 181910082, 'DICKY ANGGARA PERMANA', 'L', 'XII-5', NULL, 1, 0),
(33014812, 181910046, 'DINI PUTRI MEILANI', 'P', 'XII-5', NULL, 1, 0),
(24458242, 181910186, 'FADLY RAHMAT ROSYADA', 'L', 'XII-5', NULL, 1, 0),
(35747932, 181910015, 'FENNY MAHARANI', 'P', 'XII-5', NULL, 1, 0),
(30850904, 181910049, 'GILANG KOMARA', 'L', 'XII-5', NULL, 1, 0),
(24558702, 181910189, 'HAWDHIYA KAYLA PRADINA ZAHRA', 'P', 'XII-5', NULL, 1, 0),
(30434345, 181910155, 'HAYKAL INDRA PERKASA ANUGRAH S.', 'L', 'XII-5', NULL, 1, 0),
(30434728, 181910191, 'INTAN ROSDIANA', 'P', 'XII-5', NULL, 1, 0),
(22667281, 181910192, 'IQBAL CHENDRIAWAN', 'L', 'XII-5', NULL, 1, 0),
(24890193, 181910022, 'MELANI MUSTIKA SARI', 'P', 'XII-5', NULL, 1, 0),
(32294894, 181910194, 'MOHAMAD RICO PRIBAWAN WIBISONO', 'L', 'XII-5', NULL, 1, 0),
(28864648, 181910095, 'MUHAMMAD VIRGYAWAN', 'L', 'XII-5', NULL, 1, 0),
(32321371, 181910059, 'NADYA DWI PRAMESTI', 'P', 'XII-5', NULL, 1, 0),
(30434714, 181910026, 'NISA NUR ERNI', 'P', 'XII-5', NULL, 1, 0),
(30434780, 181910027, 'NURUL AWANIS', 'P', 'XII-5', NULL, 1, 0),
(30434413, 181910127, 'PUTRI MAHARANI', 'P', 'XII-5', NULL, 1, 0),
(30434275, 181910202, 'RANI ANGGRAENI', 'P', 'XII-5', NULL, 1, 0),
(30434349, 181910131, 'RHEVATA ANANDA PUTRI', 'P', 'XII-5', NULL, 1, 0),
(30434941, 181910204, 'RISNA MELIANDA', 'P', 'XII-5', NULL, 1, 0),
(47513596, 181910031, 'SESILIA INDAH SABILA', 'P', 'XII-5', NULL, 1, 0),
(21281778, 181910067, 'SHADIQ MUBARAK GUNAWAN', 'L', 'XII-5', NULL, 1, 0),
(31630908, 181910103, 'SRI DEWI APRILIANI', 'P', 'XII-5', NULL, 1, 0),
(28310344, 181910032, 'TIA ELIANA PUTRI', 'P', 'XII-5', NULL, 1, 0),
(24697392, 181910211, 'WITA MEILASARY', 'P', 'XII-5', NULL, 1, 0),
(24697062, 181910107, 'YUDI HERMANSYAH', 'L', 'XII-5', NULL, 1, 0),
(32059098, 181910177, 'YURIKA NUR ANNISA', 'P', 'XII-5', NULL, 1, 0),
(30851242, 181910108, 'A. IKBAL KHOIRULLOH', 'L', 'XII-6', NULL, 1, 0),
(24578921, 181910072, 'ADELIA OCTAVIANI RAHADIAN', 'P', 'XII-6', NULL, 1, 0),
(30534336, 181910110, 'ALVIANA INDRIYANI SURACHMAN', 'P', 'XII-6', NULL, 1, 0),
(28648280, 181910007, 'ANGGI SEPTIANI', 'P', 'XII-6', NULL, 1, 0),
(35411003, 181910039, 'ANNISA FITRI WIDIESTA', 'P', 'XII-6', NULL, 1, 0),
(24391997, 181910076, 'ANNISYA NUR RIZKY', 'P', 'XII-6', NULL, 1, 0),
(25293449, 181910179, 'ARI ABDUL MUGHNI', 'L', 'XII-6', NULL, 1, 0),
(34202087, 181910145, 'AYU LESTARI', 'P', 'XII-6', NULL, 1, 0),
(30434863, 181910146, 'CILVIANIAR HASMANITA', 'P', 'XII-6', NULL, 1, 0),
(30534160, 181910148, 'DENDRY SUARGANA SUTISNA', 'L', 'XII-6', NULL, 1, 0),
(24392015, 181910149, 'DHIVA TANIA LUTHFIANIE', 'P', 'XII-6', NULL, 1, 0),
(24458109, 181910151, 'DIVA PRAMUDYA PUTRI PRATIWI', 'L', 'XII-6', NULL, 1, 0),
(30851241, 181910122, 'DWI IMELDA TALIA', 'P', 'XII-6', NULL, 1, 0),
(24391731, 181910048, 'FAISAL NUGRAHA', 'L', 'XII-6', NULL, 1, 0),
(24697108, 181910125, 'FITRI HANDAYANI', 'P', 'XII-6', NULL, 1, 0),
(30434736, 181910088, 'GILANG PERMANA', 'L', 'XII-6', NULL, 1, 0),
(32054533, 181910190, 'ILMA NURUL AULIA', 'P', 'XII-6', NULL, 1, 0),
(30434289, 181910052, 'IRMA RAHAYU', 'P', 'XII-6', NULL, 1, 0),
(24697396, 181910157, 'IVAN FATURAHMAN', 'L', 'XII-6', NULL, 1, 0),
(40210164, 181910056, 'MELSA BERLIANA HERAWATI', 'P', 'XII-6', NULL, 1, 0),
(27828313, 181910024, 'MOHAMMAD RIZKY NURYAMIHARJA', 'L', 'XII-6', NULL, 1, 0),
(30434978, 181910161, 'NAHDA MUFIDA DIYATI', 'P', 'XII-6', NULL, 1, 0),
(34110888, 181910163, 'NUR CANTIKA UTAMI', 'P', 'XII-6', NULL, 1, 0),
(28310206, 181910165, 'OKTAVIA DRUPADA', 'P', 'XII-6', NULL, 1, 0),
(31831380, 181910097, 'PANCAMUKTI FAJAR PRAKOSO', 'L', 'XII-6', NULL, 1, 0),
(26456814, 181910128, 'PUTRI SANIA SALWA KUSUMAWARDANI', 'P', 'XII-6', NULL, 1, 0),
(24391979, 181910098, 'RANIA SALSABILA', 'P', 'XII-6', NULL, 1, 0),
(30434348, 181910132, 'RHEVITA ANINDYA PUTRI', 'P', 'XII-6', NULL, 1, 0),
(30434888, 181910065, 'RISSA ISMAYA', 'P', 'XII-6', NULL, 1, 0),
(30434346, 181910136, 'SHINTA NUR ISMAYA', 'P', 'XII-6', NULL, 1, 0),
(25310942, 181910137, 'SONI RAGIL KRISTOFER', 'L', 'XII-6', NULL, 1, 0),
(24716638, 181910138, 'SUCI HERDIANTI IRAWAN', 'P', 'XII-6', NULL, 1, 0),
(30434699, 181910139, 'TIAN FITRIYANI', 'P', 'XII-6', NULL, 1, 0),
(30850806, 181910033, 'YENI ROSA DAMAYANTI', 'P', 'XII-6', NULL, 1, 0),
(30534232, 181910141, 'ZAHRA AULIA FATIMAH', 'P', 'XII-6', NULL, 1, 0),
(22868673, 181910249, 'ANISA APRIANA NABABAN', 'P', 'XII-7', NULL, 1, 0),
(30434784, 181910214, 'ARI GUNAWAN', 'L', 'XII-7', NULL, 1, 0),
(30434621, 30434620, 'AUDY VIOLAN AULVIAN', 'L', 'XII-7', NULL, 1, 0),
(30434390, 181910316, 'CHELSEA FELLMA CAHAYA PUTRI', 'P', 'XII-7', NULL, 1, 0),
(35155355, 181910215, 'CICI SUMIATI', 'P', 'XII-7', NULL, 1, 0),
(30434397, 181910318, 'DHIMAS RAHARDIAN WIDIARTO', 'L', 'XII-7', NULL, 1, 0),
(24392017, 181910253, 'DINI JULIANI', 'P', 'XII-7', NULL, 1, 0),
(20494189, 181910217, 'FARHAN MUBAROK', 'L', 'XII-7', NULL, 1, 0),
(30434730, 181910320, 'FARIDA ZAHRA ARINDRA', 'P', 'XII-7', NULL, 1, 0),
(24697183, 181910257, 'FATHIA SYIFA FARHANI', 'P', 'XII-7', NULL, 1, 0),
(40030952, 181910323, 'HIDAYA HILMI ARISTAWIDYA', 'P', 'XII-7', NULL, 1, 0),
(24391911, 181910261, 'LILIYANASARI INDRAYANA', 'P', 'XII-7', NULL, 1, 0),
(30434308, 181910294, 'MEILANI NUR FAUZIAH', 'P', 'XII-7', NULL, 1, 0),
(23467293, 181910225, 'MISBACHHUDDIN ROISYULLWATTON', 'L', 'XII-7', NULL, 1, 0),
(31623841, 181910327, 'MOCH. HIKMAL AL FARIZI', 'L', 'XII-7', NULL, 1, 0),
(30434392, 181910227, 'MUHAMMAD FAISHAL FATURROHMAN', 'L', 'XII-7', NULL, 1, 0),
(39149835, 181910297, 'NABILA JULIANTIKA PUTRI', 'P', 'XII-7', NULL, 1, 0),
(24391898, 181910329, 'PERGIWA JAYANTI WIDI UTAMI', 'P', 'XII-7', NULL, 1, 0),
(30434634, 181910232, 'PUTRI DIAN PURNAMA', 'P', 'XII-7', NULL, 1, 0),
(35155526, 181910269, 'PUTRI NUR AZIZAH RAHMAWATI', 'P', 'XII-7', NULL, 1, 0),
(24391927, 181910233, 'RANI AINI', 'P', 'XII-7', NULL, 1, 0),
(37123924, 181910272, 'RENDY BAGAS', 'L', 'XII-7', NULL, 1, 0),
(30434672, 181910334, 'RIMBA SUHERMAWAN', 'L', 'XII-7', NULL, 1, 0),
(30434719, 181910335, 'RINA AYU MAHARANI', 'P', 'XII-7', NULL, 1, 0),
(24391910, 181910336, 'RITA RAHMAWATI', 'P', 'XII-7', NULL, 1, 0),
(26456819, 181910337, 'RIYAN AGUSTIANSYAH', 'L', 'XII-7', NULL, 1, 0),
(24391773, 181910274, 'SELPINA INTANI', 'P', 'XII-7', NULL, 1, 0),
(24945848, 181910276, 'SITI RAHMAH NURAENI', 'P', 'XII-7', NULL, 1, 0),
(24391937, 181910306, 'SUCI MAULIDDINA', 'P', 'XII-7', NULL, 1, 0),
(40039484, 181910308, 'TANIA PUTRI NADILA', 'P', 'XII-7', NULL, 1, 0),
(24697266, 181910240, 'TRIANA NOVIANTY', 'P', 'XII-7', NULL, 1, 0),
(24391700, 181910242, 'WIDI SEPTIADI', 'L', 'XII-7', NULL, 1, 0),
(24391751, 181910245, 'YAYANG DIAN SETYA', 'L', 'XII-7', NULL, 1, 0),
(30434638, 181910312, 'ALFI AHMAD PRATAMA', 'L', 'XII-8', NULL, 1, 0),
(30434954, 181910213, 'ANDI SOPIAN', 'L', 'XII-8', NULL, 1, 0),
(24697344, 181910250, 'ANNISA BARKAH', 'P', 'XII-8', NULL, 1, 0),
(24391739, 181910252, 'DEDE REZA HERDIANA', 'L', 'XII-8', NULL, 1, 0),
(30658757, 181910317, 'DEWI NURA\'ENI GUNAWAN', 'L', 'XII-8', NULL, 1, 0),
(24391725, 181910285, 'DIKI LESMANA', 'L', 'XII-8', NULL, 1, 0),
(35406169, 181910286, 'ELI YULIANA', 'P', 'XII-8', NULL, 1, 0),
(30434350, 181910256, 'FARIDAH', 'P', 'XII-8', NULL, 1, 0),
(30434287, 181910288, 'FITRI NURJANAH', 'P', 'XII-8', NULL, 1, 0),
(26175010, 181910322, 'HANA NUR AINI', 'P', 'XII-8', NULL, 1, 0),
(25293476, 181910290, 'IDA WIDIAWATI', 'P', 'XII-8', NULL, 1, 0),
(26630710, 181910291, 'IIS RISKA MULYANI', 'P', 'XII-8', NULL, 1, 0),
(32709463, 181910220, 'IMAS SUSILAWATI', 'P', 'XII-8', NULL, 1, 0),
(30434394, 181910292, 'IMEY PUJI NIRWANA', 'P', 'XII-8', NULL, 1, 0),
(30434637, 181910222, 'LEONARDO SEIRERA SIRINGO RINGO', 'L', 'XII-8', NULL, 1, 0),
(24697488, 181910295, 'MELISA FARIDAH', 'P', 'XII-8', NULL, 1, 0),
(36961269, 181910226, 'MUHAMMAD ADIB ABDULFAQIH', 'L', 'XII-8', NULL, 1, 0),
(33014922, 181910328, 'MUHAMMAD BENTAR R ROYYAS FADHALAH', 'L', 'XII-8', NULL, 1, 0),
(30434311, 181910263, 'NABILAH NUR AZIZAH', 'P', 'XII-8', NULL, 1, 0),
(30434429, 181910230, 'NURFADILAH', 'P', 'XII-8', NULL, 1, 0),
(25654423, 181910266, 'NURMALASARI', 'P', 'XII-8', NULL, 1, 0),
(38587766, 181910271, 'RATIH SRI RAHAYU', 'P', 'XII-8', NULL, 1, 0),
(30851232, 181910332, 'RENNI NURHALISA AMELIA', 'P', 'XII-8', NULL, 1, 0),
(33014923, 181910235, 'SAHDA DINAH SABRINA', 'P', 'XII-8', NULL, 1, 0),
(33014935, 181910278, 'SYAHRUL NUR RIZKI', 'L', 'XII-8', NULL, 1, 0),
(24697331, 181910339, 'SYIFA APRILLIA SUDIANA', 'P', 'XII-8', NULL, 1, 0),
(30850711, 181910279, 'TASYA SALSABILA DARMAWAN', 'P', 'XII-8', NULL, 1, 0),
(30434288, 181910310, 'ULSAN YULIA', 'P', 'XII-8', NULL, 1, 0),
(35515264, 181910311, 'WIDYA RAHMA LIZARNI', 'P', 'XII-8', NULL, 1, 0),
(28310346, 181910345, 'YULIA SITI FATONAH NURCHOER', 'L', 'XII-8', NULL, 1, 0),
(26818921, 26818920, 'ZAHRA PUTRI NABILAH', 'P', 'XII-8', NULL, 1, 0),
(30658023, 181910246, 'ZAMIE LAUREN', 'L', 'XII-8', NULL, 1, 0),
(30434741, 181910247, 'ABDILLAH ZAIDAN GUNAWAN', 'L', 'XII-9', NULL, 1, 0),
(36538888, 181910280, 'ADILLA RAHMA DIANISA', 'P', 'XII-9', NULL, 1, 0),
(24697268, 181910314, 'ANANDA UAIS ALKORNI', 'L', 'XII-9', NULL, 1, 0),
(30434388, 181910281, 'ANISHA RAHMA WATIE', 'P', 'XII-9', NULL, 1, 0),
(24697574, 181910283, 'AZHAR SURYA FADHILLAH', 'L', 'XII-9', NULL, 1, 0),
(24391779, 181910251, 'DEA NUR RAHMAWATI', 'P', 'XII-9', NULL, 1, 0),
(27826428, 181910319, 'DIKI RAMDANI', 'L', 'XII-9', NULL, 1, 0),
(30434983, 181910287, 'FIRNA NAHWA FIRDAUSI', 'P', 'XII-9', NULL, 1, 0),
(24476477, 181910321, 'FITRA DANDI MAYO', 'L', 'XII-9', NULL, 1, 0),
(28102668, 181910258, 'GHIANI NOVIANTI', 'P', 'XII-9', NULL, 1, 0),
(24558658, 181910289, 'HERLINA ENZELIKA PASARIBU', 'P', 'XII-9', NULL, 1, 0),
(39968793, 181910259, 'INTAN NURMALA FAIRUZYAH', 'P', 'XII-9', NULL, 1, 0),
(24391931, 181910326, 'MAHESA DWI PUTRA', 'L', 'XII-9', NULL, 1, 0),
(24697332, 181910223, 'MAULADY RAHMAN', 'L', 'XII-9', NULL, 1, 0),
(40030949, 181910296, 'MUHAMMAD RIZKY', 'L', 'XII-9', NULL, 1, 0),
(32143371, 181910229, 'NENG SUSI SOFIAH', 'P', 'XII-9', NULL, 1, 0),
(21240315, 181910265, 'NUR PAULINDA', 'P', 'XII-9', NULL, 1, 0),
(32091323, 181910267, 'OKTI HERAWATI', 'P', 'XII-9', NULL, 1, 0),
(30693122, 181910300, 'PUTRI HARIANI SIREGAR', 'P', 'XII-9', NULL, 1, 0),
(24391948, 181910331, 'RENDI OKTORA', 'L', 'XII-9', NULL, 1, 0),
(24697094, 181910234, 'RHAKHEAN KANDIAS', 'L', 'XII-9', NULL, 1, 0),
(22727629, 181910303, 'RITA SULASWATI', 'P', 'XII-9', NULL, 1, 0),
(21227564, 181910236, 'SENDI SETIANA', 'L', 'XII-9', NULL, 1, 0),
(30434614, 181910305, 'SHERINA BIRLIAN YANUAR', 'P', 'XII-9', NULL, 1, 0),
(30434694, 181910237, 'SITI YULIANI UTAMI PUTRI', 'P', 'XII-9', NULL, 1, 0),
(30434661, 181910238, 'SONA SONIA NURFADILAH', 'P', 'XII-9', NULL, 1, 0),
(35155452, 181910277, 'SRI WAHYUNI FAUZIAH', 'P', 'XII-9', NULL, 1, 0),
(26456928, 181910340, 'TIANITA FITRI LIANTO', 'P', 'XII-9', NULL, 1, 0),
(30434636, 181910341, 'TIRAYANTI', 'P', 'XII-9', NULL, 1, 0),
(27130320, 181910241, 'VENY SEVIANTY', 'P', 'XII-9', NULL, 1, 0),
(37114090, 181910342, 'WIDYA PARAMITA', 'P', 'XII-9', NULL, 1, 0),
(30850938, 181910346, 'ZENDRA PUJA HERA ASMARA', 'L', 'XII-9', NULL, 1, 0),
(24578918, 181910313, 'ALGIE RAHMAWAN HIDAYAT', 'L', 'XII-10', NULL, 1, 0),
(30850986, 181910248, 'AMEL LIA PUTRI', 'P', 'XII-10', NULL, 1, 0),
(31634309, 181910282, 'ANNISA AGUSTINA', 'P', 'XII-10', NULL, 1, 0),
(24391623, 181910315, 'ARIF BUDIANSYAH', 'L', 'XII-10', NULL, 1, 0),
(28568388, 181910284, 'DESY FITRIANI', 'P', 'XII-10', NULL, 1, 0),
(24391977, 181910216, 'DINI SAHNUR', 'P', 'XII-10', NULL, 1, 0),
(24696998, 181910254, 'DINI ZAHARA', 'P', 'XII-10', NULL, 1, 0),
(30434635, 181910219, 'HAMZAH', 'L', 'XII-10', NULL, 1, 0),
(30434979, 181910324, 'HILDA ASHYA IMANIAR', 'P', 'XII-10', NULL, 1, 0),
(33014937, 181910221, 'K. FAJAR AZIZ RAMADHAN', 'L', 'XII-10', NULL, 1, 0),
(30658182, 181910293, 'KARTIKA PURNAMA DEWI', 'P', 'XII-10', NULL, 1, 0),
(30851038, 181910260, 'LAURA RAMDANI', 'P', 'XII-10', NULL, 1, 0),
(34754358, 181910325, 'LUTHFI FADHIIL ROIHANSYAH', 'L', 'XII-10', NULL, 1, 0),
(30434774, 181910262, 'MIRA MEILANI', 'P', 'XII-10', NULL, 1, 0),
(30434362, 181910224, 'MIRA PUTRI HAYATI', 'P', 'XII-10', NULL, 1, 0),
(30434731, 181910228, 'MUHAMMAD NASRUL FALAH', 'L', 'XII-10', NULL, 1, 0),
(24697464, 181910298, 'NOVA SOPIA', 'P', 'XII-10', NULL, 1, 0),
(30434640, 181910299, 'NOVITA ANDINI', 'P', 'XII-10', NULL, 1, 0),
(30434351, 181910231, 'PAHRIZAL HIDAYAT', 'L', 'XII-10', NULL, 1, 0),
(28468556, 181910268, 'PURI NURDIANTI', 'P', 'XII-10', NULL, 1, 0),
(24391740, 181910301, 'RAHADIAN SUGIHBANDANA', 'L', 'XII-10', NULL, 1, 0),
(30434718, 181910270, 'RANI AYU MAHARANI', 'P', 'XII-10', NULL, 1, 0),
(30435022, 181910330, 'RELLIAWAN', 'L', 'XII-10', NULL, 1, 0),
(30434612, 181910333, 'RIJQI SUCIPTO PRATAMA', 'L', 'XII-10', NULL, 1, 0),
(22363906, 181910338, 'SAIDAH FITRI PURNAMA', 'P', 'XII-10', NULL, 1, 0),
(31878577, 181910304, 'SHAKILA ADELIA SAFITR', 'P', 'XII-10', NULL, 1, 0),
(30434953, 181910275, 'SIBI RIBIAN', 'P', 'XII-10', NULL, 1, 0),
(30851332, 181910307, 'SURATMAN MULYADI', 'L', 'XII-10', NULL, 1, 0),
(37791139, 181910239, 'TESA SRI RAHAYU', 'P', 'XII-10', NULL, 1, 0),
(34085944, 181910309, 'TITA AULIA', 'P', 'XII-10', NULL, 1, 0),
(24392025, 181910343, 'WILDAN RAMADAN', 'L', 'XII-10', NULL, 1, 0),
(33014900, 181910344, 'WINDA HERLINA', 'P', 'XII-10', NULL, 1, 0),
(24697262, 181910244, 'YASHINTA AUDREYA BUDIMAN', 'P', 'XII-10', NULL, 1, 0);

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
,`NISS` bigint(20)
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
,`NISS` bigint(20)
,`NISN` bigint(20)
,`student_name` varchar(40)
,`counseling` tinyint(4)
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

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_reportViolation`  AS SELECT `report`.`date` AS `date`, `student`.`NISS` AS `NISS`, `student`.`NISN` AS `NISN`, `student`.`fullname` AS `student_name`, `student`.`counseling` AS `counseling`, `criteria`.`name` AS `criteria_name`, `criteria`.`weight` AS `weight`, `reporter`.`homeroom_teacher` AS `reporter_teacher`, `homeroom`.`homeroom_teacher` AS `confirmation_teacher` FROM (((((select `tbl_reporting`.`id` AS `id`,`tbl_reporting`.`id_behavior` AS `id_behavior`,`tbl_reporting`.`type` AS `type`,`tbl_reporting`.`NISS` AS `NISS`,`tbl_reporting`.`id_reporter` AS `id_reporter`,`tbl_reporting`.`id_confirmation` AS `id_confirmation`,`tbl_reporting`.`message` AS `message`,`tbl_reporting`.`date` AS `date` from `tbl_reporting` where `tbl_reporting`.`type` = 'violation') `report` join `tbl_student` `student` on(`report`.`NISS` = `student`.`NISS`)) join (select `tbl_criteria`.`id` AS `id`,`tbl_criteria`.`name` AS `name`,`tbl_criteria`.`type` AS `type`,`tbl_criteria`.`weight` AS `weight` from `tbl_criteria` where `tbl_criteria`.`type` = 'violation') `criteria` on(`report`.`id_behavior` = `criteria`.`id`)) join `tbl_teacher` `reporter` on(`report`.`id_reporter` = `reporter`.`NIP`)) join `tbl_teacher` `homeroom` on(`report`.`id_confirmation` = `homeroom`.`NIP`)) ;

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
-- Indexes for table `tbl_teacher`
--
ALTER TABLE `tbl_teacher`
  ADD PRIMARY KEY (`NIP`),
  ADD KEY `class` (`class`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
