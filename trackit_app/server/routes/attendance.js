const express = require('express');
const pool = require('../db');
const { requireAuth } = require('../middleware/auth');
const { computeProgressStatus } = require('../utils/progressStatus');
const { notifyInstructorForStudent } = require('../utils/notifyInstructor');

const router = express.Router();
router.use(requireAuth);

const GEOFENCE_RADIUS_METERS = 100;
const EARTH_RADIUS_METERS = 6371000;
// Only a successful clock-in spends an attempt (see the migration file's
// comment) -- 2 per calendar day, tracked server-side on
// attendance_records.attempts_used, enforced atomically so it can't be
// bypassed by rapid double-clicks, duplicate requests, refreshing, or
// switching devices.
const MAX_DAILY_ATTEMPTS = 2;

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
    res.json({
      success: true,
      attendance: result.rows[0] || null,
      maxAttempts: MAX_DAILY_ATTEMPTS,
    });
  } catch (error) {
    console.error('Get today attendance error:', error);
    res.status(500).json({ success: false, message: 'Failed to load attendance.' });
  }
});

// Clock In consumes one of the day's 2 attempts. The INSERT/UPDATE below is
// a single atomic statement: the eligibility check (no session already
// open, attempts left) and the write happen together, so a duplicate or
// rapid double-tapped request can't both pass the check and both write --
// only one can ever succeed, and a request that fails the WHERE guard
// writes nothing at all (no attempt is spent on a rejected request). A new
// cycle clears clock_out so the student can clock out again for it.
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
    const result = await pool.query(
      `INSERT INTO attendance_records (student_id, work_date, clock_in, clock_out, attempts_used)
       VALUES ($1, $2, now(), NULL, 1)
       ON CONFLICT (student_id, work_date) DO UPDATE
         SET clock_in = now(), clock_out = NULL,
             attempts_used = attendance_records.attempts_used + 1,
             updated_at = now()
         WHERE NOT (attendance_records.clock_in IS NOT NULL AND attendance_records.clock_out IS NULL)
           AND attendance_records.attempts_used < $3
       RETURNING *`,
      [req.studentId, today, MAX_DAILY_ATTEMPTS],
    );

    if (result.rows.length === 0) {
      const existing = await pool.query(
        'SELECT * FROM attendance_records WHERE student_id = $1 AND work_date = $2',
        [req.studentId, today],
      );
      const row = existing.rows[0];
      if (row && row.clock_in && !row.clock_out) {
        return res.status(409).json({ success: false, message: 'Already clocked in today.' });
      }
      return res.status(403).json({
        success: false,
        message: `You've used all ${MAX_DAILY_ATTEMPTS} of your clocking attempts for today.`,
      });
    }

    res.json({ success: true, attendance: result.rows[0] });
  } catch (error) {
    console.error('Clock in error:', error);
    res.status(500).json({ success: false, message: 'Failed to clock in.' });
  }
});

// Clock Out just closes whatever session is currently open -- it never
// spends an attempt, so it's always available once clocked in, regardless
// of how many attempts remain. Same atomic-guard pattern as clock-in.
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
    const result = await pool.query(
      `UPDATE attendance_records SET clock_out = now(), updated_at = now()
       WHERE student_id = $1 AND work_date = $2
         AND clock_in IS NOT NULL AND clock_out IS NULL
       RETURNING *`,
      [req.studentId, today],
    );

    if (result.rows.length === 0) {
      const existing = await pool.query(
        'SELECT * FROM attendance_records WHERE student_id = $1 AND work_date = $2',
        [req.studentId, today],
      );
      const row = existing.rows[0];
      if (!row || !row.clock_in) {
        return res.status(409).json({ success: false, message: 'You need to clock in first.' });
      }
      return res.status(409).json({ success: false, message: 'Already clocked out today.' });
    }

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
    const requiredHours = Number(studentResult.rows[0].required_hours);

    const totals = await pool.query(
      `SELECT
         COUNT(*) FILTER (WHERE clock_out IS NOT NULL) AS days_attended,
         COALESCE(SUM(EXTRACT(EPOCH FROM (clock_out - clock_in)) / 3600.0)
           FILTER (WHERE clock_out IS NOT NULL), 0) AS completed_hours,
         MAX(work_date) FILTER (WHERE clock_out IS NOT NULL) AS last_attendance_date
       FROM attendance_records
       WHERE student_id = $1`,
      [req.studentId],
    );
    const daysAttended = Number(totals.rows[0].days_attended);
    const completedHours = Number(totals.rows[0].completed_hours);
    const lastAttendanceDate = totals.rows[0].last_attendance_date;

    const weekly = await pool.query(
      `SELECT COALESCE(SUM(EXTRACT(EPOCH FROM (clock_out - clock_in)) / 3600.0), 0) AS weekly_hours
       FROM attendance_records
       WHERE student_id = $1 AND clock_out IS NOT NULL
         AND work_date >= (CURRENT_DATE - INTERVAL '7 days')`,
      [req.studentId],
    );
    const weeklyAverageHours = Number(weekly.rows[0].weekly_hours);
    const averageHoursPerDay = daysAttended > 0 ? completedHours / daysAttended : 0;

    const profileResult = await pool.query(
      'SELECT ojt_start_date FROM student_profiles WHERE student_id = $1',
      [req.studentId],
    );
    const ojtStartDate = profileResult.rows[0]?.ojt_start_date ?? null;

    const status = computeProgressStatus({
      completedHours,
      requiredHours,
      ojtStartDate,
      lastAttendanceDate,
    });

    res.json({
      success: true,
      progress: {
        completedHours,
        totalHours: requiredHours,
        daysAttended,
        averageHoursPerDay,
        weeklyAverageHours,
        status,
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

    try {
      const studentResult = await pool.query('SELECT name FROM students WHERE id = $1', [
        req.studentId,
      ]);
      const studentName = studentResult.rows[0]?.name;
      if (studentName) {
        await notifyInstructorForStudent(req.studentId, {
          title: 'Attendance Correction Requested',
          message: `${studentName} requested an attendance correction for ${workDate}.`,
          relatedModule: 'attendance',
        });
      }
    } catch (notifyError) {
      console.error('Notify instructor of correction request error:', notifyError);
    }

    res.status(201).json({ success: true, request: toCorrectionJson(result.rows[0]) });
  } catch (error) {
    console.error('Submit correction request error:', error);
    res
      .status(500)
      .json({ success: false, message: 'Failed to submit correction request.' });
  }
});

module.exports = router;
