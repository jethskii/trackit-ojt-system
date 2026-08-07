const express = require('express');
const pool = require('../db');
const { requireInstructorAuth } = require('../middleware/instructorAuth');

const router = express.Router();
router.use(requireInstructorAuth);

router.get('/', async (req, res) => {
  try {
    const instructorResult = await pool.query('SELECT name FROM advisers WHERE id = $1', [
      req.instructorId,
    ]);
    if (instructorResult.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Instructor not found.' });
    }
    const instructorName = instructorResult.rows[0].name;

    const studentsResult = await pool.query(
      `SELECT s.id, s.course, s.section, s.required_hours
       FROM students s
       JOIN student_profiles sp ON sp.student_id = s.id
       WHERE sp.adviser_id = $1`,
      [req.instructorId],
    );
    const students = studentsResult.rows;
    const programs = [...new Set(students.map((s) => s.course))];
    const sections = [...new Set(students.map((s) => s.section))];

    if (students.length === 0) {
      return res.json({
        success: true,
        dashboard: {
          instructorName,
          programs,
          sections,
          assignedStudents: 0,
          activeStudents: 0,
          readyForDeployment: 0,
          completedStudents: 0,
          requirementsToReview: 0,
          attendanceCorrections: 0,
        },
      });
    }
    const studentIds = students.map((s) => s.id);

    const hoursResult = await pool.query(
      `SELECT student_id,
         COALESCE(SUM(EXTRACT(EPOCH FROM (clock_out - clock_in)) / 3600.0)
           FILTER (WHERE clock_out IS NOT NULL), 0) AS completed_hours
       FROM attendance_records
       WHERE student_id = ANY($1::bigint[])
       GROUP BY student_id`,
      [studentIds],
    );
    const hoursByStudent = new Map(
      hoursResult.rows.map((r) => [r.student_id, Number(r.completed_hours)]),
    );

    const profileResult = await pool.query(
      'SELECT student_id, ojt_start_date FROM student_profiles WHERE student_id = ANY($1::bigint[])',
      [studentIds],
    );
    const startedByStudent = new Map(
      profileResult.rows.map((r) => [r.student_id, r.ojt_start_date != null]),
    );

    // Lifecycle buckets derived from existing data (no extra schema):
    // - completed: hit required hours
    // - active: deployed (has an OJT Start Date) and has logged some hours
    // - ready for deployment: deployed but hasn't started logging hours yet
    // - (the remainder, uncounted here) still working through Requirements
    let activeStudents = 0;
    let readyForDeployment = 0;
    let completedStudents = 0;
    for (const student of students) {
      const completedHours = hoursByStudent.get(student.id) || 0;
      const started = startedByStudent.get(student.id) || false;
      if (completedHours >= Number(student.required_hours)) {
        completedStudents++;
      } else if (started && completedHours > 0) {
        activeStudents++;
      } else if (started) {
        readyForDeployment++;
      }
    }

    const reqReviewResult = await pool.query(
      `SELECT COUNT(*) FROM student_requirement_submissions
       WHERE student_id = ANY($1::bigint[]) AND status = 'submitted'`,
      [studentIds],
    );
    const correctionsResult = await pool.query(
      `SELECT COUNT(*) FROM attendance_corrections
       WHERE student_id = ANY($1::bigint[]) AND status = 'pending'`,
      [studentIds],
    );

    res.json({
      success: true,
      dashboard: {
        instructorName,
        programs,
        sections,
        assignedStudents: students.length,
        activeStudents,
        readyForDeployment,
        completedStudents,
        requirementsToReview: Number(reqReviewResult.rows[0].count),
        attendanceCorrections: Number(correctionsResult.rows[0].count),
      },
    });
  } catch (error) {
    console.error('Get teacher dashboard error:', error);
    res.status(500).json({ success: false, message: 'Failed to load dashboard.' });
  }
});

module.exports = router;
