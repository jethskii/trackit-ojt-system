const express = require('express');
const pool = require('../db');
const { requireInstructorAuth } = require('../middleware/instructorAuth');
const { generateWeeks } = require('../utils/weekSlots');
const { loadAssignedStudents } = require('./teacherStudents');

const router = express.Router();
router.use(requireInstructorAuth);

function dateOnly(date) {
  return date.toISOString().slice(0, 10);
}

// Weekly AR Submissions -- "record/compilation only" per spec, so this is
// read-only: no approve/reject action exists here, unlike Official
// Requirements and Attendance corrections.
router.get('/students/:studentId', async (req, res) => {
  try {
    const studentId = Number(req.params.studentId);
    const owns = await pool.query(
      `SELECT s.id, s.name, s.avatar_url FROM students s
       JOIN student_profiles sp ON sp.student_id = s.id
       WHERE s.id = $1 AND sp.adviser_id = $2`,
      [studentId, req.instructorId],
    );
    if (owns.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Student not found or not assigned to you.' });
    }
    const student = owns.rows[0];

    const profileResult = await pool.query(
      'SELECT ojt_start_date FROM student_profiles WHERE student_id = $1',
      [studentId],
    );
    const ojtStartDate = profileResult.rows[0]?.ojt_start_date ?? null;
    if (!ojtStartDate) {
      return res.json({
        success: true,
        student: { id: Number(student.id), name: student.name, avatarUrl: student.avatar_url },
        reports: [],
      });
    }

    const weeks = generateWeeks(ojtStartDate);
    const submissions = await pool.query(
      'SELECT * FROM activity_reports WHERE student_id = $1 AND week_number IS NOT NULL',
      [studentId],
    );
    const byWeek = new Map(submissions.rows.map((r) => [r.week_number, r]));

    const reports = weeks.map((week) => {
      const submission = byWeek.get(week.weekNumber);
      return {
        weekNumber: week.weekNumber,
        weekStartDate: dateOnly(week.weekStartDate),
        weekEndDate: dateOnly(week.weekEndDate),
        status: submission?.status || 'missing',
        description: submission?.description || null,
        submittedAt: submission?.submitted_at || null,
      };
    });

    res.json({
      success: true,
      student: { id: Number(student.id), name: student.name, avatarUrl: student.avatar_url },
      reports,
    });
  } catch (error) {
    console.error('Get teacher weekly reports error:', error);
    res.status(500).json({ success: false, message: 'Failed to load weekly reports.' });
  }
});

// Compilation summary across all assigned students (submitted count vs.
// expected weeks so far), for the list view under Weekly AR Submissions.
router.get('/students', async (req, res) => {
  try {
    const students = await loadAssignedStudents(req.instructorId);
    const result = [];
    for (const student of students) {
      const profileResult = await pool.query(
        'SELECT ojt_start_date FROM student_profiles WHERE student_id = $1',
        [student.id],
      );
      const ojtStartDate = profileResult.rows[0]?.ojt_start_date ?? null;
      const weeks = ojtStartDate ? generateWeeks(ojtStartDate) : [];
      const submittedResult = await pool.query(
        `SELECT COUNT(*)::int AS count FROM activity_reports
         WHERE student_id = $1 AND week_number IS NOT NULL AND status = 'submitted'`,
        [student.id],
      );
      result.push({
        id: Number(student.id),
        name: student.name,
        avatarUrl: student.avatar_url,
        course: student.course,
        section: student.section,
        expectedWeeks: weeks.length,
        submittedWeeks: submittedResult.rows[0].count,
      });
    }
    res.json({ success: true, students: result });
  } catch (error) {
    console.error('Get teacher weekly report students error:', error);
    res.status(500).json({ success: false, message: 'Failed to load students.' });
  }
});

module.exports = router;
