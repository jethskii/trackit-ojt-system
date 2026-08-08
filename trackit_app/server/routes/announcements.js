const express = require('express');
const pool = require('../db');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();
router.use(requireAuth);

// The real, rich announcement feed for the Student Dashboard -- author
// name, title, content, image, timestamp -- read fresh from the source
// tables (not the flattened notifications-table snapshot used for the
// badge count / Notifications tab), so edits are reflected immediately
// and nothing here is ever hardcoded or mocked. Unions two sources:
// instructor announcements targeted at the student's class, and admin
// announcements broadcast to 'all' or 'students'.
router.get('/', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT a.id, a.title, a.content, a.image_url, a.created_at,
              adv.name AS author_name, 'instructor' AS source
       FROM announcements a
       JOIN advisers adv ON adv.id = a.instructor_id
       WHERE EXISTS (
         SELECT 1 FROM announcement_targets t
         JOIN student_profiles sp ON sp.class_id = t.class_id
         WHERE t.announcement_id = a.id AND sp.student_id = $1
       )
       UNION ALL
       SELECT aa.id, aa.title, aa.content, aa.image_url, aa.created_at,
              adm.name AS author_name, 'admin' AS source
       FROM admin_announcements aa
       JOIN admins adm ON adm.id = aa.admin_id
       WHERE aa.target_audience IN ('all', 'students')
       ORDER BY created_at DESC`,
      [req.studentId],
    );
    res.json({
      success: true,
      announcements: result.rows.map((row) => ({
        id: Number(row.id),
        title: row.title,
        content: row.content,
        imageUrl: row.image_url,
        authorName: row.author_name,
        source: row.source,
        createdAt: row.created_at,
      })),
    });
  } catch (error) {
    console.error('Get student announcements error:', error);
    res.status(500).json({ success: false, message: 'Failed to load announcements.' });
  }
});

module.exports = router;
