const pool = require('../db');

const CODE_CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I ambiguity

function randomSegment(length) {
  let out = '';
  for (let i = 0; i < length; i++) {
    out += CODE_CHARS[Math.floor(Math.random() * CODE_CHARS.length)];
  }
  return out;
}

// TRACKIT-XXXX-XXXX -- shared by instructors creating their own class
// (routes/teacherClasses.js) and admins regenerating a class's code
// (routes/adminClasses.js), so both always produce/validate codes the
// same way.
async function generateUniqueCode() {
  for (let attempt = 0; attempt < 10; attempt++) {
    const code = `TRACKIT-${randomSegment(4)}-${randomSegment(4)}`;
    const existing = await pool.query(
      'SELECT id FROM instructor_classes WHERE activation_code = $1',
      [code],
    );
    if (existing.rows.length === 0) return code;
  }
  throw new Error('Could not generate a unique activation code.');
}

module.exports = { generateUniqueCode };
