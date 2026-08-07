const express = require('express');
const pool = require('../db');
const { requireInstructorAuth } = require('../middleware/instructorAuth');

const router = express.Router();
router.use(requireInstructorAuth);

const SELECT_WITH_TARGETS = `
  SELECT a.*,
    COALESCE(
      json_agg(
        json_build_object('classId', c.id, 'program', c.program, 'section', c.section)
      ) FILTER (WHERE c.id IS NOT NULL),
      '[]'
    ) AS targets
  FROM announcements a
  LEFT JOIN announcement_targets at2 ON at2.announcement_id = a.id
  LEFT JOIN instructor_classes c ON c.id = at2.class_id
`;

router.get('/', async (req, res) => {
  try {
    const result = await pool.query(
      `${SELECT_WITH_TARGETS}
       WHERE a.instructor_id = $1
       GROUP BY a.id
       ORDER BY a.created_at DESC`,
      [req.instructorId],
    );
    res.json({ success: true, announcements: result.rows });
  } catch (error) {
    console.error('Get announcements error:', error);
    res.status(500).json({ success: false, message: 'Failed to load announcements.' });
  }
});

// Creating an announcement fans out into the student-facing notifications
// table for every student in the targeted classes -- this is what
// actually connects it to students, not just a post that sits on the
// instructor's side.
router.post('/', async (req, res) => {
  try {
    const { title, content, classIds } = req.body;
    if (!title || !content || !Array.isArray(classIds) || classIds.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'title, content, and at least one target section are required.',
      });
    }

    const ownedClasses = await pool.query(
      'SELECT id FROM instructor_classes WHERE id = ANY($1::bigint[]) AND instructor_id = $2',
      [classIds, req.instructorId],
    );
    if (ownedClasses.rows.length !== classIds.length) {
      return res
        .status(400)
        .json({ success: false, message: 'One or more target sections are invalid.' });
    }

    const inserted = await pool.query(
      'INSERT INTO announcements (instructor_id, title, content) VALUES ($1, $2, $3) RETURNING id',
      [req.instructorId, title.trim(), content.trim()],
    );
    const announcementId = inserted.rows[0].id;

    for (const classId of classIds) {
      await pool.query(
        'INSERT INTO announcement_targets (announcement_id, class_id) VALUES ($1, $2)',
        [announcementId, classId],
      );
    }

    await pool.query(
      `INSERT INTO notifications (receiver_id, category, title, message)
       SELECT sp.student_id, 'instructor', $1, $2
       FROM student_profiles sp
       WHERE sp.class_id = ANY($3::bigint[])`,
      [title.trim(), content.trim(), classIds],
    );

    const full = await pool.query(`${SELECT_WITH_TARGETS} WHERE a.id = $1 GROUP BY a.id`, [
      announcementId,
    ]);
    res.status(201).json({ success: true, announcement: full.rows[0] });
  } catch (error) {
    console.error('Create announcement error:', error);
    res.status(500).json({ success: false, message: 'Failed to create announcement.' });
  }
});

module.exports = router;
