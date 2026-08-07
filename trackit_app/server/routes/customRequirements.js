const express = require('express');
const multer = require('multer');
const path = require('path');
const pool = require('../db');
const { requireAuth } = require('../middleware/auth');
const { notifyInstructorForStudent } = require('../utils/notifyInstructor');

const router = express.Router();
router.use(requireAuth);

const storage = multer.diskStorage({
  destination: path.join(__dirname, '..', 'uploads', 'requirements'),
  filename: (req, file, cb) => {
    const unique = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    cb(null, `${unique}${path.extname(file.originalname)}`);
  },
});
const upload = multer({ storage, limits: { fileSize: 10 * 1024 * 1024 } });

// Additional Requirements -- instructor-created, targeted at the
// student's class. Same submit/status flow as the fixed Official
// Requirements, just a different source table (see
// migration_teacher_documents.sql).
router.get('/', async (req, res) => {
  try {
    const requirementsResult = await pool.query(
      `SELECT cr.* FROM custom_requirements cr
       JOIN custom_requirement_targets crt ON crt.custom_requirement_id = cr.id
       JOIN instructor_classes ic ON ic.id = crt.class_id
       JOIN student_profiles sp ON sp.class_id = ic.id
       WHERE sp.student_id = $1
       ORDER BY cr.created_at DESC`,
      [req.studentId],
    );
    const submissionsResult = await pool.query(
      'SELECT * FROM student_custom_requirement_submissions WHERE student_id = $1',
      [req.studentId],
    );
    const byRequirement = new Map(
      submissionsResult.rows.map((s) => [s.custom_requirement_id, s]),
    );

    const requirements = requirementsResult.rows.map((requirement) => {
      const submission = byRequirement.get(requirement.id);
      return {
        id: requirement.id,
        name: requirement.title,
        description: requirement.description,
        deadline: requirement.deadline,
        status: submission ? submission.status : 'missing',
        uploadedFileName: submission ? submission.uploaded_file_name : null,
        remarks: submission ? submission.remarks : null,
      };
    });

    res.json({ success: true, requirements });
  } catch (error) {
    console.error('Get custom requirements error:', error);
    res.status(500).json({ success: false, message: 'Failed to load additional requirements.' });
  }
});

router.post('/:requirementId/submit', upload.single('file'), async (req, res) => {
  try {
    const requirementId = Number(req.params.requirementId);
    const fileName = req.file ? req.file.originalname : req.body.fileName;
    const fileUrl = req.file ? `/uploads/requirements/${req.file.filename}` : null;
    if (!fileName) {
      return res.status(400).json({ success: false, message: 'No file provided.' });
    }

    const owns = await pool.query(
      `SELECT cr.id FROM custom_requirements cr
       JOIN custom_requirement_targets crt ON crt.custom_requirement_id = cr.id
       JOIN instructor_classes ic ON ic.id = crt.class_id
       JOIN student_profiles sp ON sp.class_id = ic.id
       WHERE cr.id = $1 AND sp.student_id = $2`,
      [requirementId, req.studentId],
    );
    if (owns.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Requirement not found.' });
    }

    const result = await pool.query(
      `INSERT INTO student_custom_requirement_submissions
         (student_id, custom_requirement_id, status, uploaded_file_name, uploaded_file_url, submitted_at)
       VALUES ($1, $2, 'submitted', $3, $4, now())
       ON CONFLICT (student_id, custom_requirement_id)
       DO UPDATE SET status = 'submitted', uploaded_file_name = $3,
         uploaded_file_url = $4, submitted_at = now(), updated_at = now()
       RETURNING *`,
      [req.studentId, requirementId, fileName, fileUrl],
    );

    try {
      const [studentResult, requirementResult] = await Promise.all([
        pool.query('SELECT name FROM students WHERE id = $1', [req.studentId]),
        pool.query('SELECT title FROM custom_requirements WHERE id = $1', [requirementId]),
      ]);
      const studentName = studentResult.rows[0]?.name;
      const requirementName = requirementResult.rows[0]?.title;
      if (studentName && requirementName) {
        await notifyInstructorForStudent(req.studentId, {
          title: 'Requirement Submitted',
          message: `${studentName} submitted "${requirementName}" for review.`,
          relatedModule: 'requirements',
        });
      }
    } catch (notifyError) {
      console.error('Notify instructor of custom requirement submission error:', notifyError);
    }

    res.json({ success: true, submission: result.rows[0] });
  } catch (error) {
    console.error('Submit custom requirement error:', error);
    res.status(500).json({ success: false, message: 'Failed to submit document.' });
  }
});

module.exports = router;
