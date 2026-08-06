const express = require('express');
const pool = require('../db');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();
router.use(requireAuth);

const SELECT_WITH_COMPANY = `
  SELECT r.*, c.name AS company_name
  FROM activity_reports r
  LEFT JOIN hte_companies c ON c.id = r.company_id
`;

async function attachAttachments(reports) {
  if (reports.length === 0) return reports;
  const ids = reports.map((r) => r.id);
  const attachments = await pool.query(
    'SELECT * FROM activity_report_attachments WHERE activity_report_id = ANY($1::bigint[])',
    [ids],
  );
  const byReport = new Map();
  for (const a of attachments.rows) {
    const list = byReport.get(a.activity_report_id) || [];
    list.push(a.file_name);
    byReport.set(a.activity_report_id, list);
  }
  return reports.map((r) => ({ ...r, attachments: byReport.get(r.id) || [] }));
}

router.get('/', async (req, res) => {
  try {
    const reports = await pool.query(
      `${SELECT_WITH_COMPANY} WHERE r.student_id = $1 ORDER BY r.report_date DESC`,
      [req.studentId],
    );
    const result = await attachAttachments(reports.rows);
    res.json({ success: true, reports: result });
  } catch (error) {
    console.error('Get activity reports error:', error);
    res.status(500).json({ success: false, message: 'Failed to load activity reports.' });
  }
});

router.post('/', async (req, res) => {
  try {
    const { title, reportDate, hoursRendered, description, status, attachments } = req.body;
    if (!title || !reportDate || hoursRendered === undefined || !description || !status) {
      return res.status(400).json({ success: false, message: 'Missing required fields.' });
    }

    const studentResult = await pool.query('SELECT company_id FROM students WHERE id = $1', [
      req.studentId,
    ]);
    const companyId = studentResult.rows[0]?.company_id ?? null;

    const inserted = await pool.query(
      `INSERT INTO activity_reports
         (student_id, company_id, title, report_date, hours_rendered, description, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING id`,
      [req.studentId, companyId, title, reportDate, hoursRendered, description, status],
    );
    const reportId = inserted.rows[0].id;

    if (Array.isArray(attachments)) {
      for (const fileName of attachments) {
        await pool.query(
          'INSERT INTO activity_report_attachments (activity_report_id, file_name) VALUES ($1, $2)',
          [reportId, fileName],
        );
      }
    }

    const full = await pool.query(`${SELECT_WITH_COMPANY} WHERE r.id = $1`, [reportId]);
    res.status(201).json({
      success: true,
      report: { ...full.rows[0], attachments: attachments || [] },
    });
  } catch (error) {
    console.error('Create activity report error:', error);
    res.status(500).json({ success: false, message: 'Failed to create activity report.' });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { title, reportDate, hoursRendered, description, status, attachments } = req.body;

    const existing = await pool.query(
      'SELECT id FROM activity_reports WHERE id = $1 AND student_id = $2',
      [id, req.studentId],
    );
    if (existing.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Report not found.' });
    }

    await pool.query(
      `UPDATE activity_reports
       SET title = $1, report_date = $2, hours_rendered = $3, description = $4,
           status = $5, updated_at = now()
       WHERE id = $6 AND student_id = $7`,
      [title, reportDate, hoursRendered, description, status, id, req.studentId],
    );

    await pool.query('DELETE FROM activity_report_attachments WHERE activity_report_id = $1', [
      id,
    ]);
    if (Array.isArray(attachments)) {
      for (const fileName of attachments) {
        await pool.query(
          'INSERT INTO activity_report_attachments (activity_report_id, file_name) VALUES ($1, $2)',
          [id, fileName],
        );
      }
    }

    const full = await pool.query(`${SELECT_WITH_COMPANY} WHERE r.id = $1`, [id]);
    res.json({ success: true, report: { ...full.rows[0], attachments: attachments || [] } });
  } catch (error) {
    console.error('Update activity report error:', error);
    res.status(500).json({ success: false, message: 'Failed to update activity report.' });
  }
});

module.exports = router;
