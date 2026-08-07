const express = require('express');
const pool = require('../db');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();
router.use(requireAuth);

// The real, rich announcement feed for the Student Dashboard -- instructor
// name, title, content, image, timestamp -- read fresh from the
// announcements table (not the flattened notifications-table snapshot
// used for the badge count / Notifications tab), so edits are reflected
// immediately and nothing here is ever hardcoded or mocked.
router.get('/', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT a.id, a.title, a.content, a.image_url, a.created_at, adv.name AS instructor_name
       FROM announcements a
       JOIN advisers adv ON adv.id = a.instructor_id
       WHERE EXISTS (
         SELECT 1 FROM announcement_targets t
         JOIN student_profiles sp ON sp.class_id = t.class_id
         WHERE t.announcement_id = a.id AND sp.student_id = $1
       )
       ORDER BY a.created_at DESC`,
      [req.studentId],
    );
    res.json({
      success: true,
      announcements: result.rows.map((row) => ({
        id: Number(row.id),
        title: row.title,
        content: row.content,
        imageUrl: row.image_url,
        instructorName: row.instructor_name,
        createdAt: row.created_at,
      })),
    });
  } catch (error) {
    console.error('Get student announcements error:', error);
    res.status(500).json({ success: false, message: 'Failed to load announcements.' });
  }
});

module.exports = router;
