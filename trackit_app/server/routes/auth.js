const express = require('express');
const bcrypt = require('bcrypt');
const pool = require('../db');
const { generateToken } = require('../middleware/auth');

const router = express.Router();

// NOTE: this is straightforward email/password registration. The
// capstone spec wants activation-code-gated registration against a
// department master list, which needs Admin tooling that doesn't exist
// yet -- that's a follow-up once the Admin module is built.
router.post('/register', async (req, res) => {
  try {
    const { name, email, password, course, section, studentNumber, yearLevel } = req.body;
    if (!name || !email || !password || !course || !section) {
      return res.status(400).json({
        success: false,
        message: 'name, email, password, course, and section are required.',
      });
    }
    if (password.length < 8) {
      return res
        .status(400)
        .json({ success: false, message: 'Password must be at least 8 characters.' });
    }

    const normalizedEmail = email.toLowerCase().trim();
    const existing = await pool.query('SELECT id FROM students WHERE email = $1', [
      normalizedEmail,
    ]);
    if (existing.rows.length > 0) {
      return res
        .status(409)
        .json({ success: false, message: 'An account with this email already exists.' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const result = await pool.query(
      `INSERT INTO students (name, email, password_hash, course, section, student_number, year_level)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING id, name, email, course, section, avatar_url, required_hours`,
      [name, normalizedEmail, passwordHash, course, section, studentNumber || null, yearLevel || null],
    );
    const student = result.rows[0];
    const token = generateToken(student.id);
    res.status(201).json({ success: true, token, student });
  } catch (error) {
    console.error('Register error:', error);
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
    const result = await pool.query('SELECT * FROM students WHERE email = $1', [
      normalizedEmail,
    ]);
    const student = result.rows[0];
    if (!student) {
      return res.status(401).json({ success: false, message: 'Invalid email or password.' });
    }

    const passwordMatches = await bcrypt.compare(password, student.password_hash);
    if (!passwordMatches) {
      return res.status(401).json({ success: false, message: 'Invalid email or password.' });
    }

    const token = generateToken(student.id);
    delete student.password_hash;
    res.json({ success: true, token, student });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ success: false, message: 'Login failed.' });
  }
});

module.exports = router;
