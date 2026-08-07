const express = require('express');
const pool = require('../db');

const router = express.Router();

// Public and unauthenticated -- used by the registration screen to show
// "You're joining: BSIT - 3F under Ma'am Althea" before the student
// submits the full form.
router.get('/lookup', async (req, res) => {
  try {
    const code = (req.query.code || '').toString().trim().toUpperCase();
    if (!code) {
      return res.status(400).json({ success: false, message: 'code is required.' });
    }

    const result = await pool.query(
      `SELECT c.program, c.section, c.academic_year, a.name AS instructor_name
       FROM instructor_classes c
       JOIN advisers a ON a.id = c.instructor_id
       WHERE c.activation_code = $1`,
      [code],
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Invalid activation code.' });
    }

    const row = result.rows[0];
    res.json({
      success: true,
      class: {
        program: row.program,
        section: row.section,
        academicYear: row.academic_year,
        instructorName: row.instructor_name,
      },
    });
  } catch (error) {
    console.error('Lookup class error:', error);
    res.status(500).json({ success: false, message: 'Failed to look up code.' });
  }
});

module.exports = router;
