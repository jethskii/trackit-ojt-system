const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const path = require('path');
const pool = require('../db');
const { requireAdminAuth } = require('../middleware/adminAuth');
const { generateOtpCode, maskEmail } = require('../utils/otp');
const { sendOtpEmail } = require('../utils/mailer');

const router = express.Router();
router.use(requireAdminAuth);

const OTP_TTL_MINUTES = 10;
const OTP_RESEND_COOLDOWN_SECONDS = 60;
const OTP_MAX_ATTEMPTS = 5;
const RESET_TOKEN_TTL_MINUTES = 5;

const storage = multer.diskStorage({
  destination: path.join(__dirname, '..', 'uploads', 'avatars'),
  filename: (req, file, cb) => {
    const unique = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    cb(null, `${unique}${path.extname(file.originalname)}`);
  },
});
const upload = multer({
  storage,
  limits: { fileSize: 2 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowed = ['image/jpeg', 'image/png'];
    cb(null, allowed.includes(file.mimetype));
  },
});

function deviceLabelFrom(userAgent) {
  if (!userAgent) return 'Unknown device';
  const ua = userAgent;
  let os = 'Unknown OS';
  if (/windows/i.test(ua)) os = 'Windows';
  else if (/mac os|macintosh/i.test(ua)) os = 'macOS';
  else if (/android/i.test(ua)) os = 'Android';
  else if (/iphone|ipad|ios/i.test(ua)) os = 'iOS';
  else if (/linux/i.test(ua)) os = 'Linux';

  let browser = 'Unknown browser';
  if (/edg\//i.test(ua)) browser = 'Edge';
  else if (/chrome\//i.test(ua) && !/chromium/i.test(ua)) browser = 'Chrome';
  else if (/firefox\//i.test(ua)) browser = 'Firefox';
  else if (/safari\//i.test(ua) && !/chrome\//i.test(ua)) browser = 'Safari';
  else if (/dart|flutter/i.test(ua)) browser = 'TrackIT App';

  return `${browser} on ${os}`;
}

// Combined single-save edit: name, email, and/or a new avatar in one
// request, matching the spec's single Edit Profile form rather than
// separate endpoints per field.
router.patch('/', upload.single('avatar'), async (req, res) => {
  try {
    const { name, email } = req.body;
    if (name !== undefined && !name.trim()) {
      return res.status(400).json({ success: false, message: 'Name cannot be empty.' });
    }
    if (email !== undefined && !email.trim()) {
      return res.status(400).json({ success: false, message: 'Email cannot be empty.' });
    }
    if (req.file && !req.file.mimetype) {
      // multer's fileFilter already rejects non-jpg/png silently (no
      // req.file set); this branch is unreachable but documents intent.
    }

    let normalizedEmail;
    if (email !== undefined) {
      normalizedEmail = email.toLowerCase().trim();
      const existing = await pool.query('SELECT id FROM admins WHERE email = $1 AND id != $2', [
        normalizedEmail,
        req.adminId,
      ]);
      if (existing.rows.length > 0) {
        return res.status(409).json({ success: false, message: 'That email is already in use.' });
      }
    }

    const avatarUrl = req.file ? `/uploads/avatars/${req.file.filename}` : undefined;

    const result = await pool.query(
      `UPDATE admins
       SET name = COALESCE($1, name),
           email = COALESCE($2, email),
           avatar_url = COALESCE($3, avatar_url)
       WHERE id = $4
       RETURNING id, name, email, avatar_url, password_changed_at, status`,
      [name?.trim(), normalizedEmail, avatarUrl, req.adminId],
    );
    const admin = result.rows[0];
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
    console.error('Update admin profile error:', error);
    res.status(500).json({ success: false, message: 'Failed to update profile.' });
  }
});

// Real active/recent sessions -- never sample data. current: true marks
// the session this very request is authenticated with.
router.get('/sessions', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, login_at, logout_at, revoked_at, user_agent, ip_address
       FROM admin_login_history
       WHERE admin_id = $1
       ORDER BY login_at DESC
       LIMIT 50`,
      [req.adminId],
    );
    res.json({
      success: true,
      sessions: result.rows.map((row) => ({
        id: Number(row.id),
        device: deviceLabelFrom(row.user_agent),
        ipAddress: row.ip_address,
        loginAt: row.login_at,
        logoutAt: row.logout_at,
        revokedAt: row.revoked_at,
        active: !row.logout_at && !row.revoked_at,
        current: Number(row.id) === Number(req.sessionId),
      })),
    });
  } catch (error) {
    console.error('Get admin sessions error:', error);
    res.status(500).json({ success: false, message: 'Failed to load sessions.' });
  }
});

// Real termination -- requireAdminAuth checks revoked_at on every
// subsequent request for that session's token, so this isn't cosmetic.
router.delete('/sessions/:id', async (req, res) => {
  try {
    const sessionId = Number(req.params.id);
    const result = await pool.query(
      `UPDATE admin_login_history
       SET revoked_at = now()
       WHERE id = $1 AND admin_id = $2 AND logout_at IS NULL AND revoked_at IS NULL
       RETURNING id`,
      [sessionId, req.adminId],
    );
    if (result.rows.length === 0) {
      return res
        .status(404)
        .json({ success: false, message: 'Session not found or already ended.' });
    }
    res.json({ success: true });
  } catch (error) {
    console.error('Revoke admin session error:', error);
    res.status(500).json({ success: false, message: 'Failed to terminate session.' });
  }
});

// Step 1 of change-password: email a one-time code to the admin's own
// registered address. Cooldown prevents resend spam; code is stored
// bcrypt-hashed, never in plaintext.
router.post('/change-password/request-otp', async (req, res) => {
  try {
    const adminResult = await pool.query('SELECT email FROM admins WHERE id = $1', [req.adminId]);
    const admin = adminResult.rows[0];
    if (!admin) {
      return res.status(404).json({ success: false, message: 'Admin not found.' });
    }

    const recentResult = await pool.query(
      `SELECT created_at FROM admin_password_otps
       WHERE admin_id = $1 ORDER BY created_at DESC LIMIT 1`,
      [req.adminId],
    );
    const recent = recentResult.rows[0];
    if (recent) {
      const secondsSince = (Date.now() - new Date(recent.created_at).getTime()) / 1000;
      if (secondsSince < OTP_RESEND_COOLDOWN_SECONDS) {
        return res.status(429).json({
          success: false,
          message: `Please wait ${Math.ceil(OTP_RESEND_COOLDOWN_SECONDS - secondsSince)}s before requesting another code.`,
        });
      }
    }

    const code = generateOtpCode();
    const codeHash = await bcrypt.hash(code, 10);
    const expiresAt = new Date(Date.now() + OTP_TTL_MINUTES * 60 * 1000);
    await pool.query(
      `INSERT INTO admin_password_otps (admin_id, code_hash, expires_at) VALUES ($1, $2, $3)`,
      [req.adminId, codeHash, expiresAt],
    );

    await sendOtpEmail(admin.email, code);

    res.json({ success: true, maskedEmail: maskEmail(admin.email) });
  } catch (error) {
    console.error('Request admin password OTP error:', error);
    const message = /not configured/i.test(error.message)
      ? error.message
      : 'Failed to send verification code.';
    res.status(500).json({ success: false, message });
  }
});

// Step 2: verify the code, then hand back a short-lived reset token that
// /change-password/confirm must present -- so the final step can't be
// called directly without ever having proven the OTP.
router.post('/change-password/verify-otp', async (req, res) => {
  try {
    const { code } = req.body;
    if (!code) {
      return res.status(400).json({ success: false, message: 'code is required.' });
    }

    const otpResult = await pool.query(
      `SELECT * FROM admin_password_otps
       WHERE admin_id = $1 AND used_at IS NULL AND expires_at > now()
       ORDER BY created_at DESC LIMIT 1`,
      [req.adminId],
    );
    const otp = otpResult.rows[0];
    if (!otp) {
      return res
        .status(400)
        .json({ success: false, message: 'Code has expired. Please request a new one.' });
    }
    if (otp.attempts >= OTP_MAX_ATTEMPTS) {
      return res
        .status(429)
        .json({ success: false, message: 'Too many incorrect attempts. Please request a new code.' });
    }

    const matches = await bcrypt.compare(code.toString().trim(), otp.code_hash);
    if (!matches) {
      await pool.query('UPDATE admin_password_otps SET attempts = attempts + 1 WHERE id = $1', [
        otp.id,
      ]);
      return res.status(400).json({ success: false, message: 'Incorrect code.' });
    }

    await pool.query('UPDATE admin_password_otps SET verified_at = now() WHERE id = $1', [otp.id]);

    const resetToken = jwt.sign(
      { adminId: req.adminId, otpId: Number(otp.id), purpose: 'admin-password-reset' },
      process.env.JWT_SECRET,
      { expiresIn: `${RESET_TOKEN_TTL_MINUTES}m` },
    );
    res.json({ success: true, resetToken });
  } catch (error) {
    console.error('Verify admin password OTP error:', error);
    res.status(500).json({ success: false, message: 'Failed to verify code.' });
  }
});

// Step 3: actually change the password. Requires both normal auth
// (router-level requireAdminAuth) and the reset token from step 2.
router.post('/change-password/confirm', async (req, res) => {
  try {
    const { resetToken, newPassword, confirmPassword } = req.body;
    if (!resetToken || !newPassword || !confirmPassword) {
      return res.status(400).json({
        success: false,
        message: 'resetToken, newPassword, and confirmPassword are required.',
      });
    }
    if (newPassword !== confirmPassword) {
      return res.status(400).json({ success: false, message: 'Passwords do not match.' });
    }
    if (newPassword.length < 8) {
      return res
        .status(400)
        .json({ success: false, message: 'New password must be at least 8 characters.' });
    }

    let payload;
    try {
      payload = jwt.verify(resetToken, process.env.JWT_SECRET);
    } catch {
      return res
        .status(401)
        .json({ success: false, message: 'Reset session has expired. Please verify the code again.' });
    }
    if (payload.purpose !== 'admin-password-reset' || payload.adminId !== req.adminId) {
      return res.status(401).json({ success: false, message: 'Invalid reset session.' });
    }

    const otpResult = await pool.query(
      `SELECT * FROM admin_password_otps WHERE id = $1 AND admin_id = $2`,
      [payload.otpId, req.adminId],
    );
    const otp = otpResult.rows[0];
    if (!otp || !otp.verified_at || otp.used_at) {
      return res
        .status(401)
        .json({ success: false, message: 'Reset session is no longer valid. Please verify the code again.' });
    }

    const newHash = await bcrypt.hash(newPassword, 10);
    await pool.query(
      `UPDATE admins SET password_hash = $1, password_changed_at = now() WHERE id = $2`,
      [newHash, req.adminId],
    );
    await pool.query('UPDATE admin_password_otps SET used_at = now() WHERE id = $1', [otp.id]);

    res.json({ success: true, message: 'Password changed successfully.' });
  } catch (error) {
    console.error('Confirm admin password change error:', error);
    res.status(500).json({ success: false, message: 'Failed to change password.' });
  }
});

module.exports = router;
