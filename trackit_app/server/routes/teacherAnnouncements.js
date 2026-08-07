const express = require('express');
const fs = require('fs');
const multer = require('multer');
const path = require('path');
const pool = require('../db');
const { requireInstructorAuth } = require('../middleware/instructorAuth');

const router = express.Router();
router.use(requireInstructorAuth);

const storage = multer.diskStorage({
  destination: path.join(__dirname, '..', 'uploads', 'announcements'),
  filename: (req, file, cb) => {
    const unique = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    cb(null, `${unique}${path.extname(file.originalname)}`);
  },
});
const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowed = ['image/jpeg', 'image/png', 'image/webp'];
    cb(null, allowed.includes(file.mimetype));
  },
});

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

function deleteImageFile(imageUrl) {
  if (!imageUrl) return;
  const filePath = path.join(__dirname, '..', imageUrl.replace(/^\//, ''));
  fs.unlink(filePath, (err) => {
    if (err && err.code !== 'ENOENT') {
      console.error('Failed to delete announcement image file:', err);
    }
  });
}

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
// table (so it shows up in the badge count / Notifications tab), but the
// rich content students see on their Dashboard -- instructor name, image,
// etc. -- is read fresh from GET /api/announcements, not this snapshot.
// The image is optional: multer's fileFilter above silently skips
// non-image files rather than erroring, so req.file is only set when a
// valid image was actually attached.
router.post('/', upload.single('image'), async (req, res) => {
  try {
    const { title, content } = req.body;
    const classIds = JSON.parse(req.body.classIds || '[]');
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

    const imageUrl = req.file ? `/uploads/announcements/${req.file.filename}` : null;

    const inserted = await pool.query(
      'INSERT INTO announcements (instructor_id, title, content, image_url) VALUES ($1, $2, $3, $4) RETURNING id',
      [req.instructorId, title.trim(), content.trim(), imageUrl],
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

// Edit an announcement -- only the instructor who created it may. Passing
// a new image replaces the old file; passing removeImage='true' with no
// new file clears it.
router.patch('/:id', upload.single('image'), async (req, res) => {
  try {
    const announcementId = Number(req.params.id);
    const existing = await pool.query(
      'SELECT * FROM announcements WHERE id = $1 AND instructor_id = $2',
      [announcementId, req.instructorId],
    );
    if (existing.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Announcement not found.' });
    }
    const current = existing.rows[0];

    const { title, content, removeImage } = req.body;
    const classIds = req.body.classIds != null ? JSON.parse(req.body.classIds) : null;
    if (!title || !content) {
      return res.status(400).json({ success: false, message: 'title and content are required.' });
    }
    if (classIds != null) {
      if (!Array.isArray(classIds) || classIds.length === 0) {
        return res
          .status(400)
          .json({ success: false, message: 'At least one target section is required.' });
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
    }

    let imageUrl = current.image_url;
    if (req.file) {
      deleteImageFile(current.image_url);
      imageUrl = `/uploads/announcements/${req.file.filename}`;
    } else if (removeImage === 'true') {
      deleteImageFile(current.image_url);
      imageUrl = null;
    }

    await pool.query(
      'UPDATE announcements SET title = $1, content = $2, image_url = $3 WHERE id = $4',
      [title.trim(), content.trim(), imageUrl, announcementId],
    );

    if (classIds != null) {
      await pool.query('DELETE FROM announcement_targets WHERE announcement_id = $1', [
        announcementId,
      ]);
      for (const classId of classIds) {
        await pool.query(
          'INSERT INTO announcement_targets (announcement_id, class_id) VALUES ($1, $2)',
          [announcementId, classId],
        );
      }
    }

    const full = await pool.query(`${SELECT_WITH_TARGETS} WHERE a.id = $1 GROUP BY a.id`, [
      announcementId,
    ]);
    res.json({ success: true, announcement: full.rows[0] });
  } catch (error) {
    console.error('Update announcement error:', error);
    res.status(500).json({ success: false, message: 'Failed to update announcement.' });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const announcementId = Number(req.params.id);
    const existing = await pool.query(
      'SELECT image_url FROM announcements WHERE id = $1 AND instructor_id = $2',
      [announcementId, req.instructorId],
    );
    if (existing.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Announcement not found.' });
    }

    await pool.query('DELETE FROM announcements WHERE id = $1', [announcementId]);
    deleteImageFile(existing.rows[0].image_url);

    res.json({ success: true });
  } catch (error) {
    console.error('Delete announcement error:', error);
    res.status(500).json({ success: false, message: 'Failed to delete announcement.' });
  }
});

module.exports = router;
