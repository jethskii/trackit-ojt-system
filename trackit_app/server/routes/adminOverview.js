const express = require('express');
const pool = require('../db');
const { requireAdminAuth } = require('../middleware/adminAuth');
const { computeStage, computeProgressStatus } = require('../utils/progressStatus');
const { todayInManila } = require('../utils/manilaTime');

const router = express.Router();
router.use(requireAdminAuth);

// A student who hasn't clocked in by this hour (Philippine time) is
// "Late / Missed" rather than "Not Yet Clocked In" -- there's no
// per-company configured start time anywhere in the system, so this is
// a documented policy constant, the same way GEOFENCE_RADIUS_METERS and
// MAX_DAILY_ATTEMPTS are in attendance.js.
const LATE_CLOCK_IN_HOUR_PHT = 9;

const MS_PER_DAY = 24 * 60 * 60 * 1000;

function currentHourInManila() {
  return Number(
    new Intl.DateTimeFormat('en-US', {
      timeZone: 'Asia/Manila',
      hour: 'numeric',
      hour12: false,
    }).format(new Date()),
  );
}

function daysAgoInManila(days) {
  const [y, m, d] = todayInManila().split('-').map(Number);
  const todayUtcMidnight = Date.UTC(y, m - 1, d);
  const target = new Date(todayUtcMidnight - days * MS_PER_DAY);
  return target.toISOString().slice(0, 10);
}

// Everything the Admin Overview dashboard shows, for one academic year --
// deliberately one aggregation endpoint (mirroring teacherDashboard.js's
// shape, just school-wide and year-scoped) rather than a call per card, so
// the whole dashboard is one consistent snapshot instead of cards that can
// individually race and disagree with each other.
router.get('/', async (req, res) => {
  try {
    const academicYear = (req.query.academicYear || '').toString().trim();
    if (!academicYear) {
      return res.status(400).json({ success: false, message: 'academicYear is required.' });
    }

    // The full active-student roster for this year in one shot -- avoids
    // N+1 queries for the per-student computations below.
    const rosterResult = await pool.query(
      `SELECT s.id, s.name, s.email, s.student_number, s.required_hours, s.password_hash,
              s.company_id, sp.class_id, sp.ojt_start_date, sp.company_confirmed_at,
              sp.company_name, c.program, c.section, c.instructor_id,
              a.name AS instructor_name
       FROM students s
       JOIN student_profiles sp ON sp.student_id = s.id
       JOIN instructor_classes c ON c.id = sp.class_id
       LEFT JOIN advisers a ON a.id = c.instructor_id
       WHERE c.academic_year = $1
       ORDER BY s.name ASC`,
      [academicYear],
    );
    const roster = rosterResult.rows;
    const studentIds = roster.map((r) => Number(r.id));

    const instructorCountResult = await pool.query(
      `SELECT COUNT(DISTINCT c.instructor_id) AS count
       FROM instructor_classes c
       JOIN advisers a ON a.id = c.instructor_id AND a.status = 'active'
       WHERE c.academic_year = $1`,
      [academicYear],
    );
    const totalInstructors = Number(instructorCountResult.rows[0].count);

    if (studentIds.length === 0) {
      return res.json({
        success: true,
        overview: emptyOverview(academicYear, totalInstructors),
      });
    }

    const today = todayInManila();
    const weekAgo = daysAgoInManila(6);

    const [hoursResult, todayAttendanceResult, attendedThisWeekResult, docsResult, customDocsResult, correctionsResult] =
      await Promise.all([
        pool.query(
          `SELECT student_id,
                  COALESCE(SUM(EXTRACT(EPOCH FROM (clock_out - clock_in)) / 3600.0)
                    FILTER (WHERE clock_out IS NOT NULL), 0) AS completed_hours,
                  MAX(work_date) AS last_attendance_date
           FROM attendance_records
           WHERE student_id = ANY($1::bigint[])
           GROUP BY student_id`,
          [studentIds],
        ),
        pool.query(
          `SELECT student_id, clock_in, clock_out
           FROM attendance_records
           WHERE student_id = ANY($1::bigint[]) AND work_date = $2`,
          [studentIds, today],
        ),
        // "This week" is Philippine calendar days, computed the same way
        // "today" is (todayInManila()/daysAgoInManila) -- not a raw
        // 7*24h window and not the DB server's own idea of a day.
        pool.query(
          `SELECT DISTINCT student_id
           FROM attendance_records
           WHERE student_id = ANY($1::bigint[]) AND work_date >= $2`,
          [studentIds, weekAgo],
        ),
        pool.query(
          `SELECT srs.id, srs.student_id, s.name AS student_name, ort.name AS requirement_name,
                  srs.submitted_at
           FROM student_requirement_submissions srs
           JOIN students s ON s.id = srs.student_id
           JOIN ojt_requirement_templates ort ON ort.id = srs.requirement_template_id
           WHERE srs.student_id = ANY($1::bigint[]) AND srs.status = 'submitted'
           ORDER BY srs.submitted_at ASC`,
          [studentIds],
        ),
        pool.query(
          `SELECT scrs.id, scrs.student_id, s.name AS student_name, cr.title AS requirement_name,
                  scrs.submitted_at
           FROM student_custom_requirement_submissions scrs
           JOIN students s ON s.id = scrs.student_id
           JOIN custom_requirements cr ON cr.id = scrs.custom_requirement_id
           WHERE scrs.student_id = ANY($1::bigint[]) AND scrs.status = 'submitted'
           ORDER BY scrs.submitted_at ASC`,
          [studentIds],
        ),
        pool.query(
          `SELECT ac.id, ac.student_id, s.name AS student_name, ac.work_date, ac.reason,
                  ac.created_at
           FROM attendance_corrections ac
           JOIN students s ON s.id = ac.student_id
           WHERE ac.student_id = ANY($1::bigint[]) AND ac.status = 'pending'
           ORDER BY ac.created_at ASC`,
          [studentIds],
        ),
      ]);

    const hoursByStudent = new Map(hoursResult.rows.map((r) => [Number(r.student_id), r]));
    const todayByStudent = new Map(todayAttendanceResult.rows.map((r) => [Number(r.student_id), r]));
    const attendedThisWeek = new Set(attendedThisWeekResult.rows.map((r) => Number(r.student_id)));
    const nowHourPht = currentHourInManila();

    let completed = 0;
    let ongoing = 0;
    let notStarted = 0;
    let clockedIn = 0;
    let lateMissed = 0;
    let notYetClockedIn = 0;
    let totalRenderedHours = 0;
    let totalRequiredHours = 0;
    let accountsPreparing = [];
    let companyVerification = [];
    const belowHalfHours = [];
    const noAttendanceThisWeek = [];
    const behindSchedule = [];
    const studentList = [];
    const attendanceList = [];

    for (const row of roster) {
      const id = Number(row.id);
      const requiredHours = Number(row.required_hours);
      const hoursRow = hoursByStudent.get(id);
      const completedHours = hoursRow ? Number(hoursRow.completed_hours) : 0;
      const lastAttendanceDate = hoursRow ? hoursRow.last_attendance_date : null;
      const hasStarted = row.ojt_start_date != null;
      const isActivated = row.password_hash != null;

      const stage = computeStage({ completedHours, requiredHours, hasStarted });
      const completionBucket =
        stage === 'completed' ? 'completed' : stage === 'notStarted' ? 'notStarted' : 'ongoing';
      if (completionBucket === 'completed') completed++;
      else if (completionBucket === 'ongoing') ongoing++;
      else notStarted++;

      totalRenderedHours += completedHours;
      totalRequiredHours += requiredHours;

      const todayRow = todayByStudent.get(id);
      let todayStatus;
      if (todayRow && todayRow.clock_in) {
        todayStatus = 'clockedIn';
        clockedIn++;
      } else if (nowHourPht >= LATE_CLOCK_IN_HOUR_PHT) {
        todayStatus = 'lateMissed';
        lateMissed++;
      } else {
        todayStatus = 'notYetClockedIn';
        notYetClockedIn++;
      }

      if (!isActivated) {
        accountsPreparing.push({
          id,
          name: row.name,
          email: row.email,
          program: row.program,
          section: row.section,
        });
      }

      if (row.company_confirmed_at != null && row.company_id == null) {
        companyVerification.push({
          id,
          name: row.name,
          program: row.program,
          section: row.section,
          companyName: row.company_name,
        });
      }

      // At-risk buckets only apply to students actually underway --
      // a student who hasn't started yet isn't "behind," they're simply
      // not started (already its own, non-alarming completion bucket).
      if (hasStarted && stage !== 'completed') {
        if (completedHours < requiredHours * 0.5) {
          belowHalfHours.push({ id, name: row.name });
        }
        if (!attendedThisWeek.has(id)) {
          noAttendanceThisWeek.push({ id, name: row.name });
        }
        const progressStatus = computeProgressStatus({
          completedHours,
          requiredHours,
          ojtStartDate: row.ojt_start_date,
          lastAttendanceDate,
        });
        if (progressStatus === 'behind' || progressStatus === 'needsAttention') {
          behindSchedule.push({ id, name: row.name });
        }
      }

      studentList.push({
        id,
        name: row.name,
        program: row.program,
        section: row.section,
        instructorName: row.instructor_name,
        accountStatus: isActivated ? 'activated' : 'pending',
        completionBucket,
        completedHours,
        requiredHours,
      });

      attendanceList.push({
        id,
        name: row.name,
        program: row.program,
        section: row.section,
        status: todayStatus,
        clockIn: todayRow ? todayRow.clock_in : null,
        clockOut: todayRow ? todayRow.clock_out : null,
      });
    }

    const documentsAwaitingReview = [
      ...docsResult.rows.map((r) => ({
        id: `req-${r.id}`,
        studentName: r.student_name,
        requirementName: r.requirement_name,
        submittedAt: r.submitted_at,
      })),
      ...customDocsResult.rows.map((r) => ({
        id: `custom-${r.id}`,
        studentName: r.student_name,
        requirementName: r.requirement_name,
        submittedAt: r.submitted_at,
      })),
    ].sort((a, b) => new Date(a.submittedAt) - new Date(b.submittedAt));

    const correctionRequests = correctionsResult.rows.map((r) => ({
      id: r.id,
      studentName: r.student_name,
      workDate: r.work_date,
      reason: r.reason,
      createdAt: r.created_at,
    }));

    res.json({
      success: true,
      overview: {
        academicYear,
        totalStudents: roster.length,
        totalInstructors,
        completion: { completed, ongoing, notStarted, total: roster.length },
        attendanceToday: {
          clockedIn,
          lateMissed,
          notYetClockedIn,
          total: roster.length,
          lateClockInHourPht: LATE_CLOCK_IN_HOUR_PHT,
        },
        hours: {
          totalRendered: Math.round(totalRenderedHours * 10) / 10,
          totalRequired: totalRequiredHours,
          overallCompletionPercent:
            totalRequiredHours > 0
              ? Math.round((totalRenderedHours / totalRequiredHours) * 1000) / 10
              : 0,
        },
        pendingTasks: {
          accountsPreparing,
          documentsAwaitingReview,
          companyVerification,
          correctionRequests,
        },
        atRisk: { belowHalfHours, noAttendanceThisWeek, behindSchedule },
        studentList,
        attendanceList,
      },
    });
  } catch (error) {
    console.error('Get admin overview error:', error);
    res.status(500).json({ success: false, message: 'Failed to load overview.' });
  }
});

function emptyOverview(academicYear, totalInstructors) {
  return {
    academicYear,
    totalStudents: 0,
    totalInstructors,
    completion: { completed: 0, ongoing: 0, notStarted: 0, total: 0 },
    attendanceToday: {
      clockedIn: 0,
      lateMissed: 0,
      notYetClockedIn: 0,
      total: 0,
      lateClockInHourPht: LATE_CLOCK_IN_HOUR_PHT,
    },
    hours: { totalRendered: 0, totalRequired: 0, overallCompletionPercent: 0 },
    pendingTasks: {
      accountsPreparing: [],
      documentsAwaitingReview: [],
      companyVerification: [],
      correctionRequests: [],
    },
    atRisk: { belowHalfHours: [], noAttendanceThisWeek: [], behindSchedule: [] },
    studentList: [],
    attendanceList: [],
  };
}

module.exports = router;
