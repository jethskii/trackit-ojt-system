const express = require('express');
const bcrypt = require('bcrypt');
const pool = require('../db');
const { generateToken } = require('../middleware/auth');

const router = express.Router();

// Students join a class by activation code rather than free-typing
// course/section and picking an adviser separately -- one code sets
// course, section, and adviser together, consistently. The code is
// normally admin-generated; since there's no Admin module yet,
// instructors create their own classes (see routes/teacherClasses.js).
router.post('/register', async (req, res) => {
  try {
    const { name, email, password, activationCode, studentNumber, yearLevel } = req.body;
    if (!name || !email || !password || !activationCode) {
      return res.status(400).json({
        success: false,
        message: 'name, email, password, and activationCode are required.',
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

    const classResult = await pool.query(
      'SELECT * FROM instructor_classes WHERE activation_code = $1',
      [activationCode.toString().trim().toUpperCase()],
    );
    if (classResult.rows.length === 0) {
      return res.status(400).json({ success: false, message: 'Invalid activation code.' });
    }
    const studentClass = classResult.rows[0];

    const passwordHash = await bcrypt.hash(password, 10);
    const result = await pool.query(
      `INSERT INTO students (name, email, password_hash, course, section, student_number, year_level)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING id, name, email, course, section, avatar_url, required_hours`,
      [
        name,
        normalizedEmail,
        passwordHash,
        studentClass.program,
        studentClass.section,
        studentNumber || null,
        yearLevel || null,
      ],
    );
    const student = result.rows[0];

    await pool.query(
      `INSERT INTO student_profiles (student_id, adviser_id, class_id)
       VALUES ($1, $2, $3)
       ON CONFLICT (student_id) DO UPDATE SET adviser_id = $2, class_id = $3, updated_at = now()`,
      [student.id, studentClass.instructor_id, studentClass.id],
    );

    // Non-blocking -- a notification failure shouldn't fail registration,
    // which has already succeeded by this point.
    try {
      await pool.query(
        `INSERT INTO instructor_notifications
           (instructor_id, category, title, message, related_module, related_student_id)
         VALUES ($1, 'student', $2, $3, 'students', $4)`,
        [
          studentClass.instructor_id,
          'New Student Joined',
          `${student.name} joined ${studentClass.program} - ${studentClass.section}.`,
          student.id,
        ],
      );
    } catch (notifyError) {
      console.error('Notify instructor of new student error:', notifyError);
    }

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
