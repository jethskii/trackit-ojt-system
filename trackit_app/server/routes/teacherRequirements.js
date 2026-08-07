const express = require('express');
const pool = require('../db');
const { requireInstructorAuth } = require('../middleware/instructorAuth');
const { loadAssignedStudents } = require('./teacherStudents');

const router = express.Router();
router.use(requireInstructorAuth);

// A document counts toward "Completed" once approved, "Needs Review" once
// submitted and awaiting a decision, everything else ("missing", "pending",
// "rejected" -- i.e. needs the student to (re-)upload) counts as "Pending".
function bucketOf(status) {
  if (status === 'approved') return 'completed';
  if (status === 'submitted') return 'needsReview';
  return 'pending';
}

// Every assigned student's Official Requirements progress, for the
// "OJT Requirements" student list. Official-only (custom requirements are
// counted separately in the per-student detail view).
router.get('/students', async (req, res) => {
  try {
    const students = await loadAssignedStudents(req.instructorId);
    if (students.length === 0) {
      return res.json({ success: true, students: [] });
    }

    const totalResult = await pool.query('SELECT COUNT(*)::int AS total FROM ojt_requirement_templates');
    const totalDocuments = totalResult.rows[0].total;

    const studentIds = students.map((s) => s.id);
    const submissionsResult = await pool.query(
      'SELECT student_id, status FROM student_requirement_submissions WHERE student_id = ANY($1::bigint[])',
      [studentIds],
    );
    const byStudent = new Map();
    for (const row of submissionsResult.rows) {
      const list = byStudent.get(row.student_id) || [];
      list.push(row.status);
      byStudent.set(row.student_id, list);
    }

    let { search, status } = req.query;
    let result = students.map((student) => {
      const statuses = byStudent.get(student.id) || [];
      const completed = statuses.filter((s) => bucketOf(s) === 'completed').length;
      const needsReview = statuses.filter((s) => bucketOf(s) === 'needsReview').length;
      const pending = totalDocuments - completed - needsReview;
      return {
        id: Number(student.id),
        name: student.name,
        avatarUrl: student.avatar_url,
        course: student.course,
        section: student.section,
        totalDocuments,
        completedCount: completed,
        needsReviewCount: needsReview,
        pendingCount: pending,
        progress: totalDocuments > 0 ? completed / totalDocuments : 0,
      };
    });

    if (search) {
      const query = search.toString().toLowerCase();
      result = result.filter((s) => s.name.toLowerCase().includes(query));
    }
    if (status === 'needsReview') {
      result = result.filter((s) => s.needsReviewCount > 0);
    } else if (status === 'completed') {
      result = result.filter((s) => s.completedCount === s.totalDocuments && s.totalDocuments > 0);
    } else if (status === 'pending') {
      result = result.filter((s) => s.pendingCount > 0);
    }

    res.json({ success: true, students: result });
  } catch (error) {
    console.error('Get requirement students error:', error);
    res.status(500).json({ success: false, message: 'Failed to load students.' });
  }
});

async function assertOwnsStudent(instructorId, studentId) {
  const result = await pool.query(
    `SELECT s.id FROM students s
     JOIN student_profiles sp ON sp.student_id = s.id
     WHERE s.id = $1 AND sp.adviser_id = $2`,
    [studentId, instructorId],
  );
  return result.rows.length > 0;
}

// Official Requirements (phases/templates) + Additional Requirements
// (custom, targeted at the student's class), both merged with this
// student's real submissions -- the same shape the student's own
// GET /api/requirements uses, plus reviewer-facing fields.
router.get('/students/:studentId', async (req, res) => {
  try {
    const studentId = Number(req.params.studentId);
    const owns = await assertOwnsStudent(req.instructorId, studentId);
    if (!owns) {
      return res.status(404).json({ success: false, message: 'Student not found or not assigned to you.' });
    }

    const studentResult = await pool.query(
      'SELECT id, name, avatar_url, course, section FROM students WHERE id = $1',
      [studentId],
    );
    const student = studentResult.rows[0];

    const [phasesResult, templatesResult, submissionsResult] = await Promise.all([
      pool.query('SELECT * FROM ojt_requirement_phases ORDER BY order_index ASC'),
      pool.query('SELECT * FROM ojt_requirement_templates ORDER BY phase_id, sort_order ASC'),
      pool.query('SELECT * FROM student_requirement_submissions WHERE student_id = $1', [studentId]),
    ]);
    const submissionsByTemplate = new Map(
      submissionsResult.rows.map((s) => [s.requirement_template_id, s]),
    );

    const phasesWithDocs = phasesResult.rows.map((phase) => {
      const documents = templatesResult.rows
        .filter((t) => t.phase_id === phase.id)
        .map((template) => {
          const submission = submissionsByTemplate.get(template.id);
          return {
            id: Number(template.id),
            submissionId: submission ? Number(submission.id) : null,
            name: template.name,
            description: template.description,
            status: submission ? submission.status : 'missing',
            uploadedFileName: submission ? submission.uploaded_file_name : null,
            uploadedFileUrl: submission ? submission.uploaded_file_url : null,
            submittedAt: submission ? submission.submitted_at : null,
            reviewedAt: submission ? submission.reviewed_at : null,
            remarks: submission ? submission.remarks : null,
          };
        });
      const fulfilled = documents.every((d) => d.status === 'submitted' || d.status === 'approved');
      return {
        id: Number(phase.id),
        order: phase.order_index,
        title: phase.title,
        description: phase.description,
        documents,
        fulfilled,
      };
    });

    let previousCompleted = true;
    const phases = phasesWithDocs.map((phase) => {
      let status;
      if (!previousCompleted) status = 'locked';
      else if (phase.fulfilled) status = 'completed';
      else status = 'inProgress';
      previousCompleted = phase.fulfilled;
      return { ...phase, status };
    });

    const customResult = await pool.query(
      `SELECT cr.*, scs.id AS submission_id, scs.status AS submission_status,
              scs.uploaded_file_name, scs.uploaded_file_url, scs.submitted_at,
              scs.reviewed_at, scs.remarks
       FROM custom_requirements cr
       JOIN custom_requirement_targets crt ON crt.custom_requirement_id = cr.id
       JOIN instructor_classes ic ON ic.id = crt.class_id
       JOIN student_profiles sp ON sp.class_id = ic.id
       LEFT JOIN student_custom_requirement_submissions scs
         ON scs.custom_requirement_id = cr.id AND scs.student_id = $1
       WHERE sp.student_id = $1 AND cr.instructor_id = $2
       ORDER BY cr.created_at DESC`,
      [studentId, req.instructorId],
    );
    const customRequirements = customResult.rows.map((row) => ({
      id: Number(row.id),
      submissionId: row.submission_id ? Number(row.submission_id) : null,
      name: row.title,
      description: row.description,
      deadline: row.deadline,
      status: row.submission_status || 'missing',
      uploadedFileName: row.uploaded_file_name,
      uploadedFileUrl: row.uploaded_file_url,
      submittedAt: row.submitted_at,
      reviewedAt: row.reviewed_at,
      remarks: row.remarks,
    }));

    const allDocs = [...phases.flatMap((p) => p.documents), ...customRequirements];
    const summary = {
      completed: allDocs.filter((d) => bucketOf(d.status) === 'completed').length,
      needsReview: allDocs.filter((d) => bucketOf(d.status) === 'needsReview').length,
      pending: allDocs.filter((d) => bucketOf(d.status) === 'pending').length,
    };

    res.json({
      success: true,
      student: {
        id: Number(student.id),
        name: student.name,
        avatarUrl: student.avatar_url,
        course: student.course,
        section: student.section,
      },
      summary,
      phases,
      customRequirements,
    });
  } catch (error) {
    console.error('Get requirement student detail error:', error);
    res.status(500).json({ success: false, message: 'Failed to load student requirements.' });
  }
});

async function notifyStudentOfDecision(studentId, { requirementName, decision, remarks }) {
  const title = decision === 'approved' ? 'Requirement Approved' : 'Requirement Needs Re-upload';
  const message =
    decision === 'approved'
      ? `Your instructor approved "${requirementName}".`
      : `Your instructor requested a re-upload for "${requirementName}"${remarks ? `: ${remarks}` : '.'}`;
  await pool.query(
    `INSERT INTO notifications (receiver_id, category, title, message, related_module)
     VALUES ($1, 'instructor', $2, $3, 'requirements')`,
    [studentId, title, message],
  );
}

// Approve or request a re-upload for an Official Requirement submission.
router.patch('/submissions/:submissionId', async (req, res) => {
  try {
    const submissionId = Number(req.params.submissionId);
    const { decision, remarks } = req.body;
    if (decision !== 'approved' && decision !== 'rejected') {
      return res.status(400).json({ success: false, message: 'decision must be "approved" or "rejected".' });
    }

    const existing = await pool.query(
      `SELECT srs.*, t.name AS template_name FROM student_requirement_submissions srs
       JOIN ojt_requirement_templates t ON t.id = srs.requirement_template_id
       JOIN student_profiles sp ON sp.student_id = srs.student_id
       WHERE srs.id = $1 AND sp.adviser_id = $2`,
      [submissionId, req.instructorId],
    );
    if (existing.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Submission not found.' });
    }
    const submission = existing.rows[0];

    const updated = await pool.query(
      `UPDATE student_requirement_submissions
       SET status = $1, remarks = $2, reviewed_at = now(), reviewed_by = $3, updated_at = now()
       WHERE id = $4
       RETURNING *`,
      [decision, remarks || null, req.instructorId, submissionId],
    );

    try {
      await notifyStudentOfDecision(submission.student_id, {
        requirementName: submission.template_name,
        decision,
        remarks,
      });
    } catch (notifyError) {
      console.error('Notify student of requirement decision error:', notifyError);
    }

    res.json({ success: true, submission: updated.rows[0] });
  } catch (error) {
    console.error('Review requirement submission error:', error);
    res.status(500).json({ success: false, message: 'Failed to save decision.' });
  }
});

// Approve or request a re-upload for an Additional (custom) Requirement
// submission. Uses the same status enum and decision flow as official ones.
router.patch('/custom-submissions/:submissionId', async (req, res) => {
  try {
    const submissionId = Number(req.params.submissionId);
    const { decision, remarks } = req.body;
    if (decision !== 'approved' && decision !== 'rejected') {
      return res.status(400).json({ success: false, message: 'decision must be "approved" or "rejected".' });
    }

    const existing = await pool.query(
      `SELECT scs.*, cr.title FROM student_custom_requirement_submissions scs
       JOIN custom_requirements cr ON cr.id = scs.custom_requirement_id
       WHERE scs.id = $1 AND cr.instructor_id = $2`,
      [submissionId, req.instructorId],
    );
    if (existing.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Submission not found.' });
    }
    const submission = existing.rows[0];

    const updated = await pool.query(
      `UPDATE student_custom_requirement_submissions
       SET status = $1, remarks = $2, reviewed_at = now(), reviewed_by = $3, updated_at = now()
       WHERE id = $4
       RETURNING *`,
      [decision, remarks || null, req.instructorId, submissionId],
    );

    try {
      await notifyStudentOfDecision(submission.student_id, {
        requirementName: submission.title,
        decision,
        remarks,
      });
    } catch (notifyError) {
      console.error('Notify student of custom requirement decision error:', notifyError);
    }

    res.json({ success: true, submission: updated.rows[0] });
  } catch (error) {
    console.error('Review custom requirement submission error:', error);
    res.status(500).json({ success: false, message: 'Failed to save decision.' });
  }
});

const CUSTOM_WITH_TARGETS = `
  SELECT cr.*,
    COALESCE(
      json_agg(
        json_build_object('classId', c.id, 'program', c.program, 'section', c.section)
      ) FILTER (WHERE c.id IS NOT NULL),
      '[]'
    ) AS targets
  FROM custom_requirements cr
  LEFT JOIN custom_requirement_targets crt ON crt.custom_requirement_id = cr.id
  LEFT JOIN instructor_classes c ON c.id = crt.class_id
`;

function toCustomRequirementJson(row) {
  return { ...row, id: Number(row.id), instructor_id: Number(row.instructor_id) };
}

router.get('/custom', async (req, res) => {
  try {
    const result = await pool.query(
      `${CUSTOM_WITH_TARGETS} WHERE cr.instructor_id = $1 GROUP BY cr.id ORDER BY cr.created_at DESC`,
      [req.instructorId],
    );
    res.json({ success: true, requirements: result.rows.map(toCustomRequirementJson) });
  } catch (error) {
    console.error('Get custom requirements error:', error);
    res.status(500).json({ success: false, message: 'Failed to load additional requirements.' });
  }
});

router.post('/custom', async (req, res) => {
  try {
    const { title, description, deadline, classIds } = req.body;
    if (!title || !Array.isArray(classIds) || classIds.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'title and at least one target section are required.',
      });
    }

    const ownedClasses = await pool.query(
      'SELECT id FROM instructor_classes WHERE id = ANY($1::bigint[]) AND instructor_id = $2',
      [classIds, req.instructorId],
    );
    if (ownedClasses.rows.length !== classIds.length) {
      return res.status(400).json({ success: false, message: 'One or more target sections are invalid.' });
    }

    const inserted = await pool.query(
      'INSERT INTO custom_requirements (instructor_id, title, description, deadline) VALUES ($1, $2, $3, $4) RETURNING id',
      [req.instructorId, title.trim(), (description || '').trim(), deadline || null],
    );
    const requirementId = inserted.rows[0].id;

    for (const classId of classIds) {
      await pool.query(
        'INSERT INTO custom_requirement_targets (custom_requirement_id, class_id) VALUES ($1, $2)',
        [requirementId, classId],
      );
    }

    const full = await pool.query(`${CUSTOM_WITH_TARGETS} WHERE cr.id = $1 GROUP BY cr.id`, [
      requirementId,
    ]);
    res.status(201).json({ success: true, requirement: toCustomRequirementJson(full.rows[0]) });
  } catch (error) {
    console.error('Create custom requirement error:', error);
    res.status(500).json({ success: false, message: 'Failed to create additional requirement.' });
  }
});

module.exports = router;
