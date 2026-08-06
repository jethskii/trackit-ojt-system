const express = require('express');
const multer = require('multer');
const path = require('path');
const pool = require('../db');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();
router.use(requireAuth);

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
    const studentResult = await pool.query(
      `SELECT s.name, s.email, s.course, s.section, s.student_number, s.year_level,
              s.avatar_url, s.company_id,
              c.name AS company_name, c.industry, c.address AS company_address,
              c.email AS company_email, c.phone AS company_phone, c.website,
              c.description AS company_description, c.available_positions, c.available_slots
       FROM students s
       LEFT JOIN hte_companies c ON c.id = s.company_id
       WHERE s.id = $1`,
      [req.studentId],
    );
    if (studentResult.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Student not found.' });
    }
    const student = studentResult.rows[0];

    const profileResult = await pool.query(
      `SELECT sp.phone,
              a.name AS adviser_name, a.position AS adviser_position,
              a.email AS adviser_email, a.phone AS adviser_phone,
              sup.name AS supervisor_name, sup.position AS supervisor_position,
              sup.email AS supervisor_email, sup.phone AS supervisor_phone
       FROM student_profiles sp
       LEFT JOIN advisers a ON a.id = sp.adviser_id
       LEFT JOIN supervisors sup ON sup.id = sp.supervisor_id
       WHERE sp.student_id = $1`,
      [req.studentId],
    );
    const profile = profileResult.rows[0] || null;

    res.json({
      success: true,
      profile: {
        fullName: student.name,
        email: student.email,
        course: student.course,
        section: student.section,
        studentNumber: student.student_number,
        yearLevel: student.year_level,
        avatarUrl: student.avatar_url,
        mobileNumber: profile ? profile.phone : null,
        adviser: profile && profile.adviser_name
          ? {
              name: profile.adviser_name,
              role: profile.adviser_position,
              email: profile.adviser_email,
              phone: profile.adviser_phone,
            }
          : null,
        // snake_case keys here match /api/hte-companies's raw row shape so
        // HteCompany.fromJson can parse both without special-casing.
        company: student.company_id
          ? {
              id: student.company_id,
              name: student.company_name,
              industry: student.industry,
              address: student.company_address,
              email: student.company_email,
              phone: student.company_phone,
              website: student.website,
              description: student.company_description,
              available_positions: student.available_positions,
              available_slots: student.available_slots,
            }
          : null,
        supervisor: profile && profile.supervisor_name
          ? {
              name: profile.supervisor_name,
              role: profile.supervisor_position,
              email: profile.supervisor_email,
              phone: profile.supervisor_phone,
            }
          : null,
      },
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ success: false, message: 'Failed to load profile.' });
  }
});

router.patch('/', async (req, res) => {
  try {
    const { phone, alternateEmail, address, emergencyContact, studentNumber, yearLevel } =
      req.body;

    await pool.query(
      `INSERT INTO student_profiles (student_id, phone, alternate_email, address, emergency_contact)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (student_id)
       DO UPDATE SET phone = $2, alternate_email = $3, address = $4,
         emergency_contact = $5, updated_at = now()`,
      [req.studentId, phone, alternateEmail, address, emergencyContact],
    );

    if (studentNumber !== undefined || yearLevel !== undefined) {
      await pool.query(
        `UPDATE students
         SET student_number = COALESCE($1, student_number),
             year_level = COALESCE($2, year_level),
             updated_at = now()
         WHERE id = $3`,
        [studentNumber, yearLevel, req.studentId],
      );
    }

    res.json({ success: true });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ success: false, message: 'Failed to update profile.' });
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
    await pool.query('UPDATE students SET avatar_url = $1, updated_at = now() WHERE id = $2', [
      avatarUrl,
      req.studentId,
    ]);
    res.json({ success: true, avatarUrl });
  } catch (error) {
    console.error('Upload avatar error:', error);
    res.status(500).json({ success: false, message: 'Failed to upload avatar.' });
  }
});

module.exports = router;
