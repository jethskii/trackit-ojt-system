const express = require('express');
const fs = require('fs');
const multer = require('multer');
const path = require('path');
const pool = require('../db');
const { requireAdminAuth } = require('../middleware/adminAuth');

const router = express.Router();
router.use(requireAdminAuth);

const storage = multer.diskStorage({
  destination: path.join(__dirname, '..', 'uploads', 'admin-announcements'),
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

const VALID_AUDIENCES = ['all', 'instructors', 'students'];

function deleteImageFile(imageUrl) {
  if (!imageUrl) return;
  const filePath = path.join(__dirname, '..', imageUrl.replace(/^\//, ''));
  fs.unlink(filePath, (err) => {
    if (err && err.code !== 'ENOENT') {
      console.error('Failed to delete admin announcement image file:', err);
    }
  });
}

router.get('/', async (req, res) => {
  try {
    const { search } = req.query;
    const params = [];
    let where = '';
    if (search) {
      params.push(`%${search.toString().toLowerCase()}%`);
      where = 'WHERE LOWER(aa.title) LIKE $1 OR LOWER(aa.content) LIKE $1';
    }
    const result = await pool.query(
      `SELECT aa.*, a.name AS admin_name
       FROM admin_announcements aa
       JOIN admins a ON a.id = aa.admin_id
       ${where}
       ORDER BY aa.created_at DESC`,
      params,
    );
    res.json({
      success: true,
      announcements: result.rows.map((row) => ({
        id: Number(row.id),
        title: row.title,
        content: row.content,
        targetAudience: row.target_audience,
        imageUrl: row.image_url,
        adminName: row.admin_name,
        createdAt: row.created_at,
      })),
    });
  } catch (error) {
    console.error('Get admin announcements error:', error);
    res.status(500).json({ success: false, message: 'Failed to load announcements.' });
  }
});

// Fans out into the existing flattened notification tables (category
// 'admin', already a recognized category on both sides -- the Student
// Notifications tab already styles it distinctly, and the instructor
// Home Dashboard's "Recent Notifications" reads instructor_notifications
// directly). The rich version students see on their Dashboard is read
// fresh from GET /api/announcements, which unions this table in.
router.post('/', upload.single('image'), async (req, res) => {
  try {
    const { title, content } = req.body;
    const targetAudience = (req.body.targetAudience || 'all').toString();
    if (!title || !content) {
      return res
        .status(400)
        .json({ success: false, message: 'title and content are required.' });
    }
    if (!VALID_AUDIENCES.includes(targetAudience)) {
      return res.status(400).json({ success: false, message: 'Invalid target audience.' });
    }

    const imageUrl = req.file ? `/uploads/admin-announcements/${req.file.filename}` : null;

    const inserted = await pool.query(
      `INSERT INTO admin_announcements (admin_id, title, content, target_audience, image_url)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [req.adminId, title.trim(), content.trim(), targetAudience, imageUrl],
    );
    const row = inserted.rows[0];

    if (targetAudience === 'all' || targetAudience === 'students') {
      await pool.query(
        `INSERT INTO notifications (receiver_id, category, title, message)
         SELECT id, 'admin', $1, $2 FROM students`,
        [title.trim(), content.trim()],
      );
    }
    if (targetAudience === 'all' || targetAudience === 'instructors') {
      await pool.query(
        `INSERT INTO instructor_notifications (instructor_id, category, title, message)
         SELECT id, 'admin', $1, $2 FROM advisers`,
        [title.trim(), content.trim()],
      );
    }

    const adminResult = await pool.query('SELECT name FROM admins WHERE id = $1', [
      req.adminId,
    ]);

    res.status(201).json({
      success: true,
      announcement: {
        id: Number(row.id),
        title: row.title,
        content: row.content,
        targetAudience: row.target_audience,
        imageUrl: row.image_url,
        adminName: adminResult.rows[0]?.name ?? '',
        createdAt: row.created_at,
      },
    });
  } catch (error) {
    console.error('Create admin announcement error:', error);
    res.status(500).json({ success: false, message: 'Failed to create announcement.' });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const announcementId = Number(req.params.id);
    const existing = await pool.query(
      'SELECT image_url FROM admin_announcements WHERE id = $1 AND admin_id = $2',
      [announcementId, req.adminId],
    );
    if (existing.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Announcement not found.' });
    }

    await pool.query('DELETE FROM admin_announcements WHERE id = $1', [announcementId]);
    deleteImageFile(existing.rows[0].image_url);

    res.json({ success: true });
  } catch (error) {
    console.error('Delete admin announcement error:', error);
    res.status(500).json({ success: false, message: 'Failed to delete announcement.' });
  }
});

module.exports = router;
