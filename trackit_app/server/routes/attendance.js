const express = require('express');
const pool = require('../db');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();
router.use(requireAuth);

function todayDateString() {
  return new Date().toISOString().slice(0, 10);
}

router.get('/today', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM attendance_records WHERE student_id = $1 AND work_date = $2',
      [req.studentId, todayDateString()],
    );
    res.json({ success: true, attendance: result.rows[0] || null });
  } catch (error) {
    console.error('Get today attendance error:', error);
    res.status(500).json({ success: false, message: 'Failed to load attendance.' });
  }
});

router.post('/clock-in', async (req, res) => {
  try {
    const today = todayDateString();
    const existing = await pool.query(
      'SELECT * FROM attendance_records WHERE student_id = $1 AND work_date = $2',
      [req.studentId, today],
    );
    if (existing.rows.length > 0 && existing.rows[0].clock_in) {
      return res.status(409).json({ success: false, message: 'Already clocked in today.' });
    }

    const result = await pool.query(
      `INSERT INTO attendance_records (student_id, work_date, clock_in)
       VALUES ($1, $2, now())
       ON CONFLICT (student_id, work_date)
       DO UPDATE SET clock_in = now(), updated_at = now()
       RETURNING *`,
      [req.studentId, today],
    );
    res.json({ success: true, attendance: result.rows[0] });
  } catch (error) {
    console.error('Clock in error:', error);
    res.status(500).json({ success: false, message: 'Failed to clock in.' });
  }
});

router.post('/clock-out', async (req, res) => {
  try {
    const today = todayDateString();
    const existing = await pool.query(
      'SELECT * FROM attendance_records WHERE student_id = $1 AND work_date = $2',
      [req.studentId, today],
    );
    if (existing.rows.length === 0 || !existing.rows[0].clock_in) {
      return res.status(409).json({ success: false, message: 'You need to clock in first.' });
    }
    if (existing.rows[0].clock_out) {
      return res.status(409).json({ success: false, message: 'Already clocked out today.' });
    }

    const result = await pool.query(
      `UPDATE attendance_records SET clock_out = now(), updated_at = now()
       WHERE student_id = $1 AND work_date = $2
       RETURNING *`,
      [req.studentId, today],
    );
    res.json({ success: true, attendance: result.rows[0] });
  } catch (error) {
    console.error('Clock out error:', error);
    res.status(500).json({ success: false, message: 'Failed to clock out.' });
  }
});

router.get('/history', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT * FROM attendance_records
       WHERE student_id = $1 AND clock_out IS NOT NULL
       ORDER BY work_date DESC
       LIMIT 30`,
      [req.studentId],
    );
    res.json({ success: true, history: result.rows });
  } catch (error) {
    console.error('Get attendance history error:', error);
    res.status(500).json({ success: false, message: 'Failed to load attendance history.' });
  }
});

// Completed hours, days attended, and hour averages are computed here
// from attendance_records rather than stored redundantly (see the
// comment in schema.sql).
router.get('/progress', async (req, res) => {
  try {
    const studentResult = await pool.query(
      'SELECT required_hours FROM students WHERE id = $1',
      [req.studentId],
    );
    if (studentResult.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Student not found.' });
    }
    const requiredHours = studentResult.rows[0].required_hours;

    const totals = await pool.query(
      `SELECT
         COUNT(*) FILTER (WHERE clock_out IS NOT NULL) AS days_attended,
         COALESCE(SUM(EXTRACT(EPOCH FROM (clock_out - clock_in)) / 3600.0)
           FILTER (WHERE clock_out IS NOT NULL), 0) AS completed_hours
       FROM attendance_records
       WHERE student_id = $1`,
      [req.studentId],
    );
    const daysAttended = Number(totals.rows[0].days_attended);
    const completedHours = Number(totals.rows[0].completed_hours);

    const weekly = await pool.query(
      `SELECT COALESCE(SUM(EXTRACT(EPOCH FROM (clock_out - clock_in)) / 3600.0), 0) AS weekly_hours
       FROM attendance_records
       WHERE student_id = $1 AND clock_out IS NOT NULL
         AND work_date >= (CURRENT_DATE - INTERVAL '7 days')`,
      [req.studentId],
    );
    const weeklyAverageHours = Number(weekly.rows[0].weekly_hours);
    const averageHoursPerDay = daysAttended > 0 ? completedHours / daysAttended : 0;

    res.json({
      success: true,
      progress: {
        completedHours,
        totalHours: Number(requiredHours),
        daysAttended,
        averageHoursPerDay,
        weeklyAverageHours,
        // Simplified heuristic pending an OJT start-date field to compute
        // a real expected-pace comparison.
        aheadOfSchedule: completedHours > 0,
      },
    });
  } catch (error) {
    console.error('Get progress error:', error);
    res.status(500).json({ success: false, message: 'Failed to load progress.' });
  }
});

module.exports = router;
