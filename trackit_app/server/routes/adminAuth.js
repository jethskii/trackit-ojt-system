const express = require('express');
const bcrypt = require('bcrypt');
const pool = require('../db');
const { generateAdminToken } = require('../middleware/adminAuth');

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

    const token = generateAdminToken(admin.id);
    res.json({
      success: true,
      token,
      admin: { id: Number(admin.id), name: admin.name, email: admin.email },
    });
  } catch (error) {
    console.error('Admin login error:', error);
    res.status(500).json({ success: false, message: 'Login failed.' });
  }
});

module.exports = router;
