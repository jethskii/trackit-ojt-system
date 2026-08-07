const express = require('express');
const pool = require('../db');
const { requireInstructorAuth } = require('../middleware/instructorAuth');

const router = express.Router();
router.use(requireInstructorAuth);

router.get('/', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM instructor_notifications WHERE instructor_id = $1 ORDER BY created_at DESC',
      [req.instructorId],
    );
    res.json({ success: true, notifications: result.rows });
  } catch (error) {
    console.error('Get instructor notifications error:', error);
    res.status(500).json({ success: false, message: 'Failed to load notifications.' });
  }
});

router.patch('/:id/read', async (req, res) => {
  try {
    await pool.query(
      'UPDATE instructor_notifications SET is_read = true WHERE id = $1 AND instructor_id = $2',
      [req.params.id, req.instructorId],
    );
    res.json({ success: true });
  } catch (error) {
    console.error('Mark instructor notification read error:', error);
    res.status(500).json({ success: false, message: 'Failed to update notification.' });
  }
});

router.patch('/read-all', async (req, res) => {
  try {
    await pool.query(
      'UPDATE instructor_notifications SET is_read = true WHERE instructor_id = $1 AND is_read = false',
      [req.instructorId],
    );
    res.json({ success: true });
  } catch (error) {
    console.error('Mark all instructor notifications read error:', error);
    res.status(500).json({ success: false, message: 'Failed to update notifications.' });
  }
});

module.exports = router;
