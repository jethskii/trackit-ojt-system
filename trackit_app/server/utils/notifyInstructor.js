const pool = require('../db');

// Looks up the student's adviser (if any) and inserts a real
// instructor_notifications row. Silently does nothing if the student
// has no adviser yet -- there's no one to notify. Callers should wrap
// this in its own try/catch so a notification failure never fails the
// student-facing action that triggered it.
async function notifyInstructorForStudent(studentId, { title, message, relatedModule }) {
  const result = await pool.query(
    'SELECT adviser_id FROM student_profiles WHERE student_id = $1',
    [studentId],
  );
  const adviserId = result.rows[0]?.adviser_id;
  if (!adviserId) return;

  await pool.query(
    `INSERT INTO instructor_notifications
       (instructor_id, category, title, message, related_module, related_student_id)
     VALUES ($1, 'student', $2, $3, $4, $5)`,
    [adviserId, title, message, relatedModule || null, studentId],
  );
}

module.exports = { notifyInstructorForStudent };
