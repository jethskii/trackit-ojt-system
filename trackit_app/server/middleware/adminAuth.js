const jwt = require('jsonwebtoken');

function requireAdminAuth(req, res, next) {
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
    req.adminId = payload.adminId;
    next();
  } catch (error) {
    return res.status(401).json({ success: false, message: 'Invalid or expired token.' });
  }
}

function generateAdminToken(adminId) {
  return jwt.sign({ adminId, role: 'admin' }, process.env.JWT_SECRET, { expiresIn: '7d' });
}

module.exports = { requireAdminAuth, generateAdminToken };
