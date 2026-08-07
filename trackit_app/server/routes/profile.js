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
      `SELECT name, email, course, section, student_number, year_level, avatar_url
       FROM students
       WHERE id = $1`,
      [req.studentId],
    );
    if (studentResult.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Student not found.' });
    }
    const student = studentResult.rows[0];

    const profileResult = await pool.query(
      `SELECT sp.phone,
              sp.company_name, sp.company_address, sp.company_industry,
              sp.company_supervisor_name, sp.company_contact_number,
              sp.company_latitude, sp.company_longitude, sp.ojt_start_date,
              a.name AS adviser_name, a.position AS adviser_position,
              a.email AS adviser_email, a.phone AS adviser_phone
       FROM student_profiles sp
       LEFT JOIN advisers a ON a.id = sp.adviser_id
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
        // Self-reported via the Confirm Company Details form -- independent
        // of the HTE Directory. Matches CompanyDetails.fromJson's shape.
        company: profile && profile.company_name
          ? {
              name: profile.company_name,
              address: profile.company_address,
              industry: profile.company_industry,
              supervisorName: profile.company_supervisor_name,
              contactNumber: profile.company_contact_number,
              latitude: profile.company_latitude,
              longitude: profile.company_longitude,
              ojtStartDate: profile.ojt_start_date,
            }
          : null,
        // Derived from the same Confirm Company Details form (it collects
        // the supervisor's name and contact number together with the
        // company info) rather than a separate supervisors-table FK.
        supervisor: profile && profile.company_supervisor_name
          ? {
              name: profile.company_supervisor_name,
              role: 'HR Supervisor',
              email: '',
              phone: profile.company_contact_number,
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

// Confirm Company Details: manual, self-reported entry shown once all
// Startup Requirements phases are complete. This is the source of truth
// for the Home/Profile company card, independent of the HTE Directory.
router.post('/company', async (req, res) => {
  try {
    const {
      name,
      address,
      industry,
      supervisorName,
      contactNumber,
      latitude,
      longitude,
      ojtStartDate,
    } = req.body;
    if (!name || !address || !industry || !supervisorName || !contactNumber) {
      return res
        .status(400)
        .json({ success: false, message: 'All company detail fields are required.' });
    }

    await pool.query(
      `INSERT INTO student_profiles
         (student_id, company_name, company_address, company_industry,
          company_supervisor_name, company_contact_number,
          company_latitude, company_longitude, ojt_start_date, company_confirmed_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, now())
       ON CONFLICT (student_id)
       DO UPDATE SET company_name = $2, company_address = $3, company_industry = $4,
         company_supervisor_name = $5, company_contact_number = $6,
         company_latitude = $7, company_longitude = $8, ojt_start_date = $9,
         company_confirmed_at = now(), updated_at = now()`,
      [
        req.studentId,
        name,
        address,
        industry,
        supervisorName,
        contactNumber,
        latitude ?? null,
        longitude ?? null,
        ojtStartDate ?? null,
      ],
    );

    res.json({ success: true });
  } catch (error) {
    console.error('Submit company details error:', error);
    res.status(500).json({ success: false, message: 'Failed to save company details.' });
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
