const jwt = require('jsonwebtoken');

function requireInstructorAuth(req, res, next) {
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
