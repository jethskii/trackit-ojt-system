const express = require('express');
const multer = require('multer');
const path = require('path');
const pool = require('../db');
const { requireAuth } = require('../middleware/auth');

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

router.get('/', async (req, res) => {
  try {
    const phases = await pool.query(
      'SELECT * FROM ojt_requirement_phases ORDER BY order_index ASC',
    );
    const templates = await pool.query(
      'SELECT * FROM ojt_requirement_templates ORDER BY phase_id, sort_order ASC',
    );
    const submissions = await pool.query(
      'SELECT * FROM student_requirement_submissions WHERE student_id = $1',
      [req.studentId],
    );
    const submissionsByTemplate = new Map(
      submissions.rows.map((s) => [s.requirement_template_id, s]),
    );

    const phasesWithDocs = phases.rows.map((phase) => {
      const documents = templates.rows
        .filter((t) => t.phase_id === phase.id)
        .map((template) => {
          const submission = submissionsByTemplate.get(template.id);
          return {
            id: template.id,
            name: template.name,
            description: template.description,
            hasTemplate: template.has_template,
            status: submission ? submission.status : 'missing',
            uploadedFileName: submission ? submission.uploaded_file_name : null,
            deadline: submission ? submission.deadline : null,
          };
        });
      const fulfilled = documents.every(
        (d) => d.status === 'submitted' || d.status === 'approved',
      );
      return {
        id: phase.id,
        order: phase.order_index,
        title: phase.title,
        description: phase.description,
        documents,
        fulfilled,
      };
    });

    // Sequential lock/unlock: a phase can only be in progress or completed
    // if every earlier phase is fulfilled.
    let previousCompleted = true;
    const result = phasesWithDocs.map((phase) => {
      let status;
      if (!previousCompleted) status = 'locked';
      else if (phase.fulfilled) status = 'completed';
      else status = 'inProgress';
      previousCompleted = phase.fulfilled;
      return { ...phase, status };
    });

    res.json({ success: true, phases: result });
  } catch (error) {
    console.error('Get requirements error:', error);
    res.status(500).json({ success: false, message: 'Failed to load requirements.' });
  }
});

router.post('/:templateId/submit', upload.single('file'), async (req, res) => {
  try {
    const templateId = Number(req.params.templateId);
    if (!req.file) {
      return res.status(400).json({ success: false, message: 'No file uploaded.' });
    }
    const fileUrl = `/uploads/requirements/${req.file.filename}`;

    const result = await pool.query(
      `INSERT INTO student_requirement_submissions
         (student_id, requirement_template_id, status, uploaded_file_name, uploaded_file_url, submitted_at)
       VALUES ($1, $2, 'submitted', $3, $4, now())
       ON CONFLICT (student_id, requirement_template_id)
       DO UPDATE SET status = 'submitted', uploaded_file_name = $3,
         uploaded_file_url = $4, submitted_at = now(), updated_at = now()
       RETURNING *`,
      [req.studentId, templateId, req.file.originalname, fileUrl],
    );

    res.json({ success: true, submission: result.rows[0] });
  } catch (error) {
    console.error('Submit requirement error:', error);
    res.status(500).json({ success: false, message: 'Failed to submit document.' });
  }
});

module.exports = router;
