const pool = require('../db');

// One row per issued token (register or login). Its id gets embedded in
// the JWT as `sessionId` so logout can close exactly this row -- see
// middleware/auth.js and routes/auth.js.
async function createLoginSession(studentId, userAgent) {
  const result = await pool.query(
    `INSERT INTO login_history (student_id, user_agent) VALUES ($1, $2) RETURNING id`,
    [studentId, userAgent || null],
  );
  return result.rows[0].id;
}

module.exports = { createLoginSession };
