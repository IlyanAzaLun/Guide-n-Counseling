SELECT 
	 report.date
      , student.NISS
      , student.NISN
      , student.fullname student_name
      , criteria.name criteria_name
      , criteria.weight
      , reporter.homeroom_teacher reporter_teacher
      , homeroom.homeroom_teacher confirmation_teacher
FROM ( SELECT * 
       FROM tbl_reporting 
       WHERE tbl_reporting.type = 'violation') report
JOIN tbl_student student ON report.NISS = student.NISS
JOIN ( SELECT * 
       FROM tbl_criteria 
       WHERE tbl_criteria.type = 'violation') criteria 
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
                   AND criteria.type = 'violation'
============================================================================================


============================================================================================
CREATE TABLE tbl_reporting(id int(11), id_criteria int(11), id_student int(11));
INSERT INTO tbl_reporting VALUE 
								(1,2,3),
								(2,1,2),
								(3,1,1),
								(4,2,2),
								(5,1,1);

CREATE TABLE tbl_criteria(id int(11), name varchar(11), weight int(11));
INSERT INTO tbl_criteria VALUE
								(1, 'worrying', 3),
								(2, 'naughty', 2),
								(3, 'usually', 2),
								(4, 'good', 1),
								(5, 'obey', 1);

CREATE TABLE tbl_student(id int(11), name varchar(11));
INSERT INTO tbl_student VALUE	
								(1,'Nina'),
								(2,'Adam'),
								(3,'Dodi'),
								(4,'Zarah'),
								(5,'Udep');


tbl_reporting                          		tbl_criteria                   tbl_student
|===============================|			|========================|     |===============|
| id | id_criteria | id_student |			| id |   name    |weight |     | id |   name   |
|===============================|           |========================|     |===============|
| 1  |     2       |	  3		|           |  1 | worrying  |  3    |     | 1  | Nina	   |
| 2  |     1       |	  2		|           |  2 | naughty   |  2    |     | 2  | Adam	   |
| 3  |     1       |	  1		|           |  3 | usually   |  2    |     | 3  | Dodi	   |
| 4  |     2       |	  2		|           |  4 | good      |  1    |     | 4  | Zarah	   |
| 5  |     1       |	  1		|           |  5 | obey      |  1    |     | 5  | Udep	   |


result
| id | student_name   | criteria_name | weight |
|==============================================|
| 1  | Dodi	  		  |    naughty    |   2	   |
| 2  | Adam	  		  |    worrying   |   3	   |
| 3  | Nina	  		  |    worrying   |   3	   |
| 4  | Adam	  		  |    naughty    |   2	   |
| 5  | Nina	  		  |    worrying   |   3	   |
|NULL| Zarah		  |      NULL     |   0    |    
|NULL| Udep	  		  |      NULL     |   0    |    
|NULL| NULL	  		  |     usualy    |   0    |    
|NULL| NULL	  		  |      good     |   0    |    
|NULL| NULL	  		  |      obey     |   0    |


