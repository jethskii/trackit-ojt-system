const express = require('express');
const pool = require('../db');
const { requireInstructorAuth } = require('../middleware/instructorAuth');
const { generateUniqueCode } = require('../utils/activationCode');

const router = express.Router();
router.use(requireInstructorAuth);

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
