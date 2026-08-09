const express = require('express');
const bcrypt = require('bcrypt');
const pool = require('../db');
const { generateAdminToken, requireAdminAuth } = require('../middleware/adminAuth');
const { createAdminSession } = require('../utils/adminSessions');

const router = express.Router();

// No self-registration -- admin accounts are seeded directly (see
// migration_admin.sql). Login only.
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res
        .status(400)
        .json({ success: false, message: 'email and password are required.' });
    }

    const normalizedEmail = email.toLowerCase().trim();
    const result = await pool.query('SELECT * FROM admins WHERE email = $1', [normalizedEmail]);
    const admin = result.rows[0];
    if (!admin) {
      return res.status(401).json({ success: false, message: 'Invalid email or password.' });
    }

    const passwordMatches = await bcrypt.compare(password, admin.password_hash);
    if (!passwordMatches) {
      return res.status(401).json({ success: false, message: 'Invalid email or password.' });
    }

    const sessionId = await createAdminSession(admin.id, req.get('User-Agent'), req.ip);
    const token = generateAdminToken(admin.id, sessionId);
    res.json({
      success: true,
      token,
      admin: {
        id: Number(admin.id),
        name: admin.name,
        email: admin.email,
        avatarUrl: admin.avatar_url,
        lastPasswordChange: admin.password_changed_at,
        status: admin.status,
      },
    });
  } catch (error) {
    console.error('Admin login error:', error);
    res.status(500).json({ success: false, message: 'Login failed.' });
  }
});

// Used by the Flutter sidebar/profile screen to show the real logged-in
// admin's identity -- the token only carries adminId, not the rest, so a
// fresh app launch (token restored from storage, no login response in
// memory) needs this to render anything beyond a placeholder.
router.get('/me', requireAdminAuth, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, name, email, avatar_url, password_changed_at, status
       FROM admins WHERE id = $1`,
      [req.adminId],
    );
    const admin = result.rows[0];
    if (!admin) {
      return res.status(404).json({ success: false, message: 'Admin not found.' });
    }
    res.json({
      success: true,
      admin: {
        id: Number(admin.id),
        name: admin.name,
        email: admin.email,
        avatarUrl: admin.avatar_url,
        lastPasswordChange: admin.password_changed_at,
        status: admin.status,
      },
    });
  } catch (error) {
    console.error('Get admin me error:', error);
    res.status(500).json({ success: false, message: 'Failed to load admin.' });
  }
});

// Closes the session this token belongs to, mirroring the student
// auth.js pattern -- never touches other sessions/devices.
router.post('/logout', requireAdminAuth, async (req, res) => {
  try {
    if (req.sessionId) {
      await pool.query(
        `UPDATE admin_login_history SET logout_at = now()
         WHERE id = $1 AND admin_id = $2 AND logout_at IS NULL`,
        [req.sessionId, req.adminId],
      );
    }
    res.json({ success: true });
  } catch (error) {
    console.error('Admin logout error:', error);
    res.status(500).json({ success: false, message: 'Failed to log out.' });
  }
});

module.exports = router;
