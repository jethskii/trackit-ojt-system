const pool = require('../db');

// One row per issued admin token (login only -- no self-registration).
// Its id gets embedded in the JWT as `sessionId` so logout/termination
// can target exactly this row, and requireAdminAuth checks it on every
// request (see middleware/adminAuth.js).
async function createAdminSession(adminId, userAgent, ipAddress) {
  const result = await pool.query(
    `INSERT INTO admin_login_history (admin_id, user_agent, ip_address) VALUES ($1, $2, $3) RETURNING id`,
    [adminId, userAgent || null, ipAddress || null],
  );
  return result.rows[0].id;
}

module.exports = { createAdminSession };
