const express = require('express');
const pool = require('../db');
const { requireAuth } = require('../middleware/auth');
const { notifyInstructorForStudent } = require('../utils/notifyInstructor');
const { generateWeeks } = require('../utils/weekSlots');

const router = express.Router();
router.use(requireAuth);

function dateOnly(date) {
  return date.toISOString().slice(0, 10);
}

async function attachAttachments(reports) {
  if (reports.length === 0) return reports;
  const ids = reports.map((r) => r.id).filter(Boolean);
  if (ids.length === 0) return reports;
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
  return reports.map((r) => ({
    ...r,
    attachments: r.id ? byReport.get(r.id) || [] : [],
  }));
}

function toReportJson(row) {
  return {
    weekNumber: row.weekNumber,
    weekStartDate: dateOnly(row.weekStartDate),
    weekEndDate: dateOnly(row.weekEndDate),
    status: row.status || 'missing',
    description: row.description || null,
    attachments: row.attachments || [],
    submittedAt: row.submitted_at,
    remarks: row.remarks || null,
  };
}

router.get('/', async (req, res) => {
  try {
    const profileResult = await pool.query(
      'SELECT ojt_start_date FROM student_profiles WHERE student_id = $1',
      [req.studentId],
    );
    const ojtStartDate = profileResult.rows[0]?.ojt_start_date ?? null;
    if (!ojtStartDate) {
      return res.json({ success: true, reports: [] });
    }

    const weeks = generateWeeks(ojtStartDate);
    const submissions = await pool.query(
      'SELECT * FROM activity_reports WHERE student_id = $1 AND week_number IS NOT NULL',
      [req.studentId],
    );
    const withAttachments = await attachAttachments(submissions.rows);
    const byWeek = new Map(withAttachments.map((r) => [r.week_number, r]));

    const merged = weeks.map((week) => {
      const submission = byWeek.get(week.weekNumber);
      return toReportJson({
        ...week,
        status: submission?.status,
        description: submission?.description,
        attachments: submission?.attachments,
        submitted_at: submission?.submitted_at,
        remarks: submission?.remarks,
      });
    });

    res.json({ success: true, reports: merged });
  } catch (error) {
    console.error('Get activity reports error:', error);
    res.status(500).json({ success: false, message: 'Failed to load activity reports.' });
  }
});

router.post('/:weekNumber/submit', async (req, res) => {
  try {
    const weekNumber = Number(req.params.weekNumber);
    const { description, attachments } = req.body;
    if (!description || !description.trim()) {
      return res
        .status(400)
        .json({ success: false, message: 'A description is required.' });
    }

    const profileResult = await pool.query(
      'SELECT ojt_start_date FROM student_profiles WHERE student_id = $1',
      [req.studentId],
    );
    const ojtStartDate = profileResult.rows[0]?.ojt_start_date ?? null;
    if (!ojtStartDate) {
      return res.status(400).json({
        success: false,
        message: 'Set your company details (with OJT Start Date) before submitting reports.',
      });
    }

    const weeks = generateWeeks(ojtStartDate);
    const week = weeks.find((w) => w.weekNumber === weekNumber);
    if (!week) {
      return res.status(400).json({ success: false, message: 'Invalid or future week.' });
    }

    const inserted = await pool.query(
      `INSERT INTO activity_reports
         (student_id, week_number, week_start_date, week_end_date, description, status, submitted_at)
       VALUES ($1, $2, $3, $4, $5, 'submitted', now())
       ON CONFLICT (student_id, week_number)
       DO UPDATE SET description = $5, status = 'submitted', submitted_at = now(),
         week_start_date = $3, week_end_date = $4, updated_at = now()
       RETURNING id`,
      [
        req.studentId,
        weekNumber,
        dateOnly(week.weekStartDate),
        dateOnly(week.weekEndDate),
        description.trim(),
      ],
    );
    const reportId = inserted.rows[0].id;

    await pool.query('DELETE FROM activity_report_attachments WHERE activity_report_id = $1', [
      reportId,
    ]);
    if (Array.isArray(attachments)) {
      for (const fileName of attachments) {
        await pool.query(
          'INSERT INTO activity_report_attachments (activity_report_id, file_name) VALUES ($1, $2)',
          [reportId, fileName],
        );
      }
    }

    try {
      const studentResult = await pool.query('SELECT name FROM students WHERE id = $1', [
        req.studentId,
      ]);
      const studentName = studentResult.rows[0]?.name;
      if (studentName) {
        await notifyInstructorForStudent(req.studentId, {
          title: 'Weekly Report Submitted',
          message: `${studentName} submitted the Week ${weekNumber} accomplishment report.`,
          relatedModule: 'reports',
        });
      }
    } catch (notifyError) {
      console.error('Notify instructor of weekly report error:', notifyError);
    }

    res.json({ success: true });
  } catch (error) {
    console.error('Submit activity report error:', error);
    res.status(500).json({ success: false, message: 'Failed to submit activity report.' });
  }
});

module.exports = router;
