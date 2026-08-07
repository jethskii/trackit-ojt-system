const express = require('express');
const pool = require('../db');
const { requireInstructorAuth } = require('../middleware/instructorAuth');
const { computeProgressStatus, computeStage } = require('../utils/progressStatus');

const router = express.Router();
router.use(requireInstructorAuth);

// Shared by the list and detail endpoints: every assigned student, joined
// with what's needed to compute hours/pace/stage. Scoped to this
// instructor's own students only.
async function loadAssignedStudents(instructorId) {
  const studentsResult = await pool.query(
    `SELECT s.id, s.name, s.email, s.course, s.section, s.student_number,
            s.year_level, s.avatar_url, s.required_hours,
            sp.emergency_contact, sp.company_name, sp.company_address,
            sp.company_supervisor_name, sp.company_contact_number,
            sp.ojt_start_date
     FROM students s
     JOIN student_profiles sp ON sp.student_id = s.id
     WHERE sp.adviser_id = $1
     ORDER BY s.name ASC`,
    [instructorId],
  );
  const students = studentsResult.rows;
  if (students.length === 0) return [];

  const studentIds = students.map((s) => s.id);
  const hoursResult = await pool.query(
    `SELECT student_id,
       COUNT(*) FILTER (WHERE clock_out IS NOT NULL) AS days_attended,
       COALESCE(SUM(EXTRACT(EPOCH FROM (clock_out - clock_in)) / 3600.0)
         FILTER (WHERE clock_out IS NOT NULL), 0) AS completed_hours,
       MAX(work_date) FILTER (WHERE clock_out IS NOT NULL) AS last_attendance_date
     FROM attendance_records
     WHERE student_id = ANY($1::bigint[])
     GROUP BY student_id`,
    [studentIds],
  );
  const hoursByStudent = new Map(hoursResult.rows.map((r) => [r.student_id, r]));

  return students.map((student) => {
    const hours = hoursByStudent.get(student.id);
    const completedHours = hours ? Number(hours.completed_hours) : 0;
    const daysAttended = hours ? Number(hours.days_attended) : 0;
    const lastAttendanceDate = hours ? hours.last_attendance_date : null;
    const requiredHours = Number(student.required_hours);
    const hasStarted = student.ojt_start_date != null;

    return {
      ...student,
      completedHours,
      daysAttended,
      lastAttendanceDate,
      requiredHours,
      stage: computeStage({ completedHours, requiredHours, hasStarted }),
      progressStatus: computeProgressStatus({
        completedHours,
        requiredHours,
        ojtStartDate: student.ojt_start_date,
        lastAttendanceDate,
      }),
    };
  });
}

function toSummaryJson(student) {
  return {
    id: Number(student.id),
    name: student.name,
    avatarUrl: student.avatar_url,
    course: student.course,
    section: student.section,
    companyName: student.company_name,
    completedHours: student.completedHours,
    requiredHours: student.requiredHours,
    stage: student.stage,
    progressStatus: student.progressStatus,
  };
}

router.get('/', async (req, res) => {
  try {
    const { search, company, stage, progress, sortBy, sortDir } = req.query;
    let students = await loadAssignedStudents(req.instructorId);

    if (search) {
      const query = search.toString().toLowerCase();
      students = students.filter((s) => s.name.toLowerCase().includes(query));
    }
    if (company) {
      if (company === 'none') {
        students = students.filter((s) => !s.company_name);
      } else {
        students = students.filter((s) => s.company_name === company);
      }
    }
    if (stage) {
      students = students.filter((s) => s.stage === stage);
    }
    if (progress) {
      students = students.filter((s) => s.progressStatus === progress);
    }

    const direction = sortDir === 'desc' ? -1 : 1;
    if (sortBy === 'progress') {
      students.sort(
        (a, b) =>
          direction *
          (a.completedHours / (a.requiredHours || 1) -
            b.completedHours / (b.requiredHours || 1)),
      );
    } else {
      students.sort((a, b) => direction * a.name.localeCompare(b.name));
    }

    res.json({ success: true, students: students.map(toSummaryJson) });
  } catch (error) {
    console.error('Get teacher students error:', error);
    res.status(500).json({ success: false, message: 'Failed to load students.' });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const studentId = Number(req.params.id);
    const students = await loadAssignedStudents(req.instructorId);
    // s.id comes straight from a pg BIGINT column, which node-postgres
    // returns as a string -- compare numerically, not by reference type.
    const student = students.find((s) => Number(s.id) === studentId);
    if (!student) {
      return res
        .status(404)
        .json({ success: false, message: 'Student not found or not assigned to you.' });
    }

    const weeklyResult = await pool.query(
      `SELECT COALESCE(SUM(EXTRACT(EPOCH FROM (clock_out - clock_in)) / 3600.0), 0) AS weekly_hours
       FROM attendance_records
       WHERE student_id = $1 AND clock_out IS NOT NULL
         AND work_date >= (CURRENT_DATE - INTERVAL '7 days')`,
      [studentId],
    );
    const weeklyAverageHours = Number(weeklyResult.rows[0].weekly_hours);
    const averageHoursPerDay =
      student.daysAttended > 0 ? student.completedHours / student.daysAttended : 0;

    res.json({
      success: true,
      student: {
        id: Number(student.id),
        name: student.name,
        email: student.email,
        course: student.course,
        section: student.section,
        studentNumber: student.student_number,
        yearLevel: student.year_level,
        avatarUrl: student.avatar_url,
        contactPerson: student.emergency_contact,
        company: student.company_name
          ? {
              name: student.company_name,
              address: student.company_address,
              supervisorName: student.company_supervisor_name,
              contactNumber: student.company_contact_number,
            }
          : null,
        progress: {
          completedHours: student.completedHours,
          requiredHours: student.requiredHours,
          daysAttended: student.daysAttended,
          averageHoursPerDay,
          weeklyAverageHours,
          lastAttendanceDate: student.lastAttendanceDate,
        },
        stage: student.stage,
        progressStatus: student.progressStatus,
      },
    });
  } catch (error) {
    console.error('Get teacher student detail error:', error);
    res.status(500).json({ success: false, message: 'Failed to load student.' });
  }
});

module.exports = router;
