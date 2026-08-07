const express = require('express');
const pool = require('../db');
const { requireInstructorAuth } = require('../middleware/instructorAuth');

const router = express.Router();
router.use(requireInstructorAuth);

const CODE_CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I ambiguity

function randomSegment(length) {
  let out = '';
  for (let i = 0; i < length; i++) {
    out += CODE_CHARS[Math.floor(Math.random() * CODE_CHARS.length)];
  }
  return out;
}

// TRACKIT-XXXX-XXXX -- normally admin-generated, but there's no Admin
// module yet, so the instructor's own class creation stands in for that.
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

router.get('/', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT c.*, COUNT(sp.student_id) AS student_count
       FROM instructor_classes c
       LEFT JOIN student_profiles sp ON sp.class_id = c.id
       WHERE c.instructor_id = $1
       GROUP BY c.id
       ORDER BY c.created_at DESC`,
      [req.instructorId],
    );
    res.json({
      success: true,
      classes: result.rows.map((row) => ({
        id: Number(row.id),
        program: row.program,
        section: row.section,
        academicYear: row.academic_year,
        activationCode: row.activation_code,
        studentCount: Number(row.student_count),
      })),
    });
  } catch (error) {
    console.error('Get classes error:', error);
    res.status(500).json({ success: false, message: 'Failed to load classes.' });
  }
});

router.post('/', async (req, res) => {
  try {
    const { program, section, academicYear } = req.body;
    if (!program || !section || !academicYear) {
      return res.status(400).json({
        success: false,
        message: 'program, section, and academicYear are required.',
      });
    }

    const code = await generateUniqueCode();
    const result = await pool.query(
      `INSERT INTO instructor_classes (instructor_id, program, section, academic_year, activation_code)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [req.instructorId, program.trim(), section.trim(), academicYear.trim(), code],
    );
    const row = result.rows[0];
    res.status(201).json({
      success: true,
      class: {
        id: Number(row.id),
        program: row.program,
        section: row.section,
        academicYear: row.academic_year,
        activationCode: row.activation_code,
        studentCount: 0,
      },
    });
  } catch (error) {
    console.error('Create class error:', error);
    res.status(500).json({ success: false, message: 'Failed to create class.' });
  }
});

module.exports = router;
