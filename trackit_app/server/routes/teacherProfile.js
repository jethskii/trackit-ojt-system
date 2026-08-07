const express = require('express');
const bcrypt = require('bcrypt');
const multer = require('multer');
const path = require('path');
const pool = require('../db');
const { requireInstructorAuth } = require('../middleware/instructorAuth');

const router = express.Router();
router.use(requireInstructorAuth);

const storage = multer.diskStorage({
  destination: path.join(__dirname, '..', 'uploads', 'avatars'),
  filename: (req, file, cb) => {
    const unique = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    cb(null, `${unique}${path.extname(file.originalname)}`);
  },
});
const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowed = ['image/jpeg', 'image/png', 'image/webp'];
    cb(null, allowed.includes(file.mimetype));
  },
});

router.get('/', async (req, res) => {
  try {
    const instructorResult = await pool.query(
      'SELECT name, email, position, photo_url FROM advisers WHERE id = $1',
      [req.instructorId],
    );
    if (instructorResult.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Instructor not found.' });
    }
    const instructor = instructorResult.rows[0];

    // Program/Section(s) are derived from the instructor's own classes --
    // matches how the Home Dashboard computes them, but from
    // instructor_classes directly rather than assigned students, so it
    // still shows something even before any student has joined.
    const classesResult = await pool.query(
      'SELECT DISTINCT program, section FROM instructor_classes WHERE instructor_id = $1',
      [req.instructorId],
    );
    const programs = [...new Set(classesResult.rows.map((r) => r.program))];
    const sections = [...new Set(classesResult.rows.map((r) => r.section))];

    res.json({
      success: true,
      profile: {
        name: instructor.name,
        email: instructor.email,
        position: instructor.position,
        photoUrl: instructor.photo_url,
        programs,
        sections,
      },
    });
  } catch (error) {
    console.error('Get teacher profile error:', error);
    res.status(500).json({ success: false, message: 'Failed to load profile.' });
  }
});

router.post('/avatar', upload.single('avatar'), async (req, res) => {
  try {
    if (!req.file) {
      return res
        .status(400)
        .json({ success: false, message: 'No image uploaded (jpg/png/webp only).' });
    }
    const avatarUrl = `/uploads/avatars/${req.file.filename}`;
    await pool.query('UPDATE advisers SET photo_url = $1 WHERE id = $2', [
      avatarUrl,
      req.instructorId,
    ]);
    res.json({ success: true, avatarUrl });
  } catch (error) {
    console.error('Upload instructor avatar error:', error);
    res.status(500).json({ success: false, message: 'Failed to upload avatar.' });
  }
});

// No OTP yet -- that needs real email-sending infrastructure (SMTP/
// SendGrid credentials) that doesn't exist in this project. Current
// password verification stands in as the security check for now.
router.patch('/password', async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'currentPassword and newPassword are required.',
      });
    }
    if (newPassword.length < 8) {
      return res
        .status(400)
        .json({ success: false, message: 'New password must be at least 8 characters.' });
    }

    const result = await pool.query('SELECT password_hash FROM advisers WHERE id = $1', [
      req.instructorId,
    ]);
    const instructor = result.rows[0];
    const matches = await bcrypt.compare(currentPassword, instructor.password_hash);
    if (!matches) {
      return res.status(401).json({ success: false, message: 'Current password is incorrect.' });
    }

    const newHash = await bcrypt.hash(newPassword, 10);
    await pool.query('UPDATE advisers SET password_hash = $1 WHERE id = $2', [
      newHash,
      req.instructorId,
    ]);
    res.json({ success: true });
  } catch (error) {
    console.error('Change instructor password error:', error);
    res.status(500).json({ success: false, message: 'Failed to change password.' });
  }
});

router.patch('/email', async (req, res) => {
  try {
    const { currentPassword, newEmail } = req.body;
    if (!currentPassword || !newEmail) {
      return res
        .status(400)
        .json({ success: false, message: 'currentPassword and newEmail are required.' });
    }
    const normalizedEmail = newEmail.toLowerCase().trim();

    const result = await pool.query('SELECT password_hash FROM advisers WHERE id = $1', [
      req.instructorId,
    ]);
    const instructor = result.rows[0];
    const matches = await bcrypt.compare(currentPassword, instructor.password_hash);
    if (!matches) {
      return res.status(401).json({ success: false, message: 'Current password is incorrect.' });
    }

    const existing = await pool.query(
      'SELECT id FROM advisers WHERE email = $1 AND id != $2',
      [normalizedEmail, req.instructorId],
    );
    if (existing.rows.length > 0) {
      return res.status(409).json({ success: false, message: 'That email is already in use.' });
    }

    await pool.query('UPDATE advisers SET email = $1 WHERE id = $2', [
      normalizedEmail,
      req.instructorId,
    ]);
    res.json({ success: true, email: normalizedEmail });
  } catch (error) {
    console.error('Change instructor email error:', error);
    res.status(500).json({ success: false, message: 'Failed to change email.' });
  }
});

module.exports = router;
