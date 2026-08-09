const jwt = require('jsonwebtoken');
const pool = require('../db');

// Checks `status` on every request (not just at login) so Revoke Access
// actually cuts off an already-issued token immediately, the same real
// enforcement pattern used for Admin session revocation.
async function requireInstructorAuth(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return res
      .status(401)
      .json({ success: false, message: 'Missing or invalid Authorization header.' });
  }

  const token = header.slice('Bearer '.length);
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    if (payload.role !== 'instructor') {
      return res.status(401).json({ success: false, message: 'Invalid token for this resource.' });
    }

    const result = await pool.query('SELECT status FROM advisers WHERE id = $1', [
      payload.instructorId,
    ]);
    const instructor = result.rows[0];
    if (!instructor || instructor.status === 'inactive') {
      return res
        .status(403)
        .json({ success: false, message: 'This account has been deactivated.' });
    }

    req.instructorId = payload.instructorId;
    next();
  } catch (error) {
    return res.status(401).json({ success: false, message: 'Invalid or expired token.' });
  }
}

function generateInstructorToken(instructorId) {
  return jwt.sign({ instructorId, role: 'instructor' }, process.env.JWT_SECRET, {
    expiresIn: '7d',
  });
}

module.exports = { requireInstructorAuth, generateInstructorToken };
