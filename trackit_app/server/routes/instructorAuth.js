const express = require('express');
const bcrypt = require('bcrypt');
const pool = require('../db');
const { generateInstructorToken } = require('../middleware/instructorAuth');

const router = express.Router();

// Admin creates the instructor account and its real Instructor
// Activation Code (see routes/adminInstructors.js) -- registration here
// only claims that pre-created row, it never creates a new one. This
// replaces the old free self-registration flow (no Admin gate at all).
router.post('/register', async (req, res) => {
  try {
    const { activationCode, password } = req.body;
    if (!activationCode || !password) {
      return res
        .status(400)
        .json({ success: false, message: 'activationCode and password are required.' });
    }
    if (password.length < 8) {
      return res
        .status(400)
        .json({ success: false, message: 'Password must be at least 8 characters.' });
    }

    const result = await pool.query('SELECT * FROM advisers WHERE activation_code = $1', [
      activationCode.toString().trim().toUpperCase(),
    ]);
    if (result.rows.length === 0) {
      return res.status(400).json({ success: false, message: 'Invalid activation code.' });
    }
    const instructorRow = result.rows[0];
    if (instructorRow.password_hash) {
      return res
        .status(409)
        .json({ success: false, message: 'This activation code has already been used.' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const updated = await pool.query(
      `UPDATE advisers
       SET password_hash = $1, activated_at = now()
       WHERE id = $2
       RETURNING id, name, email, position`,
      [passwordHash, instructorRow.id],
    );
    const instructor = updated.rows[0];
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
    const result = await pool.query('SELECT * FROM advisers WHERE email = $1', [
      normalizedEmail,
    ]);
    const instructor = result.rows[0];
    if (!instructor) {
      return res.status(401).json({ success: false, message: 'Invalid email or password.' });
    }
    // Pending row created by Admin (Add Instructor) -- no password set
    // yet, so there's nothing bcrypt.compare could meaningfully check.
    if (!instructor.password_hash) {
      return res.status(401).json({
        success: false,
        message:
          'This account has not been activated yet. Register with your Instructor Activation Code to set a password.',
      });
    }
    if (instructor.status === 'inactive') {
      return res.status(403).json({
        success: false,
        message: 'This account has been deactivated. Contact your administrator.',
      });
    }

    const passwordMatches = await bcrypt.compare(password, instructor.password_hash);
    if (!passwordMatches) {
      return res.status(401).json({ success: false, message: 'Invalid email or password.' });
    }

    await pool.query('UPDATE advisers SET last_login_at = now() WHERE id = $1', [instructor.id]);

    const token = generateInstructorToken(instructor.id);
    delete instructor.password_hash;
    res.json({ success: true, token, instructor });
  } catch (error) {
    console.error('Instructor login error:', error);
    res.status(500).json({ success: false, message: 'Login failed.' });
  }
});

module.exports = router;
