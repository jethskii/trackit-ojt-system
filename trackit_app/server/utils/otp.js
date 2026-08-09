const crypto = require('crypto');

// 6-digit numeric code, zero-padded (e.g. "042613") -- crypto.randomInt
// is cryptographically secure, unlike Math.random().
function generateOtpCode() {
  return crypto.randomInt(0, 1000000).toString().padStart(6, '0');
}

// user@example.com -> u***@example.com. Only ever shown to the account
// owner who already knows their own email, so this is just avoiding
// putting the full address on screen, not real secrecy.
function maskEmail(email) {
  const [local, domain] = email.split('@');
  if (!domain) return email;
  const visible = local.slice(0, 1);
  return `${visible}${'*'.repeat(Math.max(local.length - 1, 3))}@${domain}`;
}

module.exports = { generateOtpCode, maskEmail };
