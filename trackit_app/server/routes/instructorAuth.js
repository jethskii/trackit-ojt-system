const express = require('express');
const bcrypt = require('bcrypt');
const pool = require('../db');
const { generateInstructorToken } = require('../middleware/instructorAuth');

const router = express.Router();

// Same shape as student registration (see routes/auth.js's NOTE) --
// straightforward email/password for now, no Admin-side verification
// that this person is actually DCSE faculty. That gate is a follow-up
// once the Admin module exists.
router.post('/register', async (req, res) => {
  try {
    const { name, email, password, position } = req.body;
    if (!name || !email || !password) {
      return res
        .status(400)
        .json({ success: false, message: 'name, email, and password are required.' });
    }
    if (password.length < 8) {
      return res
        .status(400)
        .json({ success: false, message: 'Password must be at least 8 characters.' });
    }

    const normalizedEmail = email.toLowerCase().trim();
    const existing = await pool.query('SELECT id FROM advisers WHERE email = $1', [
      normalizedEmail,
    ]);
    if (existing.rows.length > 0) {
      return res
        .status(409)
        .json({ success: false, message: 'An account with this email already exists.' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const result = await pool.query(
      `INSERT INTO advisers (name, email, phone, position, password_hash)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id, name, email, position`,
      [name, normalizedEmail, '', position || 'OJT Adviser', passwordHash],
    );
    const instructor = result.rows[0];
    const token = generateInstructorToken(instructor.id);
    res.status(201).json({ success: true, token, instructor });
  } catch (error) {
    console.error('Instructor register error:', error);
    res.status(500).json({ success: false, message: 'Registration failed.' });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res
        .status(400)
        .json({ success: false, message: 'email and password are required.' });
    }

    const normalizedEmail = email.toLowerCase().trim();
    const result = await pool.query(
      'SELECT * FROM advisers WHERE email = $1 AND password_hash IS NOT NULL',
      [normalizedEmail],
    );
    const instructor = result.rows[0];
    if (!instructor) {
      return res.status(401).json({ success: false, message: 'Invalid email or password.' });
    }

    const passwordMatches = await bcrypt.compare(password, instructor.password_hash);
    if (!passwordMatches) {
      return res.status(401).json({ success: false, message: 'Invalid email or password.' });
    }

    const token = generateInstructorToken(instructor.id);
    delete instructor.password_hash;
    res.json({ success: true, token, instructor });
  } catch (error) {
    console.error('Instructor login error:', error);
    res.status(500).json({ success: false, message: 'Login failed.' });
  }
});

module.exports = router;
