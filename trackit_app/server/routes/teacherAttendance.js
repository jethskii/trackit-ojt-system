const express = require('express');
const pool = require('../db');
const { requireInstructorAuth } = require('../middleware/instructorAuth');

const router = express.Router();
router.use(requireInstructorAuth);

function toRecordJson(row) {
  const hours =
    row.clock_in && row.clock_out
      ? (new Date(row.clock_out) - new Date(row.clock_in)) / (1000 * 60 * 60)
      : null;
  return {
    id: Number(row.id),
    studentId: Number(row.student_id),
    studentName: row.student_name,
    avatarUrl: row.avatar_url,
    workDate: row.work_date,
    clockIn: row.clock_in,
    clockOut: row.clock_out,
    hoursRendered: hours,
  };
}

// Full clock-in/out log across every student assigned to this instructor.
router.get('/records', async (req, res) => {
  try {
    const { search, workDate } = req.query;
    const conditions = ['sp.adviser_id = $1'];
    const params = [req.instructorId];
    if (search) {
      params.push(`%${search.toString().toLowerCase()}%`);
      conditions.push(`LOWER(s.name) LIKE $${params.length}`);
    }
    if (workDate) {
      params.push(workDate);
      conditions.push(`ar.work_date = $${params.length}`);
    }

    const result = await pool.query(
      `SELECT ar.*, s.name AS student_name, s.avatar_url
       FROM attendance_records ar
       JOIN students s ON s.id = ar.student_id
       JOIN student_profiles sp ON sp.student_id = ar.student_id
       WHERE ${conditions.join(' AND ')}
       ORDER BY ar.work_date DESC, ar.clock_in DESC
       LIMIT 200`,
      params,
    );
    res.json({ success: true, records: result.rows.map(toRecordJson) });
  } catch (error) {
    console.error('Get teacher attendance records error:', error);
    res.status(500).json({ success: false, message: 'Failed to load attendance records.' });
  }
});

function toCorrectionJson(row) {
  return {
    id: Number(row.id),
    studentId: Number(row.student_id),
    studentName: row.student_name,
    avatarUrl: row.avatar_url,
    workDate: row.work_date,
    reason: row.reason,
    attachmentFileName: row.attachment_file_name,
    status: row.status,
    reviewerNote: row.reviewer_note,
    submittedAt: row.created_at,
    reviewedAt: row.reviewed_at,
  };
}

// Correction requests from assigned students, for approve/reject.
router.get('/corrections', async (req, res) => {
  try {
    const { status } = req.query;
    const conditions = ['sp.adviser_id = $1'];
    const params = [req.instructorId];
    if (status) {
      params.push(status);
      conditions.push(`ac.status = $${params.length}`);
    }

    const result = await pool.query(
      `SELECT ac.*, s.name AS student_name, s.avatar_url
       FROM attendance_corrections ac
       JOIN students s ON s.id = ac.student_id
       JOIN student_profiles sp ON sp.student_id = ac.student_id
       WHERE ${conditions.join(' AND ')}
       ORDER BY ac.created_at DESC`,
      params,
    );
    res.json({ success: true, requests: result.rows.map(toCorrectionJson) });
  } catch (error) {
    console.error('Get teacher corrections error:', error);
    res.status(500).json({ success: false, message: 'Failed to load correction requests.' });
  }
});

// Approve or reject a correction request after verification. There's no
// structured "requested clock-in/out time" on this table (see
// migration_attendance_geofence_corrections.sql) -- approving records the
// instructor's decision and reviewer note; it does not itself rewrite the
// underlying attendance_records row.
router.patch('/corrections/:id', async (req, res) => {
  try {
    const correctionId = Number(req.params.id);
    const { decision, reviewerNote } = req.body;
    if (decision !== 'approved' && decision !== 'rejected') {
      return res.status(400).json({ success: false, message: 'decision must be "approved" or "rejected".' });
    }

    const existing = await pool.query(
      `SELECT ac.* FROM attendance_corrections ac
       JOIN student_profiles sp ON sp.student_id = ac.student_id
       WHERE ac.id = $1 AND sp.adviser_id = $2`,
      [correctionId, req.instructorId],
    );
    if (existing.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Correction request not found.' });
    }
    const correction = existing.rows[0];

    const updated = await pool.query(
      `UPDATE attendance_corrections
       SET status = $1, reviewer_note = $2, reviewed_at = now(), reviewed_by = $3
       WHERE id = $4
       RETURNING *`,
      [decision, reviewerNote || null, req.instructorId, correctionId],
    );

    try {
      const title = decision === 'approved' ? 'Correction Request Approved' : 'Correction Request Rejected';
      const message =
        decision === 'approved'
          ? `Your attendance correction for ${correction.work_date} was approved.`
          : `Your attendance correction for ${correction.work_date} was rejected${reviewerNote ? `: ${reviewerNote}` : '.'}`;
      await pool.query(
        `INSERT INTO notifications (receiver_id, category, title, message, related_module)
         VALUES ($1, 'instructor', $2, $3, 'attendance')`,
        [correction.student_id, title, message],
      );
    } catch (notifyError) {
      console.error('Notify student of correction decision error:', notifyError);
    }

    res.json({ success: true, request: toCorrectionJson({ ...updated.rows[0], student_name: null, avatar_url: null }) });
  } catch (error) {
    console.error('Review correction request error:', error);
    res.status(500).json({ success: false, message: 'Failed to save decision.' });
  }
});

module.exports = router;
