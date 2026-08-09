const jwt = require('jsonwebtoken');
const pool = require('../db');

// Unlike the student/instructor auth middleware, this one actually
// enforces session revocation on every request (not just embedding a
// sessionId for logout bookkeeping) -- so "Terminate Session" in the
// Profile screen genuinely kills a session's access, not just its row.
async function requireAdminAuth(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return res
      .status(401)
      .json({ success: false, message: 'Missing or invalid Authorization header.' });
  }

  const token = header.slice('Bearer '.length);
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    if (payload.role !== 'admin') {
      return res.status(401).json({ success: false, message: 'Invalid token for this resource.' });
    }

    if (payload.sessionId) {
      const result = await pool.query(
        `SELECT logout_at, revoked_at FROM admin_login_history WHERE id = $1 AND admin_id = $2`,
        [payload.sessionId, payload.adminId],
      );
      const session = result.rows[0];
      if (!session || session.logout_at || session.revoked_at) {
        return res
          .status(401)
          .json({ success: false, message: 'Session has been logged out or revoked.' });
      }
    }

    req.adminId = payload.adminId;
    req.sessionId = payload.sessionId ?? null;
    next();
  } catch (error) {
    return res.status(401).json({ success: false, message: 'Invalid or expired token.' });
  }
}

// sessionId is embedded so requireAdminAuth can look up exactly this
// admin_login_history row on every request (see above).
function generateAdminToken(adminId, sessionId) {
  return jwt.sign({ adminId, role: 'admin', sessionId }, process.env.JWT_SECRET, {
    expiresIn: '7d',
  });
}

module.exports = { requireAdminAuth, generateAdminToken };
