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

// FAC-YYYY-NNN -- a completely separate code space from student
// activation codes (checked against advisers.activation_code, never
// instructor_classes.activation_code), so the two are never
// interchangeable even by accident.
async function generateInstructorActivationCode() {
  const year = new Date().getFullYear();
  for (let attempt = 0; attempt < 20; attempt++) {
    const sequence = String(Math.floor(Math.random() * 999) + 1).padStart(3, '0');
    const code = `FAC-${year}-${sequence}`;
    const existing = await pool.query('SELECT id FROM advisers WHERE activation_code = $1', [
      code,
    ]);
    if (existing.rows.length === 0) return code;
  }
  throw new Error('Could not generate a unique instructor activation code.');
}

module.exports = { generateUniqueCode, generateInstructorActivationCode };
