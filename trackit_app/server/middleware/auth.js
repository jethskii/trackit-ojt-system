const jwt = require('jsonwebtoken');

// Role is checked (not just the presence of studentId) so a token minted
// for one role family can't be replayed against the other's routes --
// matters now that instructor tokens exist too (see instructorAuth.js).
function requireAuth(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return res
      .status(401)
      .json({ success: false, message: 'Missing or invalid Authorization header.' });
  }

  const token = header.slice('Bearer '.length);
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    if (payload.role !== 'student') {
      return res.status(401).json({ success: false, message: 'Invalid token for this resource.' });
    }
    req.studentId = payload.studentId;
    next();
  } catch (error) {
    return res.status(401).json({ success: false, message: 'Invalid or expired token.' });
  }
}

// 7-day expiry, no refresh token flow yet -- fine for now, revisit once
// the app needs tighter session control.
function generateToken(studentId) {
  return jwt.sign({ studentId, role: 'student' }, process.env.JWT_SECRET, { expiresIn: '7d' });
}

module.exports = { requireAuth, generateToken };
