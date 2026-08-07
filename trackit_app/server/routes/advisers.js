const express = require('express');
const pool = require('../db');

const router = express.Router();

// Public and unauthenticated -- the Student registration form needs this
// list before the student has a token. Only real registered instructors
// (password_hash set) are returned, so this doesn't surface the old
// mock-data seed row that predates instructor auth.
router.get('/', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, name, position FROM advisers
       WHERE password_hash IS NOT NULL
       ORDER BY name ASC`,
    );
    res.json({ success: true, advisers: result.rows });
  } catch (error) {
    console.error('Get advisers error:', error);
    res.status(500).json({ success: false, message: 'Failed to load advisers.' });
  }
});

module.exports = router;
