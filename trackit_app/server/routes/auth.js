const express = require('express');
const bcrypt = require('bcrypt');
const pool = require('../db');
const { generateToken, requireAuth } = require('../middleware/auth');
const { createLoginSession } = require('../utils/loginHistory');

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
    const existing = await pool.query('SELECT * FROM students WHERE email = $1', [
      normalizedEmail,
    ]);
    const existingStudent = existing.rows[0];
    // A real duplicate (already has a password) is rejected exactly as
    // before. A row with no password is a pre-imported placeholder
    // (Admin's Import Students) that this registration should claim
    // instead, handled below once the activation code is validated.
    if (existingStudent && existingStudent.password_hash) {
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
    let student;

    if (existingStudent) {
      // Pending row from Import Students -- only claimable with a code
      // for the same section it was imported into, so a matching email
      // can't be hijacked into a different section via someone else's
      // code.
      const profileResult = await pool.query(
        'SELECT class_id FROM student_profiles WHERE student_id = $1',
        [existingStudent.id],
      );
      const currentClassId = profileResult.rows[0]?.class_id;
      if (currentClassId && Number(currentClassId) !== Number(studentClass.id)) {
        return res.status(409).json({
          success: false,
          message:
            'This email was imported into a different section. Contact your OJT coordinator.',
        });
      }

      const updated = await pool.query(
        `UPDATE students
         SET name = $1, password_hash = $2, course = $3, section = $4,
             student_number = COALESCE($5, student_number),
             year_level = COALESCE($6, year_level),
             activated_at = now(), updated_at = now()
         WHERE id = $7
         RETURNING id, name, email, course, section, avatar_url, required_hours`,
        [
          name,
          passwordHash,
          studentClass.program,
          studentClass.section,
          studentNumber || null,
          yearLevel || null,
          existingStudent.id,
        ],
      );
      student = updated.rows[0];
    } else {
      const inserted = await pool.query(
        `INSERT INTO students (name, email, password_hash, course, section, student_number, year_level, activated_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, now())
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
      student = inserted.rows[0];
    }

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

    const sessionId = await createLoginSession(student.id, req.get('User-Agent'));
    const token = generateToken(student.id, sessionId);
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
    // Pending row from Import Students -- no password set yet, so there's
    // nothing bcrypt.compare could meaningfully check against.
    if (!student.password_hash) {
      return res.status(401).json({
        success: false,
        message:
          'This account has not been activated yet. Register with your section\'s activation code to set a password.',
      });
    }

    const passwordMatches = await bcrypt.compare(password, student.password_hash);
    if (!passwordMatches) {
      return res.status(401).json({ success: false, message: 'Invalid email or password.' });
    }

    const sessionId = await createLoginSession(student.id, req.get('User-Agent'));
    const token = generateToken(student.id, sessionId);
    delete student.password_hash;
    res.json({ success: true, token, student });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ success: false, message: 'Login failed.' });
  }
});

// Closes the session this token belongs to. A page refresh never hits
// this (it just reuses the stored token), and it never touches other
// sessions, so logging in on a second device doesn't get closed out by
// logging out on the first.
router.post('/logout', requireAuth, async (req, res) => {
  try {
    if (req.sessionId) {
      await pool.query(
        `UPDATE login_history SET logout_at = now()
         WHERE id = $1 AND student_id = $2 AND logout_at IS NULL`,
        [req.sessionId, req.studentId],
      );
    } else {
      // Token minted before session tracking existed -- best effort:
      // close the most recent still-open session for this student.
      await pool.query(
        `UPDATE login_history SET logout_at = now()
         WHERE id = (
           SELECT id FROM login_history
           WHERE student_id = $1 AND logout_at IS NULL
           ORDER BY login_at DESC LIMIT 1
         )`,
        [req.studentId],
      );
    }
    res.json({ success: true });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({ success: false, message: 'Failed to log out.' });
  }
});

module.exports = router;
