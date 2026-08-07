const express = require('express');
const pool = require('../db');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();
router.use(requireAuth);

const GEOFENCE_RADIUS_METERS = 100;
const EARTH_RADIUS_METERS = 6371000;

function todayDateString() {
  return new Date().toISOString().slice(0, 10);
}

function toRadians(degrees) {
  return (degrees * Math.PI) / 180;
}

// Great-circle distance between two lat/lng points, in meters.
function haversineDistanceMeters(lat1, lon1, lat2, lon2) {
  const dLat = toRadians(lat2 - lat1);
  const dLon = toRadians(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRadians(lat1)) * Math.cos(toRadians(lat2)) * Math.sin(dLon / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return EARTH_RADIUS_METERS * c;
}

// Confirms the student is within GEOFENCE_RADIUS_METERS of their
// self-reported company location (set via Confirm Company Details).
// Returns null on success, or a { status, message } to send back.
async function checkGeofence(studentId, latitude, longitude) {
  if (typeof latitude !== 'number' || typeof longitude !== 'number') {
    return {
      status: 400,
      message: 'Your device location is required to clock in/out.',
    };
  }

  const result = await pool.query(
    'SELECT company_latitude, company_longitude FROM student_profiles WHERE student_id = $1',
    [studentId],
  );
  const profile = result.rows[0];
  if (!profile || profile.company_latitude == null || profile.company_longitude == null) {
    return {
      status: 400,
      message:
        'Set your company location first from Document > OJT Requirements > ' +
        'Confirm Company Details before clocking in/out.',
    };
  }

  const distance = haversineDistanceMeters(
    latitude,
    longitude,
    Number(profile.company_latitude),
    Number(profile.company_longitude),
  );
  if (distance > GEOFENCE_RADIUS_METERS) {
    return {
      status: 403,
      message: `You're ${Math.round(distance)}m away from your company. Move within ${GEOFENCE_RADIUS_METERS}m to clock in/out.`,
    };
  }

  return null;
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
    const { latitude, longitude } = req.body;
    const geofenceError = await checkGeofence(req.studentId, latitude, longitude);
    if (geofenceError) {
      return res
        .status(geofenceError.status)
        .json({ success: false, message: geofenceError.message });
    }

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
    const { latitude, longitude } = req.body;
    const geofenceError = await checkGeofence(req.studentId, latitude, longitude);
    if (geofenceError) {
      return res
        .status(geofenceError.status)
        .json({ success: false, message: geofenceError.message });
    }

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

function toCorrectionJson(row) {
  return {
    id: row.id,
    workDate: row.work_date,
    reason: row.reason,
    attachmentFileName: row.attachment_file_name,
    status: row.status,
    submittedAt: row.created_at,
    reviewerNote: row.reviewer_note,
  };
}

router.get('/corrections', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT * FROM attendance_corrections
       WHERE student_id = $1
       ORDER BY created_at DESC`,
      [req.studentId],
    );
    res.json({ success: true, requests: result.rows.map(toCorrectionJson) });
  } catch (error) {
    console.error('Get correction requests error:', error);
    res
      .status(500)
      .json({ success: false, message: 'Failed to load correction requests.' });
  }
});

// Routed to an instructor for approve/reject -- there's no Instructor
// module yet to actually do that review, so this just persists the
// request as 'pending' (see the migration file's note on this table).
router.post('/corrections', async (req, res) => {
  try {
    const { workDate, reason, attachmentFileName } = req.body;
    if (!workDate || !reason) {
      return res
        .status(400)
        .json({ success: false, message: 'Attendance date and reason are required.' });
    }

    const result = await pool.query(
      `INSERT INTO attendance_corrections (student_id, work_date, reason, attachment_file_name)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [req.studentId, workDate, reason, attachmentFileName || null],
    );
    res.status(201).json({ success: true, request: toCorrectionJson(result.rows[0]) });
  } catch (error) {
    console.error('Submit correction request error:', error);
    res
      .status(500)
      .json({ success: false, message: 'Failed to submit correction request.' });
  }
});

module.exports = router;
