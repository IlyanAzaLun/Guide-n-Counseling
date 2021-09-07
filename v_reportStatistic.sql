SELECT 
      report.date
      , student.class
      , criteria.weight
      , report.type
FROM (SELECT * FROM tbl_reporting WHERE tbl_reporting.type != 'tolerance') report
JOIN tbl_student student ON report.NISS = student.NISS
JOIN ( SELECT * 
       FROM tbl_criteria 
       WHERE tbl_criteria.type != 'tolerance') criteria 
      ON report.id_behavior = criteria.id
JOIN tbl_teacher reporter ON report.id_reporter = reporter.NIP
JOIN tbl_teacher homeroom ON report.id_confirmation = homeroom.NIP
UNION ALL
SELECT NULL, student.class, 0, NULL
FROM tbl_student student
WHERE NOT EXISTS ( SELECT NULL
                   FROM tbl_reporting report
                   WHERE report.NISS = student.NISS )

UNION ALL
SELECT NULL, NULL,  0, NULL
FROM tbl_criteria criteria
WHERE NOT EXISTS ( SELECT NULL
                   FROM tbl_reporting report
                   WHERE report.id_behavior = criteria.id)
                   AND criteria.type != 'tolerance'